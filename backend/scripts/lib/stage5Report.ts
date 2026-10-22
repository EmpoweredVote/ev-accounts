/**
 * stage5Report.ts — Stage 5 steps 5 and 6: the split, the themes, the early check and the report.
 *
 * Counts the three outcomes (and "not yet researched") over the roster, overall, per level and per state;
 * the seats per rung; and the seat rate measured honestly, over everyone researched and over everyone with
 * on-topic evidence (design §6). `earlyCheck` applies the ruled bars (RULINGS.md "The Stage 5 early-check
 * bar"): stop when doesn't fit is MORE than 1 in 5 of the people with on-topic evidence, or when any one theme
 * holds more than 1 in 10 of them. Doesn't-fit cases whose only record is a No vote (`nay-only`) or a gated
 * vote (`gate`) are counted and reported apart, and left out of both sides of the bars: no rung change can
 * seat them, so they say nothing about the rungs (ruling 2026-10-22). Pure.
 */
import { z } from 'zod';
import type { Stage5Code } from './stage5Code.js';
import type { RosterRow } from './stage5Roster.js';

export const DOESNT_FIT_BAR = 0.2;
export const THEME_BAR = 0.1;

export const ThemesSchema = z.object({
  at: z.string(),
  read_notes: z.number().int().min(0),
  themes: z.array(z.object({
    name: z.string().min(1),
    points_at: z.enum(['rung-change', 'new-topic', 'nothing']),
    politician_ids: z.array(z.string()).min(1),
    summary: z.string().min(1),
  })),
});
export type Themes = z.infer<typeof ThemesSchema>;

export type Counts = { seated: number; doesntFit: number; noStance: number; notYet: number };
export type Stage5Summary = {
  overall: Counts;
  byLevel: Record<string, Counts>;
  byState: Record<string, Counts>;
  perRung: Record<string, number>;
  tags: Record<string, number>;
  /** Seated plus the doesn't-fit cases the bars judge (all doesn't fit minus those reported apart). */
  withEvidence: number;
  /** Doesn't-fit cases the bars judge. */
  barDoesntFit: number;
  /** Doesn't-fit cases reported apart, by blank class. */
  apart: Record<string, number>;
  seatRateAll: number | null;
  seatRateEvidence: number | null;
  /** `count` is the theme's doesn't-fit people in this summary, once each; `dropped` the ids it named that are not. */
  themes: { name: string; points_at: string; count: number; dropped: number; share: number | null; summary: string }[];
};

/** Blank classes no rung change can seat: reported apart from the bars. */
export const APART_CLASSES = new Set(['nay-only', 'gate']);

const zero = (): Counts => ({ seated: 0, doesntFit: 0, noStance: 0, notYet: 0 });
const KEY = { seated: 'seated', 'doesnt-fit': 'doesntFit', 'no-stance': 'noStance' } as const;

export function summarise(roster: RosterRow[], codes: Stage5Code[], themes?: Themes): Stage5Summary {
  const byPerson = new Map(codes.map((c) => [c.politician_id, c]));
  const overall = zero();
  const byLevel: Record<string, Counts> = {};
  const byState: Record<string, Counts> = {};
  const perRung: Record<string, number> = {};
  const tags: Record<string, number> = {};
  for (const r of roster) {
    const c = byPerson.get(r.politician_id);
    const k: keyof Counts = c ? KEY[c.outcome] : 'notYet';
    for (const bucket of [overall, (byLevel[r.level] ??= zero()), (byState[r.state ?? '(none)'] ??= zero())]) bucket[k]++;
    if (c?.outcome === 'seated' && c.value !== undefined) perRung[String(c.value)] = (perRung[String(c.value)] ?? 0) + 1;
    for (const t of c?.tags ?? []) tags[t] = (tags[t] ?? 0) + 1;
  }
  const fits = roster.map((r) => byPerson.get(r.politician_id)).filter((c): c is Stage5Code => c?.outcome === 'doesnt-fit');
  const apart: Record<string, number> = {};
  for (const c of fits) if (c.blank_class && APART_CLASSES.has(c.blank_class)) apart[c.blank_class] = (apart[c.blank_class] ?? 0) + 1;
  // Themes are judged over the same people as the bar.
  const doesntFit = new Set(fits.filter((c) => !(c.blank_class && APART_CLASSES.has(c.blank_class))).map((c) => c.politician_id));
  const researched = overall.seated + overall.doesntFit + overall.noStance;
  const barDoesntFit = doesntFit.size;
  const withEvidence = overall.seated + barDoesntFit;
  const allEvidence = overall.seated + overall.doesntFit;
  return {
    overall, byLevel, byState, perRung, tags, withEvidence, barDoesntFit, apart,
    seatRateAll: researched ? overall.seated / researched : null,
    seatRateEvidence: allEvidence ? overall.seated / allEvidence : null,
    themes: (themes?.themes ?? []).map((t) => {
      // Trust only ids that are doesn't-fit codes in this summary: a repeated, invented or out-of-unit id would
      // move the share, and the share alone can trigger or hide a stop.
      const named = new Set(t.politician_ids);
      const count = [...named].filter((pid) => doesntFit.has(pid)).length;
      return {
        name: t.name, points_at: t.points_at, summary: t.summary, count, dropped: named.size - count,
        share: withEvidence ? count / withEvidence : null,
      };
    }).sort((a, b) => b.count - a.count),
  };
}

