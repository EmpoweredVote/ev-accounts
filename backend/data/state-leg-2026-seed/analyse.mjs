#!/usr/bin/env node
// Match AP's per-state legislative races to ours, then build the candidacy rows this wave seeds.
//
// 🔴 THE JOIN KEY IS WHERE A LEGISLATIVE PASS GOES WRONG, AND MASSACHUSETTS IS THE HARD CASE.
//   MA names its districts and `districts.ocd_id` carries an INTERNAL INDEX that happens to be a
//   number (`sldl:19` is the 10th Bristol District); its senate rows carry `sldu:NaN`. AP's
//   `seatNum` is its own internal index too ("524"). So for MA the key is the NAME on both
//   sides, normalised — and 🔴 THE ORDER OF THE COUNTY TOKENS IS LOAD BEARING: "Middlesex &
//   Norfolk" and "Norfolk & Middlesex" are BOTH real senate districts, as are Suffolk/Middlesex
//   and Worcester/Middlesex. A key that sorted its tokens would collide three real pairs.
//   Maine numbers its districts on both sides, so ME joins on the number.
//
// 🔴 THE NAME KEY IS CHECKED BY A FACT IT DID NOT PRODUCE. Where AP flags a ballot line as the
//   incumbent, `essentials.office_current_holder` independently names who holds that seat. The
//   two agreeing is evidence the key mapped the right district; a disagreement is a finding and
//   is printed, never smoothed.
import fs from 'node:fs';
import path from 'node:path';
import { maDistrictKey } from './ma-district-key.mjs';

const apDir = process.argv[2];
const ourFile = process.argv[3];
const out = process.argv[4];
if (!apDir || !ourFile || !out) {
  console.error('usage: analyse.mjs <ap-dir> <our-races.json> <output.json>');
  process.exit(2);
}

// AP ballot lines that are not people. Excluded BY ID, never by reading the name (CC_0381).
const PSEUDO_CANDIDATE_IDS = new Set(['100008', '100013']); // Total Write-ins · None of These Candidates
const OFFICE_CHAMBER = { Y: 'STATE_LOWER', Z: 'STATE_UPPER' };

const fold = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '');
// Accents folded, case dropped, and every space, hyphen, apostrophe and period removed. This is
// an EXACT comparison with the FIELD BOUNDARIES taken out, not a similarity one: AP splits
// "Rachel | Talbot | Ross" where our roster holds the surname as "Talbot Ross", and writes
// "Fluker Reid" where ours reads "Fluker-Reid". Neither is a different name.
const squash = (s) => fold(s).toLowerCase().replace(/[^a-z0-9]/g, '');

// A Massachusetts district name, reduced to its ordinal and its counties IN ORDER. Shared with
// verify-ma-soc.mjs so the two cannot drift apart — see ma-district-key.mjs.
const maNameKey = maDistrictKey;

// An optional 4th argument limits the run to named states, so one AP directory can hold every
// state the programme has fetched and each wave still reads only its own.
const only = (process.argv[5] || '').split(',').map((s) => s.trim().toUpperCase()).filter(Boolean);
const states = [...new Set(fs.readdirSync(apDir).map((f) => f.split('-')[0]))].sort().filter((s) => !only.length || only.includes(s));
const ourRaces = JSON.parse(fs.readFileSync(ourFile, 'utf8'));

const problems = [];
const races = [];
const summary = {};

