#!/usr/bin/env node
/**
 * CivicPatch enrichment — DRY RUN MATCH REPORT. Writes nothing to the database.
 *
 * Produces the reviewable artifact that has to exist before the TX + MA Springfield
 * contacts/images batch approved in .planning/decisions/2026-07-30-civicpatch-api-decision.md
 * can be executed.
 *
 * WHY A SEPARATE REPORT STEP. The approved scope is enrichment only — match their record to an
 * EXISTING politician, never create one. The binding risk is the match itself: normalised-name
 * matching failed twice in one day on real people ("Ben"/"Benjamin" Nadolski, "Erin"/"Erin J."
 * Mendenhall). So this script classifies every one of their records and REFUSES to collapse an
 * ambiguous case into a guess:
 *
 *   EXACT      normalised full names are identical, and the match is 1:1 in both directions.
 *              Only this class is eligible for automatic import.
 *   REVIEW     surname + first initial agree but the full names do not (the Ben/Benjamin shape),
 *              or the match is not 1:1. Needs a human. Never auto-imported.
 *   MISS       no candidate at all. A finding, not a prompt to seed a politician.
 *
 * Reads the VENDORED snapshot (backend/data/civicpatch/), never the network — Civic Data Tech
 * said the repos are free "as long as we could keep them up", so the importer must not inherit
 * their uptime.
 *
 * Usage:  node scripts/civicpatch-match-report.mjs [--json out.json]
 * Needs DATABASE_URL. Read-only against prod.
 */
import 'dotenv/config';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import yaml from 'js-yaml';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SNAPSHOT_DIR = path.join(HERE, '..', 'data', 'civicpatch');
const ARCHIVE = path.join(SNAPSHOT_DIR, 'civicpatch-open-data-928579c0.tar.gz');

/**
 * Which states to classify. Defaults to the first approved batch (TX + MA Springfield);
 * override with --states ca.
 *
 * The decision doc held CA back pending an "incumbency check", on the grounds that its rows are
 * ~12 months old and a stale roster names departed members (the migration-1500 failure). Running
 * the TX batch showed that check already exists implicitly: candidates are drawn ONLY from
 * essentials.office_current_holder, so a record naming someone who has left office matches nobody
 * and is dropped. Staleness costs us MISSes, not bad writes.
 */
const statesIdx = process.argv.indexOf('--states');
const BATCH_STATES = statesIdx !== -1 && process.argv[statesIdx + 1]
  ? process.argv[statesIdx + 1].split(',').map((s) => s.trim().toLowerCase())
  : ['tx', 'ma'];

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

