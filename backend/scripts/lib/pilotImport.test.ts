import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { ADAPTERS, fitInstrumentId, parseOtherNames, parseTally, resetImportNotes, importNotes, type PilotOutput } from './pilotImport.js';
import {
  DeadEndSchema, InstrumentSchema, JurisdictionSchema, PersonSourcesSchema, appendDeadEnd, upsertInstrument, validateStore,
} from './sourceStore.js';

const fx = (name: string) => join(dirname(fileURLToPath(import.meta.url)), '__fixtures__', 'pilot', name);
const adapter = (name: string) => ADAPTERS.find((a) => a.name === name)!;
const ROOT = join(dirname(fileURLToPath(import.meta.url)), '__fixtures__', 'pilot');
const read = (name: string) => adapter(name).read(fx(name), ROOT);

let root: string;
beforeEach(() => { root = mkdtempSync(join(tmpdir(), 'pilot-import-')); resetImportNotes(); });
afterEach(() => { rmSync(root, { recursive: true, force: true }); });

function schemaCheck(out: PilotOutput) {
  for (const i of out.instruments) expect(InstrumentSchema.safeParse(i).success).toBe(true);
  for (const p of out.people) expect(PersonSourcesSchema.safeParse(p).success).toBe(true);
  for (const j of out.jurisdictions) expect(JurisdictionSchema.safeParse(j).success).toBe(true);
  for (const d of out.deadEnds) expect(DeadEndSchema.safeParse(d).success).toBe(true);
}

describe('adapter matching', () => {
  it('each adapter matches only its own folder shape', () => {
    const dirs: Record<string, string> = {
      'equity-stage1': fx('equity-stage1'), 'equity-supplement': fx('equity-supplement'), 'homelessness-stage1': fx('homelessness-stage1'),
    };
    for (const a of ADAPTERS) {
      for (const [name, dir] of Object.entries(dirs)) expect(a.matches(dir)).toBe(a.name === name);
    }
    expect(ADAPTERS.some((a) => a.matches(tmpdir()))).toBe(false);
  });
});

describe('helpers', () => {
  it('reads the tally formats the pilots printed', () => {
    expect(parseTally('6-3-0 (passed); Felton absent')).toEqual({ yes: 6, no: 3 });
    expect(parseTally('Ayes 4, Nays 4, Abstain 0 (failed)')).toEqual({ yes: 4, no: 4 });
    expect(parseTally('Yes (14); No (16); Abstain (7) - failed')).toEqual({ yes: 14, no: 16 });
    expect(parseTally('Passed For: 7; Against: 0; Abstain: 0')).toEqual({ yes: 7, no: 0 });
    expect(parseTally('AYES 4, NOES 1 (Garner)')).toEqual({ yes: 4, no: 1 });
    expect(parseTally('approved, tally not printed')).toBeUndefined();
    expect(parseTally('nine-to-one')).toEqual({ yes: 9, no: 1 });
    expect(parseTally('Majority do pass 9; minority do not pass 6; minority without recommendation 2')).toEqual({ yes: 9, no: 6 });
    expect(parseTally('')).toBeUndefined();
  });
  it('keeps a pilot id that fits and builds one that does not', () => {
    expect(fitInstrumentId('ATLANTA-CLEARING-MACHINERY-2025', 'GA', 2025)).toBe('ATLANTA-CLEARING-MACHINERY-2025');
    expect(importNotes.constructedIds).toEqual([]);
    expect(fitInstrumentId('BLOOMINGTON-IN-ORD-21-06', 'IN', 2021)).toBe('IN-BLOOMINGTON-IN-ORD-21-06-2021');
    expect(fitInstrumentId('SACRAMENTO-12.74.030-2025', 'CA', 2025)).toBe('CA-SACRAMENTO-12-74-030-2025');
    expect(importNotes.constructedIds).toHaveLength(2);
  });
});

