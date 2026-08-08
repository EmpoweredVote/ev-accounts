/**
 * export-partner-csv.mts — officeholder data export for an external data-sharing partner.
 *
 *   npx tsx scripts/export-partner-csv.mts --states=ca,or --out=data/partner-export
 *
 * Read-only. Writes three joinable CSVs plus a data dictionary and a coverage report, then
 * re-reads its own output and asserts the bundle is internally consistent before exiting 0.
 *
 * The design constraint that shapes everything here: the partner must be able to judge the
 * QUALITY of what we send, not just ingest it. Two of our columns hold placeholders rather than
 * facts, and this script's job is to make sure neither one leaves the building disguised as data.
 * See docs/superpowers/specs/2026-08-08-partner-csv-export-design.md.
 */
import { writeFileSync, mkdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';

// ---------------------------------------------------------------- args

const arg = (name: string, fallback: string) =>
  process.argv.find((a) => a.startsWith(`--${name}=`))?.split('=').slice(1).join('=') ?? fallback;

const STATES = arg('states', 'ca,or')
  .split(',')
  .map((s) => s.trim().toLowerCase())
  .filter(Boolean);
const OUT_DIR = arg('out', 'data/partner-export');
const SLUG = STATES.join('_');

// ---------------------------------------------------------------- csv

/** RFC 4180. Quote when the value contains a delimiter, quote, or newline; double interior quotes. */
function csvCell(v: unknown): string {
  if (v === null || v === undefined) return '';
  const s = typeof v === 'boolean' ? String(v) : String(v);
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function toCsv(rows: Record<string, unknown>[], columns: string[]): string {
  const lines = [columns.join(',')];
  for (const r of rows) lines.push(columns.map((c) => csvCell(r[c])).join(','));
  return lines.join('\r\n') + '\r\n';
}

/** Minimal RFC 4180 reader — used only to verify what we just wrote. */
function parseCsv(text: string): { header: string[]; rows: string[][] } {
  const rows: string[][] = [];
  let row: string[] = [];
  let cell = '';
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"') {
        if (text[i + 1] === '"') { cell += '"'; i++; } else quoted = false;
      } else cell += c;
      continue;
    }
    if (c === '"') { quoted = true; continue; }
    if (c === ',') { row.push(cell); cell = ''; continue; }
    if (c === '\r') continue;
    if (c === '\n') { row.push(cell); rows.push(row); row = []; cell = ''; continue; }
    cell += c;
  }
  if (cell.length || row.length) { row.push(cell); rows.push(row); }
  const header = rows.shift() ?? [];
  return { header, rows };
}

// ---------------------------------------------------------------- queries

/**
 * Seats. `essentials.offices` holds no occupant (ADR 0002) — occupancy is resolved through the
 * view. `occupancy_status` keeps the three cases distinct on purpose:
 *   seated  — a current office_terms row names a holder
 *   vacant  — no holder, and offices.is_vacant asserts the seat is genuinely empty
 *   unknown — no holder and no assertion: we simply never researched it
 * Collapsing `unknown` into `vacant` would claim knowledge we don't have; dropping those rows
 * would overstate our completeness. Note is_vacant is read here, never used to filter the match
 * (see the is_vacant trap in CLAUDE.md).
 */
const Q_OFFICES = `
  SELECT o.id                        AS office_id,
         o.title,
         o.role_canonical,
         o.normalized_position_name,
         o.seats,
         o.partisan_type,
         o.is_appointed_position,
         d.id                        AS district_id,
         d.label                     AS district_label,
         d.district_type,
         d.subtype                   AS district_subtype,
         lower(d.state)              AS state,
         d.city,
         d.ocd_id,
         d.geo_id,
         CASE WHEN och.politician_id IS NOT NULL THEN 'seated'
              WHEN o.is_vacant                   THEN 'vacant'
              ELSE 'unknown' END     AS occupancy_status
  FROM essentials.offices o
  JOIN essentials.districts d              ON d.id = o.district_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = ANY($1::text[])
  ORDER BY lower(d.state), d.district_type, o.title, o.id
`;

