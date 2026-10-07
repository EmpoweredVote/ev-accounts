import { describe, it, expect, vi, beforeEach } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

const mockQuery = vi.fn();
vi.mock('./db.js', () => ({ pool: { query: (...a: unknown[]) => mockQuery(...a), connect: vi.fn() } }));

vi.mock('./supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));

import {
  SEASON_IS_PUBLISHED, servedRevisionLateral,
  UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL, UPSERT_ANSWER_IN_SEASON_SQL, UPSERT_CONTEXT_IN_SEASON_SQL,
} from './seasonService.js';
import { writeVerifiedStance, accumulateEvidence } from './researchEvidenceService.js';

// Research can be PRE-STAGED into a DRAFT season (`--season draft` on the stance scripts). Its rows
// carry the draft season's id. They must reach NO voter read until the season opens.
//
// Why this is a static gate and not only unit tests: the failure is a read nobody thought of. On
// 2026-10-07 two such reads existed — the public coverage maps counted a person as "researched" on
// ANY politician_answers row, and getCompassPoliticians listed anyone holding one — so a draft-only
// answer would have put a person on the voter compass. Every reader of the three tables is checked.

const SRC = new URL('..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

const blankComments = (text: string) =>
  text.replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, ' ')).replace(/\/\/[^\n]*/g, (m) => m.replace(/[^\n]/g, ' '));

interface Reader { rel: string; line: number; guarded: boolean; marker: string | null }

const TABLES = /inform\.politician_(answers|context_evidence|context)\b/;
const WRITE = /^`\s*(?:--[^\n]*\n\s*)*(INSERT|UPDATE|DELETE)\b/i;
// The shared predicate, or a spelled-out draft exclusion (the citations read excludes draft EVIDENCE rows).
const GUARD = /\$\{SEASON_IS_PUBLISHED\}|status\s*<>\s*'draft'|NOT EXISTS \(SELECT 1 FROM inform\.seasons ds WHERE ds\.id = \w+\.season_id AND ds\.status = 'draft'\)/;
const MARKER = /@draft-(?:reads|scope):\s*(ADMIN-ONLY|INCLUDES-DRAFT)\s*(?:—|--|-)?\s*(\S.*)?/;

function scan(): Reader[] {
  const out: Reader[] = [];
  const files = readdirSync(SRC, { recursive: true, encoding: 'utf8' })
    .filter((f) => f.endsWith('.ts') && !f.endsWith('.test.ts'))
    .filter((f) => f.split(sep).join('/') !== 'types/database.types.ts');
  for (const f of files) {
    const raw = readFileSync(join(SRC, f), 'utf8');
    const text = blankComments(raw);
    const re = /`(?:[^`\\]|\\[\s\S])*`/g;
    let m: RegExpExecArray | null;
    while ((m = re.exec(text)) !== null) {
      const body = m[0];
      if (!TABLES.test(body) || WRITE.test(body)) continue;
      const line = text.slice(0, m.index).split('\n').length;
      const before = raw.split('\n').slice(Math.max(0, line - 14), line).join('\n');
      out.push({ rel: relative(SRC, join(SRC, f)).split(sep).join('/'), line, guarded: GUARD.test(body), marker: MARKER.exec(before)?.[1] ?? null });
    }
  }
  return out;
}

describe('a draft-season research write is not visible on any voter read', () => {
  const readers = scan();

  it('finds the readers at all — a scan that matches nothing proves nothing', () => {
    expect(readers.length).toBeGreaterThanOrEqual(25);
  });

  it('every reader of answers / context / evidence excludes draft, or is declared admin-only', () => {
    const offenders = readers.filter((r) => !r.guarded && r.marker === null).map((r) => `${r.rel}:${r.line}`);
    expect(offenders, offenders.length
      ? 'these read inform.politician_answers/context/context_evidence with no draft exclusion — add ' +
        '`AND ${SEASON_IS_PUBLISHED}` to the seasons join, or declare `@draft-reads: ADMIN-ONLY — <reason>` above the literal:\n  '
        + offenders.join('\n  ') : undefined).toEqual([]);
  });

  it('the unguarded readers are exactly the editor surfaces, and each states why', () => {
    const marked = readers.filter((r) => !r.guarded && r.marker !== null).map((r) => r.rel).sort();
    expect([...new Set(marked)]).toEqual(['lib/researchEvidenceService.ts', 'lib/seasonCompositionService.ts', 'lib/seasonService.ts']);
  });

  it('the public coverage maps and the compass politician list read published seasons only', () => {
    for (const rel of ['lib/coverageMapService.ts', 'lib/coverageService.ts', 'lib/electionsMapService.ts', 'lib/federalCoverage.ts', 'lib/compassService.ts']) {
      const mine = readers.filter((r) => r.rel === rel);
      expect(mine.length, rel).toBeGreaterThan(0);
      expect(mine.filter((r) => !r.guarded), rel).toEqual([]);
    }
  });
});

