/**
 * One state's sweep, moved from JSON on this machine into the database the operator reviews.
 *
 * 🔴 A RE-IMPORT MUST NOT ERASE A DECISION. The operator will re-sweep a state after round 2,
 * and the second import arrives with refreshed candidates for counties that already carry a
 * keep. The review upsert's SET list therefore names ONLY the sweep's own columns: every
 * decision column -- status, chosen_title, vertical_anchor, focus, caption_sighted, decided_at,
 * decided_by -- is absent from it, and that absence is the whole protection. It has a test, and
 * the test reads the SET clause rather than the result, because a SET list that quietly grew is
 * exactly the change that would pass a result-shaped test. 73 counties of cropping were nearly
 * lost once already.
 *
 * 🔴 THE SOURCE PAGE IS DERIVED FROM THE TITLE, NOT FROM THE UPLOAD URL. plan 1's CandidateFile
 * carries only the upload URL, which names no author and states no terms, and the table's CHECK
 * refuses one. The file description page is `commons.wikimedia.org/wiki/<title>`, which is
 * deterministic from a title we already hold. Building a TITLE from an upload path is the thing
 * the repo's Commons rule forbids; this is the opposite direction.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 * Plan: docs/superpowers/plans/2026-11-20-county-banner-review-surface.md
 */
import fs from 'node:fs';
import path from 'node:path';
import type { CandidateFile } from './types.js';
import type { QueryFn } from './locate.js';
import { pathToFileURL } from 'node:url';
import { uploadFrame, ensureBucket } from './frames.js';

export interface ImportDeps {
  query: QueryFn;
  /** Injected in tests; defaults to the real storage upload. */
  upload?: (localPath: string, key: string) => Promise<string>;
}

export interface ImportSummary {
  counties: number;
  candidates: number;
  framesUploaded: number;
  /** Files named in a county row whose frame was not on disk. Not fatal, but not invisible. */
  framesMissing: number;
  unreadable: string[];
}

/** The page a file's licence and author were read from. */
export function descriptionPageUrl(commonsTitle: string): string {
  return `https://commons.wikimedia.org/wiki/${encodeURI(commonsTitle).replace(/#/g, '%23')}`;
}

const CANDIDATE_SQL = `
  INSERT INTO essentials.county_banner_candidates
    (geoid, commons_title, rank_position, frame_url, source_page_url, width, height,
     licence, author, located_by, lat, lon, caption_text, caption_source_url,
     confirming_source_url, place_list_available)
  VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)
  ON CONFLICT (geoid, commons_title) DO UPDATE SET
    rank_position         = EXCLUDED.rank_position,
    frame_url             = EXCLUDED.frame_url,
    source_page_url       = EXCLUDED.source_page_url,
    width                 = EXCLUDED.width,
    height                = EXCLUDED.height,
    licence               = EXCLUDED.licence,
    author                = EXCLUDED.author,
    located_by            = EXCLUDED.located_by,
    lat                   = EXCLUDED.lat,
    lon                   = EXCLUDED.lon,
    caption_text          = EXCLUDED.caption_text,
    caption_source_url    = EXCLUDED.caption_source_url,
    confirming_source_url = EXCLUDED.confirming_source_url,
    place_list_available  = EXCLUDED.place_list_available`;

// 🔴 THE SET LIST BELOW IS A SAFETY PROPERTY, NOT A STYLE CHOICE. Every column the operator
// decides is deliberately missing from it. Adding one here erases work silently.
const REVIEW_SQL = `
  INSERT INTO essentials.county_banner_review
    (geoid, state_usps, county_name, swept, files_swept, categories_found, category_errors,
     geometry_candidates, caption_candidates, rejected)
  VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10::jsonb)
  ON CONFLICT (geoid) DO UPDATE SET
    state_usps          = EXCLUDED.state_usps,
    county_name         = EXCLUDED.county_name,
    swept               = EXCLUDED.swept,
    files_swept         = EXCLUDED.files_swept,
    categories_found    = EXCLUDED.categories_found,
    category_errors     = EXCLUDED.category_errors,
    geometry_candidates = EXCLUDED.geometry_candidates,
    caption_candidates  = EXCLUDED.caption_candidates,
    rejected            = EXCLUDED.rejected,
    imported_at         = now()`;

