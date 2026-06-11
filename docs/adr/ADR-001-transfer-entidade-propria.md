# ADR-001: Transfer como entidade própria

## Estado

Aceite (Plano v2)

## Contexto

No Plano v1, uma transferência entre contas era modelada como duas linhas em `tb_transactions` ligadas por `transferPairId`, sem agregado explícito. Isso complica:

- Listagem e detalhe de transferências
- Relatórios (risco de contar movimentos duplicados como despesa/receita "reais")
- Regras de negócio (saldo, rollback) espalhadas pela lógica de pares

## Decisão

Introduzir a entidade de domínio **`Transfer`** e a tabela **`tb_transfers`**, com duas `Transaction` filhas (EXPENSE na origem, INCOME no destino) referenciando `transfer_id`.

## Consequências

### Positivas

- Agregado claro: `POST /transfers` cria um único recurso
- `GET /transfers/{id}` devolve contexto completo
- Relatórios podem excluir `transfer_id IS NOT NULL` no resumo por categoria
- Transacção `@Transactional` no `TransferService` com rollback unificado

### Negativas

- Migração Flyway adicional (`V2__create_transfers.sql`)
- Mais uma entidade JPA + mapper + adapter
- Três persistências por operação (Transfer + 2 Transaction)

## Alternativas consideradas

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Manter `transferPairId` | Sem agregado; API e relatórios mais frágeis |
| Tipo `TRANSFER` em Transaction | Mistura transferência com receita/despesa; categorização ambígua |
| Apenas uma Transaction "net" | Não reflecte débito/crédito em duas contas |

## Referências

- [03-entidades.md](../03-entidades.md) — modelo Transfer
- [05-fluxo-regras.md](../05-fluxo-regras.md) — fluxo de transferência
- [07-persistencia-flyway.md](../07-persistencia-flyway.md) — V2 schema