for (const st of states) {
  const md = JSON.parse(fs.readFileSync(path.join(apDir, `${st}-metadata.json`), 'utf8'));
  const pr = JSON.parse(fs.readFileSync(path.join(apDir, `${st}-progress.json`), 'utf8'));
  const stLower = st.toLowerCase();

  for (const chamber of ['STATE_LOWER', 'STATE_UPPER']) {
    const officeID = chamber === 'STATE_LOWER' ? 'Y' : 'Z';
    const apIds = Object.keys(md).filter((k) => md[k].officeID === officeID);
    const ours = ourRaces.filter((r) => r.state === stLower && r.district_type === chamber);
    summary[`${st} ${chamber}`] = { ap: apIds.length, ours: ours.length };

    // ── keys ────────────────────────────────────────────────────────────────────────────────
    // 🔴 A NUMBERED DISTRICT IS NOT ALWAYS A NUMBER. Maryland splits a legislative district into
    //    LETTERED SUBDISTRICTS — "District 42A", `sldl:47B` — so a key that takes `(\d+)` off
    //    each side reads 42A and 42B as the same district 42, and ours (which ends in a letter)
    //    yields no key at all under `:(\d+)$`. Both sides therefore take an alphanumeric token,
    //    upper-cased, and the form is REQUIRED rather than guessed at: anything that is not
    //    "District <token>" is reported, never keyed on whatever digits happen to be in it.
    const apKey = (m) => {
      if (stLower === 'ma') return maNameKey(m.seatName);
      const n = String(m.seatName || '').match(/^District\s+([0-9]+[A-Za-z]?)$/i);
      return n ? `d${n[1].toUpperCase()}` : null;
    };
    const ourKey = (r) => {
      if (stLower === 'ma') return maNameKey(r.district_label);
      const n = String(r.ocd_id || '').match(/:([0-9]+[A-Za-z]?)$/);
      return n ? `d${n[1].toUpperCase()}` : null;
    };

    const apByKey = new Map();
    for (const id of apIds) {
      const k = apKey(md[id]);
      if (!k) { problems.push(`${st} ${chamber}: AP race ${id} "${md[id].seatName}" yields no key`); continue; }
      if (apByKey.has(k)) problems.push(`${st} ${chamber}: AP key "${k}" is not unique (${apByKey.get(k)} and ${id})`);
      apByKey.set(k, id);
    }
    const ourByKey = new Map();
    for (const r of ours) {
      const k = ourKey(r);
      if (!k) { problems.push(`${st} ${chamber}: our race ${r.race_id} "${r.district_label}" (${r.ocd_id}) yields no key`); continue; }
      if (ourByKey.has(k)) problems.push(`${st} ${chamber}: our key "${k}" is not unique (${ourByKey.get(k).race_id} and ${r.race_id})`);
      ourByKey.set(k, r);
    }
    for (const k of ourByKey.keys()) if (!apByKey.has(k)) problems.push(`${st} ${chamber}: OURS WITH NO AP RACE — "${ourByKey.get(k).district_label}" (key ${k})`);
    for (const k of apByKey.keys()) if (!ourByKey.has(k)) problems.push(`${st} ${chamber}: AP RACE WITH NO RACE OF OURS — "${md[apByKey.get(k)].seatName}" (key ${k})`);

    // ── ballot lines ────────────────────────────────────────────────────────────────────────
    for (const [k, r] of ourByKey) {
      const apId = apByKey.get(k);
      if (!apId) continue;
      const m = md[apId];
      const p = pr[apId];
      if (!p) { problems.push(`${st} ${chamber} ${k}: AP metadata has the race and progress does not`); continue; }

      // 🔴 THE TWO FILES DISAGREE ON SHAPE: metadata.candidates is a MAP, progress.candidates an
      //   ARRAY. Reading one as the other returns undefined for every candidate and looks like
      //   "no results".
      const mCands = m.candidates;
      if (Array.isArray(mCands)) { problems.push(`${st} ${chamber} ${k}: metadata.candidates is an ARRAY, expected a map`); continue; }
      const pCands = p.candidates;
      if (!Array.isArray(pCands)) { problems.push(`${st} ${chamber} ${k}: progress.candidates is not an ARRAY`); continue; }

      const byId = new Map(Object.values(mCands).map((c) => [String(c.candidateID), c]));
      const prById = new Map(pCands.map((c) => [String(c.candidateID), c]));
      for (const id of byId.keys()) if (!prById.has(id)) problems.push(`${st} ${chamber} ${k}: candidate ${id} in metadata and not in progress`);
      for (const id of prById.keys()) if (!byId.has(id)) problems.push(`${st} ${chamber} ${k}: candidate ${id} in progress and not in metadata`);

      const lines = [];
      for (let [id, c] of byId) {
        if (PSEUDO_CANDIDATE_IDS.has(id)) continue;
        const prc = prById.get(id) || {};
        // 🔴 AP MARKS A DECLARED WRITE-IN INSIDE THE SURNAME FIELD — "LaPointe (write-in)" — so
        //   the marker reaches `last_name` and the display name unless it is lifted out. It is a
        //   COLUMN of ours (`is_write_in`), not part of anybody's name.
        const writeIn = /\(write-?in\)/i.test([c.first, c.middle, c.last, c.suffix].filter(Boolean).join(' '));
        const clean = (s) => (s ? s.replace(/\s*\(write-?in\)\s*/i, '').trim() || null : null);
        c = { ...c, first: clean(c.first), middle: clean(c.middle), last: clean(c.last), suffix: clean(c.suffix) };
        const nameParts = [c.nickname || c.first, c.middle, c.last, c.suffix].filter(Boolean);
        lines.push({
          candidateID: id,
          is_write_in: writeIn,
          first: c.first || null,
          middle: c.middle || null,
          last: c.last || null,
          suffix: c.suffix || null,
          nickname: c.nickname || null,
          full_name: nameParts.join(' '),
          party: c.party || null,
          ap_incumbent: c.incumbent === true,
          ballotOrder: c.ballotOrder ?? null,
          voteCount: prc.voteCount ?? null,
          votePct: prc.votePct ?? null,
          winner: prc.winner || null,
        });
      }
      lines.sort((a, b) => (a.ballotOrder ?? 99) - (b.ballotOrder ?? 99));

      const called = m.raceCallStatus === 'Called';
      const winners = lines.filter((l) => l.winner === 'X');
      const allZero = lines.every((l) => (l.voteCount ?? 0) === 0);

      // The result each line gets. 🔴 A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM, NEVER
      // BECAUSE THEY ARE NOT THE WINNER — so an UNCALLED race writes no result at all.
      for (const l of lines) l.result = called ? (l.winner === 'X' ? 'won' : 'lost') : null;

      // The incumbent cross-check: AP's flag against our own roster, for this same office.
      let holder = null;
      const apIncumbents = lines.filter((l) => l.ap_incumbent);
      // 🔴 A MULTI-MEMBER DISTRICT HAS SEVERAL SITTING MEMBERS AND WE MODEL ONE HOLDER PER
      //    OFFICE. Maryland elects up to three delegates from one district on one race row, so
      //    AP rightly flags two or three incumbents while `office_current_holder` — one row per
      //    office by construction — names exactly one of them. That is not a disagreement, and
      //    the first version of this analyser reported all 41 such districts as problems.
      //    ▶ The rule is therefore: link the ONE AP incumbent our roster names, and leave every
      //    other incumbent on the ballot with politician_id NULL. They are real sitting members;
      //    we simply hold no office row for them to be the holder of.
      if (r.current_holder_id && apIncumbents.length) {
        const ourLast = squash(r.current_holder_last);
        const ourFirst = squash(r.current_holder_first);
        const ourFull = squash(r.current_holder_name);
        const rank = (l) => {
          const apLast = squash(l.last);
          const apFirst = squash(l.first);
          const apNick = squash(l.nickname);
          if (ourFull === squash(l.full_name)) return ['holder-exact-full-name', 0];
          if (ourLast === apLast && (ourFirst === apFirst || (apNick && ourFirst === apNick))) return ['holder-exact-first-last', 1];
          // A suffix stored inside our surname ("Schmidt, Jr." against AP's "Schmidt" + "Jr."),
          // or a compound surname one side prints whole ("Zermeño Moore" against "Moore").
          // Each is an exact comparison once that field artefact is removed, and each still
          // requires the FIRST name to agree exactly.
          const ourLastNoSuffix = ourLast.replace(/(jr|sr|ii|iii|iv)$/, '');
          const apWithSuffix = squash([l.last, l.suffix].filter(Boolean).join(''));
          if (ourFirst === apFirst && (ourLast === apWithSuffix || ourLastNoSuffix === apLast)) return ['holder-suffix-folded', 2];
          if (ourFirst === apFirst && apLast.length > 2 && ourLast.includes(apLast)) return ['holder-compound-surname', 3];
          // ⚠ AN INITIAL CAN LIVE IN THE FIRST-NAME FIELD. Our Nevada row reads first "Max E.",
          //    surname "Carter II", where AP splits "Max" / "Carter" / "II". The first token is
          //    identical and the remainder is a single initial, so this is the same field
          //    artefact as the two rungs above, met from the other side.
          const initialOnly = ourFirst.startsWith(apFirst) && ourFirst.length - apFirst.length <= 2;
          if (initialOnly && (ourLastNoSuffix === apLast || ourLast === apWithSuffix)) return ['holder-initial-in-first-name-field', 3];
          if (ourLast === apLast) return ['holder-surname-plus-roster', 4];
          return [null, 99];
        };
        const ranked = apIncumbents.map((l) => ({ l, r: rank(l) })).filter((x) => x.r[0]).sort((a, b) => a.r[1] - b.r[1]);
        if (ranked.length) {
          const { l, r: [basis] } = ranked[0];
          holder = {
            politician_id: r.current_holder_id, our_name: r.current_holder_name,
            ap_name: l.full_name, candidateID: l.candidateID, basis, link: true,
            ap_incumbents: apIncumbents.length,
          };
        } else {
          holder = {
            politician_id: r.current_holder_id, our_name: r.current_holder_name,
            ap_name: apIncumbents.map((x) => x.full_name).join(' / '), candidateID: null,
            basis: 'holder-DISAGREES', link: false, ap_incumbents: apIncumbents.length,
          };
          problems.push(`${st} ${chamber} ${k}: our holder "${r.current_holder_name}" is not among AP's incumbent(s) ${holder.ap_name} — nothing is linked in this race`);
        }
      }
      if (apIncumbents.length > r.seats) {
        problems.push(`${st} ${chamber} ${k}: AP flags ${apIncumbents.length} incumbents for ${r.seats} seat(s)`);
      }

      races.push({
        state: stLower,
        chamber,
        key: k,
        our: {
          race_id: r.race_id, office_id: r.office_id, office_title: r.office_title,
          district_label: r.district_label, ocd_id: r.ocd_id, seats: r.seats,
          existing_candidates: Number(r.candidates),
          current_holder_id: r.current_holder_id, current_holder_name: r.current_holder_name,
        },
        ap: {
          raceID: apId, seatName: m.seatName, officeName: m.officeName,
          raceCallStatus: m.raceCallStatus, uncontested: m.uncontested === true,
          rankedChoice: m.rankedChoice === true, eevp: p.eevp ?? null,
          calledAt: pCands.find((c) => c.winner === 'X')?.calledAt || null,
        },
        called, winners: winners.length, allZero, holder, lines,
      });

      if (called && winners.length !== r.seats) {
        problems.push(`${st} ${chamber} ${k}: ${winners.length} winner(s) for seats=${r.seats}`);
      }
      // 🔴 A TOP-VOTE-GETTER CROSS-CHECK OVER AN ALL-ZERO BALLOT COMPARES NOTHING. Record where
      //   AP had an ordering decision to make and no votes to make it on.
      if (called && allZero && lines.length > winners.length) {
        problems.push(`${st} ${chamber} ${k}: all votes zero and ${lines.length} candidates for ${winners.length} winner(s) — AP ordered this without a count`);
      }
      if (m.rankedChoice) problems.push(`${st} ${chamber} ${k}: ranked-choice race`);
    }
  }
}

