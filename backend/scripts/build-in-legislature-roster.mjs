#!/usr/bin/env node
/**
 * build-in-legislature-roster.mjs
 *
 * Reconciles the Indiana General Assembly roster and writes data/in-legislature-roster.json.
 * Reads nothing from the database and writes nothing to it.
 *
 * SOURCES -- one official, one third party, which is a stronger pairing than GA-2's two
 * endpoints of one site:
 *   A. iga.in.gov/api/getLegislators?session_lpid=session_2026
 *      The General Assembly's own list, behind its React front end. 151 rows.
 *   B. data.openstates.org/people/current/in.csv
 *      Open States. 150 rows. A DETECTOR, NOT AN ORACLE -- every disagreement is a reading
 *      queue against the chamber's own page, never a verdict.
 *
 * 🔴 SOURCE A IS OVER-LONG BY ONE AND THE MARKER IS A NULL DISTRICT. Indiana keeps a departed
 * member in the list and blanks the district rather than removing the row. Senator Andy Zay is
 * the 151st: "district": null. He resigned effective 2026-01-08 on appointment to chair the
 * Indiana Utility Regulatory Commission; Nick McKinley took SD-17 on 2026-02-09. So the rule is
 * `district != null` -- Georgia's `dateVacated == null` in another dress. Do NOT de-duplicate on
 * name or on district.
 *
 * 🔴 THERE IS NO term_start TO BE HAD, AND NONE IS INVENTED. getLegislatorDetails -- the richest
 * per-member endpoint the site has -- returns lpid, honorific, firstname, lastname, statephone,
 * district_id, party, busemail, contact_form_url, caucus_page_url, bills[], committees[]. No
 * service-start of any kind, and no portrait URL either. Every term is therefore written
 * open-ended at start_precision 'unknown', which is the GA-2 pattern and is what the 18 rows
 * already in production carry.
 *
 * 🔴 PARTY IS DELIBERATELY DROPPED. Both payloads carry it. Party lives on races.primary_party
 * in this schema, never on a person or an office.
 *
 * 🔴 A UNIFORM ANSWER IS A BROKEN DETECTOR. The two sources agree on all 150 seats, so
 * --self-test plants three defects into source B and requires each to be reported before that
 * agreement is trusted.
 *
 *   node scripts/build-in-legislature-roster.mjs
 *   node scripts/build-in-legislature-roster.mjs --self-test
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SEED = path.join(HERE, '..', 'data', 'seed-in-legislature-2026');
const OUT = path.join(HERE, '..', 'data', 'in-legislature-roster.json');

const IGA = path.join(SEED, '_iga_getLegislators_2026.json');
const OPENSTATES = path.join(SEED, '_openstates_in.csv');

const CHAMBERS = {
  Representative: { chamber: 'STATE_LOWER', os: 'lower', seats: 100, title: 'Representative' },
  Senator: { chamber: 'STATE_UPPER', os: 'upper', seats: 50, title: 'Senator' },
};

/** RFC4180-ish CSV reader. Open States quotes biography and address fields containing commas. */
function parseCsv(text) {
  const rows = [];
  let field = '', row = [], inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') { if (text[i + 1] === '"') { field += '"'; i++; } else inQuotes = false; }
      else field += c;
    } else if (c === '"') inQuotes = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); field = ''; rows.push(row); row = []; }
    else if (c !== '\r') field += c;
  }
  if (field.length || row.length) { row.push(field); rows.push(row); }
  return rows;
}

function loadOpenStates() {
  const rows = parseCsv(fs.readFileSync(OPENSTATES, 'utf8'));
  const hdr = rows[0];
  const at = (r, n) => r[hdr.indexOf(n)];
  return rows.slice(1).filter((r) => r.length > 3).map((r) => ({
    name: at(r, 'name'),
    given: at(r, 'given_name'),
    family: at(r, 'family_name'),
    chamber: at(r, 'current_chamber'),
    district: at(r, 'current_district'),
    image: at(r, 'image') || null,
  }));
}

function loadIga() {
  const all = JSON.parse(fs.readFileSync(IGA, 'utf8')).legislators;
  const sitting = all.filter((x) => x.district !== null && x.district !== undefined);
  const departed = all.filter((x) => x.district === null || x.district === undefined);
  return { sitting, departed };
}

const norm = (s) => String(s || '').toLowerCase().replace(/[^a-z ]/g, '').replace(/\s+/g, ' ').trim();
const key = (chamber, district) => `${chamber}-${district}`;