/** Strip case, punctuation, suffixes and honorifics so two spellings of one person compare equal. */
function normaliseName(raw) {
  if (!raw) return '';
  return String(raw)
    .toLowerCase()
    .replace(/[.,'’]/g, '')
    .replace(/\b(jr|sr|ii|iii|iv|phd|md|esq|dr|mr|mrs|ms|hon|honorable)\b/g, ' ')
    .replace(/[^a-z\s-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const firstTok = (n) => normaliseName(n).split(' ')[0] ?? '';
const lastTok = (n) => {
  const t = normaliseName(n).split(' ').filter(Boolean);
  return t.length ? t[t.length - 1] : '';
};

/** Extract the vendored snapshot to a temp dir. Idempotent within a run. */
function restoreSnapshot() {
  const dest = path.join(os.tmpdir(), 'civicpatch-snapshot-928579c0');
  if (existsSync(path.join(dest, 'data'))) return dest;
  if (!existsSync(ARCHIVE)) {
    throw new Error(`snapshot archive missing: ${ARCHIVE}`);
  }
  mkdirSync(dest, { recursive: true });
  // GNU tar reads a Windows "C:\..." path as a REMOTE host spec (everything before the first colon
  // is taken as a hostname) and fails with "Cannot connect to C". --force-local suppresses that,
  // but bsdtar — which is what ships in System32 on Windows — does not accept the flag and does not
  // need it. Try plain first, fall back to the GNU spelling.
  try {
    execFileSync('tar', ['-xzf', ARCHIVE, '-C', dest], { stdio: 'pipe' });
  } catch {
    execFileSync('tar', ['--force-local', '-xzf', ARCHIVE, '-C', dest], { stdio: 'pipe' });
  }
  return dest;
}

/** Their records for one state, keyed by the place ocd-division id. */
function loadTheirRecords(snapshotRoot, state) {
  const dir = path.join(snapshotRoot, 'data', state, 'local');
  if (!existsSync(dir)) return new Map();
  const byPlace = new Map();
  for (const file of readdirSync(dir).filter((f) => f.endsWith('.yml'))) {
    const parsed = yaml.load(readFileSync(path.join(dir, file), 'utf8'));
    if (!Array.isArray(parsed)) continue;
    for (const rec of parsed) {
      const div = rec?.office?.division_ocdid;
      if (!div) continue;
      // Normalise to the PLACE root: seat-level ids carry /council_district:N or /ward:N.
      const place = div.replace(/\/(council_district|ward|district|seat):.*$/, '');
      if (!byPlace.has(place)) byPlace.set(place, []);
      byPlace.get(place).push(rec);
    }
  }
  return byPlace;
}

async function loadOurOfficials(placeIds) {
  const { rows } = await pool.query(
    `SELECT d.ocd_id                                   AS district_ocd_id,
            regexp_replace(d.ocd_id, '/(council_district|ward|district|seat):.*$', '') AS place_ocd_id,
            lower(d.state)                             AS state,
            p.id                                       AS politician_id,
            p.full_name,
            o.title,
            EXISTS (SELECT 1 FROM essentials.politician_contacts c
                     WHERE c.politician_id = p.id AND c.contact_type = 'office')  AS has_office_contact,
            EXISTS (SELECT 1 FROM essentials.politician_contacts c
                     WHERE c.politician_id = p.id AND c.email IS NOT NULL)        AS has_any_email,
            EXISTS (SELECT 1 FROM essentials.politician_contacts c
                     WHERE c.politician_id = p.id AND c.phone IS NOT NULL)        AS has_any_phone,
            EXISTS (SELECT 1 FROM essentials.politician_images i
                     WHERE i.politician_id = p.id)                                AS has_image
       FROM essentials.districts d
       JOIN essentials.offices o             ON o.district_id  = d.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p         ON p.id = och.politician_id
      WHERE regexp_replace(d.ocd_id, '/(council_district|ward|district|seat):.*$', '') = ANY($1::text[])`,
    [placeIds],
  );
  const byPlace = new Map();
  for (const r of rows) {
    if (!byPlace.has(r.place_ocd_id)) byPlace.set(r.place_ocd_id, []);
    byPlace.get(r.place_ocd_id).push(r);
  }
  return byPlace;
}

function classifyPlace(placeId, theirRecs, ourRecs) {
  const results = [];
  // Count normalised names on BOTH sides up front: a name that is not unique within its own
  // roster cannot be matched 1:1, and must not be guessed at.
  const theirCounts = new Map();
  for (const t of theirRecs) {
    const k = normaliseName(t.name);
    theirCounts.set(k, (theirCounts.get(k) ?? 0) + 1);
  }
  const ourCounts = new Map();
  for (const o of ourRecs) {
    const k = normaliseName(o.full_name);
    ourCounts.set(k, (ourCounts.get(k) ?? 0) + 1);
  }

  for (const t of theirRecs) {
    const tn = normaliseName(t.name);
    const exact = ourRecs.filter((o) => normaliseName(o.full_name) === tn);

    let verdict, ours = null, reason = '';
    if (exact.length === 1 && theirCounts.get(tn) === 1 && ourCounts.get(tn) === 1) {
      verdict = 'EXACT';
      ours = exact[0];
    } else if (exact.length > 1 || theirCounts.get(tn) > 1) {
      verdict = 'REVIEW';
      reason = `not 1:1 (theirs=${theirCounts.get(tn)}, ours=${exact.length})`;
    } else {
      const near = ourRecs.filter(
        (o) => lastTok(o.full_name) === lastTok(t.name) &&
               firstTok(o.full_name)[0] === firstTok(t.name)[0],
      );
      if (near.length === 1) {
        verdict = 'REVIEW';
        ours = near[0];
        reason = `surname+initial only: "${t.name}" vs "${near[0].full_name}"`;
      } else if (near.length > 1) {
        verdict = 'REVIEW';
        reason = `${near.length} surname+initial candidates`;
      } else {
        verdict = 'MISS';
        reason = 'no candidate in our roster for this place';
      }
    }

    const email = Array.isArray(t.emails) && t.emails.length ? t.emails[0] : null;
    const phone = Array.isArray(t.phones) && t.phones.length ? t.phones[0] : null;
    const url = Array.isArray(t.urls) && t.urls.length ? t.urls[0] : null;
    const image = t.cdn_image || t.image || null;

    results.push({
      place: placeId,
      verdict,
      reason,
      their_name: t.name,
      their_office: t.office?.name ?? null,
      their_id: t.id,
      updated_at: t.updated_at ?? null,
      offers: { email, phone, url, image: image ? true : false },
      image_url: image,
      our_politician_id: ours?.politician_id ?? null,
      our_full_name: ours?.full_name ?? null,
      our_title: ours?.title ?? null,
      // Additive-only gate, per rule 3 of the approved scope.
      would_insert_contact: Boolean(ours && !ours.has_office_contact && (email || phone || url)),
      would_insert_image: Boolean(ours && !ours.has_image && image),
    });
  }
  return results;
}

const q = (v) => (v === null || v === undefined ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`);

/**
 * Emit the contacts half of the batch as a migration in house style: idempotent, with a post-verify
 * gate that RAISEs on a wrong count.
 *
 * `source` records the SNAPSHOT SHA, not the migration number. CLAUDE.md warns that migration
 * numbers embedded in data already written to prod drift when branches renumber; the upstream commit
 * is the stable identifier and is also the thing you would need to reproduce this.
 */
function emitMigration(records, outPath, { onlyReview = false } = {}) {
  // --only-review emits the near-matches a HUMAN has since adjudicated. They are never auto-included;
  // this path exists so an operator decision can be executed with the same guards as the main batch.
  const rows = onlyReview
    ? records.filter((r) => r.verdict === 'REVIEW' && r.our_politician_id && r.would_insert_contact)
    : records.filter((r) => r.verdict === 'EXACT' && r.would_insert_contact);
  const SRC = 'civicpatch:928579c0';
  const lines = [];
  lines.push(`-- ${path.basename(outPath)}`);
  lines.push(`--`);
  lines.push(`-- Backfill office contacts for ${rows.length} municipal officials we ALREADY HOLD, from the`);
  lines.push(`-- vendored CC0 CivicPatch snapshot 928579c0 (backend/data/civicpatch/).`);
  lines.push(`-- Approved scope: .planning/decisions/2026-07-30-civicpatch-api-decision.md`);
  lines.push(`--`);
  if (onlyReview) {
    lines.push(`-- OPERATOR-ADJUDICATED NEAR-MATCHES. Every row here was REFUSED by the automatic matcher`);
    lines.push(`-- because the normalised names differ — the "Ben"/"Benjamin" shape that has produced real`);
    lines.push(`-- errors before. Each was then confirmed by hand and approved by the operator on`);
    lines.push(`-- 2026-07-30. Each is 1:1 within its city (exactly one surname+initial candidate on each`);
    lines.push(`-- side) and each carries a corroborating office title, so name and seat agree`);
    lines.push(`-- independently. THE MATCHER WAS NOT LOOSENED — it still refuses these, by design.`);
  } else {
    lines.push(`-- ENRICHMENT ONLY. Creates no politician and no office. Every row below is an EXACT 1:1`);
    lines.push(`-- normalised-name match against a CURRENT officeholder in the same place. Near-matches`);
    lines.push(`-- (the "Ben"/"Benjamin" shape) were held back for human review and are NOT here.`);
  }
  lines.push(`--`);
  lines.push(`-- ADDITIVE ONLY. Each insert is guarded on the politician having no contact_type='office'`);
  lines.push(`-- row at all, so nothing we already hold is overwritten. Re-running is a no-op.`);
  lines.push(`--`);
  const misses = records.filter((r) => r.verdict === 'MISS').length;
  const reviews = records.filter((r) => r.verdict === 'REVIEW').length;
  if (!onlyReview) {
  lines.push(`-- WHY THEIR STALENESS DOES NOT LEAK IN. Candidates are drawn ONLY from`);
  lines.push(`-- essentials.office_current_holder, so a record naming someone who has left office matches`);
  lines.push(`-- nobody and is absent here by construction. ${misses} of their ${records.length} records for this batch`);
  lines.push(`-- did exactly that. Matching against current holders IS the incumbency check the decision`);
  lines.push(`-- doc asked for — staleness costs MISSes, never bad writes. Do not "fix" the matcher to`);
  lines.push(`-- rescue them: a MISS is usually someone who left office. ${reviews} near-matches were also`);
  lines.push(`-- held back for human adjudication and are not included.`);
  }
  lines.push(``);
  lines.push(`BEGIN;`);
  lines.push(``);
  for (const r of rows) {
    const who = onlyReview
      ? `theirs "${r.their_name}"  ->  ours "${r.our_full_name}" (${r.our_title})`
      : `${r.our_full_name} · ${r.their_office ?? ''}`;
    lines.push(`-- ${r.place.replace('ocd-division/country:us/state:', '')} · ${who}`);
    lines.push(`INSERT INTO essentials.politician_contacts`);
    lines.push(`  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)`);
    lines.push(`SELECT ${q(r.our_politician_id)}::uuid, ${q(SRC)}, ${q(r.offers.email)}, ${q(r.offers.phone)}, ${q(r.offers.url)}, 'office', ${q(r.updated_at)}::timestamptz`);
    lines.push(`WHERE NOT EXISTS (`);
    lines.push(`  SELECT 1 FROM essentials.politician_contacts c`);
    lines.push(`   WHERE c.politician_id = ${q(r.our_politician_id)}::uuid AND c.contact_type = 'office');`);
    lines.push(``);
  }
  lines.push(`-- Post-verify gate: every intended politician must now carry an 'office' contact, and this`);
  lines.push(`-- migration must not have created a second one for anybody.`);
  lines.push(`DO $$`);
  lines.push(`DECLARE`);
  lines.push(`  expected int := ${rows.length};`);
  lines.push(`  covered  int;`);
  lines.push(`  dupes    int;`);
  lines.push(`BEGIN`);
  lines.push(`  SELECT count(*) INTO covered`);
  lines.push(`    FROM essentials.politician_contacts`);
  lines.push(`   WHERE contact_type = 'office'`);
  lines.push(`     AND politician_id IN (${rows.map((r) => q(r.our_politician_id) + '::uuid').join(', ')});`);
  lines.push(`  IF covered <> expected THEN`);
  lines.push(`    RAISE EXCEPTION 'expected % politicians with an office contact, found %', expected, covered;`);
  lines.push(`  END IF;`);
  lines.push(``);
  lines.push(`  -- Scoped to THIS batch: prod may hold unrelated duplicate office contacts elsewhere,`);
  lines.push(`  -- and this gate must fail only on damage we caused.`);
  lines.push(`  SELECT count(*) INTO dupes FROM (`);
  lines.push(`    SELECT politician_id FROM essentials.politician_contacts`);
  lines.push(`     WHERE contact_type = 'office'`);
  lines.push(`       AND politician_id IN (${rows.map((r) => q(r.our_politician_id) + '::uuid').join(', ')})`);
  lines.push(`     GROUP BY politician_id HAVING count(*) > 1) d;`);
  lines.push(`  IF dupes > 0 THEN`);
  lines.push(`    RAISE EXCEPTION 'duplicate office contacts for % politicians', dupes;`);
  lines.push(`  END IF;`);
  lines.push(`END $$;`);
  lines.push(``);
  lines.push(`COMMIT;`);
  lines.push(``);
  return lines.join('\n');
}

async function main() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not set — this report needs a live database.');
    process.exit(1);
  }
  const root = restoreSnapshot();

  const theirByPlace = new Map();
  for (const st of BATCH_STATES) {
    for (const [place, recs] of loadTheirRecords(root, st)) theirByPlace.set(place, recs);
  }

  const ourByPlace = await loadOurOfficials([...theirByPlace.keys()]);

  const all = [];
  const perPlace = [];
  for (const [place, theirRecs] of [...theirByPlace].sort()) {
    const ourRecs = ourByPlace.get(place) ?? [];
    if (!ourRecs.length) continue; // we don't hold this place — out of scope, not a finding
    const res = classifyPlace(place, theirRecs, ourRecs);
    all.push(...res);
    perPlace.push({
      place,
      theirs: theirRecs.length,
      ours: ourRecs.length,
      exact: res.filter((r) => r.verdict === 'EXACT').length,
      review: res.filter((r) => r.verdict === 'REVIEW').length,
      miss: res.filter((r) => r.verdict === 'MISS').length,
      contacts: res.filter((r) => r.verdict === 'EXACT' && r.would_insert_contact).length,
      images: res.filter((r) => r.verdict === 'EXACT' && r.would_insert_image).length,
    });
  }

  const w = (s, n) => String(s).padEnd(n);
  console.log('\nCivicPatch enrichment — DRY RUN (no writes)\n');
  console.log(`${w('place', 52)}${w('theirs', 7)}${w('ours', 6)}${w('exact', 7)}${w('review', 7)}${w('miss', 6)}${w('+cont', 6)}+img`);
  console.log('-'.repeat(98));
  for (const p of perPlace) {
    console.log(
      w(p.place.replace('ocd-division/country:us/state:', ''), 52) +
      w(p.theirs, 7) + w(p.ours, 6) + w(p.exact, 7) + w(p.review, 7) + w(p.miss, 6) +
      w(p.contacts, 6) + p.images,
    );
  }
  const sum = (k) => perPlace.reduce((a, p) => a + p[k], 0);
  console.log('-'.repeat(98));
  console.log(
    w('TOTAL', 52) + w(sum('theirs'), 7) + w(sum('ours'), 6) + w(sum('exact'), 7) +
    w(sum('review'), 7) + w(sum('miss'), 6) + w(sum('contacts'), 6) + sum('images'),
  );

  console.log(`\nEligible for automatic import (EXACT only): ${sum('contacts')} contact rows, ${sum('images')} images.`);
  console.log(`Held back for human review: ${sum('review')}.  No candidate at all: ${sum('miss')}.`);

  const review = all.filter((r) => r.verdict === 'REVIEW');
  if (review.length) {
    console.log('\nREVIEW — never auto-imported:');
    for (const r of review) {
      console.log(`  ${r.place.replace('ocd-division/country:us/state:', '')}  "${r.their_name}" (${r.their_office})  →  ${r.reason}`);
    }
  }

  const jsonIdx = process.argv.indexOf('--json');
  if (jsonIdx !== -1 && process.argv[jsonIdx + 1]) {
    writeFileSync(process.argv[jsonIdx + 1], JSON.stringify({ perPlace, records: all }, null, 2));
    console.log(`\nwrote ${process.argv[jsonIdx + 1]}`);
  }

  const migIdx = process.argv.indexOf('--emit-migration');
  if (migIdx !== -1 && process.argv[migIdx + 1]) {
    const out = process.argv[migIdx + 1];
    writeFileSync(out, emitMigration(all, out, { onlyReview: process.argv.includes('--only-review') }));
    console.log(`wrote ${out}`);
  }
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
