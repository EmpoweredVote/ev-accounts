#!/usr/bin/env node
// Pull one county's results export from Oregon's election-night site.
//
// results.oregonvotes.gov/ResultsExport.aspx offers a per-county CSV behind an ASP.NET
// __doPostBack link: there is no GET URL for it. This replays the postback directly -- fetch the
// page, carry its cookie and its __VIEWSTATE / __VIEWSTATEGENERATOR / __EVENTVALIDATION, select
// the CSV radio (value "1"), and POST with __EVENTTARGET set to the county's LinkButton.
//
// ⚠ A COUNTY EXPORT IS THE ONLY MACHINE-READABLE LIST OF WHAT WAS ON THAT COUNTY'S BALLOT.
//   The per-contest results pages are paginated and, for the State Representative page at least,
//   stop halfway through a chamber while looking complete.
//
// 🔴 A CLEAN 200 IS NOT A CSV. ASP.NET answers a rejected postback with the PAGE again, status
//    200, and a reader that trusts the status code would parse an HTML document as an empty
//    ballot -- "this county held no elections", which is exactly the kind of false absence this
//    whole audit exists to avoid. So the response is required to carry the export's header row,
//    and anything else aborts with a non-zero exit.
import fs from 'node:fs';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36';
const PAGE = 'https://results.oregonvotes.gov/ResultsExport.aspx';
const EXPECTED_HEADER = 'ContestName';

const [ctl, outPath] = process.argv.slice(2);
if (!ctl || !outPath) {
  console.error('usage: fetch-or-county-export.mjs <ctlNN e.g. ctl25> <out.csv>');
  process.exit(2);
}

function hidden(html, id) {
  const re = new RegExp(`id="${id}"[^>]*value="([^"]*)"`);
  const m = html.match(re);
  if (!m) throw new Error(`the page has no hidden field ${id} -- the form has changed`);
  return m[1].replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&#39;/g, "'");
}

const r1 = await fetch(PAGE, { headers: { 'User-Agent': UA } });
if (!r1.ok) throw new Error(`the export page answered ${r1.status}`);
const cookie = (r1.headers.getSetCookie?.() || []).map((c) => c.split(';')[0]).join('; ');
const html = await r1.text();

// Name the county the link belongs to, so a wrong index cannot pass silently.
const nameRe = new RegExp(`rptCountyExport\\$${ctl}\\$LinkButton1&#39;,&#39;&#39;\\)"[^>]*>([^<]+)<`);
const nameMatch = html.match(nameRe);
if (!nameMatch) throw new Error(`no county link named ${ctl} on the page`);
const county = nameMatch[1].trim();

const target = `ctl00$MainContent$rptCountyExport$${ctl}$LinkButton1`;
const body = new URLSearchParams({
  __EVENTTARGET: target,
  __EVENTARGUMENT: '',
  __VIEWSTATE: hidden(html, '__VIEWSTATE'),
  __VIEWSTATEGENERATOR: hidden(html, '__VIEWSTATEGENERATOR'),
  __EVENTVALIDATION: hidden(html, '__EVENTVALIDATION'),
  'ctl00$MainContent$rblTypes': '1',            // 1 = CSV
});

const r2 = await fetch(PAGE, {
  method: 'POST',
  headers: {
    'User-Agent': UA,
    'Content-Type': 'application/x-www-form-urlencoded',
    Referer: PAGE,
    ...(cookie ? { Cookie: cookie } : {}),
  },
  body,
});
const text = await r2.text();
const disposition = r2.headers.get('content-disposition') || '';

if (!text.includes(EXPECTED_HEADER)) {
  console.error(`🔴 ${ctl} (${county}): the response is not an export.`);
  console.error(`   status ${r2.status}, content-type ${r2.headers.get('content-type')}, ${text.length} bytes`);
  console.error(`   first 200 chars: ${JSON.stringify(text.slice(0, 200))}`);
  process.exit(1);
}

fs.writeFileSync(outPath, text);
console.log(`${ctl} = ${county}: wrote ${outPath} — ${text.length} bytes, ${text.split('\n').length} lines, disposition ${JSON.stringify(disposition)}`);
