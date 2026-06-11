# ADR-003: Separar JPA do domínio

## Estado

Aceite (Plano v2)

## Contexto

O Plano v1 permitia entidades JPA em `domain/model` para acelerar o MVP. Isso acopla regras de negócio a `jakarta.persistence` e Spring, dificultando testes unitários puros e evolução do modelo.

## Decisão

- **`domain`:** POJOs/records, enums, ports (`*Repository`), domain services — **sem** imports JPA/Spring.
- **`infrastructure.persistence`:** `*JpaEntity`, Spring Data `*JpaRepository`, `*RepositoryAdapter`, MapStruct `*Mapper`.
- **Application services** dependem apenas de ports do domínio.

## Consequências

### Positivas

- Domínio testável sem contexto Spring
- Fronteira clara entre negócio e persistência
- Facilita trocar JPA no longo prazo (baixa probabilidade, alta flexibilidade conceptual)

### Negativas

- Duplicação de modelos (mitigada com MapStruct)
- Mais classes e pastas na fase inicial
- Curva de aprendizagem para adapters

## Alternativas consideradas

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| JPA no domain (Plano v1) | Acoplamento; anotações em entidades de negócio |
| Hexagonal estrito com muitos bounded contexts | Complexidade excessiva para o tamanho do projeto |
| JDBC template sem JPA | Mais SQL manual; menos ganho para CRUD |

## Implementação

```
AccountService → AccountRepository (port)
                      ↓
              AccountRepositoryAdapter
                      ↓
         AccountMapper ↔ AccountJpaEntity
                      ↓
              AccountJpaRepository
```

## Referências

- [01-arquitetura.md](../01-arquitetura.md)
- [02-estrutura-directorios.md](../02-estrutura-directorios.md)
- [07-persistencia-flyway.md](../07-persistencia-flyway.md)
