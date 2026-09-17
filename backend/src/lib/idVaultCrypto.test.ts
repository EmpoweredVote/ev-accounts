import { describe, it, expect } from 'vitest';
import { generateKeypair, sealTo, openSealed, publicKeyFromB64 } from './idVaultCrypto.js';

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
