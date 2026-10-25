import { describe, it, expect } from 'vitest';
import { formatTable, refuseTransactionControl, runReadOnly, TransactionControlError, type QueryResultLike } from './readOnlyQuery.js';

function fakeClient(answer: (sql: string) => QueryResultLike | QueryResultLike[] | Error) {
  const calls: string[] = [];
  return {
    calls,
    async query(sql: string) {
      calls.push(sql);
      if (sql === 'BEGIN READ ONLY' || sql === 'ROLLBACK') return { fields: [], rows: [] };
      const a = answer(sql);
      if (a instanceof Error) throw a;
      return a;
    },
  };
}

describe('runReadOnly', () => {
  it('opens BEGIN READ ONLY first and ROLLBACK last on success', async () => {
    const c = fakeClient(() => ({ fields: [{ name: 'one' }], rows: [{ one: 1 }] }));
    const r = await runReadOnly(c, 'select 1 as one');
    expect(c.calls).toEqual(['BEGIN READ ONLY', 'select 1 as one', 'ROLLBACK']);
    expect(r).toEqual({ fields: ['one'], rows: [{ one: 1 }] });
  });

  it('still rolls back on error and re-throws the original error', async () => {
    const boom = new Error('cannot execute CREATE TABLE in a read-only transaction');
    const c = fakeClient(() => boom);
    await expect(runReadOnly(c, 'create table zz(x int)')).rejects.toBe(boom);
    expect(c.calls).toEqual(['BEGIN READ ONLY', 'create table zz(x int)', 'ROLLBACK']);
  });

  it('returns the last result of a multi-statement file', async () => {
    const c = fakeClient(() => [
      { fields: [{ name: 'a' }], rows: [{ a: 1 }] },
      { fields: [{ name: 'b' }], rows: [{ b: 2 }, { b: 3 }] },
    ]);
    expect(await runReadOnly(c, 'select 1 a; select 2 b')).toEqual({ fields: ['b'], rows: [{ b: 2 }, { b: 3 }] });
  });

  it('refuses transaction control without touching the database', async () => {
    const c = fakeClient(() => ({ fields: [], rows: [] }));
    await expect(runReadOnly(c, 'commit; delete from x')).rejects.toBeInstanceOf(TransactionControlError);
    expect(c.calls).toEqual([]);
  });
});

describe('refuseTransactionControl', () => {
  it.each([
    'COMMIT;', 'begin', 'select 1; rollback; delete from t', 'abort', 'start  transaction',
    'set transaction read write', 'SET SESSION CHARACTERISTICS AS TRANSACTION READ WRITE', 'select 1;\nend;',
  ])('refuses %j', (sql) => expect(() => refuseTransactionControl(sql)).toThrow(TransactionControlError));

  it.each([
    '-- commit later\nselect 1',
    '/* begin */ select 1',
    "select 'commit; begin' as note",
    "select 'it''s a rollback' as s",
    'select "commit" from t',
    "select $$ begin end $$",
    "select case when true then 1 else 0 end as x",
    'select committed_at, beginning from t',
  ])('allows %j', (sql) => expect(() => refuseTransactionControl(sql)).not.toThrow());
});

describe('formatTable', () => {
  it('aligns columns and counts rows', () => {
    expect(formatTable(['id', 'name'], [{ id: 1, name: 'Ann' }, { id: 22, name: null }])).toBe(
      ['id  name', '--  ----', '1   Ann', '22  NULL', '(2 rows)'].join('\n'));
  });
  it('renders dates, objects and a single row', () => {
    expect(formatTable(['at', 'j'], [{ at: new Date('2026-01-02T03:04:05Z'), j: { a: 1 } }])).toBe(
      ['at                        j', '------------------------  -------', '2026-01-02T03:04:05.000Z  {"a":1}', '(1 row)'].join('\n'));
  });
  it('handles no columns', () => expect(formatTable([], [])).toBe('(no columns; 0 rows)'));
});
