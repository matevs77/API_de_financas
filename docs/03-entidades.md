# Entidades de domínio

Modelo **Plano v2**: domínio em `com.financas.api.domain.model` (sem JPA). Persistência em `*JpaEntity` na infraestrutura.

## Diagrama ER

```mermaid
erDiagram
    USER ||--o{ ACCOUNT : owns
    USER ||--o{ CATEGORY : owns
    USER ||--o{ BUDGET : defines
    USER ||--o{ GOAL : defines
    USER ||--o{ REFRESH_TOKEN : has
    ACCOUNT ||--o{ TRANSACTION : has
    ACCOUNT ||--o{ TRANSFER : from
    ACCOUNT ||--o{ TRANSFER : to
    CATEGORY ||--o{ TRANSACTION : classifies
    CATEGORY ||--o{ BUDGET : limits
    TRANSFER ||--o| TRANSACTION : debit
    TRANSFER ||--o| TRANSACTION : credit

    USER {
        uuid id PK
        string email UK
        string password_hash
        string name
        boolean active
        datetime created_at
        datetime updated_at
    }

    ACCOUNT {
        uuid id PK
        uuid user_id FK
        string name
        enum type
        decimal initial_balance
        string currency
        boolean active
        audit fields
    }

    CATEGORY {
        uuid id PK
        uuid user_id FK
        string name
        enum kind
        uuid parent_id FK
        boolean system_default
        audit fields
    }

    TRANSACTION {
        uuid id PK
        uuid user_id FK
        uuid account_id FK
        uuid category_id FK
        uuid transfer_id FK
        enum type
        decimal amount
        date occurred_on
        string description
        audit fields
    }

    TRANSFER {
        uuid id PK
        uuid user_id FK
        uuid from_account_id FK
        uuid to_account_id FK
        decimal amount
        date occurred_on
        string description
        enum status
        audit fields
    }

    BUDGET {
        uuid id PK
        uuid user_id FK
        uuid category_id FK
        decimal limit_amount
        date period_start
        date period_end
        audit fields
    }

    GOAL {
        uuid id PK
        uuid user_id FK
        string name
        decimal target_amount
        decimal current_amount
        date deadline
        audit fields
    }
```

## Auditoria (BaseEntity)

### Domínio — `AuditableDomain`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `UUID` | Identificador |
| `createdAt` | `Instant` ou `LocalDateTime` | UTC |
| `updatedAt` | `Instant` ou `LocalDateTime` | UTC |
| `createdBy` | `String` (opcional) | `userId` do JWT |
| `updatedBy` | `String` (opcional) | `userId` do JWT |

Entidades que estendem: `Account`, `Category`, `Transaction`, `Transfer`, `Budget`, `Goal`.

`User` e `RefreshToken` podem ter auditoria simplificada (apenas timestamps) sem `createdBy`/`updatedBy` se preferível.

### JPA — `BaseJpaEntity`

- `@EntityListeners(AuditingEntityListener.class)`
- `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`
- `@EnableJpaAuditing` + `AuditorAware<String>` na config

## Entidades — detalhe

### User

| Campo | Tipo | Regras |
|-------|------|--------|
| `id` | UUID | Gerado na criação |
| `email` | String | Único, formato válido |
| `passwordHash` | String | BCrypt; nunca expor na API |
| `name` | String | Obrigatório |
| `active` | boolean | Default `true` |
| `createdAt`, `updatedAt` | DateTime | Auditoria |

**Nota:** `User` não implementa lógica de domínio financeiro; pode integrar com Spring Security via adapter na infra.

### Account

| Campo | Tipo | Regras |
|-------|------|--------|
| `userId` | UUID | FK obrigatória |
| `name` | String | Único por utilizador (recomendado) |
| `type` | `AccountType` | CHECKING, SAVINGS, CASH, CREDIT |
| `initialBalance` | BigDecimal | Default 0 |
| `currency` | String | ISO 4217 (ex.: BRL, EUR) |
| `active` | boolean | Conta inactiva não aceita novas transações |

