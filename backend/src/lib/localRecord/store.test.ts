import { describe, expect, it } from 'vitest';
import { externalVoteId, saveDocument, sha256Hex, type StorageLike } from './store.js';

// A tiny in-memory stand-in for the source-documents table.
function fakeDb() {
  const rows: { id: string; source_url: string; sha256: string; superseded_by: string | null }[] = [];
  const sql: string[] = [];
  return {
    rows,
    sql,
    async query(text: string, params: unknown[] = []) {
      sql.push(text);
      if (/^\s*SELECT id/i.test(text)) {
        const r = rows.find((x) => x.source_url === params[0] && x.sha256 === params[1]);
        return { rows: r ? [{ id: r.id }] : [] };
      }
      if (/^\s*INSERT INTO essentials.local_record_source_documents/i.test(text)) {
        const [, , url, , sha] = params as string[];
        if (rows.some((x) => x.source_url === url && x.sha256 === sha)) return { rows: [] };
        const id = `d${rows.length + 1}`;
        rows.push({ id, source_url: url, sha256: sha, superseded_by: null });
        return { rows: [{ id }] };
      }
      if (/^\s*UPDATE essentials.local_record_source_documents/i.test(text)) {
        const [newId, url] = params as string[];
        for (const r of rows) if (r.source_url === url && r.id !== newId && !r.superseded_by) r.superseded_by = newId;
        return { rows: [] };
      }
      throw new Error(`unexpected SQL: ${text}`);
    },
  } as any;
}

function fakeStorage() {
  const files = new Map<string, Uint8Array>();
  const storage: StorageLike = {
    async upload(path, bytes) {
      files.set(path, bytes);
    },
  };
  return { files, storage };
}

const enc = (s: string) => new TextEncoder().encode(s);

describe('sha256Hex', () => {
  it('hashes a known byte string', () => {
    expect(sha256Hex(enc('abc'))).toBe('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });
});

describe('externalVoteId', () => {
  it('slugs the date, item and question', () => {
    expect(externalVoteId('place:1', '2026-10-07', 'App Ord 2026-02', 'Amendment 03')).toBe(
      'bloomington-2026-10-07-app-ord-2026-02-amendment-03',
    );
  });
});

describe('saveDocument', () => {
  const base = { city: 'place:1', kind: 'minutes' as const, url: 'https://x/1', cityFileId: '9' };

  it('stores a new document once and recognises the same bytes', async () => {
    const db = fakeDb();
    const { storage, files } = fakeStorage();
    const a = await saveDocument(db, storage, { ...base, bytes: enc('one') });
    const b = await saveDocument(db, storage, { ...base, bytes: enc('one') });
    expect(a.isNew).toBe(true);
    expect(b.isNew).toBe(false);
    expect(b.id).toBe(a.id);
    expect(db.rows).toHaveLength(1);
    expect([...files.keys()]).toEqual([`place:1/minutes/${a.sha256}.pdf`]);
  });

  it('supersedes the old row when the same URL has new bytes', async () => {
    const db = fakeDb();
    const { storage } = fakeStorage();
    const a = await saveDocument(db, storage, { ...base, bytes: enc('one') });
    const b = await saveDocument(db, storage, { ...base, bytes: enc('two') });
    expect(b.isNew).toBe(true);
    expect(db.rows).toHaveLength(2);
    expect(db.rows.find((r: any) => r.id === a.id).superseded_by).toBe(b.id);
    expect(db.rows.find((r: any) => r.id === b.id).superseded_by).toBeNull();
  });

  it('accepts a memorandum and item text', async () => {
    const db = fakeDb();
    const { storage, files } = fakeStorage();
    const m = await saveDocument(db, storage, { ...base, kind: 'memorandum', url: 'https://x/2', bytes: enc('m') });
    const t = await saveDocument(db, storage, { ...base, kind: 'item_text', url: 'https://x/3', bytes: enc('t') });
    expect([...files.keys()]).toEqual([`place:1/memorandum/${m.sha256}.pdf`, `place:1/item_text/${t.sha256}.txt`]);
  });
});
