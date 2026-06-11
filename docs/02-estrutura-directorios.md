# Estrutura de diretórios

Pacote base: `com.financas.api`

## Árvore do projeto

```
financas-pessoais-api/
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── docs/                          # (cópia ou link; neste repo: APIagentica/docs)
├── src/
│   ├── main/
│   │   ├── java/com/financas/api/
│   │   │   ├── FinancasPessoaisApplication.java
│   │   │   ├── config/
│   │   │   │   ├── SecurityConfig.java
│   │   │   │   ├── JwtProperties.java
│   │   │   │   ├── OpenApiConfig.java
│   │   │   │   ├── CacheConfig.java
│   │   │   │   ├── JpaAuditingConfig.java
│   │   │   │   └── ActuatorSecurityConfig.java
│   │   │   ├── web/
│   │   │   │   ├── controller/
│   │   │   │   │   ├── AuthController.java
│   │   │   │   │   ├── AccountController.java
│   │   │   │   │   ├── CategoryController.java
│   │   │   │   │   ├── TransactionController.java
│   │   │   │   │   ├── TransferController.java
│   │   │   │   │   ├── BudgetController.java
│   │   │   │   │   ├── GoalController.java
│   │   │   │   │   └── ReportController.java
│   │   │   │   ├── dto/
│   │   │   │   │   ├── auth/
│   │   │   │   │   ├── account/
│   │   │   │   │   ├── category/
│   │   │   │   │   ├── transaction/
│   │   │   │   │   ├── transfer/
│   │   │   │   │   ├── budget/
│   │   │   │   │   ├── goal/
│   │   │   │   │   ├── report/
│   │   │   │   │   └── common/
│   │   │   │   ├── mapper/              # DTO ↔ domínio (web)
│   │   │   │   └── exception/
│   │   │   │       └── GlobalExceptionHandler.java
│   │   │   ├── application/
│   │   │   │   ├── service/
│   │   │   │   │   ├── AuthService.java
│   │   │   │   │   ├── AccountService.java
│   │   │   │   │   ├── CategoryService.java
│   │   │   │   │   ├── TransactionService.java
│   │   │   │   │   ├── TransferService.java
│   │   │   │   │   ├── BudgetService.java
│   │   │   │   │   ├── GoalService.java
│   │   │   │   │   └── ReportService.java
│   │   │   │   └── security/
│   │   │   │       └── CurrentUserService.java
│   │   │   ├── domain/
│   │   │   │   ├── model/
│   │   │   │   │   ├── AuditableDomain.java
│   │   │   │   │   ├── User.java
│   │   │   │   │   ├── Account.java
│   │   │   │   │   ├── Category.java
│   │   │   │   │   ├── Transaction.java
│   │   │   │   │   ├── Transfer.java
│   │   │   │   │   ├── Budget.java
│   │   │   │   │   └── Goal.java
│   │   │   │   ├── enums/
│   │   │   │   │   ├── AccountType.java
│   │   │   │   │   ├── CategoryKind.java
│   │   │   │   │   ├── TransactionType.java
│   │   │   │   │   └── TransferStatus.java
│   │   │   │   ├── repository/          # Ports (interfaces)
│   │   │   │   │   ├── UserRepository.java
│   │   │   │   │   ├── AccountRepository.java
│   │   │   │   │   └── ...
│   │   │   │   └── service/
│   │   │   │       ├── BalanceCalculator.java
│   │   │   │       └── TransferValidator.java
│   │   │   └── infrastructure/
│   │   │       ├── persistence/
│   │   │       │   ├── entity/
│   │   │       │   │   ├── BaseJpaEntity.java
│   │   │       │   │   ├── UserJpaEntity.java
│   │   │       │   │   ├── AccountJpaEntity.java
│   │   │       │   │   └── ...
│   │   │       │   ├── repository/        # Spring Data JPA
│   │   │       │   ├── adapter/           # Implementa ports
│   │   │       │   └── mapper/            # MapStruct JPA ↔ domínio
│   │   │       ├── security/
│   │   │       │   ├── JwtTokenProvider.java
│   │   │       │   └── JwtAuthenticationFilter.java
│   │   │       └── report/
│   │   │           └── ReportQueryAdapter.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-docker.yml
│   │       └── db/migration/
│   │           ├── V1__init_schema.sql
│   │           └── V2__create_transfers.sql
│   └── test/
│       ├── java/com/financas/api/
│       │   ├── domain/                    # testes unitários de domínio
│       │   └── integration/               # Testcontainers
│       └── resources/
│           └── application-test.yml
├── pom.xml
├── .env.example
└── README.md
```

## Responsabilidade por pasta

| Pasta | Responsabilidade |
|-------|------------------|
| `config` | Beans Spring: segurança, JWT, cache, auditoria JPA, OpenAPI, Actuator |
| `web.controller` | HTTP, status codes, delegação para application services |
| `web.dto` | Contratos API (records), validação Jakarta |
| `web.exception` | Problem Details, mapeamento de excepções |
| `application.service` | Casos de uso, `@Transactional`, `@Cacheable` / `@CacheEvict` |
| `domain.model` | Entidades de negócio (sem anotações JPA) |
| `domain.repository` | Ports — interfaces que a infra implementa |
| `domain.service` | Regras puras reutilizáveis (saldo, validação de transfer) |
| `infrastructure.persistence` | JPA, adapters, mappers |
| `infrastructure.security` | JWT, filtros |
| `infrastructure.report` | Queries nativas/JPQL para relatórios |

## Convenções de nomenclatura

| Tipo | Sufixo / padrão | Exemplo |
|------|-----------------|---------|
| Controller | `*Controller` | `AccountController` |
| Application service | `*Service` | `TransferService` |
| Port | `*Repository` | `AccountRepository` |
| Adapter | `*RepositoryAdapter` | `AccountRepositoryAdapter` |
| JPA entity | `*JpaEntity` | `AccountJpaEntity` |
| Spring Data | `*JpaRepository` | `AccountJpaRepository` |
| Mapper | `*Mapper` | `AccountMapper` |
| Request DTO | `Create*Request`, `Update*Request` | `CreateAccountRequest` |
| Response DTO | `*Response` | `AccountResponse` |

## Onde configurar cross-cutting

| Preocupação | Localização |
|-------------|-------------|
| JWT secret / expiração | `application.yml` + `JwtProperties` |
| Cache Caffeine | `CacheConfig` + `application.yml` |
| Auditoria `createdBy` | `JpaAuditingConfig` + `AuditorAware` |
| Rotas públicas | `SecurityConfig` |
| Actuator exposto | `application.yml` + `ActuatorSecurityConfig` |
| Migrações SQL | `src/main/resources/db/migration/` |