describe('the in-season writes', () => {
  it('write an OPEN or DRAFT season by id, never a closed one', () => {
    for (const sql of [UPSERT_ANSWER_IN_SEASON_SQL, UPSERT_CONTEXT_IN_SEASON_SQL]) {
      expect(sql).toMatch(/s\.status IN \('open', 'draft'\)/);
      expect(sql).not.toMatch(/closed/);
      expect(sql).toMatch(/s\.id = \$\d::uuid/);
    }
  });
  it('the draft writes land on a row the voter reads exclude', () => {
    // A row in a draft season has s.status = 'draft'; SEASON_IS_PUBLISHED is false for it.
    expect(SEASON_IS_PUBLISHED).toBe("s.status <> 'draft'");
  });
  it('the open-season statements are untouched', () => {
    expect(UPSERT_ANSWER_SQL).toContain("s.status = 'open'");
    expect(UPSERT_CONTEXT_SQL).toContain("s.status = 'open'");
  });
});

describe('writeVerifiedStance routing', () => {
  const run = vi.fn();
  beforeEach(() => { run.mockReset().mockResolvedValue({ rows: [], rowCount: 1 }); });
  const base = { politicianId: 'p', topicId: 't', value: 3, reasoning: 'why', sources: ['u'], editorId: 'e' };

  it('without a season id it runs the original open-season statements, with the original params', async () => {
    await writeVerifiedStance(base, { query: run } as never);
    expect(run.mock.calls[0]).toEqual([UPSERT_ANSWER_SQL, ['p', 't', 3, 'e']]);
    expect(run.mock.calls[1]).toEqual([UPSERT_CONTEXT_SQL, ['p', 't', 'why', ['u'], 'e']]);
  });
  it('with a season id it writes that season, answer and context together', async () => {
    await writeVerifiedStance({ ...base, seasonId: 'draft-id' }, { query: run } as never);
    expect(run.mock.calls[0]).toEqual([UPSERT_ANSWER_IN_SEASON_SQL, ['p', 't', 3, 'e', 'draft-id']]);
    expect(run.mock.calls[1]).toEqual([UPSERT_CONTEXT_IN_SEASON_SQL, ['p', 't', 'why', ['u'], 'e', 'draft-id']]);
  });
  it('evidence for a draft season attaches to that season\'s own context row, not the newest published one', async () => {
    const row = { politician_id: 'p', topic_id: 't', source_url: 'u', snippet: 's', snippet_index: 0, batch_id: 'b' };
    await accumulateEvidence([row], { query: run } as never, { seasonId: 'draft-id' });
    const [sql, params] = run.mock.calls[0];
    expect(String(sql)).toMatch(/c\.season_id = \$7::uuid/);
    expect(String(sql)).not.toContain('SEASON_IS_PUBLISHED');
    expect(params.at(-1)).toBe('draft-id');
    run.mockClear();
    await accumulateEvidence([row], { query: run } as never);
    expect(String(run.mock.calls[0][0])).toContain("s.status <> 'draft'");
  });
});

describe('servedRevisionLateral', () => {
  it('is the voters\' status list, byte for byte, unless a caller opts in', () => {
    expect(servedRevisionLateral('x', 'eff')).toContain("AND e.status IN ('published', 'superseded')");
    expect(servedRevisionLateral('x', 'eff')).not.toContain('approved');
  });
  it('counts an approved revision only when the caller says the pin is a draft season\'s', () => {
    const sql = servedRevisionLateral('x', 'eff', { includeApprovedWhen: 'IS_DRAFT' });
    expect(sql).toContain("e.status = 'approved' AND (IS_DRAFT)");
    expect(sql).toContain("e.status IN ('published', 'superseded')");
  });
});

describe('the voter citations read', () => {
  it('excludes evidence rows written for a draft season', async () => {
    const { getPoliticianCitations } = await import('./compassService.js');
    mockQuery.mockReset().mockResolvedValue({ rows: [] });
    await getPoliticianCitations('pol');
    const sql = String(mockQuery.mock.calls[0][0]);
    expect(sql).toContain("ds.id = pce.season_id AND ds.status = 'draft'");
  });
});
