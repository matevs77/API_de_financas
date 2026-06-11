# API REST

Base URL: `http://localhost:8080/api/v1`

Documentação interactiva: `http://localhost:8080/api/v1/swagger-ui.html` (springdoc-openapi). Ver [CONVENCOES.md](CONVENCOES.md).

Autenticação: `Authorization: Bearer <accessToken>` (excepto rotas de auth).

---

## Auth

| Método | Path | Auth | Descrição |
|--------|------|------|-----------|
| POST | `/auth/register` | Pública | Registo de utilizador |
| POST | `/auth/login` | Pública | Login |
| POST | `/auth/refresh` | Pública | Renovar access token |
| POST | `/auth/logout` | Bearer | Revogar refresh token |
| GET | `/auth/me` | Bearer | Perfil do utilizador autenticado |

---

## Accounts

| Método | Path | Descrição |
|--------|------|-----------|
| GET | `/accounts` | Listar contas (paginado) |
| GET | `/accounts/{id}` | Detalhe + saldo |
| POST | `/accounts` | Criar conta |
| PUT | `/accounts/{id}` | Actualizar conta |
| DELETE | `/accounts/{id}` | Remover conta |

---

## Categories

| Método | Path | Descrição |
|--------|------|-----------|
| GET | `/categories` | Listar (inclui sistema + user) |
| GET | `/categories/{id}` | Detalhe |
| POST | `/categories` | Criar categoria do utilizador |
| PUT | `/categories/{id}` | Actualizar |
| DELETE | `/categories/{id}` | Remover (não sistema) |

---

## Transactions

| Método | Path | Descrição |
|--------|------|-----------|
| GET | `/transactions` | Listar com filtros |
| GET | `/transactions/{id}` | Detalhe |
| POST | `/transactions` | Criar receita/despesa |
| PUT | `/transactions/{id}` | Actualizar |
| DELETE | `/transactions/{id}` | Remover |

**Query params (GET list):**

| Param | Tipo | Descrição |
|-------|------|-----------|
| `accountId` | UUID | Filtrar por conta |
| `categoryId` | UUID | Filtrar por categoria |
| `type` | INCOME \| EXPENSE | Filtrar por tipo |
| `from` | date | Data inicial |
| `to` | date | Data final |
| `page` | int | Página (0-based) |
| `size` | int | Tamanho da página |

---

## Transfers

| Método | Path | Descrição |
|--------|------|-----------|
| GET | `/transfers` | Listar transferências |
| GET | `/transfers/{id}` | Detalhe com transações filhas |
| POST | `/transfers` | Criar transferência |

**Nota:** Não expor CRUD de transações de transferência isoladamente; manipular via agregado `Transfer`.

---

## Budgets

| Método | Path | Descrição |
|--------|------|-----------|
| GET | `/budgets` | Listar orçamentos |
| GET | `/budgets/{id}` | Detalhe (+ spent, exceeded) |
| POST | `/budgets` | Criar |
| PUT | `/budgets/{id}` | Actualizar |
| DELETE | `/budgets/{id}` | Remover |

---

## Goals

| Método | Path | Descrição |
|--------|------|-----------|
| GET | `/goals` | Listar metas |
| GET | `/goals/{id}` | Detalhe |
| POST | `/goals` | Criar meta |
| PUT | `/goals/{id}` | Actualizar |
| PATCH | `/goals/{id}/contribute` | Adicionar valor ao progresso |
| DELETE | `/goals/{id}` | Remover |

---

## Reports

| Método | Path | Descrição |
|--------|------|-----------|
| GET | `/reports/balance` | Saldo por conta |
| GET | `/reports/cash-flow` | Fluxo de caixa |
| GET | `/reports/by-category` | Resumo por categoria |

**Query params (todos):**

| Param | Obrigatório | Descrição |
|-------|-------------|-----------|
| `from` | Sim | Data inicial (ISO-8601) |
| `to` | Sim | Data final |
| `accountId` | Não | Restringir a uma conta |
| `categoryId` | Não | Restringir a uma categoria |

**Query param adicional (cash-flow):**

| Param | Valores | Default |
|-------|---------|---------|
| `groupBy` | DAY, WEEK, MONTH | MONTH |

---

## Respostas de erro (RFC 7807)

```json
{
  "type": "https://api.financas.example/problems/insufficient-balance",
  "title": "Saldo insuficiente",
  "status": 422,
  "detail": "A conta de origem não tem saldo para esta transferência.",
  "instance": "/api/v1/transfers"
}
```

Tipos sugeridos (`type`):

| Problema | status |
|----------|--------|
| validation-error | 400 |
| unauthorized | 401 |
| forbidden | 403 |
| not-found | 404 |
| conflict | 409 |
| insufficient-balance | 422 |
| budget-exceeded | 422 |
| inactive-account | 422 |

---

## Headers de resposta

| Header | Quando |
|--------|--------|
| `X-Budget-Warning: true` | Despesa criada mas orçamento ultrapassado (MVP) |
| `Location` | 201 Created — URI do recurso criado |

---

## Versionamento

- Prefixo `/api/v1` via `server.servlet.context-path` ou mapeamento global.
- Breaking changes futuras → `/api/v2`.

---

## Paginação padrão

```
GET /accounts?page=0&size=20&sort=createdAt,desc
```

Resposta: `PageResponse<T>` — ver [04-dtos.md](04-dtos.md).
