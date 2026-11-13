#!/usr/bin/env node
// Controls for CC_0413 (Massachusetts) and CC_0414 (Maine).
//
// 🔴 A CONTROL THAT HAS ONLY EVER PASSED PROVES NOTHING. Each variant below plants ONE fault,
//    runs the real dry-run tool against production data, and requires a NAMED gate to fire. V0
//    is the untampered file and must come back green, or every red below might be red for an
//    unrelated reason.
//
// 🔴 A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS.
//    Every edit here goes through `sub()`, which counts its matches and throws unless it made
//    exactly the replacement it claims.
//
// 🔴 A TAMPER MUST SATISFY EVERY GATE BEFORE ITS OWN. The gates run in order, so a variant that
//    also disturbs an earlier count dies on that count and never reaches the gate it was aimed
//    at. Each one below is therefore made internally consistent first — outcomes are SWAPPED
//    rather than added, a re-pointed race carries its own office, a moved link keeps the link
//    count whole.
//
// usage: DATABASE_URL=... node controls.mjs <work-dir>
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

const workDir = process.argv[2];
if (!workDir) { console.error('usage: controls.mjs <work-dir>'); process.exit(2); }
fs.mkdirSync(workDir, { recursive: true });

const here = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\//, '')));
const backend = path.resolve(here, '..', '..');
const MIG = {
  ma: path.join(backend, 'migrations', 'CC_0413_ma_legislature_2026_seed_ballots.sql'),
  me: path.join(backend, 'migrations', 'CC_0414_me_legislature_2026_seed_ballots.sql'),
};
const analysis = JSON.parse(fs.readFileSync(path.join(here, 'analysis-2026-11-13.json'), 'utf8'));

function sub(text, find, replace, expected = 1) {
  const n = text.split(find).length - 1;
  if (n !== expected) throw new Error(`REFUSED: the pattern occurs ${n} time(s), expected ${expected}: ${String(find).slice(0, 90)}`);
  return text.split(find).join(replace);
}

// Find the VALUES line that carries this AP candidate id.
function lineOf(text, apId) {
  const lines = text.split('\n').filter((l) => l.includes(`'${apId}'`));
  if (lines.length !== 1) throw new Error(`REFUSED: ${lines.length} line(s) carry AP candidate ${apId}`);
  return lines[0];
}
function setOutcome(line, from, to) {
  const re = /, '(won|lost)', /g;
  const hits = line.match(re);
  if (!hits || hits.length !== 1) throw new Error(`REFUSED: ${hits ? hits.length : 0} outcome field(s) on this line`);
  if (!line.includes(`, '${from}', `)) throw new Error(`REFUSED: this line's outcome is not '${from}'`);
  return line.replace(`, '${from}', `, `, '${to}', `);
}

// ── pick the targets from the analysis, not by eye ────────────────────────────────────────────
const empty = (st) => analysis.races.filter((r) => r.state === st && r.our.existing_candidates === 0);

// A called, CONTESTED Maine race with real counts — the only shape in which a transposed win is
// visible at all (an uncontested race publishes zero for everyone and orders nothing).
const meContested = empty('me').find((r) => r.called && !r.ap.uncontested
  && r.lines.length > 1 && r.lines.some((l) => l.winner === 'X') && r.lines.every((l) => (l.voteCount ?? 0) > 0));
const meContested2 = empty('me').find((r) => r !== meContested && r.called && !r.ap.uncontested
  && r.lines.length > 1 && r.lines.some((l) => l.winner === 'X'));
const meLinked = empty('me').filter((r) => r.holder && r.holder.link).slice(0, 2);
const maLinked = empty('ma').find((r) => r.holder && r.holder.link);
const maAny = empty('ma')[0];
// 🔴 A RE-POINTED RACE MUST BE A RACE WITH ONE BALLOT LINE. Moving one row out of a two-row race
//    leaves the old race behind and adds a new one — 197 distinct races where the file says 196 —
//    so the RACE COUNT gate fires and shadows the gate being tested. Both V3 and V4 died that way
//    on their first run. Moving the only line of a single-candidate race keeps 196 and 256 whole,
//    and Massachusetts, where 140 of 196 races are uncontested, has no shortage of them.
const maSingle = empty('ma').find((r) => r.lines.length === 1 && r.our.seats === 1 && !(r.holder && r.holder.link));
if (!meContested || !meContested2 || meLinked.length < 2 || !maLinked || !maAny || !maSingle) throw new Error('REFUSED: could not pick control targets');