/**
 * People. DISTINCT ON collapses the officials who hold two seats (2 in CA) to one row.
 * `nullif(btrim(...),'')` on party and data_source is load-bearing: 76 CA rows hold an empty
 * string, which a plain NOT NULL check reports as a populated affiliation.
 *
 * photo_url needs three separate guards, because `photo_origin_url` is not a clean column:
 *   - 83 rows hold a research breadcrumb, not a URL at all ('explored', 'searched:no_results').
 *     Those are blanked — they are process state that leaked into a data column.
 *   - 224 rows hold a real URL that is a roster page or a Wikipedia article about the *city*,
 *     not a portrait. Those are kept but labelled `page`, so nobody renders a city-council
 *     index page as a headshot.
 *   - 175 rows are genuine images, labelled `image`.
 * Counting this column with IS NOT NULL overstates photo coverage by roughly 3.5x.
 *
 * external_id is negative for internally-synthesized records and positive for real upstream
 * vendor keys. 94% are synthetic and mean nothing outside our database, so the distinction is
 * exported rather than left for the partner to discover the hard way.
 */
const Q_POLITICIANS = `
  SELECT DISTINCT ON (pol.id)
         pol.id                                   AS politician_id,
         pol.external_id,
         (pol.external_id < 0)                    AS external_id_is_synthetic,
         nullif(btrim(pol.bioguide_id), '')       AS bioguide_id,
         pol.full_name,
         pol.first_name,
         pol.last_name,
         pol.middle_initial,
         pol.name_suffix,
         pol.preferred_name,
         nullif(btrim(pol.party), '')             AS party,
         pol.urls[1]                              AS official_url,
         -- NULL must be tested explicitly and FIRST: a NULL compared with !~* yields NULL, not
         -- true, so a photo-less row would otherwise fall through to the ELSE branch and be
         -- labelled as having a page URL.
         CASE WHEN coalesce(pol.photo_custom_url, pol.photo_origin_url) ~* '^https?://'
              THEN coalesce(pol.photo_custom_url, pol.photo_origin_url) END AS photo_url,
         CASE WHEN coalesce(pol.photo_custom_url, pol.photo_origin_url) IS NULL THEN NULL
              WHEN coalesce(pol.photo_custom_url, pol.photo_origin_url) !~* '^https?://' THEN NULL
              WHEN coalesce(pol.photo_custom_url, pol.photo_origin_url)
                   ~* '\\.(jpg|jpeg|png|gif|webp|avif)(\\?|#|$)' THEN 'image'
              ELSE 'page' END                     AS photo_url_kind,
         CASE WHEN coalesce(pol.photo_custom_url, pol.photo_origin_url) IS NULL THEN NULL
              WHEN coalesce(pol.photo_custom_url, pol.photo_origin_url) !~* '^https?://' THEN NULL
              ELSE (pol.photo_custom_url IS NULL) END          AS photo_url_is_third_party,
         nullif(btrim(pol.data_source), '')       AS data_source
  FROM essentials.offices o
  JOIN essentials.districts d              ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians pol          ON pol.id = och.politician_id
  WHERE lower(d.state) = ANY($1::text[])
  ORDER BY pol.id
`;

/**
 * Occupancy. term_start is emitted ONLY at day or year precision. 95% of CA and 97% of OR term
 * rows carry start_precision='unknown' — open-ended placeholders written by the ADR 0002 phase-2
 * backfill, not researched dates. Shipping those as dates would hand the partner ~1,369 false
 * facts, so the date is withheld and the precision column says why.
 */
const Q_HOLDERS = `
  SELECT och.office_id,
         och.politician_id,
         CASE WHEN t.start_precision IN ('day', 'year')
              THEN to_char(och.term_start, 'YYYY-MM-DD') END AS term_start,
         coalesce(t.start_precision, 'unknown')              AS start_precision,
         to_char(och.term_end, 'YYYY-MM-DD')                 AS term_end,
         t.source
  FROM essentials.office_current_holder och
  JOIN essentials.offices o   ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_terms t
         ON t.office_id      = och.office_id
        AND t.politician_id  = och.politician_id
        AND t.term_start IS NOT DISTINCT FROM och.term_start
        AND t.term_end   IS NOT DISTINCT FROM och.term_end
  WHERE lower(d.state) = ANY($1::text[])
    AND och.politician_id IS NOT NULL
  ORDER BY och.office_id
`;

