# DTOs

Contratos da camada **web** (`com.financas.api.web.dto`). Implementação recomendada: **Java 17 records** com Jakarta Validation.

## Convenções gerais

| Regra | Detalhe |
|-------|---------|
| Request | `Create*Request`, `Update*Request` |
| Response | `*Response` — sem password, sem tokens em logs |
| Paginação | `PageResponse<T>` com `content`, `page`, `size`, `totalElements`, `totalPages` |
| Erros | RFC 7807 Problem Details (não DTO de negócio) |
| Valores | `BigDecimal` para montantes |
| Datas | `LocalDate` para `occurredOn`; ISO-8601 no JSON |

## Validações comuns

| Campo | Anotações sugeridas |
|-------|---------------------|
| `email` | `@NotBlank`, `@Email` |
| `password` | `@NotBlank`, `@Size(min = 8)` (+ política de complexidade se exigida) |
| `amount` | `@NotNull`, `@Positive`, `@Digits(integer = 10, fraction = 2)` |
| `occurredOn` | `@NotNull`, `@PastOrPresent` (configurável) |
| `currency` | `@Pattern` ISO 4217 ou enum |
| UUIDs | `@NotNull` onde obrigatório |

---

## Auth

### Requests

**RegisterRequest**
```java
record RegisterRequest(
    @Email @NotBlank String email,
    @NotBlank @Size(min = 8) String password,
    @NotBlank String name
) {}
```

**LoginRequest**
```java
record LoginRequest(
    @NotBlank String email,
    @NotBlank String password
) {}
```

**RefreshTokenRequest**
```java
record RefreshTokenRequest(@NotBlank String refreshToken) {}
```

### Responses

**AuthResponse**
```java
record AuthResponse(
    String accessToken,
    String refreshToken,
    long expiresInMs,
    String tokenType  // "Bearer"
) {}
```

**UserResponse**
```java
record UserResponse(
    UUID id,
    String email,
    String name,
    boolean active,
    Instant createdAt
) {}
```

---

## Account

**CreateAccountRequest**
```java
record CreateAccountRequest(
    @NotBlank String name,
    @NotNull AccountType type,
    @NotNull @Digits(integer = 10, fraction = 2) BigDecimal initialBalance,
    @NotBlank String currency
) {}
```

**UpdateAccountRequest**
```java
record UpdateAccountRequest(
    String name,
    Boolean active
) {}
```

**AccountResponse**
```java
record AccountResponse(
    UUID id,
    String name,
    AccountType type,
    BigDecimal initialBalance,
    BigDecimal balance,      // calculado
    String currency,
    boolean active,
    Instant createdAt,
    Instant updatedAt
) {}
```

---

## Category

**CreateCategoryRequest**
```java
record CreateCategoryRequest(
    @NotBlank String name,
    @NotNull CategoryKind kind,
    UUID parentId
) {}
```

**UpdateCategoryRequest**
```java
record UpdateCategoryRequest(
    String name,
    UUID parentId
) {}
```

**CategoryResponse**
```java
record CategoryResponse(
    UUID id,
    String name,
    CategoryKind kind,
    UUID parentId,
    boolean systemDefault,
    Instant createdAt
) {}
```

---

## Transaction

**CreateTransactionRequest**
```java
record CreateTransactionRequest(
    @NotNull UUID accountId,
    @NotNull UUID categoryId,
    @NotNull TransactionType type,
    @NotNull @Positive BigDecimal amount,
    @NotNull LocalDate occurredOn,
    String description
) {}
```

**UpdateTransactionRequest**
```java
record UpdateTransactionRequest(
    UUID categoryId,
    BigDecimal amount,
    LocalDate occurredOn,
    String description
) {}
```

**TransactionResponse**
```java
record TransactionResponse(
    UUID id,
    UUID accountId,
    UUID categoryId,
    UUID transferId,           // null se não for parte de transferência
    TransactionType type,
    BigDecimal amount,
    LocalDate occurredOn,
    String description,
    Instant createdAt,
    Instant updatedAt
) {}
```

---

## Transfer

