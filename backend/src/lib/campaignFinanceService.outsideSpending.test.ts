import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// getOutsideSpendingForPolitician reports independent-expenditure committees that spent in a
// politician's race. It was written for `la_socrata` and hardcoded that source system into the
// CTE that gathers a committee's rows, while the CTE that LISTS the committees carried no such
// filter — so a confirmed `ie_committee` link from any other system rendered as a committee card
// with an empty name and $0. Measured on prod 2026-10-09 while adjudicating the CAL-ACCESS
// surname buckets: two real IE committees (Melissa Hurtado's business coalition, John Erickson's
// UNITE HERE Local 11 committee) had to be parked at `not_applicable` for exactly this reason.
//
// ⚠ THE NAIVE FIX IS WRONG, THOUGH NOT FOR THE REASON IT FIRST LOOKED. `la_socrata` reuses
// CAL-ACCESS filer ids, so a shared id is the SAME committee, not a collision — measured on prod
// 2026-10-09: of 36 shared ids carrying a name in both systems, 36 name the same committee and
// none collide. The hazard is DOUBLE COUNTING. The gathering CTE joins on external_id alone, so
// deleting the source_system filter sums both systems' ingests of one committee: measured, 193
// ids are shared and 3 carry contributions in both systems (1349095 is Blumenfield 2013, 446 rows
// via cal_access against 470 via la_socrata — the same money, twice). So the source system is
// CORRELATED between the CTEs. `does not sum one committee across source systems` is the control.
//
// The fake pool models the two tables and INTERPRETS each query's own predicates — which
// source_system values it admits, and which `notes` keys it reads, in order — so these tests
// assert on what the service returns rather than on SQL text, and stay honest across a rewrite.
// ---------------------------------------------------------------------------

interface Source {
  id: string;
  politician: string;
  source_system: string;
  external_id: string;
  source_type: string;
  research_status: string;
  support_oppose: 'support' | 'oppose' | null;
  /** RAW TEXT, exactly as the column stores it — `notes` is TEXT, never jsonb. See parseNotes. */
  notes: string;
}
interface Contrib { id: string; source: string; amount: number; donor: string }

let sources: Source[] = [];
let contribs: Contrib[] = [];

const POL = 'pol-1';

/** Which source_system values the query's gathering CTE admits for a given declaring row. */
function admitsSystem(sql: string, declaring: Source): (s: Source) => boolean {
  const literal = sql.match(/ps\.source_system\s*=\s*'([a-z_]+)'/);
  if (literal) return (s) => s.source_system === literal[1];
  if (/ps\.source_system\s*=\s*\w+\.source_system/.test(sql)) {
    return (s) => s.source_system === declaring.source_system;
  }
  return () => true;
}

/** The `notes` keys the query reads, in the order it reads them. */
function notesKeys(sql: string): string[] {
  return [...sql.matchAll(/->>\s*'(\w+)'/g)].map((m) => m[1]);
}

/**
 * Read `notes` the way POSTGRES would, given what this query actually asks of it.
 *
 * 🔴 THIS IS THE GAP THAT LET THE OUTAGE SHIP. The fake previously modelled `notes` as an
 * already-parsed `Record<string, string>`, so no test could express the only thing that was
 * wrong: the column is TEXT, and the house convention appends a later note after the JSON with
 * a ` | ` separator. `CC_0225` did exactly that to all four published rows, every one of them
 * read by this query, and a bare `notes::jsonb` raised 22P02 — taking the whole /summary
 * endpoint to HTTP 500 for Newsom, Hurtado, Gipson and Erickson.
 *
 * So the fake now throws the way the database throws. A query that casts without guarding gets
 * the real error; a query that guards gets the committee name. That makes
 * `survives a note with an appended ` | ` suffix` a CONTROL: delete the guard from the service
 * and it fails with the production error rather than passing quietly.
 */
function parseNotes(sql: string, raw: string): Record<string, string> | null {
  const tryParse = (t: string): Record<string, string> | null => {
    try {
      const v: unknown = JSON.parse(t);
      return v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, string>) : null;
    } catch {
      return null;
    }
  };

  const whole = tryParse(raw);
  if (whole) return whole;

  // Unguarded `notes::jsonb` on text that is not JSON is the production failure, verbatim.
  if (!/IS JSON OBJECT/i.test(sql)) {
    throw Object.assign(new Error('invalid input syntax for type json'), { code: '22P02' });
  }

  // The guard: fall back to the prefix before the first `} |`, else NULL — never an error.
  const cut = raw.indexOf('} |');
  return cut === -1 ? null : tryParse(raw.slice(0, cut + 1));
}

