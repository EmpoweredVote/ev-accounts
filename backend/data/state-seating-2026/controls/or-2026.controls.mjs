/**
 * Oregon 2026 — the control suite that was run against `CC_0491`, `CC_0492` and `CC_0493` on
 * 2026-11-23, before they were applied. **18 of 18 went red; the negative control passed.**
 *
 *   node scripts/run-migration-controls.mjs \
 *     ../data/state-seating-2026/controls/or-2026.controls.mjs
 *
 * ⚠ **THIS SUITE CANNOT BE RE-RUN NOW, AND THAT IS CORRECT.** All three files are applied, so the
 *   negative control fails and the harness refuses to report — rather than printing eighteen
 *   triumphs. It is kept as the **record of what was tested**, and as the shape to copy next.
 *   Use `--check` to validate the needles against the migrations without touching the database.
 *
 *   🔴 **MEASURED, NOT ASSUMED — AND IT IS NOT THE GATE THIS LINE FIRST CLAIMED.** A first draft
 *   of this header said `CC_0493`'s P2 ("have I already run?") would fire. Run on 2026-11-23
 *   after the apply, what actually fires is **`CC_0491`'s P1**: *"0 Oregon legislative seats are
 *   pending, expected 75"*. `CC_0491` runs first, and its **P0 passes VACUOUSLY** — P0 asks
 *   whether any of the selected offices already carries a date row, and once the seats have left
 *   `office_pending_winner` the selection is empty, so there is nothing for P0 to find.
 *   ▶ **AN "HAVE I ALREADY RUN?" GATE BUILT OVER THE SELECTION GOES BLIND THE MOMENT THE
 *   SELECTION EMPTIES.** The seating file's P2 avoids this by keying on `source LIKE '%CC_0493%'`,
 *   which is a fact about rows this file WROTE rather than about rows it would select. The dates
 *   file has no equivalent, and its P1 is what catches a second run — with a message about the
 *   data moving, which is true of the view and misleading about the world.
 *
 * 🔴 **WHAT THE OUTCOMES WERE, INCLUDING THE TWO THAT MISSED.** The register's Oregon section has
 *   the table; the two worth remembering:
 *   • **C1 fired on assertion 1, not 3b.** Assertion 1 is a strict equality on the right date, so
 *     ANY wrong date trips it first — 3b's "no seat carries a wrong day" arm is an unreachable
 *     backstop. Its arithmetic arms are reachable and were tested by C2 and C3.
 *   • **C17 fired on P10, not assertion 10.** Seating the Governor beforehand makes 119 terms on
 *     2027-01-11, and the Washington pre-image gate catches that first. 🟢 That is a finding, not
 *     a nuisance: the gate written to measure one state's rows also catches an unexpected term on
 *     that day from any source.
 *
 * 🟢🟢 **C11 AND C11b ARE THE COMPLEMENTARY-GATES PROOF, RUN ON ONE INPUT.** The same vacancy,
 *   two selections. With the library's published selection the digest expression goes NULL and
 *   `string_agg` drops the row — the COVERAGE gate fires. With `AND och.politician_id IS NOT NULL`
 *   the value becomes `false` instead and the DIGEST gate fires on a changed hash. Neither gate
 *   can be made to see the other's fault. **Keep both, even where neither can fire today.**
 */
const M = '../../../migrations';

