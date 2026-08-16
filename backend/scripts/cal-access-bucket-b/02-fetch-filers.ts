// 02-fetch-filers.ts
// Emits the filer IDs needing evidence, and the in-page snippet that fetches their OFFICIAL
// Cal-Access committee names. Writes nothing itself -- paste the result into filer-records.json.
//
// Run from backend/:  npx tsx scripts/cal-access-bucket-b/02-fetch-filers.ts
//
// ── 🔴 WHY THIS IS NOT AN AUTOMATED FETCH, MEASURED 2026-08-16 ────────────────────────────────────
// The plan originally specified a Playwright script looping over the detail pages. It does not work,
// and the failure is silent -- every page returns an EMPTY BODY with a 200, so a naive script reports
// "not-found" for all 25 rather than erroring. Measured, in this order:
//
//   curl (any UA) ................... 212-byte Incapsula stub
//   chromium.launch({headless:true}) . home page 0 chars      -- headless is refused outright
//   chromium.launch({headless:false}) home page 1451 chars, detail page 0 chars
//   ...same, plus a custom userAgent . home page 0 chars      -- the UA override made it WORSE
//   MCP Playwright browser ........... home OK, detail OK     -- works
//
// The difference is the browser: a freshly launched Chromium is fingerprinted and refused, while the
// long-lived MCP browser has already passed the challenge and holds the Incapsula cookie.
// ⚠ Do NOT conclude from a run of "not-found" that the filers are missing. They are not; you are
// being blocked. The control below distinguishes the two cases.
//
// ── THE METHOD THAT WORKS ────────────────────────────────────────────────────────────────────────
// 1. Navigate the MCP browser to https://cal-access.sos.ca.gov/ (clears the challenge for the context).
// 2. Navigate to any Detail.aspx page, to confirm the context is good.
// 3. Run the snippet this script prints via browser_evaluate. It fetches all filers SAME-ORIGIN from
//    inside that page, so the cookie rides along, and returns every official name in ONE call.
// 4. Paste the result into data/cal-access-bucket-b/filer-records.json in the documented shape.
//
// 🔑 CONTROL: filer 1414018 MUST return "NEWSOM FOR CALIFORNIA GOVERNOR 2022". If it does not, the
// context is blocked or the anchor changed -- fix that before trusting any other row.
import * as fs from 'fs';
import * as path from 'path';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');

const worklist = JSON.parse(fs.readFileSync(path.join(DIR, 'worklist.json'), 'utf8'));
const ids: string[] = worklist.filter((r: any) => r.verdict !== 'names-them').map((r: any) => r.filer_id);

console.log(`${ids.length} filers need evidence.\n`);
console.log('Paste into browser_evaluate, with the MCP browser already on a cal-access.sos.ca.gov page:\n');
console.log(`async () => {
  const ids = ${JSON.stringify(ids)};
  const out = {};
  for (const id of ids) {
    try {
      const r = await fetch('/Campaign/Committees/Detail.aspx?id=' + id, { credentials: 'include' });
      const html = await r.text();
      const doc = new DOMParser().parseFromString(html, 'text/html');
      const text = (doc.body ? doc.body.innerText || doc.body.textContent || '' : '').replace(/\\s+/g, ' ');
      const m = text.match(/SUMMARY INFORMATION\\s*-\\s*(.+?)\\s*\\(ID#/i);
      out[id] = m ? m[1].trim() : ('__NOMATCH__len=' + text.length);
    } catch (e) { out[id] = '__ERROR__' + e.message; }
    await new Promise(res => setTimeout(res, 400));
  }
  return out;
}`);
console.log(`\nThen write data/cal-access-bucket-b/filer-records.json as:`);
console.log(`  { "<filer_id>": { "official_name": "...", "fetched_at": "YYYY-MM-DD", "status": "ok" }, ... }`);
console.log(`\nAny id whose value starts with __NOMATCH__ or __ERROR__ gets status "not-found" / "error"`);
console.log(`and an empty official_name. Task 3 purges those under the prove-it-right posture.`);
