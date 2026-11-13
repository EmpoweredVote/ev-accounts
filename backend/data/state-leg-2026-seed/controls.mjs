#!/usr/bin/env node
// Controls for the seeding migrations. One run per state.
//
// 🔴 A CONTROL THAT HAS ONLY EVER PASSED PROVES NOTHING. Each variant plants ONE fault, runs the
//    real dry-run tool against production data, and requires a NAMED gate to fire. V0 is the
//    untampered file and must come back green, or every red below might be red for an unrelated
//    reason.
//
// 🔴 A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS.
//    Every edit goes through `sub()`, which counts its matches and throws unless it made exactly
//    the replacement it claims.
//
// 🔴 A TAMPER MUST SATISFY EVERY GATE BEFORE ITS OWN. The gates run in order, so a variant that
//    disturbs an earlier count dies on that count and never reaches the gate it was aimed at.
//    Outcomes are SWAPPED rather than added; a re-pointed race carries its own office AND is a
//    one-candidate race, so the race count stays whole.
//
// ⚠ A GATE THIS SUITE CANNOT REACH IS NAMED AS SUCH rather than quietly left out — see the
//    `skipped` list each run prints.
//
// usage: DATABASE_URL=... node controls.mjs <work-dir> <analysis.json> <st> <slot> <migration.sql>
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

const [workDir, analysisFile, stArg, slot, migRel] = process.argv.slice(2);
if (!workDir || !analysisFile || !stArg || !slot || !migRel) {
  console.error('usage: controls.mjs <work-dir> <analysis.json> <st> <slot> <migration.sql>');
  process.exit(2);
}
const st = stArg.toLowerCase();
fs.mkdirSync(workDir, { recursive: true });

const here = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\//, '')));
const backend = path.resolve(here, '..', '..');
const MIG = path.resolve(backend, migRel);
const analysis = JSON.parse(fs.readFileSync(path.resolve(here, analysisFile), 'utf8'));

function sub(text, find, replace, expected = 1) {
  const n = text.split(find).length - 1;
  if (n !== expected) throw new Error(`REFUSED: the pattern occurs ${n} time(s), expected ${expected}: ${String(find).slice(0, 90)}`);
  return text.split(find).join(replace);
}
function lineOf(text, apRaceId, apId) {
  const lines = text.split('\n').filter((l) => l.includes(`'${apRaceId}'`) && l.includes(`'${apId}'`));
  if (lines.length !== 1) throw new Error(`REFUSED: ${lines.length} line(s) carry AP ${apRaceId}/${apId}`);
  return lines[0];
}
function setOutcome(line, from, to) {
  const hits = line.match(/, '(won|lost)', /g);
  if (!hits || hits.length !== 1) throw new Error(`REFUSED: ${hits ? hits.length : 0} outcome field(s) on this line`);
  if (!line.includes(`, '${from}', `)) throw new Error(`REFUSED: this line's outcome is not '${from}'`);
  return line.replace(`, '${from}', `, `, '${to}', `);
}

const empty = analysis.races.filter((r) => r.state === st && r.our.existing_candidates === 0);
const seeded = analysis.races.filter((r) => r.state === st && r.our.existing_candidates > 0);
const contested = empty.filter((r) => r.called && !r.ap.uncontested && r.lines.length > r.winners
  && r.lines.some((l) => l.winner === 'X') && r.lines.every((l) => (l.voteCount ?? 0) > 0));
const linked = empty.filter((r) => r.holder && r.holder.link);
// A one-candidate, one-seat race, so that re-pointing it whole leaves the row count AND the race
// count untouched. An UNLINKED one is preferred, but a linked one serves too: the gates these
// variants aim at (the production join, then the empty-race premise) both run BEFORE the gate
// that re-asserts the incumbent link, so the link cannot shadow them. Oregon has no unlinked
// one-candidate race at all — every uncontested seat there is held by its incumbent.
const singles = empty.filter((r) => r.lines.length === 1 && r.our.seats === 1);
const single = [...singles.filter((r) => !(r.holder && r.holder.link)), ...singles.filter((r) => r.holder && r.holder.link)];
if (contested.length < 2 || linked.length < 2 || !single.length) throw new Error(`REFUSED: ${st} does not offer the control targets (contested ${contested.length}, linked ${linked.length}, single ${single.length})`);

const A = contested[0]; const B = contested[1];
const aWin = A.lines.find((l) => l.winner === 'X'); const aLose = A.lines.find((l) => l.winner !== 'X');
const bLose = B.lines.find((l) => l.winner !== 'X');
const one = single[0];
const rowCount = empty.reduce((s, r) => s + r.lines.length, 0);

