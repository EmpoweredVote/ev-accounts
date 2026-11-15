import { describe, expect, it, vi } from 'vitest';

vi.mock('../supabase.js', () => ({ supabaseAdmin: { storage: { from: vi.fn() } } }));

import { archiveDataset, archivePath } from './archive.js';

const ds = { session_id: 2037, dataset_hash: 'abdf16b3215a9c' };
const zip = Buffer.from('PK\u0003\u0004 test');

describe('archivePath', () => {
  it('names the object by state, session and hash', () => {
    expect(archivePath('WA', 2037, 'abdf16b3215a9c')).toBe('WA/2037/abdf16b3215a9c.zip');
  });
  it('refuses a malformed state or hash rather than writing a stray path', () => {
    expect(() => archivePath('wa', 1, 'abcdef')).toThrow();
    expect(() => archivePath('WA', 1, '../x')).toThrow();
  });
});

describe('archiveDataset', () => {
  it('uploads the ZIP under its path', async () => {
    const upload = vi.fn().mockResolvedValue({ error: null });
    expect(await archiveDataset('WA', ds, zip, { upload })).toBe('saved');
    expect(upload).toHaveBeenCalledWith('WA/2037/abdf16b3215a9c.zip', zip);
  });

  it('treats an existing object as already saved (same hash = same bytes)', async () => {
    const upload = vi.fn().mockResolvedValue({ error: { statusCode: '409', message: 'The resource already exists' } });
    expect(await archiveDataset('WA', ds, zip, { upload })).toBe('already-saved');
  });

  it('never throws when the upload is refused or crashes, so the import carries on', async () => {
    const refused = vi.fn().mockResolvedValue({ error: { statusCode: '413', message: 'Payload too large' } });
    expect(await archiveDataset('WA', ds, zip, { upload: refused })).toBe('failed');
    const crashed = vi.fn().mockRejectedValue(new Error('network down'));
    expect(await archiveDataset('WA', ds, zip, { upload: crashed })).toBe('failed');
    const badHash = vi.fn();
    expect(await archiveDataset('WA', { session_id: 1, dataset_hash: 'nope!' }, zip, { upload: badHash })).toBe('failed');
    expect(badHash).not.toHaveBeenCalled();
  });

  it('writes nothing on a dry run', async () => {
    const upload = vi.fn();
    expect(await archiveDataset('WA', ds, zip, { dryRun: true, upload })).toBe('skipped-dry-run');
    expect(upload).not.toHaveBeenCalled();
  });
});