describe('equity stage 1 + supplement', () => {
  it('yields WA-ESSB-5044-2021 with kind, tallies and members once both adapters are merged', () => {
    for (const name of ['equity-stage1', 'equity-supplement']) {
      const out = read(name);
      schemaCheck(out);
      for (const i of out.instruments) upsertInstrument(root, i);
    }
    expect(validateStore(root)).toEqual([]);
    const wa = JSON.parse(readFileSync(join(root, 'instruments', 'state-wa', 'WA-ESSB-5044-2021.json'), 'utf8'));
    expect(wa.scope).toBe('state:wa');
    expect(wa.version).toBe('enrolled');
    expect(wa.operative_text).toContain('Sec. 1(2)');
    expect(wa.single_subject).toEqual([{ season: 3, codebook: '0.6', topic_list_hash: 'pilot-unrecorded', verdict: 'single', other_topics: [] }]);
    expect(wa.votes).toHaveLength(1);
    expect(wa.votes[0]).toMatchObject({ date: '2021-04-20', body: 'WA Senate', kind: 'roll-call', yes: 29, no: 19 });
    const cleveland = wa.votes[0].members.find((m: any) => m.name === 'Annette Cleveland');
    expect(cleveland).toMatchObject({ vote: 'yea', politician_id: '14332488-3986-4e86-abc2-666b7a3f2dd5' });
    // a person the identity check marked WRONG keeps the printed name and gets no id
    const hunt = wa.votes[0].members.find((m: any) => m.name === 'Hunt');
    expect(hunt).toBeDefined();
    expect(hunt.politician_id).toBeUndefined();
    expect(wa.votes[0].members.find((m: any) => m.name === 'Ron Muzzall')).toMatchObject({ vote: 'absent' });
  });

  it('splits the VA pair into two instruments and builds school board ids', () => {
    const out = read('equity-stage1');
    const ids = out.instruments.map((i) => i.id).sort();
    expect(ids).toEqual(['IN-MCCSC-5518-2023', 'VA-HB-1904-2021', 'VA-SB-1196-2021', 'VA-VBCPS-0408-15F-2025', 'WA-ESSB-5044-2021']);
    const vb = out.instruments.find((i) => i.id === 'VA-VBCPS-0408-15F-2025')!;
    expect(vb.scope).toBe('school:5103840');
    expect(vb.votes[0]).toMatchObject({ yes: 6, no: 3, kind: 'action-item' });
    expect(vb.votes[0].members.some((m) => m.vote === 'absent')).toBe(true);
    const mccsc = out.instruments.find((i) => i.id === 'IN-MCCSC-5518-2023')!;
    expect(mccsc.scope).toBe('school:1800630');
    expect(out.jurisdictions.map((j) => j.scope)).toEqual(expect.arrayContaining(['school:5103840', 'school:1800630']));
    expect(mccsc.votes[0]).toMatchObject({ yes: 7, no: 0 });
    // two of the seven voters are not in the database: name only
    expect(mccsc.votes[0].members.filter((m) => !m.politician_id)).toHaveLength(2);
    expect(out.jurisdictions.length).toBeGreaterThan(0);
  });

  it('writes term rows for seated people and dead ends for blocked portals', () => {
    const out = read('equity-supplement');
    schemaCheck(out);
    expect(out.people.length).toBeGreaterThan(0);
    expect(out.people[0].sources).toEqual([]);
    expect(out.deadEnds.length).toBeGreaterThan(0);
    expect(out.deadEnds.every((d) => d.by.startsWith('pilot-import (s3-census'))).toBe(true);
  });
});

describe('homelessness stage 1', () => {
  it('imports votes with readable tallies and skips the rest', () => {
    const out = read('homelessness-stage1');
    schemaCheck(out);
    const az = out.instruments.find((i) => i.id === 'AZ-SB-1024-2023')!;
    expect(az.scope).toBe('state:az');
    expect(az.votes[0]).toMatchObject({ yes: 16, no: 13, body: 'AZ Senate' });
    expect(az.votes[0].members).toHaveLength(3);
    const la = out.instruments.find((i) => i.id.startsWith('CA-LA-LAMC-41-18'))!;
    expect(la.scope).toBe('place:0644000');
    const atl = out.instruments.find((i) => i.id === 'ATLANTA-CLEARING-MACHINERY-2025')!;
    expect(atl.votes).toEqual([]);
    expect(out.instruments.every((i) => i.provenance.fetched_by === 'pilot-import (s3-pilot-homelessness-stage1)')).toBe(true);
    expect(out.people.length).toBeGreaterThan(0);
  });
});

