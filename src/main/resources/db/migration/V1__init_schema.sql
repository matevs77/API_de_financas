-- =====================================================
-- Núcleo inicial
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------
-- tb_users
-- -----------------------------------------------------
CREATE TABLE tb_users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email        VARCHAR(150) NOT NULL UNIQUE,
    password     VARCHAR(255) NOT NULL,
    name         VARCHAR(100) NOT NULL,
    active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------
-- tb_accounts
-- -----------------------------------------------------
CREATE TABLE tb_accounts (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    name             VARCHAR(80) NOT NULL,
    type             VARCHAR(20) NOT NULL CHECK (type IN ('CHECKING','SAVINGS','CASH','CREDIT')),
    initial_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
    currency         CHAR(3) NOT NULL DEFAULT 'BRL',
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by       VARCHAR(36),
    updated_by       VARCHAR(36),
    UNIQUE (user_id, name)
);

-- -----------------------------------------------------
-- tb_categories
-- -----------------------------------------------------
CREATE TABLE tb_categories (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES tb_users(id) ON DELETE CASCADE,
    name            VARCHAR(80) NOT NULL,
    kind            VARCHAR(10) NOT NULL CHECK (kind IN ('INCOME','EXPENSE')),
    parent_id       UUID REFERENCES tb_categories(id) ON DELETE SET NULL,
    system_default  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(36),
    updated_by      VARCHAR(36)
);

-- -----------------------------------------------------
-- tb_transactions (sem transfer_id na V1)
-- -----------------------------------------------------
CREATE TABLE tb_transactions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    account_id  UUID NOT NULL REFERENCES tb_accounts(id) ON DELETE CASCADE,
    category_id UUID REFERENCES tb_categories(id) ON DELETE SET NULL,
    type         VARCHAR(10) NOT NULL CHECK (type IN ('INCOME','EXPENSE')),
    amount       NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    occurred_on  DATE NOT NULL,
    description  VARCHAR(255),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by   VARCHAR(36),
    updated_by   VARCHAR(36)
);

-- -----------------------------------------------------
-- tb_budgets
-- -----------------------------------------------------
CREATE TABLE tb_budgets (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    category_id  UUID NOT NULL REFERENCES tb_categories(id) ON DELETE CASCADE,
    limit_amount NUMERIC(15,2) NOT NULL CHECK (limit_amount > 0),
    period_start DATE NOT NULL,
    period_end   DATE NOT NULL CHECK (period_end >= period_start),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by   VARCHAR(36),
    updated_by   VARCHAR(36)
);

-- -----------------------------------------------------
-- tb_goals
-- -----------------------------------------------------
CREATE TABLE tb_goals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    target_amount   NUMERIC(15,2) NOT NULL CHECK (target_amount > 0),
    current_amount  NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    deadline        DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(36),
    updated_by      VARCHAR(36)
);

-- -----------------------------------------------------
-- tb_refresh_tokens
-- -----------------------------------------------------
CREATE TABLE tb_refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked     BOOLEAN NOT NULL DEFAULT FALSE
);

-- -----------------------------------------------------
-- Índices recomendados
-- -----------------------------------------------------
CREATE INDEX idx_transactions_user_date ON tb_transactions(user_id, occurred_on);
CREATE INDEX idx_transactions_account ON tb_transactions(account_id);
CREATE INDEX idx_transactions_category ON tb_transactions(category_id);
CREATE INDEX idx_accounts_user ON tb_accounts(user_id);
CREATE INDEX idx_categories_user ON tb_categories(user_id);
CREATE INDEX idx_budgets_user_category ON tb_budgets(user_id, category_id);
CREATE INDEX idx_goals_user ON tb_goals(user_id);

