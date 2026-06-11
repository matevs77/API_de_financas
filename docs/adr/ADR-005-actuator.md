# ADR-005: Spring Boot Actuator

## Estado

Aceite (Plano v2)

## Contexto

O Plano v1 não definia observabilidade operacional. Para Docker, deploy e diagnóstico, é necessário saber se a aplicação e a base de dados estão saudáveis, e monitorar métricas básicas e caches.

## Decisão

Adoptar **`spring-boot-starter-actuator`** com exposição restrita:

| Endpoint | MVP |
|----------|-----|
| `health` / `liveness` / `readiness` | Sim |
| `info` | Sim |
| `metrics` | Sim |
| `caches` | Sim (dev/staging; cautela em prod) |

**Não** expor em produção: `env`, `beans`, `heapdump`, `configprops`.

Proteger `/actuator/**` (excepto liveness se necessário para orchestrator) via `ActuatorSecurityConfig` ou rede interna.

Docker healthcheck aponta para `/actuator/health/liveness`.

## Consequências

### Positivas

- Healthchecks fiáveis no Compose/Kubernetes
- Métricas HTTP e JVM out-of-the-box
- Visibilidade do cache de relatórios
- Padrão Spring Boot bem documentado

### Negativas

- Superfície de ataque se mal configurado
- Exigir `management.server.add-application-context-path: false` para Actuator em `/actuator` (ver [CONVENCOES.md](../CONVENCOES.md))

## Alternativas consideradas

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Sem Actuator | Sem healthcheck standard; ops manual |
| Micrometer + Prometheus apenas (sem Actuator) | Actuator já integra Micrometer; mais simples no MVP |
| Health endpoint custom | Reinventar o que Actuator oferece |

## Referências

- [10-observabilidade-actuator.md](../10-observabilidade-actuator.md)
- [11-docker-deploy.md](../11-docker-deploy.md) — healthcheck
