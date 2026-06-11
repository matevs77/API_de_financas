-- =====================================================
-- tb_transfers + link tb_transactions.transfer_id
-- =====================================================

CREATE TABLE tb_transfers (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES tb_users(id) ON DELETE CASCADE,
    from_account_id  UUID NOT NULL REFERENCES tb_accounts(id),
    to_account_id    UUID NOT NULL REFERENCES tb_accounts(id),
    amount           NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    occurred_on      DATE NOT NULL,
    description      VARCHAR(255),
    status           VARCHAR(20) NOT NULL DEFAULT 'COMPLETED'
                     CHECK (status IN ('COMPLETED','REVERSED')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by       VARCHAR(36),
    updated_by       VARCHAR(36),
    CHECK (from_account_id <> to_account_id)
);

ALTER TABLE tb_transactions
    ADD COLUMN transfer_id UUID REFERENCES tb_transfers(id) ON DELETE SET NULL;

CREATE INDEX idx_transactions_transfer ON tb_transactions(transfer_id);
CREATE INDEX idx_transfers_user_date ON tb_transfers(user_id, occurred_on);

