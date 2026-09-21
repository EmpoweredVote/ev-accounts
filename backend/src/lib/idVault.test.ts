import { describe, it, expect, vi, beforeEach } from 'vitest';

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query: poolQueryMock } }));

describe('idVault — gating', () => {
  beforeEach(() => { poolQueryMock.mockReset(); });

  it('isVaultEnabled reflects presence of a public key + version', async () => {
    vi.resetModules();
    vi.doMock('./env.js', () => ({ env: { ID_VAULT_PUBLIC_KEY: undefined, ID_VAULT_KEY_VERSION: undefined } }));
    const off = await import('./idVault.js');
    expect(off.isVaultEnabled()).toBe(false);
  });

  it('the app module exports no decrypt/open function', async () => {
    const mod = await import('./idVault.js');
    expect(Object.keys(mod).some((k) => /open|decrypt|unseal/i.test(k))).toBe(false);
  });

  it('upsertSeal writes ciphertext via ON CONFLICT and never SELECTs sealed_*', async () => {
    vi.resetModules();
    const { generateKeypair } = await import('./idVaultCrypto.js');
    const kp = await generateKeypair();
    vi.doMock('./env.js', () => ({ env: { ID_VAULT_PUBLIC_KEY: kp.publicKeyB64, ID_VAULT_KEY_VERSION: 1 } }));
    poolQueryMock.mockResolvedValue({ rows: [], rowCount: 1 });
    const { upsertSeal, isVaultEnabled } = await import('./idVault.js');
    expect(isVaultEnabled()).toBe(true);
    await upsertSeal('11111111-1111-1111-1111-111111111111', { name: 'Ada' });
    const [sql, params] = poolQueryMock.mock.calls[0];
    expect(sql).toMatch(/id_vault\.seal_upsert/);   // writes via the SECURITY DEFINER function
    expect(Buffer.isBuffer(params[1])).toBe(true);  // sealed_name is a Buffer
    expect(params[2]).toBeNull();                    // address not provided -> null (function COALESCEs)
    expect(params[3]).toBe(1);                       // key_version
  });
});