const meWinner = meContested.lines.find((l) => l.winner === 'X');
const meLoser = meContested.lines.find((l) => l.winner !== 'X');
const meWinner2 = meContested2.lines.find((l) => l.winner === 'X');
const meLoser2 = meContested2.lines.find((l) => l.winner !== 'X');

const VARIANTS = [
  {
    id: 'V0-ma', st: 'ma', expect: null,
    what: 'the untampered Massachusetts file — it must come back green or every red below is suspect',
    edit: (s) => s,
  },
  {
    id: 'V0-me', st: 'me', expect: null,
    what: 'the untampered Maine file',
    edit: (s) => s,
  },
  {
    id: 'V1-transposed-win', st: 'me', expect: 'not among the top vote-getters',
    what: `the win in ${meContested.our.district_label} moved to the candidate with fewer votes — counts unchanged, the file agrees with itself, and ONLY the independent vote field can see it`,
    edit: (s) => {
      let out = sub(s, lineOf(s, meWinner.candidateID), setOutcome(lineOf(s, meWinner.candidateID), 'won', 'lost'));
      out = sub(out, lineOf(out, meLoser.candidateID), setOutcome(lineOf(out, meLoser.candidateID), 'lost', 'won'));
      return out;
    },
  },
  {
    id: 'V2-winners-vs-seats', st: 'me', expect: 'winner count does not match races.seats',
    what: `a second winner in ${meContested2.our.district_label}, paid for by demoting the winner of ${meContested.our.district_label} so the totals still add up`,
    edit: (s) => {
      let out = sub(s, lineOf(s, meLoser2.candidateID), setOutcome(lineOf(s, meLoser2.candidateID), 'lost', 'won'));
      out = sub(out, lineOf(out, meWinner.candidateID), setOutcome(lineOf(out, meWinner.candidateID), 'won', 'lost'));
      return out;
    },
  },
  {
    id: 'V3-race-already-seeded', st: 'ma', expect: 'already carry candidacies',
    what: `${maSingle.our.district_label}, a one-candidate race, re-pointed whole at the 25th Middlesex race, which already holds Marjorie Decker's candidacy — WITH its office id, so neither the office gate nor the race count can shadow this one`,
    edit: (s) => {
      const line = lineOf(s, maSingle.lines[0].candidateID);
      const moved = line
        .replace(`'${maSingle.our.race_id}'`, "'b6f796e2-e363-450c-b5ae-a34df3c5184e'")
        .replace(`'${maSingle.our.office_id}'`, "'a0e18b1e-478f-49b7-8ffb-351dc338875c'");
      if (moved === line) throw new Error('REFUSED: the race/office ids were not replaced');
      return sub(s, line, moved);
    },
  },
  {
    id: 'V4-unknown-race', st: 'ma', expect: 'the race join sees',
    what: `${maSingle.our.district_label} pointed at a race id that does not exist — the positive control for every gate that joins production`,
    edit: (s) => {
      const line = lineOf(s, maSingle.lines[0].candidateID);
      return sub(s, line, line.replace(`'${maSingle.our.race_id}'`, "'00000000-0000-4000-8000-000000000000'"));
    },
  },
  {
    id: 'V5-stale-holder-link', st: 'me', expect: 'no longer the seat holder',
    what: `the incumbent links of ${meLinked[0].our.district_label} and ${meLinked[1].our.district_label} swapped — each now names a real politician who really holds a seat, just not THAT seat, and the link count is untouched`,
    edit: (s) => {
      const a = lineOf(s, meLinked[0].holder.candidateID);
      const bLine = lineOf(s, meLinked[1].holder.candidateID);
      const idA = meLinked[0].holder.politician_id;
      const idB = meLinked[1].holder.politician_id;
      let out = sub(s, a, a.replace(`'${idA}'::uuid`, `'${idB}'::uuid`));
      out = sub(out, bLine, bLine.replace(`'${idB}'::uuid`, `'${idA}'::uuid`));
      return out;
    },
  },
  {
    id: 'V6-link-without-the-flag', st: 'ma', expect: 'claim the incumbent basis while AP does not flag them',
    what: `${maLinked.holder.ap_name} kept linked to the seat holder while AP's incumbent flag is cleared — the link must rest on the flag, not on the name beside it`,
    edit: (s) => {
      const line = lineOf(s, maLinked.holder.candidateID);
      const flipped = line.replace(/, true, (NULL|'[^']*'), /, ", false, $1, ");
      if (flipped === line) throw new Error('REFUSED: the incumbent flag was not cleared');
      return sub(s, line, flipped);
    },
  },
  {
    id: 'V7-vote-count-in-the-citation', st: 'me', expect: 'a citation quotes a vote count',
    what: 'the citation made to quote AP\'s raw count instead of its share — the CC_0408-CC_0411 defect, planted deliberately',
    edit: (s) => sub(s, "ELSE 'AP reported ' || s.pct || '% of the vote for this candidate.' END",
      "ELSE 'AP reported ' || s.votes || ' votes for this candidate.' END"),
  },
  {
    id: 'V8-dropped-row', st: 'ma', expect: 'expected 256 measured candidacies',
    what: 'one ballot line deleted from the file — the count gate is what stands between a partial read and a silent partial write',
    edit: (s) => {
      const line = lineOf(s, maAny.lines[maAny.lines.length - 1].candidateID);
      const trimmed = line.endsWith(',') ? line : line;
      return sub(s, `${trimmed}\n`, '');
    },
  },
  {
    id: 'V9-mirror-trigger-fires', st: 'me', expect: 'carry a photo or website url',
    what: 'the INSERT made to write a photo url, which wakes essentials.trg_race_candidate_mirror_data and lets it write onto a politician — this file must never do that',
    edit: (s) => {
      let out = sub(s, `  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, is_write_in,
   candidate_status, external_id, source, result, result_certainty, result_source,
   result_recorded_at)`, `  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, is_write_in,
   candidate_status, external_id, source, result, result_certainty, result_source,
   result_recorded_at, photo_url)`);
      out = sub(out, `       CASE WHEN s.outcome IS NULL THEN NULL ELSE now() END
  FROM seed s`, `       CASE WHEN s.outcome IS NULL THEN NULL ELSE now() END,
       'https://example.invalid/planted-by-a-control.jpg'
  FROM seed s`);
      return out;
    },
  },
];

let pass = 0; let fail = 0;
for (const v of VARIANTS) {
  const src = fs.readFileSync(MIG[v.st], 'utf8');
  let tampered;
  try { tampered = v.edit(src); } catch (e) {
    console.log(`✗ ${v.id}: the tamper itself did not apply — ${e.message}`);
    fail++; continue;
  }
  if (v.expect && tampered === src) {
    console.log(`✗ ${v.id}: the tamper changed nothing, so this control proves nothing`);
    fail++; continue;
  }
  const file = path.join(workDir, `${v.id}.sql`);
  fs.writeFileSync(file, tampered);

  let output; let ok;
  try {
    output = execFileSync(process.execPath, [
      '--import', pathToFileURL(path.join(backend, 'scripts', 'lib', 'main-checkout-fallback.mjs')).href,
      path.join(backend, 'scripts', 'dry-run-migration.mjs'), file,
    ], { cwd: backend, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
    ok = true;
  } catch (e) {
    output = `${e.stdout || ''}${e.stderr || ''}`;
    ok = false;
  }

  if (v.expect === null) {
    if (ok && /DRY RUN OK/.test(output)) { console.log(`✓ ${v.id}: green, as it must be — ${v.what}`); pass++; }
    else { console.log(`✗ ${v.id}: the UNTAMPERED file failed:\n${output.split('\n').slice(-6).join('\n')}`); fail++; }
    continue;
  }
  if (ok) {
    console.log(`✗ ${v.id}: NO GATE FIRED. ${v.what}`);
    fail++;
  } else if (output.includes(v.expect)) {
    console.log(`✓ ${v.id}: "${v.expect}" — ${v.what}`);
    pass++;
  } else {
    const line = output.split('\n').find((l) => /CC_041[34]|error|ERROR/.test(l)) || output.split('\n').slice(-3).join(' ');
    console.log(`✗ ${v.id}: a gate fired, but NOT the one aimed at (shadowed). Wanted "${v.expect}", got: ${line.trim().slice(0, 200)}`);
    fail++;
  }
}

console.log(`\n${pass} of ${pass + fail} control(s) behaved.`);
process.exit(fail ? 1 : 0);