/** A candidate as the county JSON holds it, plus the caption lane's fields once Task 8 adds them. */
interface StoredCandidate extends CandidateFile {
  locatedBy?: 'geometry' | 'caption';
  captionText?: string | null;
  captionSourceUrl?: string | null;
  confirmingSourceUrl?: string | null;
  placeListAvailable?: boolean | null;
}

export async function importState(stateUsps: string, dir: string, deps: ImportDeps): Promise<ImportSummary> {
  const upload = deps.upload ?? uploadFrame;
  const usps = stateUsps.toUpperCase();
  const summary: ImportSummary = {
    counties: 0, candidates: 0, framesUploaded: 0, framesMissing: 0, unreadable: [],
  };

  const files = fs.readdirSync(dir).filter((f) => /^\d+\.json$/.test(f)).sort();
  for (const file of files) {
    let row: Record<string, unknown>;
    try {
      row = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8')) as Record<string, unknown>;
    } catch {
      // A crash mid-write leaves truncated JSON. One bad file must not cost the state.
      summary.unreadable.push(file);
      continue;
    }

    const geoid = String(row.geoid ?? '');
    const candidates = (row.candidates ?? []) as StoredCandidate[];
    let geometryCount = 0;
    let captionCount = 0;

    for (let i = 0; i < candidates.length; i++) {
      const c = candidates[i];
      const locatedBy = c.locatedBy ?? 'geometry';
      if (locatedBy === 'caption') captionCount++; else geometryCount++;

      const key = `${geoid}-${i}.jpg`;
      const local = path.join(dir, 'img', key);
      let frameUrl: string;
      if (fs.existsSync(local)) {
        frameUrl = await upload(local, key);
        summary.framesUploaded++;
      } else {
        // The row still goes in: a candidate with no frame is visible as a broken option on
        // the review page, which is a finding. Dropping it would hide the gap instead.
        summary.framesMissing++;
        frameUrl = '';
      }

      await deps.query(CANDIDATE_SQL, [
        geoid, c.title, i, frameUrl, descriptionPageUrl(c.title), c.width, c.height,
        c.licence, c.author, locatedBy, c.lat ?? null, c.lon ?? null,
        c.captionText ?? null, c.captionSourceUrl ?? null, c.confirmingSourceUrl ?? null,
        c.placeListAvailable ?? null,
      ]);
      summary.candidates++;
    }

    await deps.query(REVIEW_SQL, [
      geoid, usps, String(row.name ?? ''), Boolean(row.swept),
      Number(row.filesSwept ?? 0), Number(row.categoriesFound ?? 0), Number(row.categoryErrors ?? 0),
      geometryCount, captionCount, JSON.stringify(row.rejected ?? {}),
    ]);
    summary.counties++;
  }

  return summary;
}

// --- CLI ------------------------------------------------------------------------------------
// npm run banners:import --prefix backend -- DE <dir>
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [, , stateArg, dirArg] = process.argv;
  if (!stateArg || !dirArg) {
    process.stderr.write('usage: banners:import <STATE> <dir>\n');
    process.exit(2);
  }
  const { Pool } = await import('pg');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const query: QueryFn = async (sql, params) => (await pool.query(sql, params as unknown[])).rows;
  try {
    await ensureBucket();
    const s = await importState(stateArg, dirArg, { query });
    process.stdout.write(
      `${stateArg.toUpperCase()}: ${s.counties} counties, ${s.candidates} candidates, ` +
      `${s.framesUploaded} frames uploaded, ${s.framesMissing} frames missing, ` +
      `${s.unreadable.length} unreadable\n`,
    );
    if (s.unreadable.length > 0) process.stdout.write(`  unreadable: ${s.unreadable.join(', ')}\n`);
  } finally {
    await pool.end();
  }
}