const OFFICE_COLS = ['office_id', 'title', 'role_canonical', 'normalized_position_name', 'seats',
  'partisan_type', 'is_appointed_position', 'district_id', 'district_label', 'district_type',
  'district_subtype', 'state', 'city', 'ocd_id', 'geo_id', 'occupancy_status'];

const POL_COLS = ['politician_id', 'external_id', 'external_id_is_synthetic', 'bioguide_id',
  'full_name', 'first_name', 'last_name', 'middle_initial', 'name_suffix', 'preferred_name',
  'party', 'official_url', 'photo_url', 'photo_url_kind', 'photo_url_is_third_party',
  'data_source'];

const HOLDER_COLS = ['office_id', 'politician_id', 'term_start', 'start_precision', 'term_end',
  'source'];

// ---------------------------------------------------------------- main

async function main() {
  console.log(`[export] states=${STATES.join(',')} out=${OUT_DIR}`);

  const [offices, politicians, holders] = await Promise.all([
    pool.query(Q_OFFICES, [STATES]).then((r) => r.rows),
    pool.query(Q_POLITICIANS, [STATES]).then((r) => r.rows),
    pool.query(Q_HOLDERS, [STATES]).then((r) => r.rows),
  ]);

  console.log(`[export] offices=${offices.length} politicians=${politicians.length} holders=${holders.length}`);

  mkdirSync(OUT_DIR, { recursive: true });
  const f = {
    offices: `ev_offices_${SLUG}.csv`,
    politicians: `ev_politicians_${SLUG}.csv`,
    holders: `ev_office_holders_${SLUG}.csv`,
  };
  writeFileSync(join(OUT_DIR, f.offices), toCsv(offices, OFFICE_COLS), 'utf8');
  writeFileSync(join(OUT_DIR, f.politicians), toCsv(politicians, POL_COLS), 'utf8');
  writeFileSync(join(OUT_DIR, f.holders), toCsv(holders, HOLDER_COLS), 'utf8');

  // Coverage is computed from the same in-memory rows that were just written, so no figure in
  // COVERAGE.md can drift from the CSVs it describes.
  const stats = buildStats(offices, politicians, holders);
  writeFileSync(join(OUT_DIR, 'COVERAGE.md'), renderCoverage(stats), 'utf8');
  writeFileSync(join(OUT_DIR, 'README.md'), renderReadme(f, stats), 'utf8');

  verify(OUT_DIR, f, offices, politicians, holders);

  console.log(`[export] wrote 5 files to ${OUT_DIR}`);
  console.log('[export] all assertions passed');
}

// ---------------------------------------------------------------- stats

type Row = Record<string, any>;

function buildStats(offices: Row[], politicians: Row[], holders: Row[]) {
  const holderOffice = new Map(holders.map((h) => [h.office_id, h]));
  const officeState = new Map(offices.map((o) => [o.office_id, o.state]));

  // A person is attributed to every state they hold a seat in.
  const polStates = new Map<string, Set<string>>();
  for (const h of holders) {
    const st = officeState.get(h.office_id);
    if (!st) continue;
    if (!polStates.has(h.politician_id)) polStates.set(h.politician_id, new Set());
    polStates.get(h.politician_id)!.add(st);
  }

  const perState = STATES.map((st) => {
    const os = offices.filter((o) => o.state === st);
    const pl = politicians.filter((p) => polStates.get(p.politician_id)?.has(st));
    const hs = holders.filter((h) => officeState.get(h.office_id) === st);
    return {
      state: st,
      offices: os.length,
      seated: os.filter((o) => o.occupancy_status === 'seated').length,
      vacant: os.filter((o) => o.occupancy_status === 'vacant').length,
      unknown: os.filter((o) => o.occupancy_status === 'unknown').length,
      districts: new Set(os.map((o) => o.district_id)).size,
      politicians: pl.length,
      withParty: pl.filter((p) => p.party).length,
      withPhoto: pl.filter((p) => p.photo_url).length,
      photoImage: pl.filter((p) => p.photo_url_kind === 'image').length,
      photoPage: pl.filter((p) => p.photo_url_kind === 'page').length,
      thirdPartyPhoto: pl.filter((p) => p.photo_url_is_third_party === true).length,
      withOfficialUrl: pl.filter((p) => p.official_url).length,
      extSynthetic: pl.filter((p) => p.external_id_is_synthetic === true).length,
      extVendor: pl.filter((p) => p.external_id_is_synthetic === false).length,
      federalSeated: os.filter((o) => o.occupancy_status === 'seated'
        && (o.district_type === 'NATIONAL_UPPER' || o.district_type === 'NATIONAL_LOWER')).length,
      withBioguide: pl.filter((p) => p.bioguide_id).length,
      withExternalId: pl.filter((p) => p.external_id).length,
      withDataSource: pl.filter((p) => p.data_source).length,
      realStart: hs.filter((h) => h.term_start).length,
      unknownStart: hs.filter((h) => h.start_precision === 'unknown').length,
      holders: hs.length,
      byType: Object.entries(
        os.reduce<Record<string, { total: number; seated: number }>>((acc, o) => {
          acc[o.district_type] ??= { total: 0, seated: 0 };
          acc[o.district_type].total++;
          if (o.occupancy_status === 'seated') acc[o.district_type].seated++;
          return acc;
        }, {}),
      ).sort((a, b) => b[1].total - a[1].total),
    };
  });

  return { perState, totals: { offices: offices.length, politicians: politicians.length, holders: holders.length }, holderOffice };
}

