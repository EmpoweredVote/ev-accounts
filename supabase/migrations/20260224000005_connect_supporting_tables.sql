BEGIN;

-- Migration 005: connect schema supporting tables
--
-- peer_connections: mutual connection requests between Connected users.
-- account_follows:  1-way follow (any Connected user → any Empowered account).
-- gem_transactions: append-only ledger; no UPDATE/DELETE ever.
-- verification_sessions: resumable Connect flow; user can abandon mid-step and return.
--
-- All FK columns have explicit indexes — PostgreSQL does NOT auto-index FK columns.

-- peer_connections: bidirectional connection requests
CREATE TABLE IF NOT EXISTS connect.peer_connections (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status       TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (requester_id, addressee_id)
);

CREATE INDEX IF NOT EXISTS idx_peer_connections_requester
  ON connect.peer_connections(requester_id);
CREATE INDEX IF NOT EXISTS idx_peer_connections_addressee
  ON connect.peer_connections(addressee_id);

-- account_follows: 1-way follow (no approval required)
-- Any Connected user can follow any Empowered account.
CREATE TABLE IF NOT EXISTS connect.account_follows (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  followed_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (follower_id, followed_id)
);

CREATE INDEX IF NOT EXISTS idx_account_follows_follower
  ON connect.account_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_account_follows_followed
  ON connect.account_follows(followed_id);

-- gem_transactions: append-only ledger (FOUND-01, CIVIC-01)
-- balance_after is denormalized onto every row for O(1) current balance lookups
-- without summing the full ledger. Must be maintained atomically.
CREATE TABLE IF NOT EXISTS connect.gem_transactions (
  id               UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount           INTEGER NOT NULL,     -- positive = credit, negative = debit
  transaction_type TEXT    NOT NULL,     -- e.g. 'stipend', 'vote_cast', 'role_fee'
  feature_context  TEXT,                 -- which feature originated the transaction
  reference_id     UUID,                 -- optional foreign key to source record
  balance_after    INTEGER NOT NULL,     -- denormalized running balance
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gem_transactions_user_id
  ON connect.gem_transactions(user_id);

-- verification_sessions: resumable Connect verification flow (CONN-01)
-- Stores draft state so a user can abandon mid-flow and pick up where they left off.
CREATE TABLE IF NOT EXISTS connect.verification_sessions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  step_reached         TEXT NOT NULL,   -- e.g. 'name', 'method', 'region', 'review'
  display_name_draft   TEXT,
  verification_method  TEXT,
  region_draft         TEXT,
  expires_at           TIMESTAMPTZ,     -- NULL = no expiry; set for time-limited sessions
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_verification_sessions_user_id
  ON connect.verification_sessions(user_id);

COMMIT;
