import { describe, it, expect } from 'vitest';
import { checkShares } from './id-vault-check-shares.mjs';
import { generateKeypair, splitSecretKey } from '../src/lib/idVaultCrypto.js';

describe('id-vault-check-shares', () => {
  it('reports MATCH for every pair of the four shares', async () => {
    const kp = await generateKeypair();
    const shares = splitSecretKey(kp.secretKeyHex);
    for (let a = 0; a < 4; a++) {
      for (let b = a + 1; b < 4; b++) {
        const out = await checkShares({ shares: [shares[a], shares[b]], publicKeyB64: kp.publicKeyB64 });
        expect(out.match).toBe(true);
      }
    }
  });

  it('reports NO MATCH for shares from a different keypair', async () => {
    const kp = await generateKeypair();
    const other = await generateKeypair();
    const shares = splitSecretKey(other.secretKeyHex);
    const out = await checkShares({ shares: [shares[0], shares[1]], publicKeyB64: kp.publicKeyB64 });
    expect(out.match).toBe(false);
  });

  it('reports NO MATCH when one character of a share is mistyped', async () => {
    const kp = await generateKeypair();
    const shares = splitSecretKey(kp.secretKeyHex);
    const mid = Math.floor(shares[1].length / 2);
    const typo = shares[1].slice(0, mid) + (shares[1][mid] === 'a' ? 'b' : 'a') + shares[1].slice(mid + 1);
    const out = await checkShares({ shares: [shares[0], typo], publicKeyB64: kp.publicKeyB64 });
    expect(out.match).toBe(false);
  });

  it('refuses one share, and the same share given twice', async () => {
    const kp = await generateKeypair();
    const shares = splitSecretKey(kp.secretKeyHex);
    await expect(checkShares({ shares: [shares[0]], publicKeyB64: kp.publicKeyB64 })).rejects.toThrow(/two shares/);
    await expect(checkShares({ shares: [shares[0], shares[0]], publicKeyB64: kp.publicKeyB64 })).rejects.toThrow(/twice/);
  });
});
