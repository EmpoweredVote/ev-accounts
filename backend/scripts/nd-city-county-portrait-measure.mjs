// ND-5 (Knight slice 12): measure the portrait sources the City of Grand Forks and
// Grand Forks County publish for the 16 seated city/county officials.
//
// 🔴 THIS FILE MUST FETCH WITH NODE, NOT PYTHON `requests`.
// Both hosts sit behind a WAF that refuses the Python/urllib3 and curl TLS stacks with
// HTTP 403 "Access Denied" (483/485 bytes) in EVERY header shape tried — bare, with a
// Chrome User-Agent, and with UA+Accept+Accept-Language. Node's fetch is served 200 both
// bare and with a UA. The discriminator is the HTTP stack, NOT the User-Agent, so adding
// headers does not help. The program's renderer and importer use Python requests, so this
// cohort is invisible to them: any future import has to go through `bytes_from`.
//
// Run:  node backend/scripts/nd-city-county-portrait-measure.mjs <out-dir>
// Writes <out-dir>/_nd5-city-county-sources.json and <out-dir>/_sources/<name>-<hash>.<ext>.
// Deterministic: re-running reproduces the same files. Two negative controls run last and
// must both report alt_hits=0, or the alt-binding detector is not discriminating.
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
const UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

const SUBJECTS = [
 ["city","Council Member, Ward 1","Danny","Weigel","https://www.grandforksgov.com/Home/Components/StaffDirectory/StaffDirectory/38/259"],
 ["city","Council Member, Ward 2","Rebecca","Osowski","https://www.grandforksgov.com/Home/Components/StaffDirectory/StaffDirectory/94/259"],
 ["city","Council Member, Ward 3","Tricia","Berg","https://www.grandforksgov.com/Home/Components/StaffDirectory/StaffDirectory/12/259"],
 ["city","Council Member, Ward 4","Angela","Salentiny","https://www.grandforksgov.com/Home/Components/StaffDirectory/StaffDirectory/14/259"],
 ["city","Council Member, Ward 5","Mike","Fridolfs","https://www.grandforksgov.com/Home/Components/StaffDirectory/StaffDirectory/36/259"],
 ["city","Council Member, Ward 6","Dana","Sande","https://www.grandforksgov.com/Home/Components/StaffDirectory/StaffDirectory/18/259"],
 ["city","Council Member, Ward 7","Ken","Vein","https://www.grandforksgov.com/Home/Components/StaffDirectory/StaffDirectory/20/259"],
 ["city","Mayor","Brandon","Bochenski","https://www.grandforksgov.com/government/city-leadership/mayor-bochenski"],
 ["city","Municipal Judge","Kerry","Rosenquist","https://www.grandforksgov.com/government/city-departments/municipal-court"],
 ["county","Commissioner","Kimberly","Hagen","https://www.gfcounty.nd.gov/Home/Components/StaffDirectory/StaffDirectory/122/142"],
 ["county","Commissioner","Terry","Bjerke","https://www.gfcounty.nd.gov/Home/Components/StaffDirectory/StaffDirectory/118/142"],
 ["county","Commissioner","Anthony","Hodny","https://www.gfcounty.nd.gov/Home/Components/StaffDirectory/StaffDirectory/281/142"],
 ["county","Commissioner","Mark","Rustad","https://www.gfcounty.nd.gov/Home/Components/StaffDirectory/StaffDirectory/120/142"],
 ["county","Commissioner","Bob","Rost","https://www.gfcounty.nd.gov/Home/Components/StaffDirectory/StaffDirectory/126/142"],
 ["county","State's Attorney","Haley","Wamstad","https://www.gfcounty.nd.gov/Home/Components/StaffDirectory/StaffDirectory/128/160"],
 // NEGATIVE CONTROL: a staff id that is not this person's
 ["CONTROL","negative: Weigel's surname against Osowski's page","Danny","Weigel","https://www.grandforksgov.com/Home/Components/StaffDirectory/StaffDirectory/94/259"],
 // NEGATIVE CONTROL: a nonexistent staff id
 ["CONTROL","negative: nonexistent staff id 99999","Danny","Weigel","https://www.grandforksgov.com/Home/Components/StaffDirectory/StaffDirectory/99999/259"],
];

const OUT = process.argv[2];
const DIR = path.join(OUT, '_sources');
fs.mkdirSync(DIR, { recursive: true });

const get = async (u) => {
  const r = await fetch(u, { headers: { 'User-Agent': UA } });
  return { status: r.status, ct: r.headers.get('content-type'), buf: Buffer.from(await r.arrayBuffer()) };
};

(async () => {
  const results = [];
  for (const [cohort, role, first, last, page] of SUBJECTS) {
    const rec = { cohort, role, name: `${first} ${last}`, page, candidates: [] };
    try {
      const p = await get(page);
      rec.page_status = p.status; rec.page_bytes = p.buf.length;
      const html = p.buf.toString('utf8');
      rec.page_title = ((html.match(/<title>([\s\S]*?)<\/title>/i) || [])[1] || '').replace(/\s+/g,' ').trim();
      rec.page_names_person = new RegExp(last, 'i').test(html);
      const imgs = [];
      for (const tag of html.match(/<img[^>]*>/gi) || []) {
        const src = (tag.match(/src="([^"]*)"/i) || [])[1];
        if (!src) continue;
        imgs.push({ src: new URL(src, page).toString(), alt: (tag.match(/alt="([^"]*)"/i) || [])[1] || '' });
      }
      rec.img_tags = imgs.length;
      const hits = imgs.filter(i => new RegExp(last, 'i').test(i.alt));
      rec.alt_hits = hits.length;
      for (const h of hits) {
        const g = await get(h.src);
        const slug = `${last.toLowerCase()}-${crypto.createHash('sha1').update(h.src).digest('hex').slice(0,8)}`;
        const ext = g.ct && g.ct.includes('png') ? 'png' : 'jpg';
        const file = path.join(DIR, `${slug}.${ext}`);
        fs.writeFileSync(file, g.buf);
        rec.candidates.push({ url: h.src, alt: h.alt, status: g.status, content_type: g.ct,
          bytes: g.buf.length, magic: g.buf.slice(0,4).toString('hex'),
          sha256: crypto.createHash('sha256').update(g.buf).digest('hex').slice(0,16), file });
      }
    } catch (e) { rec.error = e.message; }
    results.push(rec);
    const tag = cohort === 'CONTROL' ? '[CONTROL] ' : '';
    console.log(`${tag}${rec.name.padEnd(20)} ${String(rec.role).slice(0,40).padEnd(42)} status=${rec.page_status} imgs=${rec.img_tags} alt_hits=${rec.alt_hits}`);
  }
  fs.writeFileSync(path.join(OUT, '_nd5-city-county-sources.json'), JSON.stringify(results, null, 2));
  console.log('\nwrote ledger');
})();
