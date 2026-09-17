#!/usr/bin/env tsx
/**
 * id-vault-break-glass — OFFLINE two-person unmask. Never a route. Combines >=2
 * board-member shares, decrypts ONE user's sealed identity, and REQUIRES a
 * co-signed --reason, which it appends to an append-only audit log.
 *
 * Usage (offline machine):
 *   tsx scripts/id-vault-break-glass.mts \
 *     --pubkey <base64> --user <uuid> --reason "<case>" \
 *     --member alice --member bob \
 *     --share <file1> --share <file2> \
 *     --db "<privileged connection string>" --log ./break-glass.log
 */
import { appendFileSync, readFileSync } from 'node:fs';
import { combineSecretKey, openSealed, publicKeyFromB64, sodiumReady } from '../src/lib/idVaultCrypto.js';

export function breakGlass(input: {
  shares: string[]; publicKeyB64: string;
  sealedName: Buffer | null; sealedAddress: Buffer | null;
  reason: string; members: string[];
}): { name: string | null; address: string | null } {
  if (!input.reason || !input.reason.trim()) throw new Error('A --reason is required for a break-glass unmask.');
  if (input.shares.length < 2) throw new Error('At least two shares are required.');
  const skHex = combineSecretKey(input.shares);
  const sk = Uint8Array.from(Buffer.from(skHex, 'hex'));
  const pk = publicKeyFromB64(input.publicKeyB64);
  const name = input.sealedName ? openSealed(pk, sk, input.sealedName) : null;
  const address = input.sealedAddress ? openSealed(pk, sk, input.sealedAddress) : null;
  return { name, address };
}

export function appendAuditLine(
  logPath: string,
  entry: { members: string[]; user_id: string; reason: string; at: string }
): void {
  appendFileSync(logPath, JSON.stringify(entry) + '\n', { flag: 'a' });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const arg = (k: string) => { const i = process.argv.indexOf(k); return i > -1 ? process.argv[i + 1] : undefined; };
  const args = (k: string) => process.argv.reduce<string[]>((a, v, i) => (process.argv[i - 1] === k ? [...a, v] : a), []);
  const pubkey = arg('--pubkey'); const userId = arg('--user'); const reason = arg('--reason');
  const members = args('--member'); const shareFiles = args('--share'); const db = arg('--db');
  const log = arg('--log') ?? './break-glass.log';
  if (!pubkey || !userId || !reason || members.length < 2 || shareFiles.length < 2 || !db) {
    console.error('Missing required args (need --pubkey --user --reason, two --member, two --share, --db).');
    process.exit(2);
  }
  (async () => {
    await sodiumReady(); // openSealed/publicKeyFromB64 need libsodium ready
    const { Pool } = await import('pg');
    const pool = new Pool({ connectionString: db });
    const { rows } = await pool.query<{ sealed_name: Buffer | null; sealed_address: Buffer | null }>(
      `SELECT sealed_name, sealed_address FROM id_vault.sealed_identities WHERE user_id = $1`, [userId]
    );
    await pool.end();
    if (rows.length === 0) { console.error('No sealed identity for that user.'); process.exit(1); }
    const shares = shareFiles.map((f) => readFileSync(f, 'utf8').trim());
    const out = breakGlass({ shares, publicKeyB64: pubkey!, sealedName: rows[0].sealed_name, sealedAddress: rows[0].sealed_address, reason: reason!, members });
    appendAuditLine(log, { members, user_id: userId!, reason: reason!, at: new Date().toISOString() });
    console.log(JSON.stringify(out, null, 2));
    console.log(`\nLogged to ${log}. Destroy any reassembled key material now.`);
  })();
}
