# Observabilidade (Actuator)

## Objectivo

Expor endpoints de gestão para healthchecks, métricas e inspecção de cache, sem comprometer segurança.

## Dependência

`spring-boot-starter-actuator`

## Configuração recomendada

Actuator na **raiz do servidor** (`/actuator`), não sob `/api/v1`. Ver [CONVENCOES.md](CONVENCOES.md).

```yaml
server:
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
  endpoint:
    health:
      show-details: when_authorized   # never em prod pública
  info:
    env:
      enabled: false
```

## Endpoints expostos (MVP)

| Endpoint | Uso |
|----------|-----|
| `GET /actuator/health` | Liveness/readiness (Docker, K8s) |
| `GET /actuator/health/liveness` | Processo vivo (SB 3+) |
| `GET /actuator/health/readiness` | Pronto para tráfego (DB up) |
| `GET /actuator/info` | Versão da app (build info opcional) |
| `GET /actuator/metrics` | Lista de métricas |
| `GET /actuator/metrics/{name}` | Detalhe (ex.: `http.server.requests`) |
| `GET /actuator/caches` | Nomes e estatísticas de cache |

## O que NÃO expor em produção

- `env`, `beans`, `configprops`, `heapdump`, `threaddump`
- `health` com `show-details: always` publicamente

## Segurança

`ActuatorSecurityConfig` (ou regras em `SecurityConfig`):

| Ambiente | Política |
|----------|----------|
| Desenvolvimento | `health` público; resto autenticado ou local only |
| Produção | `/actuator/**` apenas rede interna ou Basic Auth dedicado |
| Docker healthcheck | Apenas `GET /actuator/health/liveness` |

Exemplo healthcheck no Compose:

```yaml
healthcheck:
  test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/actuator/health/liveness"]
  interval: 30s
  timeout: 5s
  retries: 3
```

URL canónica: `http://localhost:8080/actuator/health/liveness` (sem prefixo `/api/v1`).

## Métricas úteis

| Métrica | Interesse |
|---------|-----------|
| `http.server.requests` | Latência e volume por endpoint |
| `jvm.memory.used` | Memória |
| `hikaricp.connections.active` | Pool de conexões |
| `cache.gets` / `cache.puts` | Eficácia do Caffeine (se habilitado) |

## Integração com relatórios em cache

- Monitorar taxa de hit/miss após deploy.
- Alertar se latência de `/reports/*` sobe com cache activo (possível evict em falta).

## Logging

```yaml
logging:
  level:
    com.financas.api: INFO
    org.hibernate.SQL: WARN
```

Em desenvolvimento: `com.financas.api: DEBUG`.

**Nunca** logar tokens JWT nem passwords.

## Runbook rápido

| Sintoma | Acção |
|---------|-------|
| `health` DOWN, component `db` | Verificar PostgreSQL e credenciais |
| Relatórios desactualizados | Verificar `@CacheEvict`; `POST` invalidação manual via restart ou TTL |
| 503 após deploy | Aguardar readiness; verificar Flyway |
| Actuator 401 | Credenciais de gestão ou rede interna |

## Build info (opcional)

```xml
<plugin>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-maven-plugin</artifactId>
  <executions>
    <execution>
      <goals><goal>build-info</goal></goals>
    </execution>
  </executions>
</plugin>
```

Expõe versão em `/actuator/info`.