/** Diff the two sources on holder identity. Returns a list of disagreements. */
function diff(iga, os) {
  const igaByKey = new Map(iga.map((x) => [key(CHAMBERS[x.honorific].os, String(x.district)), x]));
  const osByKey = new Map(os.map((x) => [key(x.chamber, x.district), x]));
  const out = [];
  for (const [k, a] of igaByKey) {
    const b = osByKey.get(k);
    if (!b) { out.push(`${k} OPENSTATES MISSING (IGA has ${a.firstname} ${a.lastname})`); continue; }
    if (norm(a.lastname) !== norm(b.family)) out.push(`${k} IGA:${a.lastname} vs OS:${b.family}`);
  }
  for (const [k] of osByKey) if (!igaByKey.has(k)) out.push(`${k} IGA MISSING`);
  return out;
}

function main() {
  const { sitting, departed } = loadIga();
  const os = loadOpenStates();

  console.log(`source A (IGA):        ${sitting.length} sitting, ${departed.length} departed`);
  for (const d of departed) console.log(`  departed, null district: ${d.firstname} ${d.lastname} (${d.honorific})`);
  console.log(`source B (Open States): ${os.length} rows`);

  for (const cfg of Object.values(CHAMBERS)) {
    const got = sitting.filter((x) => CHAMBERS[x.honorific].chamber === cfg.chamber);
    const distinct = new Set(got.map((x) => x.district)).size;
    if (got.length !== cfg.seats || distinct !== cfg.seats) {
      throw new Error(`${cfg.chamber}: ${got.length} rows / ${distinct} distinct districts, expected ${cfg.seats}`);
    }
  }

  if (process.argv.includes('--self-test')) {
    console.log('\n-- POSITIVE CONTROLS ------------------------------------------');
    console.log(`  control 1  unmodified                -> ${diff(sitting, os).length} disagreements (expect 0)`);
    const c2 = os.map((r) => ({ ...r }));
    const t = c2.find((r) => r.chamber === 'upper' && r.district === '17');
    t.family = 'Zzzcontrol'; t.name = 'Nick Zzzcontrol';
    console.log(`  control 2  SD-17 surname corrupted   -> ${diff(sitting, c2).length} disagreements (expect 1)`);
    const c3 = os.filter((r) => !(r.chamber === 'lower' && r.district === '1'));
    console.log(`  control 3  HD-1 row deleted          -> ${diff(sitting, c3).length} disagreements (expect 1)`);
    const c4 = os.map((r) => ({ ...r }));
    c4.find((r) => r.chamber === 'upper' && r.district === '17').district = '99';
    console.log(`  control 4  SD-17 moved to SD-99      -> ${diff(sitting, c4).length} disagreements (expect 2)`);
  }

  const disagreements = diff(sitting, os);
  console.log(`\ndisagreements between A and B: ${disagreements.length}`);
  for (const d of disagreements) console.log(`  ${d}`);
  if (disagreements.length) {
    throw new Error('Sources disagree. Settle each one from the member\'s own page before writing a roster.');
  }

  const osByKey = new Map(os.map((x) => [key(x.chamber, x.district), x]));
  const roster = sitting.map((x) => {
    const cfg = CHAMBERS[x.honorific];
    const b = osByKey.get(key(cfg.os, String(x.district)));
    return {
      chamber: cfg.chamber,
      title: cfg.title,
      district: x.district,
      geo_id: `18${String(x.district).padStart(3, '0')}`,
      full_name: `${x.firstname} ${x.lastname}`,
      first_name: x.firstname,
      last_name: x.lastname,
      // No term_start exists to be had; see the header. Written open-ended.
      term_start: null,
      start_precision: 'unknown',
      iga_lpid: x.lpid,
      iga_url: `https://iga.in.gov${x.url}`,
      // Stage 5 only. Measure before use -- the IGA API publishes no portrait at all.
      openstates_image: b.image,
    };
  }).sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? -1 : 1));

  const payload = {
    generated_at: new Date().toISOString(),
    state: 'IN',
    wave: 'IN-2',
    sources: {
      a: 'Indiana General Assembly, https://iga.in.gov/api/getLegislators?session_lpid=session_2026',
      b: 'Open States, https://data.openstates.org/people/current/in.csv',
    },
    departed: departed.map((d) => ({ full_name: `${d.firstname} ${d.lastname}`, honorific: d.honorific, lpid: d.lpid })),
    counts: {
      STATE_LOWER: roster.filter((r) => r.chamber === 'STATE_LOWER').length,
      STATE_UPPER: roster.filter((r) => r.chamber === 'STATE_UPPER').length,
    },
    roster,
  };

  fs.writeFileSync(OUT, JSON.stringify(payload, null, 2) + '\n');
  console.log(`\nwrote ${path.relative(process.cwd(), OUT)}: ${roster.length} seats ` +
    `(${payload.counts.STATE_LOWER} House + ${payload.counts.STATE_UPPER} Senate)`);
}

main();
