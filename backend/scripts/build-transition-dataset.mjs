#!/usr/bin/env node
/**
 * build-transition-dataset.mjs — turn the status script's output into the two CSVs the
 * transition tracker renders.
 *
 * WHY A SEPARATE SCRIPT. election-transition-status.mjs answers "what is the state of every
 * race". This answers "which wave does it belong to", which is a scheduling question and needs
 * one extra fact the status script has no business knowing: whether a local office's body has a
 * history of DECEMBER term starts.
 *
 * 🔴 WAVE 3 IS ORDERED BY DEADLINE, NOT BY TIER SIZE. 175 of 236 dated local terms begin in
 * December, the earliest on 1 December -- before the federal tier's statutory 2027-01-03. Those
 * seats run third, ahead of the much larger state tier. Working Federal -> State -> Local in
 * tier order would let the nearest deadline in the program pass while the work sat queued.
 *
 * ⚠ The December dates are inferred from each body's OWN HISTORICAL rows, so they are evidence
 * of that body's convention, not proof of the 2026 date. They decide wave order only; nothing
 * is seated from them.
 */
import 'dotenv/config';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';
import { buildStatus } from './election-transition-status.mjs';

const WAVE_LABEL = {
  1: 'Wave 1 — Senate',
  2: 'Wave 2 — House',
  3: 'Wave 3 — December locals',
  4: 'Wave 4 — State',
  5: 'Wave 5 — Remaining locals',
};

const STATE_LABEL = {
  1: 'Not looked at',
  2: 'Called',
  3: 'Certified',
  4: 'Seated, awaiting swearing-in',
  5: 'Sworn in',
};

