# ADR-004: Cache Caffeine para relatórios

## Estado

Aceite (Plano v2)

## Contexto

Endpoints `GET /reports/*` executam agregações SQL (SUM, GROUP BY) potencialmente custosas. Em uso frequente (dashboards), repetir as mesmas queries sobrecarrega o PostgreSQL.

Escritas (transações, transferências) invalidam o resultado dos relatórios.

## Decisão

- Usar **Spring Cache** com implementação **Caffeine** (in-memory).
- `@Cacheable` em `ReportService` para `balanceReport`, `cashFlow`, `categorySummary`.
- `@CacheEvict` (mesmos caches) em services de write: `TransactionService`, `TransferService`, `AccountService`.
- TTL: `expireAfterWrite=10m`; `maximumSize=500` (ajustável).
- Chave: composição de `userId` + parâmetros de filtro.

## Consequências

### Positivas

- Menor latência em leituras repetidas
- Menos carga no PostgreSQL
- Integração simples com Spring Boot
- Inspecção via `/actuator/caches`

### Negativas

- Dados potencialmente stale até TTL se `@CacheEvict` falhar
- Cache não partilhado entre instâncias (MVP single-node)
- `allEntries = true` no evict é grosseiro com muitos utilizadores

## Alternativas consideradas

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Sem cache | Performance insuficiente em dashboards |
| Redis (fase 1) | Infra extra; desnecessário para MVP single instance |
| Materialized views PostgreSQL | Complexidade operacional; refresh manual |
| Cache em todos os GETs | Risco de inconsistência em listagens CRUD |

## Evolução (fase 2)

- Redis como `CacheManager` para cluster
- Evict por `userId` em vez de `allEntries`
- Métricas de hit ratio em Prometheus

## Referências

- [09-cache-relatorios-caffeine.md](../09-cache-relatorios-caffeine.md)
- [05-fluxo-regras.md](../05-fluxo-regras.md) — secção relatórios
