#!/usr/bin/env tsx
/**
 * id-vault-keygen — OFFLINE ceremony tool. Generates the vault keypair, prints
 * the PUBLIC key (safe to hold) + version, and splits the private key 2-of-4
 * into four share files for offline distribution. It does NOT persist the whole
 * private key. Run on an offline machine; destroy the reassembled key after.
 *
 * Usage: tsx scripts/id-vault-keygen.mts <out-dir> [--key-version N]
 */
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { generateKeypair, splitSecretKey } from '../src/lib/idVaultCrypto.js';

export async function runKeygen(
  outDir: string,
  keyVersion = 1
): Promise<{ publicKeyB64: string; keyVersion: number; shareFiles: string[] }> {
  const kp = await generateKeypair();
  const shares = splitSecretKey(kp.secretKeyHex);
  const shareFiles = shares.map((share, i) => {
    const f = join(outDir, `id-vault-share-${i + 1}-of-4.txt`);
    writeFileSync(f, `${share}\n`, { mode: 0o600 });
    return f;
  });
  return { publicKeyB64: kp.publicKeyB64, keyVersion, shareFiles };
}

// CLI entry (not run under vitest import)
if (import.meta.url === `file://${process.argv[1]}`) {
  const outDir = process.argv[2];
  if (!outDir) { console.error('usage: id-vault-keygen <out-dir> [--key-version N]'); process.exit(2); }
  const vIdx = process.argv.indexOf('--key-version');
  const keyVersion = vIdx > -1 ? Number(process.argv[vIdx + 1]) : 1;
  runKeygen(outDir, keyVersion).then(({ publicKeyB64, shareFiles }) => {
    console.log('\n=== id_vault key ceremony ===');
    console.log('Set in prod env (Phase B):');
    console.log(`  ID_VAULT_PUBLIC_KEY=${publicKeyB64}`);
    console.log(`  ID_VAULT_KEY_VERSION=${keyVersion}`);
    console.log('\nDistribute ONE share file to EACH board member, offline:');
    shareFiles.forEach((f) => console.log(`  ${f}`));
    console.log('\nThen DELETE the share files from this machine and destroy the reassembled key.\n');
  });
}
