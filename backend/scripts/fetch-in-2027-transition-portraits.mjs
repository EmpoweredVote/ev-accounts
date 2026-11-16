// Three Indiana portraits from iga.in.gov, with the controls scripts/sweep-in-legislature-headshots.mjs
// paid for:
//   * a non-browser client gets HTTP 200, text/html and ~691 bytes of React shell - FOR IMAGES TOO.
//     The status code reports success on the failing path.
//   * the extension lies: a .jpg served as image/jpeg can be a PNG. Magic number is the only answer.
//   * the control must be PAIRED. "No image" is satisfied when NOTHING returns an image, which is
//     exactly what a fully-blocked run looks like.
import fs from 'node:fs';
import crypto from 'node:crypto';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
const img = (chamber, lpid) => `https://iga.in.gov/images/legislators/125/2027/${chamber}/${lpid}.jpg`;

const sniff = b =>
  b.length < 12 ? null
  : b[0] === 0xff && b[1] === 0xd8 ? 'jpeg'
  : b.slice(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) ? 'png'
  : b.slice(0, 4).toString() === 'RIFF' && b.slice(8, 12).toString() === 'WEBP' ? 'webp'
  : null;

async function grab(url) {
  const r = await fetch(url, { headers: { 'User-Agent': UA, Referer: 'https://iga.in.gov/legislative/2027/legislators' } });
  const b = Buffer.from(await r.arrayBuffer());
  return { status: r.status, ct: r.headers.get('content-type'), bytes: b.length, fmt: sniff(b), buf: b };
}

// 🔴 THE PLACEHOLDER. iga.in.gov answers a member with no portrait on file with the Indiana
// statehouse-dome graphic on marble - 686x886, 403,152 bytes, PNG served as image/jpeg. It is
// not a face and no face detector we run would be asked. A batch catches it by collision only
// when TWO members get it; fetch one legislator alone and it sails through. So it is pinned by
// identity here, not by collision.
const PLACEHOLDER_SHA = 'cc1c59ec61c5be8315015efdd69e6ce3430068f20b5fd579977ca25f9701dba5';  // filled on first run, then asserted

async function pairedControl(when) {
  // 🔴 The positive control must NOT be one of the people under test. The first version of this
  // used Streeter - who turns out to BE the placeholder - so it certified the dome as "decodes
  // fine". A control drawn from the data under test moves with the defect.
  const pos = await grab(img('house', 'legislator_mike_aylesworth_1'));
  const neg = await grab(img('house', 'legislator_not_a_real_person_9'));
  console.log(`CONTROL ${when}`);
  console.log(`  positive (a real lpid, MUST decode): ${pos.status} ${pos.ct} ${pos.bytes}B -> ${pos.fmt ?? 'NOT AN IMAGE'}`);
  console.log(`  negative (a bogus lpid, MUST NOT)  : ${neg.status} ${neg.ct} ${neg.bytes}B -> ${neg.fmt ?? 'not an image'}`);
  if (!pos.fmt) throw new Error(`CONTROL ${when} FAILED: the known-good portrait did not decode - this host is serving the shell, so every "no image" below would be a lie`);
  if (neg.fmt) throw new Error(`CONTROL ${when} FAILED: a bogus lpid decoded as an image - the source is serving a placeholder to anyone who asks`);
  const posSha = crypto.createHash('sha256').update(pos.buf).digest('hex');
  if (PLACEHOLDER_SHA && posSha === PLACEHOLDER_SHA) throw new Error(`CONTROL ${when} FAILED: the control member is ALSO the placeholder, so it proves nothing - pick a different one`);
  console.log(`  control sha ${posSha.slice(0, 12)} (must differ from the placeholder)`);
}

const targets = [
  { name: 'Kellie Streeter',   politician_id: '65aadaef-c855-4fb7-907a-b7adae5d9559', chamber: 'house',  lpid: 'legislator_kellie_streeter_1',   seat: 'Indiana House 45' },
  { name: 'Amy Kippenbrock',   politician_id: 'd098cb69-71ae-4710-872d-8d43e3f55158', chamber: 'house',  lpid: 'legislator_amy_kippenbrock_1',   seat: 'Indiana House 63' },
  { name: 'Jeffrey Ellington', politician_id: '6a7a36f8-2fa5-4e1b-bdc6-6df3b63a4ac4', chamber: 'senate', lpid: 'legislator_jeff_ellington_1',    seat: 'Indiana Senate 39' },
];

await pairedControl('before');
fs.mkdirSync('raw', { recursive: true });
const shas = new Map();
const out = [];
for (const t of targets) {
  const url = img(t.chamber, t.lpid);
  const g = await grab(url);
  const rec = { ...t, url, status: g.status, bytes: g.bytes, fmt: g.fmt };
  if (g.fmt) {
    const sha = crypto.createHash('sha256').update(g.buf).digest('hex');
    rec.sha = sha;
    if (PLACEHOLDER_SHA && sha === PLACEHOLDER_SHA) rec.placeholder = true;
    if (shas.has(sha)) rec.duplicate_of = shas.get(sha);
    shas.set(sha, t.name);
    fs.writeFileSync(`raw/iga-${t.lpid}`, g.buf);
  }
  out.push(rec);
  console.log(`${g.fmt ? 'OK  ' : 'FAIL'} ${t.name.padEnd(18)} ${g.status} ${String(g.bytes).padStart(7)}B ${g.fmt ?? 'NOT AN IMAGE'}${rec.duplicate_of ? '  🔴 SAME BYTES AS ' + rec.duplicate_of : ''}`);
}
await pairedControl('after');
// a placeholder silhouette served to several members shows up as one sha across many people
const dupes = out.filter(r => r.duplicate_of);
if (dupes.length) throw new Error(`${dupes.length} portraits share bytes with another member - that is a placeholder, not a face`);
fs.writeFileSync('iga-fetched.json', JSON.stringify(out, null, 1));
console.log(`\n${out.filter(r => r.fmt).length} of ${out.length} decoded, all distinct`);
