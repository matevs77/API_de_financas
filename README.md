# API de Finanças Pessoais

API REST para gestão de finanças pessoais: contas, categorias, transações, transferências, orçamentos, metas e relatórios.

## Fonte de verdade

A pasta **`docs/`** deste repositório é a especificação oficial do projecto. Qualquer implementação ou alteração de desenho deve:

1. Seguir [docs/CONVENCOES.md](docs/CONVENCOES.md) (valores canónicos: stack, URLs, JWT, domínio).
2. Manter consistência com os documentos numerados `00`–`11` e os ADRs.
3. Actualizar a documentação **no mesmo passo** que mudar comportamento ou modelo — sem contradizer outros ficheiros.

Em conflito entre documentos: **`CONVENCOES.md` → ADRs → docs numerados**.

## Stack

| Tecnologia | Versão / uso |
|------------|----------------|
| Java | 17 |
| Spring Boot | 3.x |
| PostgreSQL | Persistência |
| JWT | Autenticação (access + refresh) |
| Docker | Deploy local e produção |
| Flyway | Migrações de schema |
| Caffeine | Cache de relatórios |
| Spring Boot Actuator | Health, métricas, caches |

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| [docs/CONVENCOES.md](docs/CONVENCOES.md) | **Valores canónicos** (stack, URLs, JWT, cache, Flyway) |
| [docs/00-visao-geral.md](docs/00-visao-geral.md) | Requisitos MVP, glossário, evolução do plano |
| [docs/01-arquitetura.md](docs/01-arquitetura.md) | Camadas, decisões, Plano v1 vs v2 |
| [docs/02-estrutura-directorios.md](docs/02-estrutura-directorios.md) | Árvore de pastas e convenções |
| [docs/03-entidades.md](docs/03-entidades.md) | Modelo de domínio e ER |
| [docs/04-dtos.md](docs/04-dtos.md) | Requests, responses, validações |
| [docs/05-fluxo-regras.md](docs/05-fluxo-regras.md) | Fluxos de negócio e HTTP |
| [docs/06-api-rest.md](docs/06-api-rest.md) | Endpoints REST |
| [docs/07-persistencia-flyway.md](docs/07-persistencia-flyway.md) | Schema, migrações, mapeamento |
| [docs/08-seguranca-jwt.md](docs/08-seguranca-jwt.md) | JWT, BCrypt, isolamento |
| [docs/09-cache-relatorios-caffeine.md](docs/09-cache-relatorios-caffeine.md) | Cache de relatórios |
| [docs/10-observabilidade-actuator.md](docs/10-observabilidade-actuator.md) | Actuator e operação |
| [docs/11-docker-deploy.md](docs/11-docker-deploy.md) | Docker Compose e variáveis |
| [docs/adr/](docs/adr/) | Architecture Decision Records |

## Decisões arquiteturais (resumo)

- Domínio **desacoplado** de JPA (ports/adapters + MapStruct)
- **Transfer** como entidade própria (agregado), não apenas par de transações
- **BaseEntity** auditável (`createdAt`, `updatedAt`, `createdBy`, `updatedBy`)
- Relatórios com **cache Caffeine** e invalidação em writes
- **Actuator** para health e métricas

## Estado

Especificação e documentação aprovadas nas conversas de desenho. Implementação de código pendente.

## ADRs

- [ADR-001](docs/adr/ADR-001-transfer-entidade-propria.md) — Transfer como entidade própria
- [ADR-002](docs/adr/ADR-002-base-entity-auditavel.md) — BaseEntity auditável
- [ADR-003](docs/adr/ADR-003-separar-jpa-dominio.md) — Separar JPA do domínio
- [ADR-004](docs/adr/ADR-004-cache-caffeine-relatorios.md) — Cache Caffeine para relatórios
- [ADR-005](docs/adr/ADR-005-actuator.md) — Spring Boot Actuator
