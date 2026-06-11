# Visão geral

## Objetivo

Fornecer uma API REST stateless para que cada utilizador registe e consulte as suas finanças pessoais de forma isolada: contas, movimentos, transferências entre contas, orçamentos por categoria, metas de poupança e relatórios agregados.

## Requisitos funcionais (MVP)

| Área | Funcionalidades |
|------|-----------------|
| **Autenticação** | Registo, login, refresh token, perfil |
| **Contas** | Contas bancárias/carteiras (saldo inicial, moeda, ativa/inativa) |
| **Categorias** | Receita/despesa, hierarquia opcional, categorias de sistema + do utilizador |
| **Transações** | CRUD de receitas e despesas (data, valor, categoria, conta) |
| **Transferências** | Movimento atómico entre duas contas do mesmo utilizador |
| **Orçamentos** | Limite por categoria e período; alerta ao ultrapassar |
| **Metas** | Poupança com valor alvo e progresso |
| **Relatórios** | Saldo por conta, fluxo de caixa, resumo por categoria/período |

## Requisitos não funcionais

- Multi-tenant lógico por `userId` (cada utilizador só acede aos seus dados)
- API REST JSON, versionada em `/api/v1`
- Validação de entrada (Bean Validation)
- Erros padronizados (RFC 7807 Problem Details)
- Migrações versionadas (Flyway)
- Testes de integração com PostgreSQL real (Testcontainers)

## Fora do MVP (fase 2)

- Transações recorrentes
- Anexos (comprovativos)
- Multi-moeda com câmbio
- Notificações push/e-mail além de alertas de orçamento
- Integração bancária (Open Banking)
- Cache distribuído (Redis) para múltiplas instâncias

## Glossário

| Termo | Definição |
|-------|-----------|
| **Conta (Account)** | Carteira ou conta bancária do utilizador com saldo inicial e moeda |
| **Categoria (Category)** | Classificação de receita ou despesa; pode ser do sistema ou criada pelo utilizador |
| **Transação (Transaction)** | Movimento de receita ou despesa numa conta |
| **Transferência (Transfer)** | Agregado que move valor entre duas contas (débito + crédito atómicos) |
| **Orçamento (Budget)** | Limite de despesa por categoria num período |
| **Meta (Goal)** | Objetivo de poupança com valor alvo e progresso |
| **Relatório** | Agregação read-only (saldo, fluxo de caixa, por categoria) |

## Evolução do plano

| Versão | Origem | Características |
|--------|--------|-----------------|
| **Plano v1** | Conversa 1 | Camadas web/application/domain/infrastructure; transferência via `transferPairId` em duas transações; JPA opcional em `domain/model` |
| **Plano v2** | Conversa 2 | `Transfer` entidade própria; `BaseEntity` auditável; JPA separado do domínio; cache Caffeine em relatórios; Actuator |

A documentação nesta pasta reflecte o **Plano v2** como especificação alvo.

## Stack técnica

- Java 17
- Spring Boot 3
- PostgreSQL
- JWT (access + refresh)
- Docker / Docker Compose
- Spring Cache + Caffeine
- Spring Boot Actuator
- MapStruct (mapeamento domínio ↔ JPA)
- Flyway

## Pacote base

`com.financas.api`

## Convenções canónicas

Todos os valores fixos (URLs, JWT, cache, Flyway, regras de transferência) estão em **[CONVENCOES.md](CONVENCOES.md)**. Essa página é a referência em caso de divergência entre documentos.
