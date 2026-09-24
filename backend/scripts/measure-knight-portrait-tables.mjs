/**
 * Measure PROGRAM.md's two PORTRAIT tables from production:
 *   - "Seated is not the same question as portraited" (the per-state split)
 *   - "Local and county seats present"
 *
 * USAGE (from C:/EV-Accounts/backend -- it reads ./.env, so the cwd matters):
 *   node scripts/measure-knight-portrait-tables.mjs
 *
 * Read-only. Paste the output over the two tables.
 *
 * 🔴 THE SPLIT IS THE POINT, NOT THE TOTAL. The read path is
 * COALESCE(photo_custom_url, photo_origin_url, ''), so a row can "have a
 * photo" by pointing at somebody else's server. Those two cases are counted
 * separately because they are not the same promise: a hosted object is ours,
 * a photo_origin_url falls over the day the source re-organises. The
 * "with headshot" column of the local table is HAS_RENDERABLE_PHOTO_SQL from
 * src/lib/photoCoverage.ts, which the table already cites -- NOT a count of
 * politician_images rows, because such a row changes nothing a voter sees.
 *
 * ⚠ SCOPE OF THE PER-STATE TABLE IS THE LEGISLATURE, STATED RATHER THAN
 * INFERRED. The 2026-09-02 version of that table used a scope nobody wrote
 * down, and it cannot be reproduced: CO 105 and NC 175 match "legislature +
 * five statewide executives" exactly, while FL 159 and GA 239 match neither
 * that nor the legislature alone. Rather than guess, this re-bases the table
 * on the legislature, which is what its sibling table tracks and what the
 * warning above it is about.
 */
import { config } from 'dotenv';
config({ quiet: true });
import pg from 'pg';

// 🔴 OUR BUCKET HAS TWO EQUIVALENT PUBLIC URL FORMS AND BOTH ARE OURS:
//   https://<ref>.storage.supabase.co/storage/v1/object/public/politician_photos/...
//   https://<ref>.supabase.co/storage/v1/object/public/politician_photos/...
// Matching only the first reports 407 of our own portraits as living on somebody
// else's server -- CA 98, IN 18, MD 187, UT 103, TX 1, all verified HTTP 200 JPEG
// from this bucket. Key on the PROJECT REF and the bucket, never on the hostname
// spelling. This is the same defect class as every other predicate that reads the
// shape of a value instead of what the value is.
const OURS = "p.photo_custom_url LIKE '%kxsdzaojfaibhuzmclfq%/storage/v1/object/public/politician_photos/%'";

const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();

// ---------------------------------------------------------------- per state
const split = await c.query(`
  SELECT upper(d.state) AS st,
         count(och.politician_id)                                          AS seated,
         count(*) FILTER (WHERE ${OURS})                                   AS hosted,
         count(*) FILTER (WHERE NOT coalesce(${OURS}, false)
                            AND btrim(coalesce(p.photo_custom_url,'')) <> '') AS custom_elsewhere,
         count(*) FILTER (WHERE btrim(coalesce(p.photo_custom_url,'')) = ''
                            AND btrim(coalesce(p.photo_origin_url,'')) <> ''
                            AND p.photo_origin_url LIKE 'http%')           AS origin_fallback,
         count(*) FILTER (WHERE btrim(coalesce(p.photo_custom_url,'')) = ''
                            AND NOT (btrim(coalesce(p.photo_origin_url,'')) <> ''
                                     AND p.photo_origin_url LIKE 'http%')) AS nothing
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE (d.ocd_id LIKE '%/sldl:%' OR d.ocd_id LIKE '%/sldu:%')
  GROUP BY 1 ORDER BY 1`);

// The table's scope is the program's states with a seated legislature. Every
// other state with one is counted separately below rather than dropped, because
// "not in this table" and "not measured" are different claims.
const KNIGHT = new Set(['CA', 'CO', 'NC', 'IN', 'FL', 'GA', 'KS', 'KY', 'MI', 'MN', 'MS', 'ND', 'OH', 'PA', 'SC', 'SD']);
const outside = split.rows.filter((r) => !KNIGHT.has(r.st));
split.rows = split.rows.filter((r) => KNIGHT.has(r.st));

