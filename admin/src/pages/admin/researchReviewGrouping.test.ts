import { describe, it, expect } from 'vitest';
import { groupResearchReviewRows, UNKNOWN_BODY, type GroupableResearchRow } from './researchReviewGrouping';

interface Row extends GroupableResearchRow {
  id: string;
}

const row = (id: string, topicKey: string, bodyLabel: string | null): Row => ({ id, topicKey, bodyLabel });

describe('groupResearchReviewRows', () => {
  it('groups by topic then by body, and counts each topic across all its bodies', () => {
    const rows = [
      row('1', 'housing', 'State Senate'),
      row('2', 'housing', 'State Assembly'),
      row('3', 'housing', 'State Senate'),
      row('4', 'gun-policy', 'State Senate'),
    ];
    const groups = groupResearchReviewRows(rows);
    expect(groups).toHaveLength(2);
    const housing = groups.find((g) => g.topicKey === 'housing')!;
    expect(housing.count).toBe(3);
    expect(housing.bodies.map((b) => b.body)).toEqual(['State Assembly', 'State Senate']);
    expect(housing.bodies.find((b) => b.body === 'State Senate')!.rows.map((r) => r.id)).toEqual(['1', '3']);
  });

  it('sorts topics alphabetically, then bodies alphabetically within a topic', () => {
    const rows = [
      row('1', 'zoning', 'City Council'),
      row('2', 'housing', 'Z Chamber'),
      row('3', 'housing', 'A Chamber'),
    ];
    const groups = groupResearchReviewRows(rows);
    expect(groups.map((g) => g.topicKey)).toEqual(['housing', 'zoning']);
    expect(groups[0].bodies.map((b) => b.body)).toEqual(['A Chamber', 'Z Chamber']);
  });

  it('buckets a null bodyLabel under UNKNOWN_BODY, distinct from a real body of the same rows', () => {
    const rows = [row('1', 'housing', null), row('2', 'housing', 'State Senate')];
    const groups = groupResearchReviewRows(rows);
    expect(groups[0].bodies.map((b) => b.body).sort()).toEqual([UNKNOWN_BODY, 'State Senate'].sort());
    expect(groups[0].bodies.find((b) => b.body === UNKNOWN_BODY)!.rows).toHaveLength(1);
  });

  it('returns an empty array for no rows', () => {
    expect(groupResearchReviewRows([])).toEqual([]);
  });
});
