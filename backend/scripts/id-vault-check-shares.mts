#!/usr/bin/env tsx
/**
 * id-vault-check-shares — OFFLINE share check. Combines two board-member shares
 * and confirms they rebuild the private key that matches the production PUBLIC
 * key. It opens no one's record, reads no database, and never prints the key.
 * Run it after a ceremony, before anything depends on the shares being right.
 *
 * Usage (offline machine):
 *   tsx scripts/id-vault-check-shares.mts \
 *     --pubkey <base64> --share <file1> --share <file2>
 *
 * Exit 0 = MATCH, 1 = NO MATCH, 2 = bad arguments.
 */
import { readFileSync } from 'node:fs';
import _sodium from 'libsodium-wrappers';
import { combineSecretKey, openSealed, publicKeyFromB64, sealTo, sodiumReady } from '../src/lib/idVaultCrypto.js';

export async function checkShares(input: {
  shares: string[]; publicKeyB64: string;
}): Promise<{ match: boolean; reason: string }> {
  await sodiumReady();
  const shares = input.shares.map((s) => s.trim());
  if (shares.length < 2) throw new Error('At least two shares are required.');
  if (new Set(shares).size !== shares.length) throw new Error('The same share was given twice.');

  let skHex: string;
  try {
    skHex = combineSecretKey(shares);
  } catch (e) {
    return { match: false, reason: `the shares could not be combined (${(e as Error).message})` };
  }
  if (!/^[0-9a-f]{64}$/i.test(skHex)) {
    return { match: false, reason: 'the shares do not rebuild a 32-byte key' };
  }

  const sk = Uint8Array.from(Buffer.from(skHex, 'hex'));
  const expected = publicKeyFromB64(input.publicKeyB64);
  const derived = _sodium.crypto_scalarmult_base(sk);
  if (!_sodium.memcmp(derived, expected)) {
    return { match: false, reason: 'the rebuilt key does not belong to this public key' };
  }

  // Round trip: seal a throwaway value to the public key and open it with the rebuilt key.
  const probe = `share-check ${Date.now()}`;
  try {
    if (openSealed(expected, sk, sealTo(expected, probe)) !== probe) {
      return { match: false, reason: 'a test seal did not open to the same value' };
    }
  } catch {
    return { match: false, reason: 'a test seal could not be opened' };
  }
  return { match: true, reason: 'the shares rebuild the key for this public key' };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const arg = (k: string) => { const i = process.argv.indexOf(k); return i > -1 ? process.argv[i + 1] : undefined; };
  const args = (k: string) => process.argv.reduce<string[]>((a, v, i) => (process.argv[i - 1] === k ? [...a, v] : a), []);
  const pubkey = arg('--pubkey'); const shareFiles = args('--share');
  if (!pubkey || shareFiles.length < 2) {
    console.error('Missing required args (need --pubkey and two --share).');
    process.exit(2);
  }
  (async () => {
    const shares = shareFiles.map((f) => readFileSync(f, 'utf8'));
    let out: { match: boolean; reason: string };
    try {
      out = await checkShares({ shares, publicKeyB64: pubkey! });
    } catch (e) {
      console.error((e as Error).message);
      process.exit(2);
    }
    console.log(out.match ? `MATCH — ${out.reason}.` : `NO MATCH — ${out.reason}.`);
    console.log('No record was opened and the key was not printed. Eject the RAM disk now.');
    process.exit(out.match ? 0 : 1);
  })();
}
