import { describe, it, expect } from 'vitest';
import { generateKeypair, sealTo, openSealed, publicKeyFromB64, splitSecretKey, combineSecretKey } from './idVaultCrypto.js';

describe('idVaultCrypto — seal/open round-trip', () => {
  it('seals with only the public key and opens only with the secret key', async () => {
    const kp = await generateKeypair();
    const sealed = sealTo(publicKeyFromB64(kp.publicKeyB64), 'Ada Lovelace');
    expect(Buffer.isBuffer(sealed)).toBe(true);
    const opened = openSealed(kp.publicKey, kp.secretKey, sealed);
    expect(opened).toBe('Ada Lovelace');
  });

  it('cannot open with the wrong secret key', async () => {
    const a = await generateKeypair();
    const b = await generateKeypair();
    const sealed = sealTo(a.publicKey, '123 Main St');
    expect(() => openSealed(a.publicKey, b.secretKey, sealed)).toThrow();
  });
});

describe('idVaultCrypto — 2-of-4 split', () => {
  it('any two of four shares reconstruct the key; the round-trip still opens', async () => {
    const kp = await generateKeypair();
    const shares = splitSecretKey(kp.secretKeyHex);
    expect(shares).toHaveLength(4);
    const sealed = sealTo(kp.publicKey, 'Grace Hopper');
    // pick shares 2 and 4
    const recoveredHex = combineSecretKey([shares[1], shares[3]]);
    const recovered = Uint8Array.from(Buffer.from(recoveredHex, 'hex'));
    expect(openSealed(kp.publicKey, recovered, sealed)).toBe('Grace Hopper');
  });

  it('a single share cannot reconstruct the key', async () => {
    const kp = await generateKeypair();
    const shares = splitSecretKey(kp.secretKeyHex);
    const wrong = combineSecretKey([shares[0]]); // below threshold -> garbage, not the key
    expect(wrong).not.toBe(kp.secretKeyHex);
  });
});