**CreateTransferRequest**
```java
record CreateTransferRequest(
    @NotNull UUID fromAccountId,
    @NotNull UUID toAccountId,
    @NotNull @Positive BigDecimal amount,
    @NotNull LocalDate occurredOn,
    String description
) {}
```

**TransferResponse**
```java
record TransferResponse(
    UUID id,
    UUID fromAccountId,
    UUID toAccountId,
    BigDecimal amount,
    LocalDate occurredOn,
    String description,
    TransferStatus status,
    UUID debitTransactionId,
    UUID creditTransactionId,
    Instant createdAt
) {}
```

---

## Budget

**CreateBudgetRequest**
```java
record CreateBudgetRequest(
    @NotNull UUID categoryId,
    @NotNull @Positive BigDecimal limitAmount,
    @NotNull LocalDate periodStart,
    @NotNull LocalDate periodEnd
) {}
```

**UpdateBudgetRequest**
```java
record UpdateBudgetRequest(
    BigDecimal limitAmount,
    LocalDate periodStart,
    LocalDate periodEnd
) {}
```

**BudgetResponse**
```java
record BudgetResponse(
    UUID id,
    UUID categoryId,
    BigDecimal limitAmount,
    LocalDate periodStart,
    LocalDate periodEnd,
    BigDecimal spent,          // calculado
    BigDecimal remaining,      // calculado
    boolean exceeded,          // calculado
    Instant createdAt
) {}
```

---

## Goal

**CreateGoalRequest**
```java
record CreateGoalRequest(
    @NotBlank String name,
    @NotNull @Positive BigDecimal targetAmount,
    LocalDate deadline
) {}
```

**UpdateGoalRequest**
```java
record UpdateGoalRequest(
    String name,
    BigDecimal targetAmount,
    LocalDate deadline
) {}
```

**ContributeGoalRequest**
```java
record ContributeGoalRequest(
    @NotNull @Positive BigDecimal amount
) {}
```

**GoalResponse**
```java
record GoalResponse(
    UUID id,
    String name,
    BigDecimal targetAmount,
    BigDecimal currentAmount,
    BigDecimal progressPercent,  // calculado
    LocalDate deadline,
    Instant createdAt
) {}
```

---

## Report

**ReportFilterRequest** (query params ou record)
```java
record ReportFilterRequest(
    @NotNull LocalDate from,
    @NotNull LocalDate to,
    UUID accountId,      // opcional
    UUID categoryId      // opcional
) {}
```

**BalanceReportResponse**
```java
record BalanceReportResponse(
    List<AccountBalanceItem> accounts,
    BigDecimal totalBalance
) {}

record AccountBalanceItem(
    UUID accountId,
    String accountName,
    BigDecimal balance
) {}
```

**CashFlowResponse**
```java
record CashFlowResponse(
    List<CashFlowPeriodItem> periods,
    BigDecimal totalIncome,
    BigDecimal totalExpense,
    BigDecimal net
) {}

record CashFlowPeriodItem(
    String period,           // ex.: "2026-05" ou "2026-05-26"
    BigDecimal income,
    BigDecimal expense,
    BigDecimal net
) {}
```

**CategorySummaryResponse**
```java
record CategorySummaryResponse(
    List<CategorySummaryItem> categories,
    BigDecimal total
) {}

record CategorySummaryItem(
    UUID categoryId,
    String categoryName,
    CategoryKind kind,
    BigDecimal total
) {}
```

---

## Common

**PageResponse**
```java
record PageResponse<T>(
    List<T> content,
    int page,
    int size,
    long totalElements,
    int totalPages
) {}
```

---

## Mapa DTO ↔ recurso

| Recurso | Request | Response |
|---------|---------|----------|
| Auth | Register, Login, Refresh | Auth, User |
| Account | Create, Update | Account |
| Category | Create, Update | Category |
| Transaction | Create, Update | Transaction |
| Transfer | Create | Transfer |
| Budget | Create, Update | Budget |
| Goal | Create, Update, Contribute | Goal |
| Report | Filter (query) | Balance, CashFlow, CategorySummary |
| Common | — | Page |

## O que não expor

- `password` / `passwordHash`
- `refreshToken` em listagens (apenas no login/refresh)
- Segredos JWT
- `createdBy` / `updatedBy` (opcional; podem ficar só em auditoria interna)
