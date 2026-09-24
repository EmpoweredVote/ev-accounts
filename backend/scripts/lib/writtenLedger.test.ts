import { describe, it, expect } from 'vitest';
import {
  buildLedgerFile, politicianIdsInBatch, evidenceTypeByKey, classifyResolvedRows,
  type ResearchCsvRow, type ResolvedReviewRow,
} from './writtenLedger.js';

const keyOf = (fullName: string, topicKey: string) => `${fullName.trim().toLowerCase()}\u0000${topicKey.trim().toLowerCase()}`;

describe('buildLedgerFile', () => {
  it('carries a top-level season_id when every row shares one (audit-chair-evidence\'s expected shape)', () => {
    const file = buildLedgerFile([
      { politician_id: 'p1', topic_id: 't1', chair_after: 2, season_id: 's1' },
      { politician_id: 'p2', topic_id: 't2', chair_after: 4, season_id: 's1' },
    ]);
    expect(file).toEqual({
      season_id: 's1',
      rows: [
        { politician_id: 'p1', topic_id: 't1', chair_after: 2, season_id: 's1' },
        { politician_id: 'p2', topic_id: 't2', chair_after: 4, season_id: 's1' },
      ],
    });
  });

  it('leaves the top-level season_id null when rows span more than one season', () => {
    const file = buildLedgerFile([
      { politician_id: 'p1', topic_id: 't1', chair_after: 2, season_id: 's1' },
      { politician_id: 'p2', topic_id: 't2', chair_after: 4, season_id: 's2' },
    ]);
    expect(file.season_id).toBeNull();
    expect(file.rows).toHaveLength(2);
  });

  it('is null (not undefined, not throwing) for zero rows', () => {
    expect(buildLedgerFile([])).toEqual({ season_id: null, rows: [] });
  });
});

describe('politicianIdsInBatch', () => {
  it('dedupes ids shared by more than one name and drops unresolved (null) names', () => {
    const idByName = new Map<string, string | null>([
      ['Jane Doe', 'p1'],
      ['J. Doe', 'p1'], // same person, two spellings in the CSV
      ['Unresolved Person', null],
    ]);
    const ids = politicianIdsInBatch(['Jane Doe', 'J. Doe', 'Unresolved Person'], idByName);
    expect(ids).toEqual(['p1']);
  });

  it('includes a name whose only rows were queued for review or scored value=null (C118)', () => {
    // Simulates the stamp set: csvNames drawn from the WHOLE batch (allStances), not just rows
    // that ended up pushed — a queued row and a blank ("insufficient evidence") row both still
    // mean the politician was researched.
    const idByName = new Map<string, string | null>([
      ['Auto Pushed', 'p-pushed'],
      ['Queued For Review', 'p-queued'],
      ['Blank Spoke', 'p-blank'],
    ]);
    const ids = politicianIdsInBatch(
      ['Auto Pushed', 'Queued For Review', 'Blank Spoke'],
      idByName,
    );
    expect(ids.sort()).toEqual(['p-blank', 'p-pushed', 'p-queued']);
  });

  it('returns nothing for an empty batch', () => {
    expect(politicianIdsInBatch([], new Map())).toEqual([]);
  });
});

describe('evidenceTypeByKey', () => {
  it('keys on the shared normalizer and trims the value', () => {
    const records: ResearchCsvRow[] = [
      { full_name: '  Jane Doe ', topic_key: ' Healthcare ', evidence_type: ' record ' },
    ];
    const m = evidenceTypeByKey(records, keyOf);
    expect(m.get(keyOf('Jane Doe', 'Healthcare'))).toBe('record');
    expect(m.get(keyOf('jane doe', 'healthcare'))).toBe('record');
  });

  it('skips a row with a blank full_name or topic_key', () => {
    const records: ResearchCsvRow[] = [
      { full_name: '', topic_key: 'healthcare', evidence_type: 'record' },
      { full_name: 'Jane Doe', topic_key: '  ', evidence_type: 'record' },
    ];
    expect(evidenceTypeByKey(records, keyOf).size).toBe(0);
  });
});

