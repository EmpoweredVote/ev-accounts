BEGIN;

-- CC_0237: contributor thank-you gems on trivia.question_flags
--
-- An admin reviewing a flagged question in the CTC admin panel can thank the
-- reporter who was right, crediting one yellow gem through connect.credit_gems
-- with transaction_type = 'ctc_flag_thanks'.
--
-- thanked_at doubles as the "already thanked" guard the route checks before it
-- calls the ledger. The ledger's own idempotency key (ctc-flagthanks-<flag id>)
-- is the real defence against a double credit; this column is what the admin UI
-- reads to render state, and what makes a replay cheap (no ledger round trip).
--
-- thanked_by is the admin who clicked, for the audit trail. No FK: public.users
-- rows are soft-deleted rather than removed, and losing the audit record if an
-- admin account is ever hard-deleted is worse than a dangling UUID.
--
-- Both nullable: every existing row predates the feature and was never thanked.

ALTER TABLE trivia.question_flags
  ADD COLUMN IF NOT EXISTS thanked_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS thanked_by UUID;

COMMENT ON COLUMN trivia.question_flags.thanked_at IS
  'When an admin awarded this reporter a contributor gem. NULL = not yet thanked.';
COMMENT ON COLUMN trivia.question_flags.thanked_by IS
  'public.users(id) of the admin who awarded the gem. No FK — audit row outlives the account.';

COMMIT;
