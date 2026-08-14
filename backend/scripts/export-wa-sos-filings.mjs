/**
 * Export the complete WA Secretary of State candidate-filing list for an election.
 *
 *   node export-wa-sos-filings.mjs 898 primary.csv    # PRIMARY 2026 (08/04/2026)
 *   node export-wa-sos-filings.mjs 899 general.csv    # GENERAL 2026 (11/03/2026)
 *
 * Election ids come from the ddlElection dropdown on
 * https://voter.votewa.gov/CandidateList.aspx (548 options, newest first).
 *
 * WHY NOT JUST SCRAPE THE PAGE: the grid renders 100 rows per page out of ~1,108.
 * Reading page 1 looks like it worked and silently truncates the field — the exact
 * failure a candidate seed cannot afford. RadGrid paging postbacks did not work
 * reliably either.
 *
 * THE TRICK: the grid's own "Export to CSV" control is a plain <input type="submit">
 * registered as a non-AJAX postback. To fire it you must replay the ENTIRE form —
 * every input and select, not just the __VIEWSTATE trio — and send the button's
 * name with its actual value attribute, which is a SINGLE SPACE, not "". Sending an
 * empty value returns the HTML page instead of the CSV.
 *
 * KNOWN LIMIT: the county dropdown filters the on-screen grid only; the export
 * always returns the full statewide list. County races appear with District="County"
 * and no county identifier, so they can only be attributed by a race name that names
 * the county (e.g. "Metropolitan King County Council District No. 4"). Mailing
 * address is NOT a reliable county discriminator — candidates share campaign PO
 * boxes across counties.
 */
import fs from 'fs';

const E = process.argv[2] || '899';
const OUT = process.argv[3] || `filings-${E}.csv`;
const URL = `https://voter.votewa.gov/CandidateList.aspx?e=${E}`;
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36';
const CSV_BTN = 'ctl00$ContentPlaceHolder1$grdCandidates$ctl00$ctl02$ctl00$ExportToCsvButton';

const res1 = await fetch(URL, { headers: { 'User-Agent': UA } });
const html = await res1.text();
const cookie = (res1.headers.getSetCookie?.() || []).map((c) => c.split(';')[0]).join('; ');
console.log(`GET ${res1.status} bytes=${html.length}`);

const form = new URLSearchParams();

// Every <input> in the document, with its value.
for (const m of html.matchAll(/<input\b[^>]*>/g)) {
  const tag = m[0];
  const name = (tag.match(/name="([^"]*)"/) || [])[1];
  if (!name) continue;
  const type = ((tag.match(/type="([^"]*)"/) || [])[1] || 'text').toLowerCase();
  const value = (tag.match(/value="([^"]*)"/) || [])[1] ?? '';
  if (type === 'submit' || type === 'image' || type === 'button') continue; // add only the one we click
  if ((type === 'checkbox' || type === 'radio') && !/\bchecked\b/i.test(tag)) continue;
  form.append(name, value);
}

// Every <select>: take the selected option, else the first.
for (const m of html.matchAll(/<select\b[^>]*name="([^"]*)"[^>]*>([\s\S]*?)<\/select>/g)) {
  const name = m[1];
  const body = m[2];
  const sel = body.match(/<option[^>]*\bselected\b[^>]*value="([^"]*)"/) ||
              body.match(/<option[^>]*value="([^"]*)"[^>]*\bselected\b/);
  const first = body.match(/<option[^>]*value="([^"]*)"/);
  const v = sel ? sel[1] : first ? first[1] : '';
  form.append(name, v);
}

form.set('__EVENTTARGET', '');
form.set('__EVENTARGUMENT', '');
form.set(CSV_BTN, ' ');   // the submit button's actual value attribute

console.log(`form fields: ${[...form.keys()].length}`);

const res2 = await fetch(URL, {
  method: 'POST',
  headers: {
    'User-Agent': UA,
    'Content-Type': 'application/x-www-form-urlencoded',
    Referer: URL,
    ...(cookie ? { Cookie: cookie } : {}),
  },
  body: form.toString(),
  redirect: 'follow',
});
const buf = Buffer.from(await res2.arrayBuffer());
const ct = res2.headers.get('content-type') || '';
const cd = res2.headers.get('content-disposition') || '';
console.log(`POST ${res2.status} content-type=${ct} disposition=${cd} bytes=${buf.length}`);
fs.writeFileSync(OUT, buf);
const head = buf.toString('utf8').slice(0, 200).replace(/\r/g, '');
console.log('--- head ---');
console.log(head);
console.log(head.startsWith('<') ? '=> STILL HTML (export did not fire)' : '=> looks like CSV');