console.log('🔴 Seated is not the same question as portraited — LEGISLATURE ONLY\n');
console.log('| State | Seated | Renders from a **hosted** object | `photo_custom_url` elsewhere | Falls back to `photo_origin_url` | Nothing renders |');
console.log('| --- | --- | --- | --- | --- | --- |');
const b = (n) => (n ? `**${n}**` : String(n));
for (const r of split.rows) {
  console.log(`| ${r.st} | ${r.seated} | ${b(r.hosted)} | ${b(r.custom_elsewhere)} | ${b(r.origin_fallback)} | ${b(r.nothing)} |`);
}
const sum = (rows, k) => rows.reduce((a, r) => a + Number(r[k]), 0);
console.log(`\nOUTSIDE THE PROGRAM, ${outside.length} more states hold a seated legislature: `
  + `${sum(outside, 'seated')} seated · ${sum(outside, 'hosted')} hosted · `
  + `${sum(outside, 'custom_elsewhere')} custom_url elsewhere · ${sum(outside, 'origin_fallback')} origin fallback · `
  + `${sum(outside, 'nothing')} nothing renders`);
console.log('  worst: ' + outside.filter((r) => Number(r.nothing) || Number(r.custom_elsewhere))
  .map((r) => `${r.st} ${r.nothing} nothing / ${r.custom_elsewhere} elsewhere`).join(' · '));

// ------------------------------------------------------- local and county
// The Knight program's own seeded jurisdictions, as an explicit (name, state)
// allowlist keyed on the government row.
//
// 🔴 A NAME ALONE IS NOT A JURISDICTION, AND EVERY TRAP IN THIS REPO IS IN THIS
// ONE LIST: "Summit County, Utah" is a different county from "County of Summit,
// Ohio"; "City of Saint Paul, Texas" is a different city; "City of Boulder City,
// Nevada" matches "boulder"; and "Long Beach Unified" and "Long Beach Community
// College District" are school districts, not the city. The state is therefore
// part of the key, and school districts are excluded explicitly.
//
// It is an allowlist rather than "every local government in these states"
// because that query sweeps in the LA County school-board wave and the
// CivicPatch import, which this table has never been about.
const JURISDICTIONS = [
  ['City of Long Beach', 'California'], ['Los Angeles County', 'California'],
  ['City of San Jos', 'California'], ['Santa Clara County', 'California'],
  ['City of Boulder', 'Colorado'], ['Boulder County', 'Colorado'],
  ['City of Colorado Springs', 'Colorado'], ['El Paso County', 'Colorado'],
  ['City of Bradenton', 'Florida'], ['Manatee County', 'Florida'],
  ['City of Tallahassee', 'Florida'], ['Leon County', 'Florida'],
  ['Palm Beach County', 'Florida'], ['City of Miami', 'Florida'],
  ['Miami-Dade County', 'Florida'],
  ['City of Milledgeville', 'Georgia'], ['Baldwin County', 'Georgia'],
  ['Columbus', 'Georgia'], ['Macon-Bibb', 'Georgia'],
  ['City of Fort Wayne', 'Indiana'], ['Allen County', 'Indiana'],
  ['City of Gary', 'Indiana'], ['Lake County', 'Indiana'],
  ['City of Duluth', 'Minnesota'], ['St. Louis County', 'Minnesota'],
  ['City of Saint Paul', 'Minnesota'], ['Ramsey County', 'Minnesota'],
  ['City of Charlotte', 'North Carolina'], ['Mecklenburg County', 'North Carolina'],
  ['City of Akron', 'Ohio'], ['County of Summit', 'Ohio'],
  ['City of Philadelphia', 'Pennsylvania'], ['Borough of State College', 'Pennsylvania'],
  ['Centre County', 'Pennsylvania'],
  ['City of Columbia', 'South Carolina'], ['Richland County', 'South Carolina'],
  ['City of Myrtle Beach', 'South Carolina'], ['Horry County', 'South Carolina'],
];

