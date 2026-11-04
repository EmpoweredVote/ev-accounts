import AdmZip from 'adm-zip';
import { describe, expect, it } from 'vitest';
import { LightZip } from './lightZip.js';

function build(files: Record<string, string>, stored = false): Buffer {
  const z = new AdmZip();
  for (const [name, text] of Object.entries(files)) z.addFile(name, Buffer.from(text, 'utf8'));
  if (stored) z.getEntries().forEach((e) => { e.header.method = 0; });
  return z.toBuffer();
}

describe('LightZip', () => {
  const files = {
    'US/2025_119th/bill/HB1.json': JSON.stringify({ bill: { bill_id: 1, bill_number: 'HB1' } }),
    'US/2025_119th/vote/678841.json': JSON.stringify({ roll_call: { roll_call_id: 678841, votes: [{ people_id: 1 }] } }),
    'US/2025_119th/people/9.json': 'not json {',
    'US/2025_119th/hash.md5': 'abc',
    'unicode/ü-é.json': '{"ok":true}',
  };

  it('lists files and reads them back (deflated)', () => {
    const z = new LightZip(build(files));
    expect(z.size).toBe(5);
    expect([...z.names].sort()).toEqual(Object.keys(files).sort());
    expect(z.read('US/2025_119th/hash.md5')?.toString()).toBe('abc');
    expect(z.readJson('US/2025_119th/bill/HB1.json').bill.bill_number).toBe('HB1');
    expect(z.readJson('unicode/ü-é.json')).toEqual({ ok: true });
  });

  it('reads stored (uncompressed) entries too', () => {
    const z = new LightZip(build(files, true));
    expect(z.readJson('US/2025_119th/vote/678841.json').roll_call.roll_call_id).toBe(678841);
  });

  it('returns undefined for a missing file or bad JSON', () => {
    const z = new LightZip(build(files));
    expect(z.read('nope.json')).toBeUndefined();
    expect(z.readJson('US/2025_119th/people/9.json')).toBeUndefined();
  });

  it('handles an archive with many files and a large one', () => {
    const many: Record<string, string> = {};
    for (let i = 0; i < 3000; i++) many[`d/f${i}.json`] = JSON.stringify({ i, pad: 'x'.repeat(i % 50) });
    many['d/big.json'] = JSON.stringify({ blob: 'y'.repeat(2_000_000) });
    const z = new LightZip(build(many));
    expect(z.size).toBe(3001);
    expect(z.readJson('d/f2999.json').i).toBe(2999);
    expect(z.readJson('d/big.json').blob.length).toBe(2_000_000);
  });

  it('rejects something that is not a zip', () => {
    expect(() => new LightZip(Buffer.from('this is not a zip file at all, just text'))).toThrow(/not a ZIP/);
  });
});
