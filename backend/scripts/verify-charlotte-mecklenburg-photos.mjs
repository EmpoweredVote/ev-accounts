// Verify NC-3 stage 5 FROM OUTSIDE the database: read what production will render,
// re-fetch each object from the CDN and DECODE it. A 200 proves nothing -- a WAF page
// and a NoSuchKey error both arrive as bytes.
//
// Two controls, because a verifier that cannot fail proves nothing and a control that
// passes can pass for the wrong reason:
//   1. NEGATIVE: a bogus bucket key must be refused.
//   2. COUNT: the run asserts it tested all 28 NC-3 seats, 27 of them with a URL.
//      MN-6 passed "108 rows, 0 broken, control failed as required" while testing none
//      of the 133 rows just written. The count is the tell.
import dotenv from 'dotenv';
dotenv.config({ quiet: true });
import pg from 'pg';

const GOV = ['90cd3033-69fc-4abd-b48f-17b6f8f57f73', '9a858f93-db6d-49a2-9a2b-518e0b226ab6'];
const EXPECT_SEATS = 28;
const EXPECT_WITH_URL = 27;
const CDN = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/';

function decode(buf) {
  if (buf.length < 2000) return null;
  if (buf[0] === 0xff && buf[1] === 0xd8) {
    let i = 2;
    while (i < buf.length) {
      if (buf[i] !== 0xff) { i++; continue; }
      const m = buf[i + 1];
      if (m >= 0xc0 && m <= 0xcf && m !== 0xc4 && m !== 0xc8 && m !== 0xcc) {
        return { w: buf.readUInt16BE(i + 7), h: buf.readUInt16BE(i + 5), fmt: 'jpeg' };
      }
      i += 2 + buf.readUInt16BE(i + 2);
    }
    return null;
  }
  if (buf.slice(0, 8).toString('hex') === '89504e470d0a1a0a') {
    return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20), fmt: 'png' };
  }
  return null;
}

const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();

// Read what the RENDER path reads, not what the importer wrote: photo_custom_url is the
// field districtQueries.ts coalesces first. A politician_images row alone changes nothing
// a voter sees.
const { rows } = await c.query(
  `SELECT p.id, p.full_name, o.title, p.photo_custom_url, p.photo_origin_url,
          pi.url AS image_row_url, pi.type, pi.photo_license
     FROM essentials.offices o
     JOIN essentials.chambers ch ON ch.id = o.chamber_id
     JOIN essentials.office_current_holder och ON och.office_id = o.id
     JOIN essentials.politicians p ON p.id = och.politician_id
     LEFT JOIN essentials.politician_images pi
            ON pi.politician_id = p.id AND pi.type = 'default'
    WHERE ch.government_id = ANY($1::uuid[])
    ORDER BY p.full_name`, [GOV]);

console.log(`seats read: ${rows.length} (expected ${EXPECT_SEATS})`);
const withUrl = rows.filter((r) => r.photo_custom_url);
console.log(`with photo_custom_url: ${withUrl.length} (expected ${EXPECT_WITH_URL})\n`);

let broken = 0;
let tested = 0;
for (const r of rows) {
  if (!r.photo_custom_url) {
    console.log(`  blank    ${r.full_name.padEnd(28)} ${r.title} - no stored portrait`);
    continue;
  }
  if (!r.photo_custom_url.startsWith(CDN)) {
    console.log(`  FOREIGN  ${r.full_name.padEnd(28)} not on our CDN: ${r.photo_custom_url}`);
    broken++;
    continue;
  }
  if (r.image_row_url !== r.photo_custom_url) {
    console.log(`  DISAGREE ${r.full_name.padEnd(28)} image row and render field point at different objects`);
    broken++;
    continue;
  }
  if (!r.photo_origin_url || /\.(jpe?g|png|webp)(\?|$)/i.test(r.photo_origin_url)) {
    console.log(`  ORIGIN   ${r.full_name.padEnd(28)} photo_origin_url is missing or is a raw image URL: ${r.photo_origin_url}`);
    broken++;
    continue;
  }
  const res = await fetch(r.photo_custom_url);
  const buf = Buffer.from(await res.arrayBuffer());
  const d = decode(buf);
  tested++;
  if (!d) {
    console.log(`  BROKEN   ${r.full_name.padEnd(28)} HTTP ${res.status} ${buf.length}B did NOT decode`);
    broken++;
    continue;
  }
  if (!r.photo_license || !r.photo_license.trim()) {
    console.log(`  LICENCE  ${r.full_name.padEnd(28)} blank photo_license`);
    broken++;
    continue;
  }
  console.log(`  ok       ${r.full_name.padEnd(28)} ${d.w}x${d.h} ${d.fmt} ${String(buf.length).padStart(7)}B`);
}

// NEGATIVE CONTROL
const bogus = `${CDN}00000000-0000-0000-0000-000000000000-headshot.jpg`;
const cr = await fetch(bogus);
const cb = Buffer.from(await cr.arrayBuffer());
const controlRefused = decode(cb) === null;
console.log(`\ncontrol: bogus bucket key refused = ${controlRefused} (HTTP ${cr.status}, ${cb.length}B)`);

const countOk = rows.length === EXPECT_SEATS && withUrl.length === EXPECT_WITH_URL && tested === EXPECT_WITH_URL;
console.log(`control: tested ${tested} objects, expected ${EXPECT_WITH_URL} -> ${countOk}`);
console.log(broken === 0 && controlRefused && countOk
  ? `\nPASS - ${tested} portraits decode from the CDN, 1 seat deliberately blank`
  : `\nFAIL - ${broken} broken, controlRefused=${controlRefused}, countOk=${countOk}`);
await c.end();
process.exit(broken === 0 && controlRefused && countOk ? 0 : 1);
