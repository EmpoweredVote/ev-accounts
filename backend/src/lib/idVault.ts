/**
 * idVault — app-facing sealing. Holds ONLY the public key (env). Can seal
 * (write) any time; can NEVER open (no secret key, no open function here).
 * Gated: when no public key is configured the caller keeps today's behaviour.
 */
import { env } from './env.js';
import { pool } from './db.js';
import { sealTo, publicKeyFromB64, sodiumReady } from './idVaultCrypto.js';

export function isVaultEnabled(): boolean {
  return Boolean(env.ID_VAULT_PUBLIC_KEY && env.ID_VAULT_KEY_VERSION);
}

function requirePublicKey(): Uint8Array {
  if (!env.ID_VAULT_PUBLIC_KEY) throw new Error('ID_VAULT_PUBLIC_KEY not configured');
  return publicKeyFromB64(env.ID_VAULT_PUBLIC_KEY);
}

export async function sealName(name: string): Promise<Buffer> {
  await sodiumReady();
  return sealTo(requirePublicKey(), name);
}

export async function sealAddress(raw: string): Promise<Buffer> {
  await sodiumReady();
  return sealTo(requirePublicKey(), raw);
}

/**
 * Seal the given parts for this user via the SECURITY DEFINER function
 * id_vault.seal_upsert. ev_api holds EXECUTE on that function and NO direct table
 * privilege, so it can seal but cannot read the ciphertext. A null part leaves the
 * other column untouched (the function COALESCEs). Idempotent. See CA_0118 + spec §4.1.
 */
export async function upsertSeal(
  userId: string,
  parts: { name?: string; address?: string }
): Promise<void> {
  const sealedName = parts.name !== undefined ? await sealName(parts.name) : null;
  const sealedAddress = parts.address !== undefined ? await sealAddress(parts.address) : null;
  await pool.query(
    `SELECT id_vault.seal_upsert($1, $2, $3, $4)`,
    [userId, sealedName, sealedAddress, env.ID_VAULT_KEY_VERSION]
  );
}
