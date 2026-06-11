# Persistência e Flyway

## Estratégia

| Aspecto | Escolha |
|---------|---------|
| Schema | Flyway (`classpath:db/migration`) |
| JPA | `spring.jpa.hibernate.ddl-auto=validate` |
| IDs | UUID (`gen_random_uuid()` no PostgreSQL) |
| Valores | `NUMERIC(15,2)` — nunca FLOAT |
| Timezone | UTC em timestamps |
| Domínio ↔ BD | Adapters + MapStruct |

## Convenção de migrações

```
V{n}__descricao_snake_case.sql
```

Exemplos:
- `V1__init_schema.sql`
- `V2__create_transfers.sql`
- `V3__create_accounts_and_budgets.sql`

Regras:
- Migrações **imutáveis** após merge — correcções via nova versão.
- `baseline-on-migrate: true` apenas se integrar BD existente.

---

## Schema previsto (Plano v2)

### V1 — núcleo inicial

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- users
CREATE TABLE tb_users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email        VARCHAR(150) NOT NULL UNIQUE,
    password     VARCHAR(255) NOT NULL,
    name         VARCHAR(100) NOT NULL,
    active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- accounts
CREATE TABLE tb_accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    name            VARCHAR(80) NOT NULL,
    type            VARCHAR(20) NOT NULL CHECK (type IN ('CHECKING','SAVINGS','CASH','CREDIT')),
    initial_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
    currency        CHAR(3) NOT NULL DEFAULT 'BRL',
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(36),
    updated_by      VARCHAR(36),
    UNIQUE (user_id, name)
);

-- categories
CREATE TABLE tb_categories (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES tb_users(id) ON DELETE CASCADE,
    name            VARCHAR(80) NOT NULL,
    kind            VARCHAR(10) NOT NULL CHECK (kind IN ('INCOME','EXPENSE')),
    parent_id       UUID REFERENCES tb_categories(id) ON DELETE SET NULL,
    system_default  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(36),
    updated_by      VARCHAR(36)
);

-- transactions (sem transfer_id na V1 se Transfer vier na V2)
CREATE TABLE tb_transactions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    account_id   UUID NOT NULL REFERENCES tb_accounts(id) ON DELETE CASCADE,
    category_id  UUID REFERENCES tb_categories(id) ON DELETE SET NULL,
    type         VARCHAR(10) NOT NULL CHECK (type IN ('INCOME','EXPENSE')),
    amount       NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    occurred_on  DATE NOT NULL,
    description  VARCHAR(255),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by   VARCHAR(36),
    updated_by   VARCHAR(36)
);

-- budgets
CREATE TABLE tb_budgets (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    category_id   UUID NOT NULL REFERENCES tb_categories(id) ON DELETE CASCADE,
    limit_amount  NUMERIC(15,2) NOT NULL CHECK (limit_amount > 0),
    period_start  DATE NOT NULL,
    period_end    DATE NOT NULL CHECK (period_end >= period_start),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by    VARCHAR(36),
    updated_by    VARCHAR(36)
);

-- goals
CREATE TABLE tb_goals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    target_amount   NUMERIC(15,2) NOT NULL CHECK (target_amount > 0),
    current_amount  NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    deadline        DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(36),
    updated_by      VARCHAR(36)
);

-- refresh tokens
CREATE TABLE tb_refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked     BOOLEAN NOT NULL DEFAULT FALSE
);
```

### V2 — transfers

```sql
CREATE TABLE tb_transfers (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    from_account_id  UUID NOT NULL REFERENCES tb_accounts(id),
    to_account_id    UUID NOT NULL REFERENCES tb_accounts(id),
    amount           NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    occurred_on      DATE NOT NULL,
    description      VARCHAR(255),
    status           VARCHAR(20) NOT NULL DEFAULT 'COMPLETED'
                     CHECK (status IN ('COMPLETED','REVERSED')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by       VARCHAR(36),
    updated_by       VARCHAR(36),
    CHECK (from_account_id <> to_account_id)
);

ALTER TABLE tb_transactions
    ADD COLUMN transfer_id UUID REFERENCES tb_transfers(id) ON DELETE SET NULL;

CREATE INDEX idx_transactions_transfer ON tb_transactions(transfer_id);
CREATE INDEX idx_transfers_user_date ON tb_transfers(user_id, occurred_on);
```

---

## Índices recomendados

```sql
CREATE INDEX idx_transactions_user_date ON tb_transactions(user_id, occurred_on);
CREATE INDEX idx_transactions_account ON tb_transactions(account_id);
CREATE INDEX idx_transactions_category ON tb_transactions(category_id);
CREATE INDEX idx_accounts_user ON tb_accounts(user_id);
CREATE INDEX idx_categories_user ON tb_categories(user_id);
CREATE INDEX idx_budgets_user_category ON tb_budgets(user_id, category_id);
CREATE INDEX idx_goals_user ON tb_goals(user_id);
```

---

## Mapeamento triplo

| Domínio | JPA Entity | Tabela |
|---------|------------|--------|
| `Account` | `AccountJpaEntity` | `tb_accounts` |
| `Transfer` | `TransferJpaEntity` | `tb_transfers` |
| `Transaction` | `TransactionJpaEntity` | `tb_transactions` |

Fluxo:
1. Application Service usa `Account` (domínio).
2. `AccountRepositoryAdapter` chama `AccountMapper.toJpa(domain)`.
3. `AccountJpaRepository.save(jpaEntity)`.

---

## Ports (interfaces no domínio)

```java
public interface AccountRepository {
    Optional<Account> findByIdAndUserId(UUID id, UUID userId);
    Account save(Account account);
    List<Account> findAllByUserId(UUID userId, Pageable pageable);
    void deleteByIdAndUserId(UUID id, UUID userId);
}
```

Implementação: `AccountRepositoryAdapter` em `infrastructure.persistence.adapter`.

---

## Queries de relatório

Localização: `infrastructure.report.ReportQueryAdapter`

- JPQL ou SQL nativo com parâmetros `userId`, `from`, `to`.
- Retorno: DTOs de domínio ou records de leitura (read models).
- **Não** expor entidades JPA para a camada web.

Exemplo — excluir transferências do resumo por categoria:

```sql
SELECT c.id, c.name, SUM(t.amount)
FROM tb_transactions t
JOIN tb_categories c ON t.category_id = c.id
WHERE t.user_id = :userId
  AND t.type = 'EXPENSE'
  AND t.occurred_on BETWEEN :from AND :to
  AND t.transfer_id IS NULL
GROUP BY c.id, c.name;
```

---

## Configuração (application.yml)

Valores canónicos completos em [CONVENCOES.md](CONVENCOES.md). Extracto:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/financas_dev
    username: ${DB_USER:financas_user}
    password: ${DB_PASSWORD:financas_pass}
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        jdbc:
          time_zone: UTC
  flyway:
    enabled: true
    locations: classpath:db/migration
  cache:
    type: caffeine
    cache-names: balanceReport,cashFlow,categorySummary
    caffeine:
      spec: maximumSize=500,expireAfterWrite=10m
```
