// Resolve a Legistar matter's CITABLE web URL from its API MatterId, and prove the page is the
// right matter before anything is cut from it.
//
// 🟢 WHY THIS EXISTS. A LegislationDetail page is only served when ID and the WEB GUID are passed
// together — `?ID=` alone returns a 19-byte 200 — and the web GUID is NOT the API's MatterGuid.
// The slice-3 note said one known pair had to bootstrap the rest by walking meetings → agendas.
// It does not: `Gateway.aspx?M=L&ID=<API MatterId>` 302s to the full page, pair included.
//
// 🔴 A REDIRECT THAT LANDS SOMEWHERE IS NOT A REDIRECT THAT LANDS ON YOUR MATTER. The gateway
// takes any integer and will happily serve a different file, so this asserts the file number
// appears on the page it reached and exits non-zero when it does not.
//
// Usage: node _legistar_gateway.mjs <client> <MatterFile> [phrase to locate]
import { fetchLegistar } from './_legistar_text.mjs';

const client = process.argv[2];
const file = process.argv[3];
const phrase = process.argv[4];

const get = async (u) => { const r = await fetch(u); if (!r.ok) throw new Error(r.status + ' ' + u); return r.json(); };
const ms = await get(`https://webapi.legistar.com/v1/${client}/matters?$filter=MatterFile+eq+'${encodeURIComponent(file)}'`);
if (!ms.length) { console.error('no matter ' + file); process.exit(1); }
const m = ms[0];

const res = await fetch(`https://${client}.legistar.com/Gateway.aspx?M=L&ID=${m.MatterId}`, { redirect: 'follow' });
const url = res.url;
if (!/LegislationDetail\.aspx\?ID=\d+&GUID=[0-9A-Fa-f-]+/.test(url)) {
  console.error('gateway did not land on a LegislationDetail pair: ' + url); process.exit(1);
}

const { page, pretty, aligned } = await fetchLegistar(url);
// The positive control: this page must BE this matter.
if (!page.includes(file.toLowerCase())) {
  console.error(`REFUSED — ${url} does not name ${file}; the gateway served a different matter`);
  process.exit(1);
}
console.log(`${file}  MatterId ${m.MatterId}`);
console.log(`URL   ${url}`);
console.log(`page  ${page.length} chars normalized | aligned=${aligned}`);

if (phrase) {
  const i = page.indexOf(phrase.toLowerCase());
  if (i < 0) { console.error(`phrase not on the page: "${phrase}"`); process.exit(2); }
  console.log(`\n--- at offset ${i} (case preserved) ---\n` + (aligned ? pretty : page).slice(i, i + 1400));
}
