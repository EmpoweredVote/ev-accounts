#!/usr/bin/env tsx
/**
 * id-vault-backfill — Phase C, run ONCE on prod AFTER the ceremony sets the
 * production ID_VAULT_PUBLIC_KEY. Seals every existing connected_profiles
 * legal_name into id_vault. Idempotent (upsertSeal). --dry-run is the default;
 * pass --apply to write.
 */

export async function backfillSeal(
  rows: { user_id: string; legal_name: string | null }[],
  seal: (userId: string, name: string) => Promise<void>,
  opts: { dryRun: boolean }
): Promise<{ sealed: number; skipped: number }> {
  let sealed = 0, skipped = 0;
  for (const r of rows) {
    if (!r.legal_name) { skipped++; continue; }
    if (opts.dryRun) continue;
    await seal(r.user_id, r.legal_name);
    sealed++;
  }
  return { sealed, skipped };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const { pool } = await import('../src/lib/db.js');
  const { upsertSeal, isVaultEnabled } = await import('../src/lib/idVault.js');

  const dryRun = !process.argv.includes('--apply');
  (async () => {
    if (!isVaultEnabled()) { console.error('ID_VAULT_PUBLIC_KEY not set — run the ceremony first.'); process.exit(2); }
    const { rows } = await pool.query<{ user_id: string; legal_name: string | null }>(
      `SELECT user_id, legal_name FROM connect.connected_profiles WHERE legal_name IS NOT NULL`
    );
    const res = await backfillSeal(rows, (u, name) => upsertSeal(u, { name }), { dryRun });
    console.log(`[backfill] ${dryRun ? 'DRY-RUN' : 'APPLIED'} rows=${rows.length} sealed=${res.sealed} skipped=${res.skipped}`);
    await pool.end();
  })();
}
