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
import { writeFileSync } from 'node:fs';
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

  // Offices whose body has a December term-start precedent → wave 3.
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

  const waveOf = (s) => {
    if (s.districtType === 'NATIONAL_UPPER') return 1;
    if (s.districtType === 'NATIONAL_LOWER') return 2;
    if (s.level === 'local') return decemberOffices.has(s.officeId) ? 3 : 5;
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

  writeFileSync('data/transition-tracker/seats.csv', csv(seats, Object.keys(seats[0])));
  writeFileSync('data/transition-tracker/waves.csv', csv(waves, Object.keys(waves[0])));
  console.log(`seats.csv ${seats.length} rows · waves.csv ${waves.length} rows`);
  console.log(waves.map((w) => `${w.wave_label}: ${w.total} (blocked ${w.blocked})`).join('\n'));
} finally {
  await pool.end();
}
