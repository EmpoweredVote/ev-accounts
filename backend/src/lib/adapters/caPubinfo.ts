/**
 * caPubinfo — California's vote documents are files on this machine, not pages on the web.
 *
 * California's vote pages (leginfo.legislature.ca.gov) are disallowed to every crawler by robots.txt and answer our bot
 * with a Cloudflare 403. The same votes are in the Legislature's bulk download, PUBINFO, which
 * scripts/stage5/openstates/ca_pubinfo.py keeps on disk (read once per session, kept current with the daily change files)
 * and indexes by bill. stateRollCallEvidence.ts names those files as `pubinfo:<year>/bills/<bill id>.json` and
 * `pubinfo:<year>/legislators.json`; this reads one from CA_PUBINFO_DIR. Like LEGISCAN_DATASETS, it is set on the
 * machine that runs the verifier and the Stage 5 tools. Without it (or without the file) the answer is null: no
 * California vote line verifies, and nothing is fetched instead.
 */
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';

const DOC = /^pubinfo:(\d{4})\/(bills\/\d{9}[A-Z]{2,3}\d{1,5}\.json|legislators\.json)$/;

export function isPubinfoDoc(doc: string): boolean {
  return DOC.test(doc);
}

/** The body of a PUBINFO document, or null when it is not one, CA_PUBINFO_DIR is not set, or the file is missing. */
export function readPubinfoDoc(doc: string, dir: string | undefined = process.env.CA_PUBINFO_DIR): string | null {
  const m = DOC.exec(doc);
  if (!m || !dir) return null;
  const file = path.join(dir, m[1], m[2]);
  return existsSync(file) ? readFileSync(file, 'utf8') : null;
}