const pct = (n: number, d: number) => (d === 0 ? '—' : `${Math.round((n / d) * 100)}%`);
const UP = (s: string) => s.toUpperCase();

function renderCoverage(stats: ReturnType<typeof buildStats>): string {
  const L: string[] = [];
  L.push('# Coverage report', '');
  L.push('Every figure below is generated by the same run that wrote the CSVs, from the same rows.');
  L.push('Nothing here is hand-entered, so no number can drift from the data it describes.', '');

  L.push('## Occupancy', '');
  L.push('| State | Seats | Seated | Vacant (confirmed) | Unknown (unresearched) |');
  L.push('|---|---:|---:|---:|---:|');
  for (const s of stats.perState) {
    L.push(`| ${UP(s.state)} | ${s.offices} | ${s.seated} (${pct(s.seated, s.offices)}) | ${s.vacant} | ${s.unknown} (${pct(s.unknown, s.offices)}) |`);
  }
  L.push('');
  L.push('`vacant` means we assert the seat is empty. `unknown` means no occupancy has ever been');
  L.push('researched for that seat — we are not claiming it is empty. Treat `unknown` as absence of');
  L.push('evidence, not evidence of absence.', '');

  L.push('## Field completeness (current officeholders)', '');
  L.push('| State | People | Party | Official URL | bioguide_id | data_source |');
  L.push('|---|---:|---:|---:|---:|---:|');
  for (const s of stats.perState) {
    L.push(`| ${UP(s.state)} | ${s.politicians} | ${s.withParty} (${pct(s.withParty, s.politicians)}) | ${s.withOfficialUrl} (${pct(s.withOfficialUrl, s.politicians)}) | ${s.withBioguide} | ${s.withDataSource} (${pct(s.withDataSource, s.politicians)}) |`);
  }
  L.push('');

  L.push('## Photographs — read this before using `photo_url`', '');
  L.push('| State | Rows with a URL | Actual images | Page URLs (NOT portraits) |');
  L.push('|---|---:|---:|---:|');
  for (const s of stats.perState) {
    L.push(`| ${UP(s.state)} | ${s.withPhoto} | ${s.photoImage} (${pct(s.photoImage, s.politicians)} of people) | ${s.photoPage} |`);
  }
  L.push('');
  L.push('Our photo column has been doing double duty as a research scratchpad, and we have cleaned');
  L.push('that up on the way out rather than passing the mess along. Rows whose value was a process');
  L.push('note rather than a link (`explored`, `searched:no_results`) are blanked here. Rows that hold');
  L.push('a real URL pointing at a roster page or a Wikipedia article about the *city* rather than a');
  L.push('portrait are kept but marked `photo_url_kind=page`.');
  L.push('');
  L.push('**Filter on `photo_url_kind=\'image\'` before displaying anything.** If you instead count');
  L.push('`photo_url IS NOT NULL`, you will overstate our portrait coverage by roughly 3x and risk');
  L.push('rendering a city-council index page as somebody\'s headshot.', '');

  L.push('## Identifiers', '');
  L.push('| State | People | Synthetic external_id | Real upstream external_id | bioguide_id |');
  L.push('|---|---:|---:|---:|---:|');
  for (const s of stats.perState) {
    L.push(`| ${UP(s.state)} | ${s.politicians} | ${s.extSynthetic} (${pct(s.extSynthetic, s.politicians)}) | ${s.extVendor} | ${s.withBioguide} |`);
  }
  L.push('');
  L.push('`external_id` is **not** a public identifier for most rows. Negative values are minted by us');
  L.push('for records we seeded ourselves and carry no meaning outside our database');
  L.push('(`external_id_is_synthetic=true`). Only positive values correspond to a real upstream key.');
  L.push('Join on `politician_id`, and use `bioguide_id` for the congressional delegation.', '');

  L.push('## Term start precision', '');
  L.push('| State | Occupancy rows | Usable start date | Unknown precision |');
  L.push('|---|---:|---:|---:|');
  for (const s of stats.perState) {
    L.push(`| ${UP(s.state)} | ${s.holders} | ${s.realStart} (${pct(s.realStart, s.holders)}) | ${s.unknownStart} (${pct(s.unknownStart, s.holders)}) |`);
  }
  L.push('');
  L.push('**This is the weakest part of the dataset and the one most likely to mislead.** Our schema');
  L.push('records tenure as a dated range, but the bulk of these ranges were opened by a backfill that');
  L.push('had no start date to record. Those rows carry `start_precision=unknown` and we have withheld');
  L.push('the underlying placeholder date entirely rather than let it be read as a fact. Where');
  L.push('`term_start` is populated, it is researched and reliable.', '');

  L.push('## Seats by district type', '');
  for (const s of stats.perState) {
    L.push(`### ${UP(s.state)}`, '');
    L.push('| District type | Seats | Seated |');
    L.push('|---|---:|---:|');
    for (const [t, v] of s.byType) L.push(`| ${t} | ${v.total} | ${v.seated} (${pct(v.seated, v.total)}) |`);
    L.push('');
  }

  L.push('## Known gaps, stated plainly', '');
  for (const s of stats.perState) {
    if (s.unknown > 0) {
      const types = s.byType.filter(([, v]) => v.seated === 0).map(([t]) => t);
      L.push(`- **${UP(s.state)}: ${s.unknown} seats with unknown occupancy.**` +
        (types.length ? ` Concentrated in: ${types.join(', ')}.` : '') +
        ' These seats are real and correctly described; we have not researched who holds them.');
    }
    if (s.withDataSource === 0) {
      L.push(`- **${UP(s.state)}: no per-row provenance.** \`data_source\` is empty for all ${s.politicians} people. The records are real but we cannot tell you per-row where each came from.`);
    }
    if (s.politicians && s.withParty / s.politicians < 0.5) {
      L.push(`- **${UP(s.state)}: party is populated for only ${pct(s.withParty, s.politicians)} of officeholders.** Blank means unrecorded, never independent. We do not infer party.`);
    }
    if (s.withPhoto > 0) {
      L.push(`- **${UP(s.state)}: only ${s.photoImage} of ${s.politicians} officeholders have a usable portrait** (${pct(s.photoImage, s.politicians)}). A further ${s.photoPage} rows hold a page URL that is not a portrait — marked \`photo_url_kind=page\`, do not render them.`);
    }
    if (s.thirdPartyPhoto > 0) {
      L.push(`- **${UP(s.state)}: ${s.thirdPartyPhoto} of ${s.withPhoto} photo URLs point at third-party hosts.** We do not host these images and cannot grant rights to them; expect link rot.`);
    }
    if (s.federalSeated > s.withBioguide) {
      L.push(`- **${UP(s.state)}: ${s.withBioguide} of ${s.federalSeated} federal officeholders carry a \`bioguide_id\`.** The cleanest cross-walk we could offer is itself incomplete; expect to match the remainder by name and district.`);
    }
    if (s.extVendor === 0 && s.politicians > 0) {
      L.push(`- **${UP(s.state)}: every \`external_id\` is synthetic.** None of them will match an upstream identifier on your side. Match on name + district, or on \`politician_id\` once we have reconciled.`);
    }
  }
  L.push('');
  return L.join('\n');
}