function csv(rows, columns) {
  const esc = (v) => {
    const s = v === null || v === undefined ? '' : String(v);
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  return [columns.join(','), ...rows.map((r) => columns.map((c) => esc(r[c])).join(','))].join('\n');
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
try {
  const status = await buildStatus(pool);

  // 🔴 WAVE 3 IS NOW DRAWN FROM REAL DATES, NOT FROM A HISTORICAL MONTH.
  // `essentials.office_swearing_in` (piece 4, CC_0344) holds a cited handover date per office.
  // A local office belongs in wave 3 when its handover falls BEFORE the federal tier's
  // statutory 2027-01-03 — which is the question wave 3 was always asking.
  const FEDERAL_SWEARING_IN = '2027-01-03';
  const { rows: dated } = await pool.query(
    `SELECT office_id, swearing_in_date
       FROM essentials.office_swearing_in
      WHERE election_date = DATE '2026-11-03'
        AND swearing_in_date < DATE '${FEDERAL_SWEARING_IN}'`);
  const earlyOffices = new Set(dated.map((x) => x.office_id));

  // 🔴 THE FALLBACK IS THE OLD HEURISTIC AND IT IS KNOWN TO BE CONTAMINATED. It is kept only
  // for offices piece 4 has not reached yet (everything outside California, as of 2026-11-04),
  // because having them in the wrong wave is better than having them in no wave.
  //
  // Two measured ways it lies:
  //   * 118 of ~140 dated California SCHOOL terms read `2022-12-01` with
  //     `start_precision = 'month'` — this repo's encoding of "December, day unknown". Reading
  //     the DAY turned a precision artifact into the programme's deadline. The real statutory
  //     date is the second Friday, 2026-12-11.
  //   * It is SILENT, not false, for an office with no dated term at all. 129 of California's
  //     337 local offices had none, so the heuristic reported nothing about 38% of the set and
  //     that read as "not December".
  // ▶ A historical month finds seats worth checking. It is not evidence of the next term.
  const { rows: dec } = await pool.query(`
    SELECT DISTINCT o.id
      FROM essentials.elections e
      JOIN essentials.races r ON r.election_id = e.id
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.office_terms t ON t.office_id = o.id
     WHERE e.election_date = '2026-11-03'
       AND d.district_type IN ('SCHOOL','LOCAL','COUNTY','LOCAL_EXEC')
       AND EXTRACT(month FROM t.term_start) = 12`);
  const decemberOffices = new Set(dec.map((x) => x.id));

  // Did piece 4 reach this office at all, and with what strength? A dated office is decided by
  // its date; an undated one falls back. Kept separate from `earlyOffices` so "its date says
  // January" and "we have no date" cannot collapse into the same answer.
  //
  // 🔴 `basis` TRAVELS WITH THE DATE ONTO THE PAGE. An 'estimated' row is NOT a handover date —
  // it is a record that one is owed, carrying the statutory floor. 106 California city seats are
  // in that state, and a reader who sees only the date would read them as settled.
  const { rows: known } = await pool.query(
    `SELECT office_id, to_char(swearing_in_date, 'YYYY-MM-DD') AS d, basis AS b
       FROM essentials.office_swearing_in WHERE election_date = DATE '2026-11-03'`);
  const swearingIn = new Map(known.map((x) => [x.office_id, { d: x.d, b: x.b }]));
  const datedOffices = new Set(known.map((x) => x.office_id));

  const waveOf = (s) => {
    if (s.districtType === 'NATIONAL_UPPER') return 1;
    if (s.districtType === 'NATIONAL_LOWER') return 2;
    if (s.level === 'local') {
      // A real date decides it. Only an office piece 4 has not reached falls back.
      if (datedOffices.has(s.officeId)) return earlyOffices.has(s.officeId) ? 3 : 5;
      return decemberOffices.has(s.officeId) ? 3 : 5;
    }
    if (s.level === 'state') return 4;
    return 5;
  };

  const seats = status.seats.map((s) => {
    const wave = waveOf(s);
    return {
      wave,
      wave_label: WAVE_LABEL[wave],
      level: s.level,
      state: s.state ?? '',
      office: s.title ?? s.positionName ?? '',
      contest: s.positionName ?? '',
      seat_state: s.seatState,
      seat_state_label: STATE_LABEL[s.seatState],
      current_holder: s.currentHolder?.name ?? '',
      winner: s.winner?.name ?? '',
      certainty: s.resultCertainty ?? '',
      blocked_no_candidates: s.flags.noCandidateRows ? 1 : 0,
      blocked_no_office: s.flags.noOffice ? 1 : 0,
      needs_headshot: s.flags.noHeadshot ? 1 : 0,
      needs_stances: s.flags.noStances ? 1 : 0,
      holder_term_ends: s.currentHolderTermEnd ?? '',
      swearing_in: swearingIn.get(s.officeId)?.d ?? '',
      swearing_in_basis: swearingIn.get(s.officeId)?.b ?? '',
      race_id: s.raceId,
    };
  });

  const byWave = new Map();
  for (const s of seats) {
    const k = s.wave;
    const w = byWave.get(k) ?? {
      wave: k, wave_label: WAVE_LABEL[k], total: 0,
      not_looked_at: 0, called: 0, certified: 0, seated: 0, sworn_in: 0,
      blocked: 0, needs_headshot: 0, needs_stances: 0,
    };
    w.total += 1;
    w[['', 'not_looked_at', 'called', 'certified', 'seated', 'sworn_in'][s.seat_state]] += 1;
    if (s.blocked_no_candidates || s.blocked_no_office) w.blocked += 1;
    if (s.needs_headshot) w.needs_headshot += 1;
    if (s.needs_stances) w.needs_stances += 1;
    byWave.set(k, w);
  }
  const waves = [...byWave.values()].sort((a, b) => a.wave - b.wave);

  // Anchored on this file, not on cwd: a cwd-relative write lands somewhere else, or throws,
  // whenever the script is run from anywhere but backend/.
  const outDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'data', 'transition-tracker');
  mkdirSync(outDir, { recursive: true });
  // The handover calendar: what piece 4 established, one row per date.
  // 🔴 SEATABLE AND OWED ARE COUNTED SEPARATELY AND MUST STAY THAT WAY. Summing them would
  // report 106 California city seats as having a handover date when what they have is a
  // statutory floor and an open question.
  const { rows: calendar } = await pool.query(`
    SELECT to_char(s.swearing_in_date, 'YYYY-MM-DD') AS handover_date,
           to_char(max(s.window_end_date), 'YYYY-MM-DD') AS window_ends,
           count(*)                                        AS offices,
           count(*) FILTER (WHERE s.basis IN ('statute','published')) AS seatable,
           count(*) FILTER (WHERE s.basis = 'estimated')              AS owed_a_date,
           string_agg(DISTINCT s.rule_id, ' · ' ORDER BY s.rule_id)   AS authorities
      FROM essentials.office_swearing_in s
     WHERE s.election_date = DATE '2026-11-03'
     GROUP BY 1 ORDER BY 1`);

  writeFileSync(join(outDir, 'seats.csv'), csv(seats, Object.keys(seats[0])));
  writeFileSync(join(outDir, 'waves.csv'), csv(waves, Object.keys(waves[0])));
  writeFileSync(join(outDir, 'handovers.csv'),
    csv(calendar, ['handover_date', 'window_ends', 'offices', 'seatable', 'owed_a_date', 'authorities']));
  console.log(`seats.csv ${seats.length} rows · waves.csv ${waves.length} rows · handovers.csv ${calendar.length} rows`);
  console.log(waves.map((w) => `${w.wave_label}: ${w.total} (blocked ${w.blocked})`).join('\n'));
  console.log(calendar.map((c) => `${c.handover_date}: ${c.offices} (${c.seatable} seatable, ${c.owed_a_date} owed)`).join('\n'));
} finally {
  await pool.end();
}
