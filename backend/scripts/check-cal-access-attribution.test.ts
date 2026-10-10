import { describe, it, expect } from 'vitest';
import { findViolations, keyOf } from './check-cal-access-attribution.mjs';

// ---------------------------------------------------------------------------
// The guard this pins: a CAL-ACCESS source that is `confirmed` is ON A VOTER'S PAGE, and almost
// none of the published ones were ever independently verified — measured 2026-10-10, 387 of 518
// were written by `confirm-cal-access.ts`, the surname matcher that produced the seven surname
// buckets, and a further 15 were flagged `--ambiguous` BY THAT SCRIPT and confirmed anyway.
//
// 🔴 A NAME-BASED GUARD WAS TRIED FIRST AND DOES NOT WORK. Flagging a confirmed source whose
// committee name carries a forename conflicting with the politician's flags 135 of 510, and every
// one sampled is a false positive: "FRIENDS OF TED" on Ted Lieu, "HOLLY J." on Holly J. Mitchell,
// "RE ELECT FIONA" on Fiona Ma. That is the false trail CC_0213 already recorded — absence of a
// forename convicts nobody, and a forename inside a phrase is not a conflict.
//
// So this is a PROVENANCE ratchet instead: the current attributions are grandfathered by key, and
// any NEW confirmed attribution must carry a marker saying who adjudicated it. It makes no claim
// about whether an existing attribution is right — only that a new one leaves a trail.
// ---------------------------------------------------------------------------

type Row = Parameters<typeof findViolations>[0][number];

const row = (over: Partial<Row> = {}): Row => ({
  id: 'src-1',
  politician_id: 'pol-1',
  politician_name: 'A Politician',
  source_system: 'cal_access',
  external_id: '1000001',
  research_status: 'confirmed',
  source_type: 'candidate_committee',
  notes: '{"confirmed_by":"confirm-cal-access.ts","committee_name":"SOMEBODY FOR OFFICE 2020"}',
  ...over,
});

describe('findViolations', () => {
  it('passes a grandfathered attribution', () => {
    const r = row();
    expect(findViolations([r], new Set([keyOf(r)]))).toEqual([]);
  });

  it('fails a new confirmed attribution that carries no marker', () => {
    const r = row({ external_id: '9999999' });
    const v = findViolations([r], new Set());
    expect(v).toHaveLength(1);
    expect(v[0]).toMatchObject({ external_id: '9999999', politician_name: 'A Politician' });
  });

  it('passes a new confirmed attribution that names who adjudicated it', () => {
    const r = row({
      external_id: '9999999',
      notes: '{"committee_name":"X","adjudicated_by":"CC_0216","adjudication":"on her candidate page"}',
    });
    expect(findViolations([r], new Set())).toEqual([]);
  });

  it('accepts published_by and verified_by as markers too', () => {
    const a = row({ external_id: '8000001', notes: '{"published_by":"CC_0219"}' });
    const b = row({ external_id: '8000002', notes: '{"verified_by":"a human"}' });
    expect(findViolations([a, b], new Set())).toEqual([]);
  });

  // 🔴 The hole a row-id baseline would leave. CC_0216 and CC_0218 moved sources BETWEEN
  // politicians keeping their ids, so the baseline must grandfather the ATTRIBUTION, not the row.
  it('fails a grandfathered source that has moved to a different politician', () => {
    const before = row({ politician_id: 'pol-1' });
    const after = row({ politician_id: 'pol-2', politician_name: 'Somebody Else' });
    const baseline = new Set([keyOf(before)]);
    expect(findViolations([after], baseline)).toHaveLength(1);
  });

  it('ignores a source that is not confirmed — it publishes nothing', () => {
    for (const research_status of ['disputed', 'not_applicable', 'needs_research']) {
      expect(findViolations([row({ research_status, external_id: '9999999' })], new Set())).toEqual([]);
    }
  });

  it('ignores a source system it does not guard', () => {
    const r = row({ source_system: 'la_socrata', external_id: '9999999' });
    expect(findViolations([r], new Set())).toEqual([]);
  });

  // A confirmed ie_committee publishes too — as outside spending — so it is in scope.
  it('guards an ie_committee as well as a candidate_committee', () => {
    const r = row({ source_type: 'ie_committee', external_id: '9999999' });
    expect(findViolations([r], new Set())).toHaveLength(1);
  });

  it('treats null notes as carrying no marker', () => {
    const r = row({ external_id: '9999999', notes: null });
    expect(findViolations([r], new Set())).toHaveLength(1);
  });

  // ⚠ notes are not always valid JSON — appended text like `{...} | UNVERIFIED … | DISPUTED …`
  // breaks a jsonb cast, so the marker test must be textual and must not throw.
  it('finds a marker in notes that are not parseable as JSON', () => {
    const r = row({
      external_id: '9999999',
      notes: '{"committee_name":"X"} | UNVERIFIED (migration 1792) | "adjudicated_by": "CC_0217"',
    });
    expect(findViolations([r], new Set())).toEqual([]);
  });

  it('does not mistake the word adjudicated in prose for a marker', () => {
    const r = row({ external_id: '9999999', notes: 'this was adjudicated by somebody, honest' });
    expect(findViolations([r], new Set())).toHaveLength(1);
  });
});