export default {
  name: 'Oregon 2026 — CC_0491 / CC_0492 / CC_0493',
  files: {
    dates: new URL(`${M}/CC_0491_or_2026_swearing_in_dates.sql`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'),
    people: new URL(`${M}/CC_0492_or_2026_seed_13_winners_link_2.sql`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'),
    seating: new URL(`${M}/CC_0493_or_legislature_2026_seat_75_winners.sql`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'),
  },
  cleanChain: ['dates', 'people', 'seating'],
  controls: [
    // ── CC_0491, the dates file ───────────────────────────────────────────────────────────────
    {
      id: 'C1',
      label: "write 2027-01-04 — the first Monday, Oregon's pre-1961 rule",
      aimedAt: 'assertion 3b',   // fired on assertion 1: an unreachable backstop. Recorded.
      chain: [{ tamper: 'dates', find: "       DATE '2027-01-11',\n       'statute',", replace: "       DATE '2027-01-04',\n       'statute'," }],
    },
    {
      id: 'C2',
      label: 'the convening day computed as the third Monday + 2',
      aimedAt: 'assertion 3b',
      chain: [{ tamper: 'dates', find: 'convene    := third_mon + 1;', replace: 'convene    := third_mon + 2;' }],
    },
    {
      id: 'C3',
      label: 'the second Monday computed as the first Monday + 14',
      aimedAt: 'assertion 3a',
      chain: [{ tamper: 'dates', find: '  second_mon := first_mon + 7;', replace: '  second_mon := first_mon + 14;' }],
    },
    {
      // 🔴 THE WASHINGTON COLLISION. Making the gate blind to `wa` must report 118 STRANGERS,
      //    which is the evidence it was reading real rows rather than passing over an empty set.
      id: 'C4',
      label: "P5 stops recognising Washington's 118 rows on 2027-01-11",
      aimedAt: 'P5',
      chain: [{
        tamper: 'dates',
        find: "     AND NOT (lower(d.state) = 'wa'\n              AND d.district_type IN ('STATE_LOWER','STATE_UPPER')\n              AND s.rule_id = 'wa-rcw-44-04-021-second-monday-january');",
        replace: "     AND NOT (lower(d.state) = 'zz'\n              AND d.district_type IN ('STATE_LOWER','STATE_UPPER')\n              AND s.rule_id = 'wa-rcw-44-04-021-second-monday-january');",
      }],
    },
    {
      // Oregon's federal exclusion needed NATIONAL_UPPER as well as NATIONAL_LOWER — Utah's did
      // not. Measured, not copied. This proves the extra arm is load-bearing.
      id: 'C5',
      label: 'assertion 7 stops excusing the 7th federal row (the Senate seat)',
      aimedAt: 'assertion 7',
      chain: [{
        tamper: 'dates',
        find: "     AND NOT (dd.district_type IN ('NATIONAL_LOWER', 'NATIONAL_UPPER')\n              AND s.swearing_in_date = DATE '2027-01-03'\n              AND s.rule_id = 'us-const-amend-xx-1');",
        replace: "     AND NOT (dd.district_type IN ('NATIONAL_LOWER')\n              AND s.swearing_in_date = DATE '2027-01-03'\n              AND s.rule_id = 'us-const-amend-xx-1');",
      }],
    },
    {
      // 🔴 THE KOTEK TRAP — the gate must be reading the real Governor row, not asserting at it.
      id: 'C6',
      label: 'assertion 5 expects the Governor term to start on the first Monday of 2023',
      aimedAt: 'assertion 5',
      chain: [{ tamper: 'dates', find: "kotek_expected CONSTANT date := DATE '2023-01-09';", replace: "kotek_expected CONSTANT date := DATE '2023-01-02';" }],
    },

    // ── CC_0492, the people file ──────────────────────────────────────────────────────────────
    {
      id: 'C7',
      label: 'House District 27 linked to Beth Helfrich, who holds a North Carolina seat',
      aimedAt: 'P4',
      chain: ['dates', {
        tamper: 'people',
        find: "'State House District 27',  '40e2b73e-4f5e-4f1a-919f-da47a9f5002d', 'b77caa26-b55a-4d98-a74c-cb210542b16e', 'Tammy Carpenter',    'Tammy',    'Carpenter',  false",
        replace: "'State House District 27',  '40e2b73e-4f5e-4f1a-919f-da47a9f5002d', 'cbbf5ae6-0793-46fb-ba4f-e6e3ffe90849', 'Tammy Carpenter',    'Tammy',    'Carpenter',  false",
      }],
    },
    {
      // Or. Const. Art. IV § 6(5) + the Chief Clerk's pairing: SD N = HD 2N-1 + HD 2N.
      id: 'C8',
      label: 'P6 pairs Senate district N with House districts 2N+1 and 2N+2',
      aimedAt: 'P6',
      chain: ['dates', { tamper: 'people', find: '  lo := 2 * sd - 1;\n  hi := 2 * sd;', replace: '  lo := 2 * sd + 1;\n  hi := 2 * sd + 2;' }],
    },
    {
      id: 'C9',
      label: "Hank Sanders created under Bernie Sanders's name",
      aimedAt: 'P3',
      chain: ['dates', {
        tamper: 'people',
        find: "'193b32fc-7470-4447-81eb-548a24e4e4f0', 'Hank Sanders',       'Hank',     'Sanders',    true",
        replace: "'193b32fc-7470-4447-81eb-548a24e4e4f0', 'Hank Sanders',       'Bernie',   'Sanders',    true",
      }],
    },

    // ── CC_0493, the seating file ─────────────────────────────────────────────────────────────
    {
      id: 'C10',
      label: "Senate District 16's winner row re-pointed at another person",
      aimedAt: 'P1 digest',
      chain: ['dates', 'people', {
        sql: `UPDATE essentials.race_candidates rc
   SET politician_id = '701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c'
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03' AND rc.result = 'won'
   AND lower(d.state) = 'or' AND d.label = 'State Senate District 16';`,
      }, 'seating'],
    },
    {
      // 🔴🔴 THE COVERAGE GATE. A seat loses its holder AND the library's published selection is
      //    used (no `och.politician_id IS NOT NULL`), so is_reelection goes NULL and string_agg
      //    drops the row. Two changes, but ONE fault model: the published template on real data.
      id: 'C11',
      label: "a seat falls vacant AND the library's published selection is used",
      aimedAt: 'P1 coverage',
      chain: ['dates', 'people', {
        sql: `UPDATE essentials.office_terms t
   SET term_end = DATE '2026-11-20', how_ended = 'resigned'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'or' AND d.label = 'State House District 42' AND t.term_end IS NULL;`,
      }, {
        tamper: 'seating',
        find: `       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,`,
        replace: `       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,`,
      }],
    },
    {
      // The SAME vacancy with the fix in place: the value changes rather than vanishing, so the
      // DIGEST gate catches it instead. Neither gate can see the other's fault.
      id: 'C11b',
      label: 'the same vacancy, with the IS NOT NULL fix in place',
      aimedAt: 'P1 digest',
      chain: ['dates', 'people', {
        sql: `UPDATE essentials.office_terms t
   SET term_end = DATE '2026-11-20', how_ended = 'resigned'
  FROM essentials.offices o, essentials.districts d
 WHERE t.office_id = o.id AND d.id = o.district_id
   AND lower(d.state) = 'or' AND d.label = 'State House District 42' AND t.term_end IS NULL;`,
      }, 'seating'],
    },
    {
      id: 'C12',
      label: "assertion 3 stops recognising Washington's 118 terms",
      aimedAt: 'assertion 3',
      chain: ['dates', 'people', {
        tamper: 'seating',
        find: "     AND NOT (lower(d.state) = 'wa' AND d.district_type IN ('STATE_LOWER','STATE_UPPER'))\n     AND NOT (lower(d.state) = 'or' AND d.district_type IN ('STATE_LOWER','STATE_UPPER'));",
        replace: "     AND NOT (lower(d.state) = 'zz' AND d.district_type IN ('STATE_LOWER','STATE_UPPER'))\n     AND NOT (lower(d.state) = 'or' AND d.district_type IN ('STATE_LOWER','STATE_UPPER'));",
      }],
    },
    {
      id: 'C13',
      label: "Tammy Carpenter's Beaverton school term closed before the file runs",
      aimedAt: 'P8',
      chain: ['dates', 'people', {
        sql: `UPDATE essentials.office_terms
   SET term_end = DATE '2026-11-22', how_ended = 'resigned'
 WHERE politician_id = 'b77caa26-b55a-4d98-a74c-cb210542b16e' AND term_end IS NULL;`,
      }, 'seating'],
    },
    {
      id: 'C14',
      label: 'assertion 11 reads Beth Helfrich instead of Jeff',
      aimedAt: 'assertion 11',
      chain: ['dates', 'people', {
        tamper: 'seating',
        find: "   WHERE t.politician_id = '701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c'\n     AND lower(d.state) = 'or' AND d.label = 'State House District 52';",
        replace: "   WHERE t.politician_id = 'cbbf5ae6-0793-46fb-ba4f-e6e3ffe90849'\n     AND lower(d.state) = 'or' AND d.label = 'State House District 52';",
      }],
    },
    {
      id: 'C15',
      label: "House District 42's result becomes certified (Ruling B)",
      aimedAt: 'P11',
      chain: ['dates', 'people', {
        sql: `UPDATE essentials.race_candidates rc
   SET result_certainty = 'certified'
  FROM essentials.races r, essentials.elections e, essentials.offices o, essentials.districts d
 WHERE rc.race_id = r.id AND e.id = r.election_id AND o.id = r.office_id AND d.id = o.district_id
   AND e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'or' AND d.label = 'State House District 42';`,
      }, 'seating'],
    },
    {
      id: 'C16',
      label: 'the written term source stops saying "called, not certified"',
      aimedAt: 'assertion 15',
      chain: ['dates', 'people', {
        tamper: 'seating',
        find: "|| 'called, not certified, when this ran — Oregon canvasses on the 37th '",
        replace: "|| 'when this ran — Oregon canvasses on the 37th '",
      }],
    },
    {
      id: 'C17',
      label: "the Governor seated on the legislature's day before the file runs",
      aimedAt: 'assertion 10',   // fired on P10: the Washington pre-image gate catches 119 first.
      chain: ['dates', 'people', {
        sql: `SELECT essentials.seat_officeholder(
  p_office_id        => '780f76cd-2ec0-42fc-bb67-74a8911ca1c8',
  p_politician_id    => (SELECT rc.politician_id FROM essentials.race_candidates rc
                           JOIN essentials.races r ON r.id = rc.race_id
                           JOIN essentials.elections e ON e.id = r.election_id
                          WHERE r.office_id = '780f76cd-2ec0-42fc-bb67-74a8911ca1c8'
                            AND e.election_date = DATE '2026-11-03' AND rc.result = 'won'
                            AND rc.politician_id IS NOT NULL LIMIT 1),
  p_term_start       => DATE '2027-01-11',
  p_source           => 'CONTROL C17 — must never happen',
  p_how_started      => 'elected',
  p_start_precision  => 'day',
  p_how_ended_prev   => 'term_expired',
  p_allow_reelection => true);`,
      }, 'seating'],
    },
  ],
};
