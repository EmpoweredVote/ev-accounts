import { describe, it, expect } from 'vitest';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { breakGlass, appendAuditLine } from './id-vault-break-glass.mjs';
import { generateKeypair, splitSecretKey, sealTo } from '../src/lib/idVaultCrypto.js';

async function fixture() {
  const kp = await generateKeypair();
  const shares = splitSecretKey(kp.secretKeyHex);
  const sealedName = sealTo(kp.publicKey, 'Ada Lovelace');
  const sealedAddress = sealTo(kp.publicKey, '742 Evergreen Terrace');
  return { kp, shares, sealedName, sealedAddress };
}

describe('breakGlass', () => {
  it('two shares + reason decrypt one user', async () => {
    const f = await fixture();
    const out = breakGlass({
      shares: [f.shares[0], f.shares[2]], publicKeyB64: f.kp.publicKeyB64,
      sealedName: f.sealedName, sealedAddress: f.sealedAddress,
      reason: 'court order 2026-11', members: ['alice', 'bob'],
    });
    expect(out).toEqual({ name: 'Ada Lovelace', address: '742 Evergreen Terrace' });
  });

  it('one share fails', async () => {
    const f = await fixture();
    expect(() => breakGlass({
      shares: [f.shares[0]], publicKeyB64: f.kp.publicKeyB64,
      sealedName: f.sealedName, sealedAddress: null, reason: 'x', members: ['a', 'b'],
    })).toThrow();
  });

  it('refuses without a reason', async () => {
    const f = await fixture();
    expect(() => breakGlass({
      shares: [f.shares[0], f.shares[1]], publicKeyB64: f.kp.publicKeyB64,
      sealedName: f.sealedName, sealedAddress: null, reason: '', members: ['a', 'b'],
    })).toThrow(/reason/i);
  });

  it('appends an audit line', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'bg-'));
    const log = join(dir, 'break-glass.log');
    appendAuditLine(log, { members: ['a', 'b'], user_id: 'u1', reason: 'r', at: '2026-09-17T00:00:00Z' });
    expect(readFileSync(log, 'utf8')).toMatch(/"user_id":"u1"/);
  });
});