function renderReadme(f: Record<string, string>, stats: ReturnType<typeof buildStats>): string {
  const t = stats.totals;
  return `# Empowered Vote — officeholder export (${STATES.map(UP).join(' + ')})

${t.offices} seats, ${t.politicians} people, ${t.holders} occupancy records.
Read \`COVERAGE.md\` before ingesting — it states where this data is thin and why.

## Data model, in one paragraph

An **office is a seat**, not a person. It has a district, a chamber and a title, and it holds no
occupant. Who occupies a seat is a separate, dated record. That is why this is three files and not
one: a seat can exist with nobody in it, one person can hold two seats, and a seat's occupant
changes without the seat changing. Flattening these into one row per person loses all three facts.

## Files

| File | Grain | Key |
|---|---|---|
| \`${f.offices}\` | one row per seat | \`office_id\` |
| \`${f.politicians}\` | one row per person | \`politician_id\` |
| \`${f.holders}\` | one row per current occupancy | \`office_id\` + \`politician_id\` |

Join: \`${f.holders}.office_id → ${f.offices}.office_id\` and
\`${f.holders}.politician_id → ${f.politicians}.politician_id\`.

Seats with no row in the holders file are unoccupied — check \`occupancy_status\` to learn whether
that is a confirmed vacancy or an unresearched seat.

## Columns

### ${f.offices}

| Column | Meaning |
|---|---|
| \`office_id\` | Our stable UUID for the seat. Use this to reference a seat back to us. |
| \`title\` | Seat title as published by the jurisdiction. |
| \`role_canonical\` | Our normalized role, where one has been assigned. |
| \`normalized_position_name\` | Normalized position label. |
| \`seats\` | Number of people the seat elects (>1 for at-large bodies). |
| \`partisan_type\` | Whether the seat is contested on a partisan ballot. |
| \`is_appointed_position\` | True where the seat is filled by appointment, not election. |
| \`district_id\` | Our stable UUID for the district. |
| \`district_label\` | Human-readable district name. |
| \`district_type\` | NATIONAL_UPPER, NATIONAL_LOWER, STATE_UPPER, STATE_LOWER, STATE_EXEC, COUNTY, LOCAL, LOCAL_EXEC, SCHOOL, JUDICIAL. |
| \`district_subtype\` | Finer classification where present. |
| \`state\` | Two-letter, lowercase. |
| \`city\` | Present for municipal districts. |
| \`ocd_id\` | Open Civic Data identifier, where we hold one. |
| \`geo_id\` | Our public geography key — how we resolve an address to a district. Not unique on its own; key on (\`geo_id\`, \`district_type\`). |
| \`occupancy_status\` | \`seated\` / \`vacant\` / \`unknown\`. See below. |

**\`occupancy_status\` is the column to read carefully.** \`seated\` means a current occupancy record
exists. \`vacant\` means we assert the seat is empty. \`unknown\` means we have never researched it —
we are **not** claiming it is empty. Do not merge \`unknown\` into \`vacant\`.

### ${f.politicians}

| Column | Meaning |
|---|---|
| \`politician_id\` | Our stable UUID for the person. **This is the join key to use.** |
| \`external_id\` | Internal record number. Mostly *not* a public identifier — see below. |
| \`external_id_is_synthetic\` | \`true\` where we minted the id ourselves and it means nothing outside our database. True for ~94% of rows. |
| \`bioguide_id\` | Federal Biographical Directory ID. Congressional delegation only, but a real cross-walk where present. |
| \`full_name\` … \`preferred_name\` | Name parts as we hold them. |
| \`party\` | Affiliation as recorded. **Blank means unrecorded, never "independent".** We do not infer party from any other signal. |
| \`official_url\` | First official URL on file. |
| \`photo_url\` | A link, not an asset. **Check \`photo_url_kind\` first.** |
| \`photo_url_kind\` | \`image\` = a real portrait. \`page\` = a URL that is a roster or article page, not a portrait. |
| \`photo_url_is_third_party\` | \`true\` where the image sits on a host that is not ours. |
| \`data_source\` | Per-row provenance where recorded. |

**On \`external_id\`:** do not try to match this against an id in your own system. A negative value
was minted by us for a record we seeded ourselves and has no external meaning. Only the small
number of positive values correspond to a real upstream key. Match people on
\`bioguide_id\` where it exists, otherwise on name plus district — and treat name matching as
requiring review, not as automatic. We have been bitten repeatedly by real people whose names
differ between sources (Ben/Benjamin, Erin/Erin J.), and by genuine same-name officials in
different jurisdictions.

**On \`photo_url\`:** filter to \`photo_url_kind='image'\` before displaying anything. The underlying
column in our database has been serving double duty as a research scratchpad; we have blanked the
process notes on the way out, but a substantial number of the surviving URLs are roster pages and
Wikipedia articles about the city rather than portraits. Those are labelled \`page\`. Counting
\`photo_url IS NOT NULL\` will overstate our portrait coverage by roughly 3x.

### ${f.holders}

| Column | Meaning |
|---|---|
| \`office_id\` / \`politician_id\` | The occupancy link. |
| \`term_start\` | **Populated only where we actually know it.** |
| \`start_precision\` | \`day\` / \`year\` / \`unknown\`. |
| \`term_end\` | Populated where the term has a known end. Mostly blank: most of these bodies do not publish one. |
| \`source\` | Where the occupancy record came from, where recorded. |

**On \`term_start\`:** where \`start_precision\` is \`unknown\`, \`term_start\` is deliberately blank. Our
database holds a placeholder date for those rows — an artifact of how the records were backfilled,
not a researched date — and we have withheld it rather than let it be ingested as fact. If you see
a date here, we stand behind it. If you see a blank, we genuinely do not know. Please do not
backfill this column with a default on your side; a blank is the accurate value.

## Rights and attribution

The factual records — seats, districts, names, affiliations, occupancy — are shared for your use.
**Photographs are not.** \`photo_url\` is a pointer to wherever the image currently lives, mostly on
jurisdiction and campaign sites we do not control. We hold no rights in those images and grant
none. Resolve the licensing yourself before displaying any of them, and expect the links to rot.

## Refreshing

Regenerate with:

\`\`\`
npx tsx scripts/export-partner-csv.mts --states=${STATES.join(',')} --out=<dir>
\`\`\`

UUIDs are stable across runs, so a later export diffs cleanly against this one.

Generated from the Empowered Vote production database. Questions: alincoln@empowered.vote
`;
}

