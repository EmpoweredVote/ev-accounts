/**
 * archive.ts — keep a copy of every LegiScan dataset ZIP the jobs download.
 *
 * 🔴 WHY: on 2026-11-13 LegiScan paused our API key for repeat downloads of datasets that had
 * not changed. The weekly job downloaded each dataset, loaded what the app needs, and threw the
 * ZIP away, so research scripts (Stage 5 vote evidence) had to download the same unchanged
 * dataset again with the same key. LegiScan sees one customer, so those count as repeats.
 *
 * Saving the ZIP here lets research read OUR copy instead of asking LegiScan again
 * (`.planning/research/legiscan-cache/fetch.py` checks this bucket first).
 *
 * Layout: private bucket `legiscan-datasets`, object `<ST>/<session_id>/<dataset_hash>.zip`.
 * The hash is in the name, so a changed dataset is a new object and an old one is never
 * overwritten. Bucket created by migration CA_0382.
 *
 * Saving never fails an import: a refused or failed upload is logged and the run carries on.
 * Dry runs save nothing.
 */
export const ARCHIVE_BUCKET = 'legiscan-datasets';

export function archivePath(state: string, sessionId: number, datasetHash: string): string {
  if (!/^[A-Z]{2}$/.test(state)) throw new Error(`archivePath: bad state code ${JSON.stringify(state)}`);
  if (!/^[0-9a-f]{6,64}$/i.test(datasetHash)) throw new Error(`archivePath: bad dataset hash for session ${sessionId}`);
  return `${state}/${sessionId}/${datasetHash}.zip`;
}

type Uploader = (path: string, zip: Buffer) => Promise<{ error: { message: string; statusCode?: string } | null }>;

// Loaded on first use, not at import: supabase.ts validates the whole API env on import, which
// would make every test that imports the importer exit.
const defaultUploader: Uploader = async (path, zip) => {
  const { supabaseAdmin } = await import('../supabase.js');
  return supabaseAdmin.storage.from(ARCHIVE_BUCKET).upload(path, zip, { contentType: 'application/zip', upsert: false });
};

export type ArchiveOutcome = 'saved' | 'already-saved' | 'failed' | 'skipped-dry-run';

/** Save one dataset ZIP. Never throws. */
export async function archiveDataset(
  state: string,
  ds: { session_id: number; dataset_hash: string },
  zip: Buffer,
  opts: { dryRun?: boolean; upload?: Uploader } = {},
): Promise<ArchiveOutcome> {
  const tag = `[legiscan-archive] ${state} session ${ds.session_id}`;
  if (opts.dryRun) return 'skipped-dry-run';
  try {
    const path = archivePath(state, ds.session_id, ds.dataset_hash);
    const { error } = await (opts.upload ?? defaultUploader)(path, zip);
    if (!error) {
      console.info(`${tag}: saved ${(zip.length / 1_048_576).toFixed(1)} MiB as ${ARCHIVE_BUCKET}/${path}`);
      return 'saved';
    }
    // Same session and hash = same bytes, so an existing object is the copy we wanted.
    if (error.statusCode === '409' || /already exists/i.test(error.message)) {
      console.info(`${tag}: already saved`);
      return 'already-saved';
    }
    console.error(`${tag}: NOT saved (${error.statusCode ?? 'no status'}: ${error.message.slice(0, 200)})`);
    return 'failed';
  } catch (err) {
    console.error(`${tag}: NOT saved (${(err as Error).message.slice(0, 200)})`);
    return 'failed';
  }
}
