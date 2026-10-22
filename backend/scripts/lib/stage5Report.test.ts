import { describe, it, expect } from 'vitest';
import { summarise, earlyCheck, formatReport, ThemesSchema, DOESNT_FIT_BAR, THEME_BAR, type Themes } from './stage5Report.js';
import type { Stage5Code } from './stage5Code.js';
import type { RosterRow } from './stage5Roster.js';

const id = (n: number) => `${String(n).padStart(8, '0')}-0000-4000-8000-000000000000`;
const row = (n: number, over: Partial<RosterRow> = {}): RosterRow => ({
  politician_id: id(n), full_name: `P${n}`, office_id: `o${n}`, level: 'state', state: 'IN', scope: 'sitting', leaving: 'no', race_ids: [], ...over,
});
const code = (n: number, outcome: Stage5Code['outcome'], value?: number): Stage5Code => ({
  politician_id: id(n), topic_key: 'voting-rights', season: 3, season_id: 's', revision_id: 'r', outcome,
  ...(value !== undefined ? { value } : {}), reasoning: 'r', tags: [], finding_ids: [], codebook: '0.6', coded_by: 'c', coded_at: 'now',
  ...(outcome === 'doesnt-fit' ? { open_note: 'note' } : {}),
} as Stage5Code);

/** n people with evidence: `fit` doesnt-fit, the rest seated at rung 4; plus `none` no-stance. */
function fixture(withEvidence: number, fit: number, none = 0) {
  const roster: RosterRow[] = [];
  const codes: Stage5Code[] = [];
  for (let i = 0; i < withEvidence + none; i++) {
    roster.push(row(i));
    codes.push(i < fit ? code(i, 'doesnt-fit') : i < withEvidence ? code(i, 'seated', 4) : code(i, 'no-stance'));
  }
  return { roster, codes };
}

describe('earlyCheck', () => {
  it('uses the ruled bars', () => {
    expect(DOESNT_FIT_BAR).toBe(0.2);
    expect(THEME_BAR).toBe(0.1);
  });

  it('does not stop at exactly 1 in 5', () => {
    const { roster, codes } = fixture(100, 20);
    expect(earlyCheck(summarise(roster, codes)).stop).toBe(false);
  });

  it('stops above 1 in 5', () => {
    const { roster, codes } = fixture(100, 21);
    const c = earlyCheck(summarise(roster, codes));
    expect(c.stop).toBe(true);
    expect(c.reasons.join()).toMatch(/21 of 100/);
  });

  it('stops when one theme alone is above 1 in 10, naming it', () => {
    const { roster, codes } = fixture(100, 15);
    const themes: Themes = { at: 'now', read_notes: 15, themes: [
      { name: 'Backs ID with no rung act', points_at: 'rung-change', politician_ids: Array.from({ length: 11 }, (_, i) => id(i)), summary: 's' },
      { name: 'Other', points_at: 'nothing', politician_ids: [id(11)], summary: 's' },
    ] };
    const c = earlyCheck(summarise(roster, codes, themes));
    expect(c.stop).toBe(true);
    expect(c.reasons.join()).toMatch(/Backs ID with no rung act/);
  });

  it('leaves no-stance people out of the denominator', () => {
    const { roster, codes } = fixture(10, 2, 90);
    const s = summarise(roster, codes);
    expect(s.withEvidence).toBe(10);
    expect(earlyCheck(s).stop).toBe(false);
  });

  it('does not stop when no one has evidence yet', () => {
    expect(earlyCheck(summarise([row(1)], [])).stop).toBe(false);
  });
});

describe('summarise', () => {
  it('computes both seat rates over the whole roster', () => {
    const { roster, codes } = fixture(8, 3, 2); // 5 seated, 3 doesnt-fit, 2 no-stance
    roster.push(row(50)); // not yet researched
    const s = summarise(roster, codes);
    expect(s.overall).toEqual({ seated: 5, doesntFit: 3, noStance: 2, notYet: 1 });
    expect(s.seatRateAll).toBeCloseTo(5 / 10);
    expect(s.seatRateEvidence).toBeCloseTo(5 / 8);
    expect(s.perRung['4']).toBe(5);
  });

  it('counts per level and per state, and ignores codes for people off the roster', () => {
    const roster = [row(1, { level: 'federal', state: 'NC' }), row(2)];
    const s = summarise(roster, [code(1, 'seated', 2), code(2, 'no-stance'), code(99, 'seated', 3)]);
    expect(s.byLevel.federal.seated).toBe(1);
    expect(s.byState.IN.noStance).toBe(1);
    expect(s.overall.seated).toBe(1);
  });
});

describe('formatReport and ThemesSchema', () => {
  it('prints the split and the decision', () => {
    const { roster, codes } = fixture(100, 21);
    const s = summarise(roster, codes);
    const text = formatReport(s, earlyCheck(s));
    expect(text).toMatch(/STOP/);
    expect(text).toMatch(/doesn't fit/);
  });
  it('says there is nothing to judge when no one has evidence yet', () => {
    const s = summarise([row(1)], []);
    expect(formatReport(s, earlyCheck(s))).toMatch(/Nothing to judge yet/);
  });
  it('refuses a theme with no cases', () => {
    expect(ThemesSchema.safeParse({ at: 'now', read_notes: 1, themes: [{ name: 'x', points_at: 'nothing', politician_ids: [], summary: 's' }] }).success).toBe(false);
  });
});
