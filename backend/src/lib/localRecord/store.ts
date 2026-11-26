// Saved copies of source documents, and the one stable id a roll call carries across runs.
import { createHash } from 'node:crypto';
import type { PoolClient } from 'pg';
import type { CityScope } from './types.js';
import type { VoteDocumentKind } from './onboard/feed.js';

export type Queryable = Pick<PoolClient, 'query'>;

/** Production: `supabaseAdmin.storage.from('local-record-sources')` (a private bucket). Tests: an in-memory stub. */
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
  const FIND = `SELECT id FROM essentials.local_record_source_documents WHERE source_url = $1 AND sha256 = $2`;

  const found = await db.query(FIND, [doc.url, sha256]);
  if (found.rows.length) return { id: found.rows[0].id, sha256, isNew: false };

  const { ext, contentType } = TYPES[doc.kind];
  const storagePath = `${doc.city}/${doc.kind}/${sha256}.${ext}`;
  await storage.upload(storagePath, doc.bytes, contentType);

  const ins = await db.query(
    `INSERT INTO essentials.local_record_source_documents
       (id, city_scope, kind, source_url, city_file_id, fetched_at, sha256, storage_path)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, now(), $5, $6)
     ON CONFLICT (source_url, sha256) DO NOTHING
     RETURNING id`,
    [doc.city, doc.kind, doc.url, doc.cityFileId, sha256, storagePath],
  );
  if (!ins.rows.length) {
    // Another run saved the same copy first.
    const again = await db.query(FIND, [doc.url, sha256]);
    return { id: again.rows[0].id, sha256, isNew: false };
  }
  const id: string = ins.rows[0].id;
  await db.query(
    `UPDATE essentials.local_record_source_documents SET superseded_by = $1
     WHERE source_url = $2 AND id <> $1 AND superseded_by IS NULL`,
    [id, doc.url],
  );
  return { id, sha256, isNew: true };
}
