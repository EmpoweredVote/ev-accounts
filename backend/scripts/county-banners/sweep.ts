/**
 * Stage 1 -- RECALL. Sweep Commons categories for county banner candidates.
 *
 * 🔴 SWEEP CATEGORIES AND THEIR SUBCATEGORIES, NOT KEYWORD SEARCH. Carried forward from
 * sweep-commons-banner-candidates.py, which learned it the hard way: the Bend banner's
 * source was missed by keyword search, by three relevant categories and by the Wikipedia
 * article images, and was found only by sweeping ~1,328 files. Recall matters more than
 * precision here, because precision is the NEXT stage's job and it is exact (a polygon).
 *
 * 🔴 A CATEGORY NAME IS NOT A JURISDICTION. Nothing this module returns is evidence of
 * where a photograph was taken. `sourceCategory` is kept for debugging only.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import { commonsApi } from './commonsClient.js';
import type { CandidateFile } from './types.js';

export type ApiFn = (params: Record<string, string | number>) => Promise<unknown>;

export interface SweepOptions {
  /** Levels of subcategory to descend. Commons buries good files one level down. */
  depth?: number;
  api?: ApiFn;
  onError?: (category: string, error: unknown) => void;
  /** Zero categories found is a different finding from zero files: the title missed. */
  onStats?: (stats: { categories: number; files: number }) => void;
}

interface CatMember { title: string }
interface ImageInfo { url?: string; width?: number; height?: number; extmetadata?: Record<string, { value?: string }> }
interface PageRow { title: string; imageinfo?: ImageInfo[] }

const str = (v: unknown): string | null => (typeof v === 'string' && v.length > 0 ? v : null);

/** Category titles to sweep for one county. */
export function countyCategoryRoots(countyName: string, stateName: string, seatName: string | null): string[] {
  // `geofence_boundaries.name` already reads "Dawson County", so never append "County".
  const roots = [`Category:${countyName}, ${stateName}`, `Category:${countyName}`];
  // The subject rule admits the county seat (spec, "Subject rule"), so it is swept
  // directly as well as reached through the county's subcategories.
  if (seatName) roots.push(`Category:${seatName}, ${stateName}`);
  return roots;
}

async function subcategories(cat: string, depth: number, api: ApiFn, seen: Set<string>, onError?: SweepOptions['onError']): Promise<void> {
  if (seen.has(cat) || depth < 0) return;
  seen.add(cat);
  if (depth === 0) return;
  try {
    const d = (await api({ action: 'query', list: 'categorymembers', cmtitle: cat, cmtype: 'subcat', cmlimit: 500 })) as { query?: { categorymembers?: CatMember[] } };
    for (const m of d.query?.categorymembers ?? []) await subcategories(m.title, depth - 1, api, seen, onError);
  } catch (e) {
    onError?.(cat, e);
  }
}

async function filesIn(cat: string, api: ApiFn): Promise<CandidateFile[]> {
  const out: CandidateFile[] = [];
  let cont: Record<string, string> = {};
  for (;;) {
    const d = (await api({ action: 'query', generator: 'categorymembers', gcmtitle: cat, gcmtype: 'file', gcmlimit: 500, prop: 'imageinfo', iiprop: 'url|size|extmetadata', ...cont })) as
      { query?: { pages?: PageRow[] }; continue?: Record<string, string> };
    for (const p of d.query?.pages ?? []) {
      const ii = p.imageinfo?.[0];
      if (!ii) continue;
      const md = ii.extmetadata ?? {};
      out.push({
        title: p.title,
        url: ii.url ?? '',
        width: ii.width ?? 0,
        height: ii.height ?? 0,
        licence: str(md.LicenseShortName?.value),
        author: str(md.Artist?.value)?.slice(0, 120) ?? null,
        date: str(md.DateTimeOriginal?.value)?.slice(0, 40) ?? null,
        sourceCategory: cat,
        lat: null,
        lon: null,
      });
    }
    if (!d.continue) return out;
    cont = d.continue;
  }
}

/** Every distinct file in `roots` and their subcategories, first category wins. */
export async function sweepCategories(roots: string[], opts: SweepOptions = {}): Promise<CandidateFile[]> {
  const api = opts.api ?? commonsApi;
  const depth = opts.depth ?? 1;
  const cats = new Set<string>();
  for (const r of roots) await subcategories(r, depth, api, cats, opts.onError);

  opts.onStats?.({ categories: cats.size, files: 0 });

  const seenTitles = new Set<string>();
  const files: CandidateFile[] = [];
  // Roots first, so `sourceCategory` names the closest category a file was found in.
  for (const cat of [...roots.filter((r) => cats.has(r)), ...[...cats].filter((c) => !roots.includes(c))]) {
    let got: CandidateFile[];
    try {
      got = await filesIn(cat, api);
    } catch (e) {
      // 🔴 One bad category must not cost the rest of the county.
      opts.onError?.(cat, e);
      continue;
    }
    for (const f of got) {
      if (seenTitles.has(f.title)) continue;
      seenTitles.add(f.title);
      files.push(f);
    }
  }
  opts.onStats?.({ categories: cats.size, files: files.length });
  return files;
}