/**
 * ADR 0008: the query withholds a committee whose DIRECTION is unknown. The fake honours that
 * only when the SQL actually asks for it, so deleting the predicate from the service makes
 * `withholds a confirmed IE committee that has no direction` fail rather than silently pass.
 */
function declaredIeLinks(sql: string, politicianId: string): Source[] {
  const requiresDirection = /support_oppose\s+IS\s+NOT\s+NULL/i.test(sql);
  return sources.filter(
    (s) =>
      s.politician === politicianId &&
      s.source_type === 'ie_committee' &&
      s.research_status === 'confirmed' &&
      (!requiresDirection || s.support_oppose != null)
  );
}

/** Every source row the query would gather for each declared committee. */
function gathered(sql: string, politicianId: string) {
  return declaredIeLinks(sql, politicianId).map((declaring) => {
    const admits = admitsSystem(sql, declaring);
    const rows = sources.filter((s) => s.external_id === declaring.external_id && admits(s));
    const keys = notesKeys(sql);
    // Only the TOTALS query reads `notes`; the top-donors query never touches it, so it must not
    // be held to the guard it has no reason to carry.
    const parsed = keys.length > 0 ? parseNotes(sql, declaring.notes) : null;
    const label = keys.map((k) => parsed?.[k]).find((v) => v != null) ?? null;
    return { declaring, rows, label };
  });
}

const query = vi.fn(async (sql: string, params: unknown[] = []) => {
  const politicianId = params[0] as string;

  if (sql.includes("'ie_committee'")) {
    const groups = gathered(sql, politicianId);

    // the top-donors query
    if (/donor_name_normalized\s+AS\s+donor_name/i.test(sql)) {
      const rows: Array<{ cmt_id: string; donor_name: string; amount: string }> = [];
      for (const g of groups) {
        const byDonor = new Map<string, number>();
        for (const c of contribs.filter((c) => g.rows.some((r) => r.id === c.source))) {
          byDonor.set(c.donor, (byDonor.get(c.donor) ?? 0) + c.amount);
        }
        for (const [donor_name, amount] of [...byDonor].sort((a, b) => b[1] - a[1])) {
          rows.push({ cmt_id: g.declaring.external_id, donor_name, amount: String(amount) });
        }
      }
      return { rows };
    }

    // the totals query
    return {
      rows: groups.map((g) => {
        const cs = contribs.filter((c) => g.rows.some((r) => r.id === c.source));
        return {
          cmt_id: g.declaring.external_id,
          cmt_nm: g.label,
          support_oppose: g.declaring.support_oppose,
          total_amount: String(cs.reduce((s, c) => s + c.amount, 0)),
          contribution_count: String(cs.length),
        };
      }),
    };
  }

  // Everything else answers empty, which drives getSummary down its zero-state path —
  // the shortest route to the outside-spending block.
  return { rows: [] };
});

vi.mock('./db.js', () => ({ pool: { query: (sql: string, params?: unknown[]) => query(sql, params) } }));

import { getSummary } from './campaignFinanceService.js';

beforeEach(() => {
  sources = [];
  contribs = [];
  query.mockClear();
});

/**
 * `notes` may be given as an object (serialised to JSON, the common case) or as RAW TEXT, which
 * is how a row that has been appended to must be expressed.
 */
function ieLink(
  over: Partial<Omit<Source, 'notes'>> & {
    id: string;
    external_id: string;
    notes?: Record<string, string> | string;
  }
): Source {
  const { notes, ...rest } = over;
  return {
    politician: POL,
    source_system: 'la_socrata',
    source_type: 'ie_committee',
    research_status: 'confirmed',
    support_oppose: 'support',
    ...rest,
    notes: typeof notes === 'string' ? notes : JSON.stringify(notes ?? {}),
  };
}

