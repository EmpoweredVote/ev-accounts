// Saved copies of source documents, and the one stable id a roll call carries across runs.
import { createHash } from 'node:crypto';
import type { PoolClient } from 'pg';
import type { CityScope } from './types.js';
import type { VoteDocumentKind } from './onboard/feed.js';

export type Queryable = Pick<PoolClient, 'query'>;

/**
 * Production: `supabaseAdmin.storage.from('local-record-sources')` (a private bucket), wrapped so that upload passes
 * `{ upsert: true }`. Paths are content-addressed, so the same bytes can be uploaded twice (a second URL, or a retry
 * after a failed insert): `upload` MUST tolerate overwriting an existing object. Tests: an in-memory stub.
 */
export interface StorageLike {
  upload(path: string, bytes: Uint8Array, contentType: string): Promise<void>;
}

export type SavedDocumentKind = VoteDocumentKind | 'item_text';

export function sha256Hex(bytes: Uint8Array): string {
  return createHash('sha256').update(bytes).digest('hex');
}

const slug = (s: string): string =>
  s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');

/** `bloomington-<date>-<item slug>-<question slug>`; the same roll call always gets the same id. */
export function externalVoteId(_city: CityScope, date: string, itemNumber: string, question: string): string {
  return `bloomington-${date}-${slug(itemNumber)}-${slug(question)}`;
}

const TYPES: Record<SavedDocumentKind, { ext: string; contentType: string }> = {
  memorandum: { ext: 'pdf', contentType: 'application/pdf' },
  minutes: { ext: 'pdf', contentType: 'application/pdf' },
  item_text: { ext: 'txt', contentType: 'text/plain' },
};

/**
 * Keep a copy of a source document. Same URL and same bytes: nothing changes. Same URL, new bytes: a new row,
 * and the old row points at it through `superseded_by`.
 */
export async function saveDocument(
  db: Queryable,
  storage: StorageLike,
  doc: { city: CityScope; kind: SavedDocumentKind; url: string; cityFileId: string | null; bytes: Uint8Array },
): Promise<{ id: string; sha256: string; isNew: boolean }> {
  const sha256 = sha256Hex(doc.bytes);
  const FIND = `SELECT id, superseded_by FROM essentials.local_record_source_documents WHERE source_url = $1 AND sha256 = $2`;
  // One statement on every path: $1 becomes the only current row of this URL, every other row points at it.
  // This also repairs a URL left with two current rows by an interrupted run.
  const MAKE_CURRENT = `UPDATE essentials.local_record_source_documents
     SET superseded_by = CASE WHEN id = $1::uuid THEN NULL ELSE $1::uuid END
     WHERE source_url = $2 AND superseded_by IS DISTINCT FROM (CASE WHEN id = $1::uuid THEN NULL ELSE $1::uuid END)`;

  const found = await db.query(FIND, [doc.url, sha256]);
  if (found.rows.length) {
    const id: string = found.rows[0].id;
    // Not current means the file went back to an older copy: that is a change the caller must read.
    const wasCurrent = found.rows[0].superseded_by == null;
    await db.query(MAKE_CURRENT, [id, doc.url]);
    return { id, sha256, isNew: !wasCurrent };
  }

  const { ext, contentType } = TYPES[doc.kind];
  const storagePath = `${doc.city.replace(/[^A-Za-z0-9._-]+/g, '-')}/${doc.kind}/${sha256}.${ext}`;
  await storage.upload(storagePath, doc.bytes, contentType);

  const ins = await db.query(
    `INSERT INTO essentials.local_record_source_documents
       (id, city_scope, kind, source_url, city_file_id, fetched_at, sha256, storage_path)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, now(), $5, $6)
     ON CONFLICT (source_url, sha256) DO NOTHING
     RETURNING id`,
    [doc.city, doc.kind, doc.url, doc.cityFileId, sha256, storagePath],
  );
  let id: string;
  let isNew = true;
  if (ins.rows.length) {
    id = ins.rows[0].id;
  } else {
    // Another run saved the same copy first.
    const again = await db.query(FIND, [doc.url, sha256]);
    id = again.rows[0].id;
    isNew = again.rows[0].superseded_by != null;
  }
  await db.query(MAKE_CURRENT, [id, doc.url]);
  return { id, sha256, isNew };
}
