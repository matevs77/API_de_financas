# ADR-002: BaseEntity auditável

## Estado

Aceite (Plano v2)

## Contexto

No Plano v1, apenas `User` tinha `createdAt`/`updatedAt` manuais (`@PreUpdate`). Outras entidades não tinham padrão uniforme nem rastreio de quem alterou registos.

## Decisão

1. **Domínio:** interface ou classe base `AuditableDomain` com `id`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
2. **JPA:** `BaseJpaEntity` com `@EntityListeners(AuditingEntityListener.class)` e campos `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`.
3. **Config:** `@EnableJpaAuditing` + `AuditorAware<String>` que lê o `userId` do JWT.

Entidades auditáveis: `Account`, `Category`, `Transaction`, `Transfer`, `Budget`, `Goal`.

`User` e `RefreshToken` podem usar subconjunto (apenas timestamps).

## Consequências

### Positivas

- Rastreabilidade consistente
- Menos código repetido (`@PreUpdate` manual)
- Suporte a requisitos de conformidade futuros

### Negativas

- Mappers devem copiar campos de auditoria entre JPA e domínio
- Testes precisam de `@DataJpaTest` com `AuditorAware` mock ou desactivar auditoria

## Alternativas consideradas

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Auditoria só em SQL (triggers) | Opaca à aplicação; difícil em testes |
| Envers (histórico completo) | Over-engineering para MVP |
| Sem `createdBy`/`updatedBy` | Perde rastreio de utilizador |

## Referências

- [03-entidades.md](../03-entidades.md)
- [08-seguranca-jwt.md](../08-seguranca-jwt.md) — AuditorAware