**Saldo calculado (MVP):**

```
saldo = initialBalance
      + Σ(transações INCOME na conta)
      - Σ(transações EXPENSE na conta)
      ± efeito líquido de transferências (via transações ligadas a Transfer)
```

Cálculo **on read** no `BalanceCalculator` (domínio) ou query na infra.

### Category

| Campo | Tipo | Regras |
|-------|------|--------|
| `userId` | UUID | Nullable se categoria de sistema |
| `name` | String | Único por (userId, name) |
| `kind` | `CategoryKind` | INCOME ou EXPENSE |
| `parentId` | UUID | Opcional; hierarquia |
| `systemDefault` | boolean | Se true, utilizador não pode editar/apagar |

### Transaction

| Campo | Tipo | Regras |
|-------|------|--------|
| `userId` | UUID | Sempre do utilizador autenticado |
| `accountId` | UUID | Conta do mesmo user |
| `categoryId` | UUID | Opcional para alguns casos; obrigatório para INCOME/EXPENSE normais |
| `transferId` | UUID | Nullable; preenchido quando faz parte de uma Transfer |
| `type` | `TransactionType` | INCOME ou EXPENSE apenas |
| `amount` | BigDecimal | `> 0` |
| `occurredOn` | LocalDate | Data do movimento |
| `description` | String | Opcional |

**Não existe** `transferPairId` no Plano v2.

Transações geradas por transferência:
- Uma EXPENSE na conta origem
- Uma INCOME na conta destino
- Ambas com o mesmo `transferId`
- `categoryId` **null** (sem categoria; ver [CONVENCOES.md](CONVENCOES.md))

### Transfer (agregado)

| Campo | Tipo | Regras |
|-------|------|--------|
| `userId` | UUID | Dono do agregado |
| `fromAccountId` | UUID | ≠ `toAccountId` |
| `toAccountId` | UUID | Mesmo user |
| `amount` | BigDecimal | `> 0` |
| `occurredOn` | LocalDate | Data da transferência |
| `description` | String | Opcional |
| `status` | `TransferStatus` | COMPLETED, REVERSED (fase 2) |

Relações:
- `debitTransactionId` / `creditTransactionId` (no domínio ou só via `transferId` nas transações)

### Budget

| Campo | Tipo | Regras |
|-------|------|--------|
| `userId` | UUID | |
| `categoryId` | UUID | Categoria deve ser EXPENSE |
| `limitAmount` | BigDecimal | `> 0` |
| `periodStart` | LocalDate | Início do período |
| `periodEnd` | LocalDate | Fim; `>= periodStart` |

Campos calculados (não persistidos): `spent`, `remaining`, `exceeded`.

### Goal

| Campo | Tipo | Regras |
|-------|------|--------|
| `userId` | UUID | |
| `name` | String | |
| `targetAmount` | BigDecimal | `> 0` |
| `currentAmount` | BigDecimal | `>= 0`, `<= targetAmount` ao contribuir |
| `deadline` | LocalDate | Opcional |

### RefreshToken

| Campo | Tipo | Regras |
|-------|------|--------|
| `userId` | UUID | |
| `tokenHash` | String | Hash do token; não armazenar plain text |
| `expiresAt` | DateTime | |
| `revoked` | boolean | true após logout |

## Enums

```java
public enum AccountType { CHECKING, SAVINGS, CASH, CREDIT }
public enum CategoryKind { INCOME, EXPENSE }
public enum TransactionType { INCOME, EXPENSE }
public enum TransferStatus { COMPLETED, REVERSED }
```

## Diferenças face ao Plano v1

| Plano v1 | Plano v2 |
|----------|----------|
| `transferPairId` em Transaction | `transferId` + entidade Transfer |
| Tipo TRANSFER opcional em Transaction | Apenas INCOME/EXPENSE; transferência é agregado |
| Auditoria ad hoc | `AuditableDomain` / `BaseJpaEntity` |
| Entidades JPA no domain | Domínio puro + `*JpaEntity` |