export function earlyCheck(s: Stage5Summary): { stop: boolean; reasons: string[] } {
  const reasons: string[] = [];
  if (!s.withEvidence) return { stop: false, reasons: ['no one with on-topic evidence yet'] };
  const share = s.barDoesntFit / s.withEvidence;
  if (share > DOESNT_FIT_BAR) {
    reasons.push(`doesn't fit is ${s.barDoesntFit} of ${s.withEvidence} people with on-topic evidence (${pct(share)}), over 1 in 5`);
  }
  for (const t of s.themes) {
    if (t.share !== null && t.share > THEME_BAR) reasons.push(`theme "${t.name}" holds ${t.count} of ${s.withEvidence} (${pct(t.share)}), over 1 in 10`);
  }
  return { stop: reasons.length > 0, reasons };
}

const pct = (x: number | null) => (x === null ? '—' : `${(x * 100).toFixed(1)}%`);

function table(rows: [string, Counts][]): string[] {
  const out = ['| | seated | doesn\'t fit | no stance found | not yet researched |', '|---|---:|---:|---:|---:|'];
  for (const [k, c] of rows) out.push(`| ${k} | ${c.seated} | ${c.doesntFit} | ${c.noStance} | ${c.notYet} |`);
  return out;
}

export function formatReport(s: Stage5Summary, check: { stop: boolean; reasons: string[] }, title = 'Stage 5 report'): string {
  const o = s.overall;
  const lines = [
    `# ${title}`,
    '',
    !s.withEvidence
      ? '**Nothing to judge yet.** No one in these units has on-topic evidence coded.'
      : check.stop
      ? `**STOP — ask whether to fix the rungs first.** ${check.reasons.join('; ')}.`
      : `**Continue.** Doesn't fit is ${s.barDoesntFit} of ${s.withEvidence} people with on-topic evidence (${pct(s.withEvidence ? s.barDoesntFit / s.withEvidence : null)}); no theme is over 1 in 10.`,
    '',
    `Doesn't fit reported apart, outside the bars (no rung change can seat them): ${o.doesntFit - s.barDoesntFit}`
      + (Object.keys(s.apart).length ? ` (${Object.entries(s.apart).map(([k, n]) => `${k} ${n}`).join(', ')})` : '') + '.',
    '',
    `Seated ${o.seated}, doesn't fit ${o.doesntFit}, no stance found ${o.noStance}, not yet researched ${o.notYet}.`,
    `Seat rate: ${pct(s.seatRateAll)} of everyone researched; ${pct(s.seatRateEvidence)} of everyone with any on-topic evidence (reported-apart cases included).`,
    '',
    '## By level',
    ...table(Object.entries(s.byLevel)),
    '',
    '## By state',
    ...table(Object.entries(s.byState).sort(([a], [b]) => a.localeCompare(b))),
    '',
    '## Seats per rung',
    Object.keys(s.perRung).length ? Object.entries(s.perRung).sort().map(([r, n]) => `rung ${r}: ${n}`).join(' · ') : 'none',
    '',
    '## Themes in "doesn\'t fit"',
  ];
  if (!s.themes.length) lines.push('No theme pass yet.');
  for (const t of s.themes) {
    lines.push(`- **${t.name}** — ${t.count} (${pct(t.share)}), points at: ${t.points_at}. ${t.summary}${t.dropped ? ` (${t.dropped} id(s) named that are not doesn't-fit codes here: not counted)` : ''}`);
  }
  lines.push('', '## Starter tags used', Object.keys(s.tags).length ? Object.entries(s.tags).map(([t, n]) => `${t} ${n}`).join(' · ') : 'none', '');
  return lines.join('\n');
}

/** A code is filed as `<politician_id>.json`, so one person has one code and a stray file is caught. */
export function codeFileProblem(fileName: string, code: Pick<Stage5Code, 'politician_id'>): string | null {
  return fileName === `${code.politician_id}.json` ? null : `file name ${fileName} does not match politician_id ${code.politician_id}`;
}

/** 4 when the bar says stop (it wins: failed codes are left out of the counts and may hide part of a stop), 3 when codes failed, else 0. */
export function exitCode(stop: boolean, failedCodes: number): number {
  return stop ? 4 : failedCodes ? 3 : 0;
}
