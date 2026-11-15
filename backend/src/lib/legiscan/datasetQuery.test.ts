import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { datasetQuery } from './datasetQuery.js';

const session = { session_id: 77, state_id: 42, year_start: 2025, year_end: 2026, special: 0, session_name: '114th General Assembly' };

function root(): string {
  const r = mkdtempSync(join(tmpdir(), 'lsds-'));
  const d = join(r, 'TN-77', 'TN', '2025-2026_114th_General_Assembly');
  for (const sub of ['bill', 'vote', 'people']) mkdirSync(join(d, sub), { recursive: true });
  writeFileSync(join(d, 'bill', 'HB0010.json'), JSON.stringify({ bill: { bill_id: 501, bill_number: 'HB10', session_id: 77, session, votes: [{ roll_call_id: 9001, chamber: 'H', yea: 70, nay: 20 }] } }));
  writeFileSync(join(d, 'vote', '9001.json'), JSON.stringify({ roll_call: { roll_call_id: 9001, bill_id: 501, chamber: 'H', yea: 70, nay: 20, votes: [{ people_id: 1, vote_id: 1, vote_text: 'Yea' }] } }));
  writeFileSync(join(d, 'people', '1.json'), JSON.stringify({ person: { people_id: 1, name: 'Ann Example', first_name: 'Ann', last_name: 'Example' } }));
  mkdirSync(join(r, 'WA-88', 'WA'), { recursive: true });
  return r;
}

describe('datasetQuery', () => {
  const r = root();
  it('lists the sessions of one state', () => {
    expect(datasetQuery(r, 'getSessionList', { state: 'TN' }).sessions.map((s: any) => s.session_id)).toEqual([77]);
    expect(datasetQuery(r, 'getSessionList', { state: 'WA' }).sessions).toEqual([]);
  });
  it('answers the master list, bill, roll call and people from disk', () => {
    const ml = datasetQuery(r, 'getMasterListRaw', { id: '77' }).masterlist;
    expect(ml['0']).toMatchObject({ bill_id: 501, number: 'HB10' });
    expect(datasetQuery(r, 'getBill', { id: '501' }).bill.bill_number).toBe('HB10');
    expect(datasetQuery(r, 'getRollCall', { id: '9001' }).roll_call.yea).toBe(70);
    expect(datasetQuery(r, 'getSessionPeople', { id: '77' }).sessionpeople.people[0].name).toBe('Ann Example');
  });
  it('never guesses: unknown ids and other operations throw', () => {
    expect(() => datasetQuery(r, 'getBill', { id: '999' })).toThrow(/not in the datasets/);
    expect(() => datasetQuery(r, 'getRollCall', { id: '1' })).toThrow(/not in the datasets/);
    expect(() => datasetQuery(r, 'getBillText', { id: '1' })).toThrow(/not answered/);
  });
});