// ---------------------------------------------------------------- verify

/**
 * Re-read what we wrote and prove it. These assertions exist because every honesty rule above is
 * silent when it fails — a placeholder date or a phantom party value looks like ordinary data.
 */
function verify(dir: string, f: Record<string, string>, offices: Row[], politicians: Row[], holders: Row[]) {
  const fail = (msg: string) => { throw new Error(`[verify] ${msg}`); };
  const read = (name: string) => parseCsv(readFileSync(join(dir, name), 'utf8'));

  const O = read(f.offices);
  const P = read(f.politicians);
  const H = read(f.holders);

  if (O.rows.length !== offices.length) fail(`offices: wrote ${O.rows.length}, queried ${offices.length}`);
  if (P.rows.length !== politicians.length) fail(`politicians: wrote ${P.rows.length}, queried ${politicians.length}`);
  if (H.rows.length !== holders.length) fail(`holders: wrote ${H.rows.length}, queried ${holders.length}`);

  const col = (h: string[], name: string) => {
    const i = h.indexOf(name);
    if (i < 0) fail(`missing column ${name}`);
    return i;
  };

  // 1. No placeholder date escaped. This is the assertion that matters most.
  const hStart = col(H.header, 'term_start');
  const hPrec = col(H.header, 'start_precision');
  const leaked = H.rows.filter((r) => r[hPrec] === 'unknown' && r[hStart] !== '');
  if (leaked.length) fail(`${leaked.length} rows carry a term_start at unknown precision`);

  const badPrec = H.rows.filter((r) => !['day', 'year', 'unknown'].includes(r[hPrec]));
  if (badPrec.length) fail(`${badPrec.length} rows have an unrecognised start_precision`);

  // 2. No phantom values anywhere. Several source columns store '' rather than NULL, and a
  //    whitespace-only cell reads as populated to anyone counting non-empty values. This is a
  //    whole-file check rather than a per-column one because it has now bitten party,
  //    bioguide_id and data_source independently.
  for (const [file, parsed] of [[f.offices, O], [f.politicians, P], [f.holders, H]] as const) {
    for (let c = 0; c < parsed.header.length; c++) {
      const phantom = parsed.rows.filter((r) => r[c] !== '' && r[c].trim() === '');
      if (phantom.length) fail(`${file}: ${phantom.length} whitespace-only values in ${parsed.header[c]}`);
    }
  }

  // 3. No research breadcrumb escaped into photo_url, and every URL is classified.
  const pPhoto = col(P.header, 'photo_url');
  const pKind = col(P.header, 'photo_url_kind');
  const notAUrl = P.rows.filter((r) => r[pPhoto] !== '' && !/^https?:\/\//i.test(r[pPhoto]));
  if (notAUrl.length) fail(`${notAUrl.length} photo_url values are not URLs (research breadcrumbs leaked)`);
  const unclassified = P.rows.filter((r) => (r[pPhoto] !== '') !== (r[pKind] !== ''));
  if (unclassified.length) fail(`${unclassified.length} rows have photo_url and photo_url_kind out of step`);
  const badKind = P.rows.filter((r) => r[pKind] !== '' && !['image', 'page'].includes(r[pKind]));
  if (badKind.length) fail(`${badKind.length} rows have an unrecognised photo_url_kind`);

  // 4. occupancy_status is closed and totals reconcile.
  const oStatus = col(O.header, 'occupancy_status');
  const counts = O.rows.reduce<Record<string, number>>((a, r) => { a[r[oStatus]] = (a[r[oStatus]] ?? 0) + 1; return a; }, {});
  const known = ['seated', 'vacant', 'unknown'];
  const unexpected = Object.keys(counts).filter((k) => !known.includes(k));
  if (unexpected.length) fail(`unexpected occupancy_status: ${unexpected.join(', ')}`);
  const sum = known.reduce((a, k) => a + (counts[k] ?? 0), 0);
  if (sum !== O.rows.length) fail(`occupancy_status totals ${sum} != ${O.rows.length} offices`);

  // 5. Referential integrity across the three files — the partner will rely on these joins.
  const oId = col(O.header, 'office_id');
  const pId = col(P.header, 'politician_id');
  const hOff = col(H.header, 'office_id');
  const hPol = col(H.header, 'politician_id');
  const officeIds = new Map(O.rows.map((r) => [r[oId], r[oStatus]]));
  const polIds = new Set(P.rows.map((r) => r[pId]));

  const orphanOffice = H.rows.filter((r) => !officeIds.has(r[hOff]));
  if (orphanOffice.length) fail(`${orphanOffice.length} occupancy rows reference an absent office`);
  const orphanPol = H.rows.filter((r) => !polIds.has(r[hPol]));
  if (orphanPol.length) fail(`${orphanPol.length} occupancy rows reference an absent politician`);
  const notSeated = H.rows.filter((r) => officeIds.get(r[hOff]) !== 'seated');
  if (notSeated.length) fail(`${notSeated.length} occupancy rows point at a seat not marked seated`);
  if (counts.seated !== H.rows.length) fail(`${counts.seated} seats marked seated but ${H.rows.length} occupancy rows`);

  // 6. Every person in the file is actually reachable from an occupancy row.
  const referenced = new Set(H.rows.map((r) => r[hPol]));
  const unreferenced = [...polIds].filter((id) => !referenced.has(id));
  if (unreferenced.length) fail(`${unreferenced.length} people have no occupancy row`);

  console.log(`[verify] ${O.rows.length} offices / ${P.rows.length} people / ${H.rows.length} occupancy rows`);
  console.log(`[verify] occupancy: ${known.map((k) => `${k}=${counts[k] ?? 0}`).join(' ')}`);
  console.log(`[verify] term_start withheld at unknown precision: ${H.rows.filter((r) => r[hPrec] === 'unknown').length}`);
  const kinds = P.rows.reduce<Record<string, number>>((a, r) => { const k = r[pKind] || 'none'; a[k] = (a[k] ?? 0) + 1; return a; }, {});
  console.log(`[verify] photo_url_kind: ${Object.entries(kinds).map(([k, v]) => `${k}=${v}`).join(' ')}`);
}

main()
  .catch((e) => { console.error(e); process.exitCode = 1; })
  .finally(() => pool.end());