const local = await c.query(`
  SELECT g.name AS government,
         count(*)                                                   AS offices,
         count(och.politician_id)                                   AS seated,
         count(*) FILTER (WHERE img.politician_id IS NOT NULL
                            OR btrim(coalesce(p.photo_custom_url,'')) <> ''
                            OR (btrim(coalesce(p.photo_origin_url,'')) <> ''
                                AND p.photo_origin_url LIKE 'http%')) AS with_headshot
  FROM essentials.governments g
  JOIN essentials.chambers ch ON ch.government_id = g.id
  JOIN essentials.offices o ON o.chamber_id = ch.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
  LEFT JOIN LATERAL (SELECT 1 AS politician_id FROM essentials.politician_images pi
                      WHERE pi.politician_id = p.id LIMIT 1) img ON true
  WHERE (EXISTS (
    SELECT 1 FROM unnest($1::text[], $2::text[]) AS j(nm, st)
     WHERE g.name LIKE j.nm || '%' AND g.name LIKE '%, ' || j.st || ', US')
    -- ⚠ ONE GOVERNMENT ROW CARRIES NO STATE SUFFIX. Every other row in this
    -- table is '<name>, <State>, US'; San José's is the bare string
    -- 'City of San Jose', so a state-scoped match drops it silently -- which is
    -- exactly how it went missing on the first run of this query. Listed by its
    -- exact name rather than by loosening the state scope for everyone, because
    -- that scope is what keeps Saint Paul TX and Summit County UT out.
    OR g.name = 'City of San Jose')
    AND g.name !~* 'unified|school|college district'
    -- 🔴 EXCLUDE THE BULK COURT BENCHES, WHICH ARE A DIFFERENT PROGRAMME.
    -- 'Los Angeles County, California, US' carries 473 Superior Court judgeships
    -- beside the Knight row's 8 (5 Supervisors + 3 countywide officials), because
    -- the judicial seeding hangs off the SAME government row. Counting them here
    -- would report LA County as 481 offices with 11 headshots and bury the 8 this
    -- table is about.
    -- ⚠ NOT a blanket "no judges" rule: Gary's City Court is ONE seat and IS a
    -- Knight office (Gary elects a judge and Fort Wayne does not), and county
    -- Probate Judges are elected county officers. Only the bench chambers go.
    AND ch.name NOT IN ('Superior Court', 'Superior Court Judge')
  GROUP BY 1 ORDER BY 1`,
  [JURISDICTIONS.map((j) => j[0]), JURISDICTIONS.map((j) => j[1])]);

console.log('\n\n### Local and county seats present\n');
console.log('| Jurisdiction | Offices | Seated | With headshot |');
console.log('| --- | --- | --- | --- |');
let to = 0, ts = 0, th = 0;
for (const r of local.rows) {
  to += Number(r.offices); ts += Number(r.seated); th += Number(r.with_headshot);
  const done = Number(r.with_headshot) === Number(r.seated) && Number(r.seated) > 0;
  console.log(`| **${r.government.replace(/, US$/, '')}** | **${r.offices}** | **${r.seated}** | ${done ? '**' + r.with_headshot + '**' : r.with_headshot} |`);
}
console.log(`\nTOTALS: ${local.rows.length} governments · ${to} offices · ${ts} seated · ${th} with a headshot · ${ts - th} owed`);

// 🔴 CONTROL: the four name collisions this repo has already paid for must NOT
// be in the result. A scope that cannot be shown to EXCLUDE the wrong rows has
// not been shown to select the right ones.
const DECOYS = ['Summit County, Utah', 'City of Saint Paul, Texas', 'City of Boulder City, Nevada', 'Long Beach Unified'];
const leaked = DECOYS.filter((d) => local.rows.some((r) => r.government.includes(d)));
console.log(leaked.length
  ? `*** CONTROL FAILED — decoys leaked in: ${leaked.join(', ')} ***`
  : `control: all ${DECOYS.length} known name-collision decoys correctly excluded (${DECOYS.join(' · ')})`);

await c.end();