fs.writeFileSync(out, JSON.stringify({ generated: new Date().toISOString(), apDir, ourFile, races }, null, 1));

// ── report ────────────────────────────────────────────────────────────────────────────────────
console.log(`matched ${races.length} race(s) -> ${out}\n`);
console.log('state chamber        AP  ours matched  empty  called  uncontested  rows  won  lost  holder-link');
for (const [k, v] of Object.entries(summary)) {
  const rs = races.filter((r) => `${r.state.toUpperCase()} ${r.chamber}` === k);
  const empty = rs.filter((r) => r.our.existing_candidates === 0);
  const rows = empty.flatMap((r) => r.lines);
  console.log(
    `${k.padEnd(20)} ${String(v.ap).padStart(3)} ${String(v.ours).padStart(5)} ${String(rs.length).padStart(7)}` +
    ` ${String(empty.length).padStart(6)} ${String(rs.filter((r) => r.called).length).padStart(7)}` +
    ` ${String(rs.filter((r) => r.ap.uncontested).length).padStart(12)} ${String(rows.length).padStart(5)}` +
    ` ${String(rows.filter((l) => l.result === 'won').length).padStart(4)} ${String(rows.filter((l) => l.result === 'lost').length).padStart(5)}` +
    ` ${String(empty.filter((r) => r.holder).length).padStart(12)}`,
  );
}

const skipped = races.filter((r) => r.our.existing_candidates > 0);
if (skipped.length) {
  console.log(`\n${skipped.length} race(s) ALREADY CARRY CANDIDATES and are not touched:`);
  for (const r of skipped) console.log(`  ${r.state} ${r.our.district_label} — ${r.our.existing_candidates} row(s)`);
}

const linked = races.filter((r) => r.our.existing_candidates === 0 && r.holder);
const byBasis = {};
for (const r of linked) (byBasis[r.holder.basis] ??= []).push(r);
console.log('\nincumbent links, by basis:');
for (const [b, rs] of Object.entries(byBasis)) console.log(`  ${b.padEnd(26)} ${String(rs.length).padStart(3)}`);
for (const b of ['holder-surname-plus-roster', 'holder-DISAGREES']) {
  for (const r of byBasis[b] || []) {
    console.log(`  ${b}: ${r.state} ${r.chamber} ${r.our.district_label} — AP "${r.holder.ap_name}" vs ours "${r.holder.our_name}"`);
  }
}

if (problems.length) {
  console.log(`\n🔴 ${problems.length} problem(s):`);
  for (const p of problems) console.log(`  ${p}`);
} else {
  console.log('\nno problems.');
}