describe('classifyResolvedRows', () => {
  const base: ResolvedReviewRow = {
    full_name_raw: 'Jane Doe',
    topic_key: 'healthcare',
    politician_id: 'p1',
    topic_id: 't1',
    season_id: 's1',
    chair_after: 2,
  };

  it('includes a resolved record row', () => {
    const typeByKey = evidenceTypeByKey(
      [{ full_name: 'Jane Doe', topic_key: 'healthcare', evidence_type: 'record' }], keyOf,
    );
    const { included, excluded } = classifyResolvedRows([base], typeByKey, keyOf);
    expect(excluded).toEqual([]);
    expect(included).toEqual([{ politician_id: 'p1', topic_id: 't1', chair_after: 2, season_id: 's1' }]);
  });

  it('drops a statement row — it cannot name an instrument by definition (Global Constraint)', () => {
    const typeByKey = evidenceTypeByKey(
      [{ full_name: 'Jane Doe', topic_key: 'healthcare', evidence_type: 'statement' }], keyOf,
    );
    const { included, excluded } = classifyResolvedRows([base], typeByKey, keyOf);
    expect(included).toEqual([]);
    expect(excluded).toHaveLength(1);
    expect(excluded[0]).toMatch(/statement evidence/);
  });

  it('drops and lists a row with no matching research.csv entry, rather than guessing', () => {
    const { included, excluded } = classifyResolvedRows([base], new Map(), keyOf);
    expect(included).toEqual([]);
    expect(excluded[0]).toMatch(/no matching research\.csv row/);
  });

  it('drops and lists a row whose evidence_type is neither record nor statement', () => {
    const typeByKey = evidenceTypeByKey(
      [{ full_name: 'Jane Doe', topic_key: 'healthcare', evidence_type: 'weird' }], keyOf,
    );
    const { included, excluded } = classifyResolvedRows([base], typeByKey, keyOf);
    expect(included).toEqual([]);
    expect(excluded[0]).toMatch(/unrecognized evidence_type "weird"/);
  });

  it('drops a row missing politician_id/topic_id', () => {
    const typeByKey = evidenceTypeByKey(
      [{ full_name: 'Jane Doe', topic_key: 'healthcare', evidence_type: 'record' }], keyOf,
    );
    const { included, excluded } = classifyResolvedRows(
      [{ ...base, politician_id: null }], typeByKey, keyOf,
    );
    expect(included).toEqual([]);
    expect(excluded[0]).toMatch(/no politician_id\/topic_id/);
  });

  it('drops a row with no written value (chair_after null)', () => {
    const typeByKey = evidenceTypeByKey(
      [{ full_name: 'Jane Doe', topic_key: 'healthcare', evidence_type: 'record' }], keyOf,
    );
    const { included, excluded } = classifyResolvedRows(
      [{ ...base, chair_after: null }], typeByKey, keyOf,
    );
    expect(included).toEqual([]);
    expect(excluded[0]).toMatch(/no written value/);
  });

  it('drops a row with no resolvable season_id', () => {
    const typeByKey = evidenceTypeByKey(
      [{ full_name: 'Jane Doe', topic_key: 'healthcare', evidence_type: 'record' }], keyOf,
    );
    const { included, excluded } = classifyResolvedRows(
      [{ ...base, season_id: null }], typeByKey, keyOf,
    );
    expect(included).toEqual([]);
    expect(excluded[0]).toMatch(/no season_id/);
  });

  it('produces an empty ledger (the precondition for the empty-refusal) when every row is statement evidence', () => {
    const rows: ResolvedReviewRow[] = [
      { ...base, full_name_raw: 'A', topic_key: 'housing' },
      { ...base, full_name_raw: 'B', topic_key: 'transit' },
    ];
    const typeByKey = evidenceTypeByKey(
      [
        { full_name: 'A', topic_key: 'housing', evidence_type: 'statement' },
        { full_name: 'B', topic_key: 'transit', evidence_type: 'statement' },
      ],
      keyOf,
    );
    const { included, excluded } = classifyResolvedRows(rows, typeByKey, keyOf);
    // The script refuses to write a ledger when `included` comes back empty like this — see
    // export-written-ledger.ts's own "REFUSING to write an empty ledger" check.
    expect(included).toEqual([]);
    expect(excluded).toHaveLength(2);
  });

  it('returns nothing for zero resolved rows', () => {
    const { included, excluded } = classifyResolvedRows([], new Map(), keyOf);
    expect(included).toEqual([]);
    expect(excluded).toEqual([]);
  });
});
