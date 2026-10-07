/**
 * Load the batch's human-saved own-site copies: <batch>/sources.json entries that are
 * source_kind `own-site` AND carry a human_saved_path inside the batch dir (ruling 2026-10-07, rule 3:
 * own-site only — a news or government page with a saved copy is NOT picked up). Absent or unparseable
 * manifest = no copies, never an error: most batches have none.
 */
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parseSourcesManifest } from './sourcesManifest.js';
import { resolveHumanSavedPath } from './snapshotSources.js';
import { sha256Hex } from '../../src/lib/humanSavedCopy.js';

export interface LoadedCopy { rawSha256: string; text: string }

export function loadHumanSavedCopies(
  dir: string,
  toText: (raw: string) => string,
  read: (p: string) => string = (p) => readFileSync(p, 'utf8'),
  exists: (p: string) => boolean = existsSync,
): { copies: Map<string, LoadedCopy>; warnings: string[] } {
  const copies = new Map<string, LoadedCopy>();
  const warnings: string[] = [];
  const manifestPath = join(dir, 'sources.json');
  if (!exists(manifestPath)) return { copies, warnings };
  let parsed;
  try { parsed = parseSourcesManifest(JSON.parse(read(manifestPath))); }
  catch (e) { return { copies, warnings: [`sources.json unreadable (${(e as Error).message}) — no human-saved copies loaded`] }; }
  if (!parsed.ok) return { copies, warnings: [`sources.json invalid — no human-saved copies loaded: ${parsed.errors.join('; ')}`] };
  for (const entry of parsed.manifest.sources) {
    if (!entry.human_saved_path || entry.source_kind !== 'own-site') continue;
    const p = resolveHumanSavedPath(dir, entry.human_saved_path);
    if (p === null) { warnings.push(`human_saved_path ${entry.human_saved_path} resolves outside the batch dir — ignored`); continue; }
    if (!exists(p)) { warnings.push(`human_saved_path ${entry.human_saved_path} does not exist — ignored`); continue; }
    const raw = read(p);
    copies.set(entry.url.trim(), { rawSha256: sha256Hex(raw), text: toText(raw) });
  }
  return { copies, warnings };
}