const skipped = [];
const VARIANTS = [
  { id: 'V0', expect: null, what: `the untampered ${st.toUpperCase()} file — it must come back green or every red below is suspect`, edit: (s) => s },
  {
    id: 'V1-transposed-win', expect: 'not among the top vote-getters',
    what: `the win in ${A.our.district_label} moved to a candidate with fewer votes — counts unchanged, the file agrees with itself, and only AP's independent vote field can see it`,
    edit: (s) => {
      let out = sub(s, lineOf(s, A.ap.raceID, aWin.candidateID), setOutcome(lineOf(s, A.ap.raceID, aWin.candidateID), 'won', 'lost'));
      out = sub(out, lineOf(out, A.ap.raceID, aLose.candidateID), setOutcome(lineOf(out, A.ap.raceID, aLose.candidateID), 'lost', 'won'));
      return out;
    },
  },
  {
    id: 'V2-winners-vs-seats', expect: 'winner count does not match races.seats',
    what: `an extra winner in ${B.our.district_label}, paid for by demoting the winner of ${A.our.district_label} so the totals still add up`,
    edit: (s) => {
      let out = sub(s, lineOf(s, B.ap.raceID, bLose.candidateID), setOutcome(lineOf(s, B.ap.raceID, bLose.candidateID), 'lost', 'won'));
      out = sub(out, lineOf(out, A.ap.raceID, aWin.candidateID), setOutcome(lineOf(out, A.ap.raceID, aWin.candidateID), 'won', 'lost'));
      return out;
    },
  },
  {
    id: 'V4-unknown-race', expect: 'the race join sees',
    what: `${one.our.district_label}, a one-candidate race, pointed at a race id that does not exist — the positive control for every gate that joins production`,
    edit: (s) => {
      const line = lineOf(s, one.ap.raceID, one.lines[0].candidateID);
      return sub(s, line, line.replace(`'${one.our.race_id}'`, "'00000000-0000-4000-8000-000000000000'"));
    },
  },
  {
    id: 'V5-stale-holder-link', expect: 'no longer the seat holder',
    what: `the incumbent links of ${linked[0].our.district_label} and ${linked[1].our.district_label} swapped — each now names a real politician who really holds a seat, just not THAT seat, and the link count is untouched`,
    edit: (s) => {
      const la = lineOf(s, linked[0].ap.raceID, linked[0].holder.candidateID);
      const lb = lineOf(s, linked[1].ap.raceID, linked[1].holder.candidateID);
      const ia = linked[0].holder.politician_id; const ib = linked[1].holder.politician_id;
      let out = sub(s, la, la.replace(`'${ia}'::uuid`, `'${ib}'::uuid`));
      out = sub(out, lb, lb.replace(`'${ib}'::uuid`, `'${ia}'::uuid`));
      return out;
    },
  },
  {
    id: 'V6-link-without-the-flag', expect: 'claim the incumbent basis while AP does not flag them',
    what: `${linked[0].holder.ap_name} kept linked to the seat holder while AP's incumbent flag is cleared — the link must rest on the flag, not on the name beside it`,
    edit: (s) => {
      const line = lineOf(s, linked[0].ap.raceID, linked[0].holder.candidateID);
      const flipped = line.replace(/, true, (NULL|'[^']*'), /, ", false, $1, ");
      if (flipped === line) throw new Error('REFUSED: the incumbent flag was not cleared');
      return sub(s, line, flipped);
    },
  },
  {
    id: 'V7-vote-count-in-the-citation', expect: 'a citation quotes a vote count',
    what: "the citation made to quote AP's raw count instead of its share — the CC_0408-CC_0411 defect, planted deliberately",
    edit: (s) => sub(s, "ELSE 'AP reported ' || s.pct || '% of the vote for this candidate.' END",
      "ELSE 'AP reported ' || s.votes || ' votes for this candidate.' END"),
  },
  {
    id: 'V8-dropped-row', expect: `expected ${rowCount} measured candidacies`,
    what: 'one ballot line deleted from the file — the count gate is what stands between a partial read and a silent partial write',
    edit: (s) => {
      // ⚠ NOT THE LAST ROW OF THE VALUES LIST. That row carries the statement's semicolon, so
      //    deleting it leaves a trailing comma and the file stops parsing — "syntax error at or
      //    near DO". The tamper then never reaches the count gate it was aimed at, which reads
      //    exactly like a shadowed control. A row in the middle of the list is the right target.
      const first = empty[0];
      const line = lineOf(s, first.ap.raceID, first.lines[first.lines.length - 1].candidateID);
      return sub(s, `${line}\n`, '');
    },
  },
  {
    id: 'V9-mirror-trigger-fires', expect: 'carry a photo or website url',
    what: 'the INSERT made to write a photo url, which wakes essentials.trg_race_candidate_mirror_data and lets it write onto a politician — this file must never do that',
    edit: (s) => {
      let out = sub(s, `   candidate_status, external_id, source, result, result_certainty, result_source,
   result_recorded_at)`, `   candidate_status, external_id, source, result, result_certainty, result_source,
   result_recorded_at, photo_url)`);
      out = sub(out, `       CASE WHEN s.outcome IS NULL THEN NULL ELSE now() END
  FROM seed s`, `       CASE WHEN s.outcome IS NULL THEN NULL ELSE now() END,
       'https://example.invalid/planted-by-a-control.jpg'
  FROM seed s`);
      return out;
    },
  },
];

// V3 needs a race IN THIS STATE that already carries candidacies. Where the state has none —
// which is the normal case, since an empty race is the premise of the whole wave — the gate is
// asserted and NOT controlled, and that is said rather than left out.
if (seeded.length) {
  const target = seeded[0];
  VARIANTS.splice(3, 0, {
    id: 'V3-race-already-seeded', expect: 'already carry candidacies',
    what: `${one.our.district_label}, a one-candidate race, re-pointed whole at ${target.our.district_label}, which already holds ${target.our.existing_candidates} candidacy(ies) — WITH its office id, so neither the office gate nor the race count can shadow this one`,
    edit: (s) => {
      const line = lineOf(s, one.ap.raceID, one.lines[0].candidateID);
      const moved = line
        .replace(`'${one.our.race_id}'`, `'${target.our.race_id}'`)
        .replace(`'${one.our.office_id}'`, `'${target.our.office_id}'`);
      if (moved === line) throw new Error('REFUSED: the race/office ids were not replaced');
      return sub(s, line, moved);
    },
  });
} else {
  skipped.push("V3 (a race that already carries candidacies): this state holds no such race — every one of its races is empty, which is the premise of the file. The gate is asserted and not proven here; Oregon's run proves it.");
}
skipped.push('the external_id collision gate: it cannot be tripped without first writing a colliding row to production.');
skipped.push('the occupancy drift baseline: it cannot be tripped without moving occupancy, which nothing in this file touches.');

let pass = 0; let fail = 0;
for (const v of VARIANTS) {
  const src = fs.readFileSync(MIG, 'utf8');
  let tampered;
  try { tampered = v.edit(src); } catch (e) { console.log(`✗ ${v.id}: the tamper itself did not apply — ${e.message}`); fail++; continue; }
  if (v.expect && tampered === src) { console.log(`✗ ${v.id}: the tamper changed nothing, so this control proves nothing`); fail++; continue; }
  const file = path.join(workDir, `${st}-${v.id}.sql`);
  fs.writeFileSync(file, tampered);

  let output; let ok;
  try {
    output = execFileSync(process.execPath, [
      '--import', pathToFileURL(path.join(backend, 'scripts', 'lib', 'main-checkout-fallback.mjs')).href,
      path.join(backend, 'scripts', 'dry-run-migration.mjs'), file,
    ], { cwd: backend, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
    ok = true;
  } catch (e) { output = `${e.stdout || ''}${e.stderr || ''}`; ok = false; }

  if (v.expect === null) {
    if (ok && /DRY RUN OK/.test(output)) { console.log(`✓ ${v.id}: green, as it must be — ${v.what}`); pass++; }
    else { console.log(`✗ ${v.id}: the UNTAMPERED file failed:\n${output.split('\n').slice(-6).join('\n')}`); fail++; }
    continue;
  }
  if (ok) { console.log(`✗ ${v.id}: NO GATE FIRED. ${v.what}`); fail++; }
  else if (output.includes(v.expect)) { console.log(`✓ ${v.id}: "${v.expect}" — ${v.what}`); pass++; }
  else {
    const line = output.split('\n').find((l) => new RegExp(slot).test(l)) || output.split('\n').slice(-3).join(' ');
    console.log(`✗ ${v.id}: a gate fired, but NOT the one aimed at (shadowed). Wanted "${v.expect}", got: ${line.trim().slice(0, 200)}`);
    fail++;
  }
}

console.log(`\n${pass} of ${pass + fail} control(s) behaved for ${st.toUpperCase()} (${slot}).`);
for (const s of skipped) console.log(`  ⚠ not controlled — ${s}`);
process.exit(fail ? 1 : 0);
