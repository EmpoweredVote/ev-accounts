/**
 * compare-extraction.ts - diff two measure-extraction.ts reports (legacy vs
 * readability) snippet-by-snippet and print the gained/lost table the decision
 * needs (task 0003 rung 1, STEP 4).
 *
 * Controls for network flakiness: the two passes run minutes apart, so a URL can
 * time out in one and not the other. A "verified -> url_broken" flip is fetch
 * noise, not an extractor effect. We therefore report gained/lost BOTH raw and
 * on the STABLE SUBSET - snippets whose page was fetched successfully in BOTH
 * passes - which is the fair measure of the extractor itself.
 *
 * Usage:
 *   npx tsx scripts/compare-extraction.ts \
 *     --before data/stance-research/extraction-legacy-2026-09-01.json \
 *     --after  data/stance-research/extraction-readability-2026-09-01.json
 */
import { readFileSync } from 'node:fs';

function opt(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i !== -1 && i + 1 < process.argv.length ? process.argv[i + 1] : undefined;
}
const BEFORE = opt('--before')!;
const AFTER = opt('--after')!;

interface SnippetResult { snippet_index: number; full_name: string; verdict: string }
interface UrlResult {
  slice: string; url: string; tier: string; extracted_chars: number;
  robots_disallowed: boolean; fetch_error: string | null; snippets: SnippetResult[];
}
interface Report { extractor: string; urls: UrlResult[] }

const before = JSON.parse(readFileSync(BEFORE, 'utf8')) as Report;
const after = JSON.parse(readFileSync(AFTER, 'utf8')) as Report;

const key = (slice: string, url: string, idx: number) => `${slice} ${url} ${idx}`;
const fetchedOk = (u: UrlResult) => u.tier === 'http' || u.tier === 'wayback' || u.tier === 'wayback_robots';

// index after-report by snippet key and by url
const afterSnip = new Map<string, SnippetResult>();
const afterUrl = new Map<string, UrlResult>();
for (const u of after.urls) {
  afterUrl.set(`${u.slice} ${u.url}`, u);
  for (const s of u.snippets) afterSnip.set(key(u.slice, u.url, s.snippet_index), s);
}
const beforeUrl = new Map<string, UrlResult>();
for (const u of before.urls) beforeUrl.set(`${u.slice} ${u.url}`, u);

interface Row {
  slice: string; url: string; idx: number; name: string;
  before: string; after: string; bothFetched: boolean;
}
const rows: Row[] = [];
for (const u of before.urls) {
  for (const s of u.snippets) {
    const a = afterSnip.get(key(u.slice, u.url, s.snippet_index));
    const au = afterUrl.get(`${u.slice} ${u.url}`);
    rows.push({
      slice: u.slice, url: u.url, idx: s.snippet_index, name: s.full_name,
      before: s.verdict, after: a?.verdict ?? 'MISSING',
      bothFetched: fetchedOk(u) && !!au && fetchedOk(au),
    });
  }
}

function median(nums: number[]): number {
  if (!nums.length) return 0;
  const s = [...nums].sort((a, b) => a - b); const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : Math.round((s[m - 1] + s[m]) / 2);
}
function medianChars(rep: Report, slice: string): number {
  return median(rep.urls.filter((u) => u.slice === slice && u.extracted_chars > 0).map((u) => u.extracted_chars));
}

const slices = [...new Set(rows.map((r) => r.slice))];
console.log(`# Extraction comparison - ${before.extractor} -> ${after.extractor}\n`);
console.log(`before: ${BEFORE}`);
console.log(`after : ${AFTER}\n`);

let grandGainStable = 0, grandLostStable = 0;
for (const slice of slices) {
  const rs = rows.filter((r) => r.slice === slice);
  const vBefore = rs.filter((r) => r.before === 'verified').length;
  const vAfter = rs.filter((r) => r.after === 'verified').length;

  // RAW transitions
  const gainedRaw = rs.filter((r) => r.before !== 'verified' && r.after === 'verified');
  const lostRaw = rs.filter((r) => r.before === 'verified' && r.after !== 'verified');

  // STABLE subset - page fetched OK in both passes (isolates the extractor)
  const stable = rs.filter((r) => r.bothFetched);
  const gainedS = stable.filter((r) => r.before !== 'verified' && r.after === 'verified');
  const lostS = stable.filter((r) => r.before === 'verified' && r.after !== 'verified');
  grandGainStable += gainedS.length; grandLostStable += lostS.length;

  console.log(`\n## slice: ${slice}  (${rs.length} snippets)`);
  console.log(`verified: ${vBefore} -> ${vAfter}   (net ${vAfter - vBefore >= 0 ? '+' : ''}${vAfter - vBefore})`);
  console.log(`median extracted chars: ${medianChars(before, slice)} -> ${medianChars(after, slice)}`);
  console.log(`RAW    gained ${gainedRaw.length}, lost ${lostRaw.length}`);
  console.log(`STABLE gained ${gainedS.length}, lost ${lostS.length}   (both passes fetched the page)`);
  if (lostS.length) {
    console.log(`  - lost (stable), before -> after:`);
    for (const r of lostS) console.log(`      ${r.before} -> ${r.after}   ${r.url}`);
  }
  if (gainedS.length) {
    console.log(`  - gained (stable), before -> after:`);
    for (const r of gainedS) console.log(`      ${r.before} -> ${r.after}   ${r.url}`);
  }
}

console.log(`\n## OVERALL (stable subset): gained ${grandGainStable}, lost ${grandLostStable}  -> net ${grandGainStable - grandLostStable >= 0 ? '+' : ''}${grandGainStable - grandLostStable}`);
console.log(grandGainStable > grandLostStable
  ? 'VERDICT: readability nets MORE matches on the stable subset -> flip default.'
  : 'VERDICT: readability does NOT net more matches on the stable subset -> do NOT flip; STOP AND ASK.');
