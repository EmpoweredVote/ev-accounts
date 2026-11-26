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
        return { rows: r ? [{ id: r.id, superseded_by: r.superseded_by }] : [] };
      }
      if (/^\s*INSERT INTO essentials.local_record_source_documents/i.test(text)) {
        const [, , url, , sha] = params as string[];
        if (rows.some((x) => x.source_url === url && x.sha256 === sha)) return { rows: [] };
        const id = `d${rows.length + 1}`;
        rows.push({ id, source_url: url, sha256: sha, superseded_by: null });
        return { rows: [{ id }] };
      }
      if (/^\s*UPDATE essentials.local_record_source_documents/i.test(text)) {
        // Makes $1 the one current row of $2 and points every other row of that URL at it.
        const [id, url] = params as string[];
        for (const r of rows) if (r.source_url === url) r.superseded_by = r.id === id ? null : id;
        return { rows: [] };
      }
      throw new Error(`unexpected SQL: ${text}`);
    },
  } as any;
}

function fakeStorage() {
  const files = new Map<string, Uint8Array>();
  const uploads: string[] = [];
  const storage: StorageLike = {
    async upload(path, bytes) {
      uploads.push(path);
      files.set(path, bytes);
    },
  };
  return { files, storage, uploads };
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
    expect([...files.keys()]).toEqual([`place-1/minutes/${a.sha256}.pdf`]);
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
    expect([...files.keys()]).toEqual([`place-1/memorandum/${m.sha256}.pdf`, `place-1/item_text/${t.sha256}.txt`]);
  });

  const current = (db: any, url: string) => db.rows.filter((r: any) => r.source_url === url && !r.superseded_by);

  it('saves identical bytes found at two URLs', async () => {
    const db = fakeDb();
    const { storage, uploads } = fakeStorage();
    const a = await saveDocument(db, storage, { ...base, bytes: enc('same') });
    const b = await saveDocument(db, storage, { ...base, url: 'https://x/other', bytes: enc('same') });
    expect(a.isNew).toBe(true);
    expect(b.isNew).toBe(true);
    expect(b.id).not.toBe(a.id);
    expect(uploads).toHaveLength(2); // the same object is written again, so storage must tolerate overwrite
    expect(uploads[0]).toBe(uploads[1]);
  });

  it('A then B then A makes A current again and B superseded', async () => {
    const db = fakeDb();
    const { storage } = fakeStorage();
    const a = await saveDocument(db, storage, { ...base, bytes: enc('A') });
    const b = await saveDocument(db, storage, { ...base, bytes: enc('B') });
    const a2 = await saveDocument(db, storage, { ...base, bytes: enc('A') });
    expect(a2.id).toBe(a.id);
    expect(a2.isNew).toBe(true); // the file changed back, so the caller must read it again
    expect(current(db, base.url).map((r: any) => r.id)).toEqual([a.id]);
    expect(db.rows.find((r: any) => r.id === b.id).superseded_by).toBe(a.id);
  });

  it('A then B then C leaves only C current', async () => {
    const db = fakeDb();
    const { storage } = fakeStorage();
    await saveDocument(db, storage, { ...base, bytes: enc('A') });
    await saveDocument(db, storage, { ...base, bytes: enc('B') });
    const c = await saveDocument(db, storage, { ...base, bytes: enc('C') });
    expect(current(db, base.url).map((r: any) => r.id)).toEqual([c.id]);
    expect(db.rows.filter((r: any) => r.superseded_by === c.id)).toHaveLength(2);
  });

  it('repairs a URL left with two current rows when the same bytes arrive again', async () => {
    const db = fakeDb();
    const { storage } = fakeStorage();
    const a = await saveDocument(db, storage, { ...base, bytes: enc('A') });
    await saveDocument(db, storage, { ...base, bytes: enc('B') });
    // Simulate a crash between insert and supersede: both rows current.
    for (const r of db.rows) r.superseded_by = null;
    const again = await saveDocument(db, storage, { ...base, bytes: enc('B') });
    expect(again.isNew).toBe(false);
    expect(current(db, base.url)).toHaveLength(1);
    expect(current(db, base.url)[0].id).toBe(again.id);
    expect(a.id).not.toBe(again.id);
  });
});

describe('saveDocument: text chain', () => {
  it('a text saved beside a PDF has its own chain, a .txt path and text/plain, and never supersedes the PDF', async () => {
    const db = fakeDb();
    const types: string[] = [];
    const paths: string[] = [];
    const storage: StorageLike = { async upload(p, _b, ct) { paths.push(p); types.push(ct); } };
    const url = 'https://example.test/meetingFiles/1/download';
    const pdf = await saveDocument(db, storage, { city: 'place:1', kind: 'minutes', url, cityFileId: '1', bytes: new TextEncoder().encode('pdf') });
    const txt = await saveDocument(db, storage, {
      city: 'place:1', kind: 'minutes', url: `${url}#inventory-text`, cityFileId: null,
      bytes: new TextEncoder().encode('text'), contentType: 'text/plain',
    });
    expect(types).toEqual(['application/pdf', 'text/plain']);
    expect(paths[0].endsWith('.pdf')).toBe(true);
    expect(paths[1].endsWith('.txt')).toBe(true);
    expect(db.rows.find((r: any) => r.id === pdf.id).superseded_by).toBeNull();
    expect(db.rows.find((r: any) => r.id === txt.id).superseded_by).toBeNull();
  });
});
