import { describe, it, expect } from 'vitest';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { runKeygen } from './id-vault-keygen.mjs';
import { combineSecretKey, sealTo, openSealed, publicKeyFromB64 } from '../src/lib/idVaultCrypto.js';

describe('id-vault-keygen', () => {
  it('writes 4 shares whose any-two reconstruct a key that opens a seal', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'idvault-'));
    const { publicKeyB64, shareFiles } = await runKeygen(dir);
    expect(shareFiles).toHaveLength(4);
    const s2 = readFileSync(shareFiles[1], 'utf8').trim();
    const s3 = readFileSync(shareFiles[2], 'utf8').trim();
    const skHex = combineSecretKey([s2, s3]);
    const sk = Uint8Array.from(Buffer.from(skHex, 'hex'));
    const sealed = sealTo(publicKeyFromB64(publicKeyB64), 'ceremony test');
    expect(openSealed(publicKeyFromB64(publicKeyB64), sk, sealed)).toBe('ceremony test');
  });
});
