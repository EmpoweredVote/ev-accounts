import { describe, it, expect } from 'vitest';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  resolveSeasonTarget, seasonSpecFromArgv, assertBundleSeason, writeBundleSeason,
  assertSeasonIdMatchesBundle, seasonIdFromArgs, SeasonTargetError,
} from './seasonTarget.js';

const OPEN = { id: '11111111-1111-1111-1111-111111111111', number: 2, name: 'Season 2', status: 'open' };
const DRAFT = { id: '7b3a066c-815d-43b2-a6a0-6a3029778075', number: 3, name: 'Season 3', status: 'draft' };
const CLOSED = { id: '33333333-3333-3333-3333-333333333333', number: 1, name: 'Season 1', status: 'closed' };
const ALL = [OPEN, DRAFT, CLOSED];

/** A fake of the two queries the resolver runs: by status ($1 = 'open'|'draft') or by id. */
const fake = (rows = ALL) => async (sql: string, params: unknown[] = []) => ({
  rows: sql.includes('WHERE status') ? rows.filter((r) => r.status === params[0])
    : rows.filter((r) => r.id === params[0]),
});

describe('seasonSpecFromArgv', () => {
  it('defaults to open, so every script behaves as before', () => {
    expect(seasonSpecFromArgv(['--dir', 'x'])).toBe('open');
  });
  it('reads --season and the older --season-id', () => {
    expect(seasonSpecFromArgv(['--season', 'draft'])).toBe('draft');
    expect(seasonSpecFromArgv(['--season-id', DRAFT.id])).toBe(DRAFT.id);
  });
  it('refuses a flag with no value', () => {
    expect(() => seasonSpecFromArgv(['--season'])).toThrow(SeasonTargetError);
    expect(() => seasonSpecFromArgv(['--season', '--dir', 'x'])).toThrow(SeasonTargetError);
  });
});

describe('resolveSeasonTarget', () => {
  it('open → the one open season; draft → the one draft season', async () => {
    expect(await resolveSeasonTarget('open', fake())).toMatchObject({ id: OPEN.id, status: 'open' });
    expect(await resolveSeasonTarget('draft', fake())).toMatchObject({ id: DRAFT.id, number: 3, status: 'draft' });
  });
  it('a uuid names a season directly, open or draft', async () => {
    expect(await resolveSeasonTarget(DRAFT.id.toUpperCase(), async (_s, p) => fake()('WHERE id', [String(p?.[0]).toLowerCase()])))
      .toMatchObject({ id: DRAFT.id });
  });
  it('REFUSES a closed season — its answers are immutable', async () => {
    await expect(resolveSeasonTarget(CLOSED.id, fake())).rejects.toThrow(/closed.*immutable/);
  });
  it('says so when there is no such season, or more than one', async () => {
    await expect(resolveSeasonTarget('draft', fake([OPEN, CLOSED]))).rejects.toThrow(/no draft season/);
    await expect(resolveSeasonTarget('open', fake([DRAFT]))).rejects.toThrow(/no open season/);
    await expect(resolveSeasonTarget('draft', fake([DRAFT, { ...DRAFT, id: 'x', number: 4 }]))).rejects.toThrow(/2 draft seasons/);
    await expect(resolveSeasonTarget('nonsense', fake())).rejects.toThrow(/expected open \| draft/);
  });
});

describe('the batch directory records a non-open season', () => {
  const dir = () => mkdtempSync(join(tmpdir(), 'season-target-'));
  const open = { ...OPEN, status: 'open' as const };
  const draft = { ...DRAFT, status: 'draft' as const };

  it('writes nothing for the open season, so an open bundle stays byte-identical', () => {
    const d = dir();
    writeBundleSeason(d, open);
    expect(() => assertBundleSeason(d, open)).not.toThrow();
    expect(() => assertSeasonIdMatchesBundle(d, OPEN.id)).not.toThrow();
  });
  it('a draft bundle is refused by an open run, and an open bundle by a draft run', () => {
    const d = dir();
    writeBundleSeason(d, draft);
    expect(() => assertBundleSeason(d, draft)).not.toThrow();
    expect(() => assertBundleSeason(d, open)).toThrow(/built for season 3/);
    expect(() => assertSeasonIdMatchesBundle(d, OPEN.id)).toThrow(/built for season 3/);
    const legacy = dir();
    expect(() => assertBundleSeason(legacy, draft)).toThrow(/no season\.json.*open season/);
  });
  it('seasonIdFromArgs: a bare uuid needs no database; --season resolves and cross-checks', async () => {
    const d = dir();
    writeBundleSeason(d, draft);
    const neverCalled = async () => { throw new Error('no query expected'); };
    expect(await seasonIdFromArgs(['--season-id', DRAFT.id], d, neverCalled)).toBe(DRAFT.id);
    expect(await seasonIdFromArgs(['--season', 'draft'], d, fake())).toBe(DRAFT.id);
    expect(await seasonIdFromArgs([], d, neverCalled)).toBeNull();
    await expect(seasonIdFromArgs(['--season-id', OPEN.id], d, neverCalled)).rejects.toThrow(/built for season 3/);
    await expect(seasonIdFromArgs(['--season', 'draft', '--season-id', OPEN.id], d, fake())).rejects.toThrow(/different seasons/);
    writeFileSync(join(d, 'unrelated'), '');
  });
});
