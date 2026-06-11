# Cache de relatórios (Caffeine)

## Objectivo

Reduzir carga no PostgreSQL em endpoints de leitura intensiva (`GET /reports/*`) sem sacrificar consistência aceitável no MVP (instância única).

## Dependências

- `spring-boot-starter-cache`
- Caffeine (via `spring.cache.type=caffeine`)

## Configuração

Nomes de cache e TTL canónicos: [CONVENCOES.md](CONVENCOES.md).

```yaml
spring:
  cache:
    type: caffeine
    cache-names: balanceReport,cashFlow,categorySummary
    caffeine:
      spec: maximumSize=500,expireAfterWrite=10m
```

Classe: `CacheConfig` com `@EnableCaching`.

## Caches nomeados

| Nome | Endpoint | Conteúdo |
|------|----------|------------|
| `balanceReport` | `GET /reports/balance` | `BalanceReportResponse` |
| `cashFlow` | `GET /reports/cash-flow` | `CashFlowResponse` |
| `categorySummary` | `GET /reports/by-category` | `CategorySummaryResponse` |

## Chave de cache

Compor de forma determinística:

```
userId + ":" + from + ":" + to + ":" + accountId + ":" + categoryId + ":" + groupBy
```

Implementação sugerida:

```java
@Cacheable(
    value = "balanceReport",
    key = "T(java.util.Objects).hash(#userId, #filter)"
)
public BalanceReportResponse getBalance(UUID userId, ReportFilterRequest filter) { ... }
```

Ou `@Cacheable(key = "@reportCacheKeyGenerator.generate(#userId, #filter)")`.

## Uso no ReportService

```java
@Service
public class ReportService {

    @Cacheable("balanceReport")
    public BalanceReportResponse balance(UUID userId, ReportFilterRequest filter) {
        return reportQueryAdapter.balance(userId, filter);
    }

    @CacheEvict(value = {"balanceReport", "cashFlow", "categorySummary"}, allEntries = true)
    public void evictAllReports() { }
}
```

**Nota:** `allEntries = true` é simples no MVP; em produção com muitos users considerar evict por chave.

## Invalidação (@CacheEvict)

Disparar após **qualquer** operação que altere dados agregados nos relatórios:

| Service | Operações que invalidam |
|---------|-------------------------|
| `TransactionService` | create, update, delete |
| `TransferService` | create |
| `AccountService` | create, update (`initialBalance`, `active`), delete |
| `CategoryService` | delete (se afectar histórico — opcional) |

Padrão:

```java
@Transactional
@CacheEvict(value = {"balanceReport", "cashFlow", "categorySummary"}, allEntries = true)
public TransactionResponse create(UUID userId, CreateTransactionRequest request) { ... }
```

## Fluxo read / write

```mermaid
flowchart LR
    W[Write Transaction/Transfer/Account] --> S[Service]
    S --> DB[(PostgreSQL)]
    S --> E[@CacheEvict]

    R[GET /reports/*] --> RS[ReportService]
    RS --> C{Cache hit?}
    C -->|Sim| Resp[Response]
    C -->|Não| Q[ReportQueryAdapter]
    Q --> DB
    Q --> Put[@CachePut implícito via @Cacheable]
    Put --> Resp
```

## Transferências e relatórios

- **Fluxo de caixa:** incluir INCOME/EXPENSE das transações de transferência (movimento real entre contas).
- **Por categoria:** excluir transações com `transfer_id IS NOT NULL` para não distorcer despesas "reais".
- Documentar a opção em `ReportQueryAdapter` como flag configurável.

## Limitações (MVP)

| Limitação | Mitigação futura |
|-----------|------------------|
| Cache local por JVM | Redis + Spring Cache |
| `allEntries` evict | Evict por `userId` |
| Stale até TTL se esquecer `@CacheEvict` | Testes de integração + métricas Actuator |
| Múltiplas instâncias | Cache distribuído (fase 2) |

## Actuator

Expor `caches` em desenvolvimento:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,caches
```

Inspecionar: `GET /actuator/caches`

## Testes recomendados

1. Primeiro `GET /reports/balance` → miss → query DB.
2. Segundo `GET` igual → hit → sem query (verificar com mock ou métricas).
3. `POST /transactions` → `@CacheEvict` → terceiro `GET` → miss novamente.