describe('fix round 1', () => {
  it('reads group labels after names and cross-checks the counts', () => {
    expect(parseOtherNames(['Acevero', 'Martinez (not voting)', 'Crosby', 'Munoz', 'Woods (excused/absent)'], '2 Not voting; 3 Excused (Absent)', 'x')).toEqual([
      { name: 'Acevero', vote: 'abstain' }, { name: 'Martinez', vote: 'abstain' },
      { name: 'Crosby', vote: 'absent' }, { name: 'Munoz', vote: 'absent' }, { name: 'Woods', vote: 'absent' },
    ]);
    expect(() => parseOtherNames(['Acevero', 'Martinez (not voting)'], '1 Not voting', 'x')).toThrow(/other_names give/);
    expect(() => parseOtherNames(['Acevero'], '1 Not voting', 'x')).toThrow(/no group label/);
  });

  it('counts only absent members as absent; not-voting members are abstentions', () => {
    const out = read('equity-supplement');
    const md = out.instruments.find((i) => i.id === 'MD-HB-1386-2024')!;
    const v = md.votes.find((x) => x.date === '2024-04-08')!;
    expect(v.absent).toBe(3);
    expect(v.members.filter((m) => m.vote === 'abstain').map((m) => m.name).sort()).toEqual(['Ashanti Martinez', 'Gabriel Acevero']);
    const va = out.instruments.find((i) => i.id === 'VA-SB-1196-2021')!;
    expect(va.votes[0].absent).toBeUndefined();
    expect(va.votes[0].members.find((m) => m.name.includes('Stuart'))?.vote).toBe('abstain');
  });

  it('writes single only for census count', () => {
    const hl = read('homelessness-stage1');
    expect(hl.instruments.find((i) => i.id === 'MIAMI-WARNING-REPEAL-2026')!.single_subject).toEqual([]);
    expect(hl.instruments.find((i) => i.id === 'AZ-SB-1024-2023')!.single_subject).toHaveLength(1);
    expect(importNotes.noRuling.some((n) => n.startsWith('MIAMI-WARNING-REPEAL-2026') && n.includes('duty'))).toBe(true);
  });

  it('keeps person sources out of instrument urls', () => {
    const hl = read('homelessness-stage1');
    const b = hl.instruments.find((i) => i.id === 'IN-BLOOMINGTON-IN-ORD-21-06-2021')!;
    expect(b.urls).toEqual(['https://bloomington.in.gov/onboard/meetingFiles/8496/download']);
  });

  it('takes the motion from the census record and never from the item number', () => {
    const hl = read('homelessness-stage1');
    const n = hl.instruments.find((i) => i.id.includes('NASHVILLE'))!;
    expect(n.votes[0].motion).toContain('Rosenberg offered a substitute');
    for (const i of hl.instruments) for (const v of i.votes) expect(v.motion).not.toMatch(/^Item /);
  });

  it('marks a portal reached with a browser user agent as works, with the full note', () => {
    const j = read('equity-stage1').jurisdictions.find((x) => x.scope === 'state:va')!;
    expect(j.portals[0].status).toBe('works');
    expect(j.portals[0].how).toMatch(/browser user agent/);
  });

  it('stores saved copies relative to the research root and unrecorded methods as unrecorded', () => {
    const vb = read('equity-stage1').instruments.find((i) => i.id === 'VA-VBCPS-0408-15F-2025')!;
    expect(vb.provenance.saved_copy?.path).toBe('equity-stage1/raw/vb/040825M.pdf');
    const hl = read('homelessness-stage1');
    expect(hl.instruments.every((i) => i.provenance.method === 'unrecorded')).toBe(true);
  });

  it('notes the inferred nay count of the MCCSC vote', () => {
    const m = read('equity-stage1').instruments.find((i) => i.id === 'IN-MCCSC-5518-2023')!;
    expect(m.votes[0].note).toMatch(/inferred/);
  });
});

describe('dead ends', () => {
  it('append helper still validates', () => {
    const d = read('equity-supplement').deadEnds[0];
    appendDeadEnd(root, d);
    expect(validateStore(root)).toEqual([]);
  });
});