describe('outside spending', () => {
  it('publishes an la_socrata IE committee', async () => {
    sources = [ieLink({ id: 's1', external_id: 'C1', notes: { cmt_nm: 'FRIENDS OF SOMEONE' } })];
    contribs = [
      { id: 'c1', source: 's1', amount: 1000, donor: 'acme corp' },
      { id: 'c2', source: 's1', amount: 500, donor: 'beta llc' },
    ];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([
      expect.objectContaining({
        cmt_id: 'C1',
        cmt_nm: 'FRIENDS OF SOMEONE',
        total_amount: 1500,
        contribution_count: 2,
      }),
    ]);
  });

  it('publishes a CAL-ACCESS IE committee, with the name from committee_name', async () => {
    sources = [
      ieLink({
        id: 's1',
        source_system: 'cal_access',
        external_id: '1447993',
        notes: { committee_name: 'COALITION OF BUSINESS ORGANIZATIONS SUPPORTING SENATOR MELISSA' },
      }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 344843.8, donor: 'a trade association' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([
      expect.objectContaining({
        cmt_id: '1447993',
        cmt_nm: 'COALITION OF BUSINESS ORGANIZATIONS SUPPORTING SENATOR MELISSA',
        total_amount: 344843.8,
        contribution_count: 1,
      }),
    ]);
  });

  it('reports top donors for a CAL-ACCESS IE committee', async () => {
    sources = [
      ieLink({ id: 's1', source_system: 'cal_access', external_id: '1489255', notes: { committee_name: 'WORKING FAMILIES FOR JOHN' } }),
    ];
    contribs = [
      { id: 'c1', source: 's1', amount: 25000, donor: 'unite here local 11' },
      { id: 'c2', source: 's1', amount: 100, donor: 'a small donor' },
    ];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees[0]?.top_donors).toEqual([
      { donor_name: 'unite here local 11', amount: 25000 },
      { donor_name: 'a small donor', amount: 100 },
    ]);
  });

  it('does not sum one committee across source systems', async () => {
    // `la_socrata` reuses CAL-ACCESS filer ids, so these two rows are the SAME committee seen by
    // two ingests — and its contributions were loaded under both. The unique constraint is on
    // (data_source, source_transaction_id), so one real donation becomes two rows. Gathering by
    // external_id alone would report the money twice.
    sources = [
      ieLink({ id: 's-cal', source_system: 'cal_access', external_id: '1349095', notes: { committee_name: 'BLUMENFIELD FOR CITY COUNCIL 2013, BOB' } }),
      ieLink({
        id: 's-la',
        politician: 'pol-other',
        source_system: 'la_socrata',
        external_id: '1349095',
        notes: { cmt_nm: 'Bob Blumenfield for City Council 2013' },
      }),
    ];
    contribs = [
      { id: 'c1', source: 's-cal', amount: 100, donor: 'a donor' },
      { id: 'c2', source: 's-la', amount: 100, donor: 'a donor' }, // the same donation, re-ingested
    ];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([
      expect.objectContaining({
        cmt_id: '1349095',
        cmt_nm: 'BLUMENFIELD FOR CITY COUNCIL 2013, BOB',
        total_amount: 100,
        contribution_count: 1,
      }),
    ]);
  });

  it('leaves a non-confirmed IE link out entirely', async () => {
    sources = [
      ieLink({ id: 's1', source_system: 'cal_access', external_id: '1447993', research_status: 'not_applicable', notes: { committee_name: 'PARKED' } }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 500, donor: 'someone' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([]);
  });

  // ADR 0008 ------------------------------------------------------------------------------
  // A committee whose DIRECTION is unknown is WITHHELD, never defaulted. There is no safe
  // default: defaulting to 'support' publishes money raised AGAINST a politician as money they
  // raised. Control: deleting `AND support_oppose IS NOT NULL` from the service makes this fail.
  it('withholds a confirmed IE committee that has no direction', async () => {
    sources = [
      ieLink({ id: 's1', source_system: 'cal_access', external_id: '1442937', support_oppose: null, notes: { committee_name: 'DIRECTION UNKNOWN' } }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 4050, donor: 'someone' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([]);
  });

  it('withholds its DONORS too, not just its total', async () => {
    sources = [
      ieLink({ id: 's1', source_system: 'cal_access', external_id: '1442937', support_oppose: null, notes: { committee_name: 'DIRECTION UNKNOWN' } }),
      ieLink({ id: 's2', source_system: 'cal_access', external_id: '1447993', support_oppose: 'support', notes: { committee_name: 'KNOWN' } }),
    ];
    contribs = [
      { id: 'c1', source: 's1', amount: 4050, donor: 'hidden donor' },
      { id: 'c2', source: 's2', amount: 100, donor: 'visible donor' },
    ];

    const { summary } = await getSummary(POL);

    const donors = summary.outside_spending.committees.flatMap((c) => c.top_donors.map((d) => d.donor_name));
    expect(donors).toEqual(['visible donor']);
  });

  // An OPPOSE committee's money and donors are reported AGAINST the politician. The field has to
  // survive to the response or a consumer cannot tell this apart from money supporting them.
  it('reports an oppose committee as oppose', async () => {
    sources = [
      ieLink({ id: 's1', source_system: 'cal_access', external_id: '1418587', support_oppose: 'oppose', notes: { committee_name: 'COMMITTEE TO RECALL GAVIN NEWSOM' } }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 33172.8, donor: 'recall funder' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([
      expect.objectContaining({
        cmt_id: '1418587',
        support_oppose: 'oppose',
        total_amount: 33172.8,
        top_donors: [{ donor_name: 'recall funder', amount: 33172.8 }],
      }),
    ]);
  });

  // ──────────────────────────────────────────────────────────────────────────────────────────
  // `notes` IS TEXT, AND THE HOUSE CONVENTION APPENDS AFTER THE JSON
  //
  // 🔴 These four are the regression for the 2026-10-10 outage. `CC_0225` appended
  // `| IE + DIRECTION CC_0225: …` to all four rows it evidenced — which were precisely the four
  // rows this query reads — and `notes::jsonb` raised 22P02 on every one. Because
  // getOutsideSpendingForPolitician is awaited inside the summary handler, the ENTIRE campaign
  // finance endpoint returned HTTP 500 for Newsom, Hurtado, Gipson and Erickson.
  //
  // The note bodies below are the real prod values, abbreviated only in the middle.
  // ──────────────────────────────────────────────────────────────────────────────────────────

  it('survives a note with an appended ` | ` suffix, and still reads the committee name', async () => {
    sources = [
      ieLink({
        id: 's1',
        source_system: 'cal_access',
        external_id: '1418587',
        support_oppose: 'oppose',
        notes:
          '{"disputed_by": "CA_0212 (2026-09-24)", "committee_name": "NEWSOM; RAN ACTION FUND ' +
          'COMMITTEE TO RECALL GAVIN"} | IE + DIRECTION CC_0225: direction oppose per Form 460 ' +
          '#2463962 Part 6 (recall measure; polarity inverted)',
      }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 33172.8, donor: 'recall funder' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([
      expect.objectContaining({
        cmt_id: '1418587',
        cmt_nm: 'NEWSOM; RAN ACTION FUND COMMITTEE TO RECALL GAVIN',
        support_oppose: 'oppose',
        total_amount: 33172.8,
      }),
    ]);
  });

  it('survives two appended notes', async () => {
    sources = [
      ieLink({ id: 's1', external_id: 'C1', notes: '{"cmt_nm": "A COMMITTEE"} | one | two' }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 10, donor: 'd' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees[0].cmt_nm).toBe('A COMMITTEE');
  });

  // ⚠ The whole-string parse must be tried FIRST. A `} |` occurring inside a JSON string value is
  // not a separator, and truncating at it would corrupt a name that parses perfectly well.
  it('does not truncate at a `} |` that sits INSIDE a JSON string value', async () => {
    sources = [
      ieLink({ id: 's1', external_id: 'C1', notes: '{"cmt_nm": "ODD } | NAME"}' }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 10, donor: 'd' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees[0].cmt_nm).toBe('ODD } | NAME');
  });

  // ▶ A note that cannot be parsed at all costs the committee its NAME. It must never cost the
  // endpoint — 510 of the 518 confirmed CAL-ACCESS sources are JSON and 8 are prose (CC_0221).
  it('renders a committee whose notes are unparseable prose, rather than failing', async () => {
    sources = [
      ieLink({ id: 's1', external_id: 'C1', notes: 'plain prose note, carrying no JSON at all' }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 250, donor: 'a donor' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([
      expect.objectContaining({ cmt_id: 'C1', cmt_nm: '', total_amount: 250 }),
    ]);
  });
});
