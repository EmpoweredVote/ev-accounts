import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { describe, expect, it, vi } from 'vitest';
import { isPubinfoDoc, readPubinfoDoc } from './caPubinfo.js';

describe('caPubinfo — California vote files on this machine', () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'pubinfo-'));
  mkdirSync(path.join(dir, '2025', 'bills'), { recursive: true });
  writeFileSync(path.join(dir, '2025', 'bills', '202520260AB1127.json'), '{"bill_id":"202520260AB1127"}');
  writeFileSync(path.join(dir, '2025', 'legislators.json'), '[]');

  it('knows a bill file and a member list, and nothing else', () => {
    expect(isPubinfoDoc('pubinfo:2025/bills/202520260AB1127.json')).toBe(true);
    expect(isPubinfoDoc('pubinfo:2025/legislators.json')).toBe(true);
    for (const d of ['pubinfo:2025/../../etc/passwd', 'pubinfo:2025/bills/../legislators.json', 'pubinfo:2025/MANIFEST.json',
      'https://leginfo.legislature.ca.gov/x', 'pubinfo:25/legislators.json']) {
      expect([d, isPubinfoDoc(d)]).toEqual([d, false]);
    }
  });

  it('reads a file from the folder it is given, and answers null without the folder or the file', () => {
    expect(readPubinfoDoc('pubinfo:2025/bills/202520260AB1127.json', dir)).toBe('{"bill_id":"202520260AB1127"}');
    expect(readPubinfoDoc('pubinfo:2025/legislators.json', dir)).toBe('[]');
    expect(readPubinfoDoc('pubinfo:2025/bills/202520260AB1128.json', dir)).toBeNull();
    expect(readPubinfoDoc('pubinfo:2023/legislators.json', dir)).toBeNull();
    expect(readPubinfoDoc('pubinfo:2025/../../x.json', dir)).toBeNull();
  });

  it('reads from CA_PUBINFO_DIR by default, and from nowhere when it is not set', () => {
    vi.stubEnv('CA_PUBINFO_DIR', dir);
    expect(readPubinfoDoc('pubinfo:2025/legislators.json')).toBe('[]');
    vi.stubEnv('CA_PUBINFO_DIR', '');
    expect(readPubinfoDoc('pubinfo:2025/legislators.json')).toBeNull();
    // not the working folder either: a 2025/legislators.json there must not be read
    const cwd = process.cwd();
    process.chdir(dir);
    try { expect(readPubinfoDoc('pubinfo:2025/legislators.json')).toBeNull(); } finally { process.chdir(cwd); vi.unstubAllEnvs(); }
  });
});
