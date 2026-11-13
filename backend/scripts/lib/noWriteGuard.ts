/**
 * A slim Stage 5 session runs unattended: nothing asks the runner before a command runs (three-state review
 * 2026-11-13, change 1). The rule "the database is written only on the runner's yes for this batch" is kept there by
 * `scripts/stage5/leg.py`, which starts every slim session with STAGE5_NO_DB_WRITE=1. Each Stage 5 tool that can
 * write the database calls `refuseWriteInSlimSession` before it does, and exits 5.
 *
 * 🔴 This guards the Stage 5 writers that call it (topic:stage5-write --apply, verify-stance-research --apply,
 * approve-batch, and write-batch.sh apply). It does not stop a hand-written SQL statement. The database has one
 * credential with full rights; a read-only connection setting (PGOPTIONS default_transaction_read_only) was tried on
 * 2026-11-13 and has no effect through the pooler. A read-only database role would be the real guard.
 */
export const NO_WRITE_ENV = 'STAGE5_NO_DB_WRITE';

/** Why a write is refused in this process, or null when it may go ahead. */
export function writeRefusal(env: Record<string, string | undefined> = process.env): string | null {
  return env[NO_WRITE_ENV] === '1'
    ? `${NO_WRITE_ENV}=1: this is a slim session, which never writes the database. Stop and hand the write to the desk session, which runs it on the runner's yes.`
    : null;
}

/** Exit 5 before a database write when this process is a slim session. `what` names the command, for the message. */
export function refuseWriteInSlimSession(what: string): void {
  const why = writeRefusal();
  if (!why) return;
  console.error(`REFUSED: ${what}. ${why}`);
  process.exit(5);
}
