# Convenções globais (fonte de verdade)

Este ficheiro fixa valores e regras **canónicos** para toda a documentação e implementação futura. Em caso de dúvida ou conflito entre documentos, **prevalece este ficheiro**, seguido dos ADRs em `docs/adr/`.

## Governança da documentação

1. Alterações de modelo, API ou stack devem actualizar **este ficheiro** e os documentos afectados (`03`, `04`, `05`, `06`, `07`, ADRs).
2. O **Plano v2** é o único alvo de implementação; referências ao Plano v1 são apenas históricas.
3. Não documentar tecnologias fora da stack acordada (ex.: Java 21/25, virtual threads, Spring Boot 4).

---

## Stack (obrigatória)

| Item | Valor canónico |
|------|----------------|
| Java | **17** |
| Spring Boot | **3.x** |
| Base de dados | PostgreSQL 16+ |
| Autenticação | JWT (jjwt 0.12.x) |
| Migrações | Flyway |
| Cache | Spring Cache + **Caffeine** |
| Observabilidade | Spring Boot **Actuator** |
| Mapeamento | MapStruct |
| Pacote base | **`com.financas.api`** |

---

## URLs e paths

| Recurso | URL base |
|---------|----------|
| API REST | `http://localhost:8080/api/v1` |
| Actuator | `http://localhost:8080/actuator` (**fora** do context-path da API) |
| Swagger UI | `http://localhost:8080/api/v1/swagger-ui.html` |
| OpenAPI JSON | `http://localhost:8080/api/v1/api-docs` |

Configuração canónica (`application.yml`):

```yaml
server:
  port: 8080
  servlet:
    context-path: /api/v1

management:
  server:
    add-application-context-path: false
  endpoints:
    web:
      base-path: /actuator
      exposure:
        include: health,info,metrics,caches

springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html
```

---

## JWT

| Parâmetro | Valor |
|-----------|--------|
| Access token TTL | `86400000` ms (24 horas) |
| Refresh token TTL | `604800000` ms (7 dias) |
| Secret | Variável `JWT_SECRET`, ≥ 256 bits em produção |
| Persistência refresh | Tabela `tb_refresh_tokens`, campo `token_hash` |
| Hash do refresh token | **SHA-256** (não armazenar token em texto claro) |
| Password utilizador | **BCrypt** |

---

## Domínio e persistência

| Regra | Valor |
|-------|--------|
| IDs | UUID |
| Montantes | `BigDecimal` / `NUMERIC(15,2)`, sempre `> 0` onde aplicável |
| Timestamps | `TIMESTAMPTZ`, timezone **UTC** |
| Moeda por defeito | **BRL** (`CHAR(3)`) |
| JPA `ddl-auto` | `validate` |
| Transferência | Entidade **`Transfer`** + tabela **`tb_transfers`** |
| Ligação transação ↔ transfer | Coluna **`transfer_id`** em `tb_transactions` |
| `transferPairId` | **Não utilizado** (apenas histórico Plano v1) |
| Transações de transferência | `category_id` **NULL**; `transfer_id` preenchido |
| Tipos de transação | Apenas **`INCOME`** e **`EXPENSE`** |

---

## Cache (relatórios)

| Cache | Nome |
|-------|------|
| Saldo | `balanceReport` |
| Fluxo de caixa | `cashFlow` |
| Por categoria | `categorySummary` |

| Parâmetro | Valor |
|-----------|--------|
| Implementação | Caffeine via `spring.cache.type=caffeine` |
| Spec default | `maximumSize=500,expireAfterWrite=10m` |
| Invalidação | `@CacheEvict` nos writes de `Transaction`, `Transfer`, `Account` |

---

## Orçamento (MVP)

| Comportamento | Valor |
|---------------|--------|
| Ao ultrapassar limite | **Persistir** despesa + `exceeded: true` + header opcional `X-Budget-Warning: true` |
| Modo bloqueante | Fase 2 / configurável (não é o padrão MVP) |

---

## Tabelas Flyway (ordem)

| Versão | Ficheiro | Conteúdo |
|--------|----------|----------|
| V1 | `V1__init_schema.sql` | users, accounts, categories, transactions, budgets, goals, refresh_tokens, índices |
| V2 | `V2__create_transfers.sql` | tb_transfers + `transfer_id` em transactions |

---

## Documentos por tema

| Tema | Documento principal |
|------|---------------------|
| Arquitectura | [01-arquitetura.md](01-arquitetura.md) |
| Pastas | [02-estrutura-directorios.md](02-estrutura-directorios.md) |
| Entidades | [03-entidades.md](03-entidades.md) |
| DTOs | [04-dtos.md](04-dtos.md) |
| Regras | [05-fluxo-regras.md](05-fluxo-regras.md) |
| REST | [06-api-rest.md](06-api-rest.md) |
| SQL / Flyway | [07-persistencia-flyway.md](07-persistencia-flyway.md) |
| Segurança | [08-seguranca-jwt.md](08-seguranca-jwt.md) |
| Cache | [09-cache-relatorios-caffeine.md](09-cache-relatorios-caffeine.md) |
| Actuator | [10-observabilidade-actuator.md](10-observabilidade-actuator.md) |
| Docker | [11-docker-deploy.md](11-docker-deploy.md) |
