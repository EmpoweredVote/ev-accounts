import { describe, it, expect, vi } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

// seasonService pulls in db.js, which validates env at import time and calls
// process.exit(1) when it is absent — the same reason every sibling test mocks
// it. Nothing here touches the pool; only the exported SQL constant is read.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

import { SEASON_IS_PUBLISHED } from './seasonService.js';

// 🔴 WHAT THIS PREVENTS, MEASURED RATHER THAN IMAGINED.
//
// Every season-aware read collapses to the newest season with `s.number DESC`.
// Nothing in that ordering asks whether the season was ever published, so a
// DRAFT season's rows win the collapse and reach the public API — while the
// ladder TEXT keeps coming from `compass_topics_promoted`, which follows the
// OPEN season's pin.
//
// Run against prod on 2026-09-03 with a rolled-back copy of the Season 2
// re-pointing, that combination produced:
//
//   rung served for one moved politician   2  ->  3
//   ladder version the product serves     v1  ->  v1   (unchanged)
//   politicians shown on Housing rung 2  757  ->  0
//
// 2,685 answers would have changed what they display while the words beside
// them did not move. This file is the gate that keeps the 20th site from being
// added without that thought.
//
// It is a vitest, not a scripts/check-*.mjs CI job, on purpose: ci.yml documents
// that every job bills a one-minute minimum on ~494 runs a month, and this rides
// inside the `backend` job that already runs.

const SRC = new URL('..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

function sourceFiles(root: string): string[] {
  return readdirSync(root, { recursive: true, encoding: 'utf8' })
    .filter((f) => f.endsWith('.ts') && !f.endsWith('.test.ts'))
    .filter((f) => f.split(sep).join('/') !== 'types/database.types.ts')
    .map((f) => join(root, f));
}

/**
 * Blank out comments, keeping every newline so offsets — and therefore line
 * numbers — survive.
 *
 * 🔴 THIS IS LOAD-BEARING. Prose in a JSDoc block quotes SQL in inline backtick
 * spans ("prefer the `LATERAL … ORDER BY s.number DESC LIMIT 1` form"), and the
 * literal regex below cannot tell that from a real query. Without this the scan
 * reports the documentation as an unguarded consumer — which is the false
 * positive that gets a gate switched off rather than obeyed.
 */
function blankComments(text: string): string {
  const blank = (m: string) => m.replace(/[^\n]/g, ' ');
  return text
    .replace(/\/\*[\s\S]*?\*\//g, blank)
    .replace(/\/\/[^\n]*/g, blank);
}

/** Every backtick literal in the file, with the line it starts on. */
function templateLiterals(text: string): { body: string; line: number }[] {
  const out: { body: string; line: number }[] = [];
  const re = /`(?:[^`\\]|\\[\s\S])*`/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(text)) !== null) {
    out.push({ body: m[0], line: text.slice(0, m.index).split('\n').length });
  }
  return out;
}

/**
 * A collapse to the newest season.
 *
 * 🔴 COUNTED, NOT TESTED FOR PRESENCE. One template literal can hold more than
 * one collapse — `getCompassPoliticians` builds answer_count and
 * answered_topic_ids as two subqueries in a single literal. A presence test
 * passes that literal as long as ONE of them is guarded, which is exactly the
 * hole a probe found in the first draft of this file: deleting one guard left
 * the other and the gate stayed green.
 */
const COLLAPSES_BY_SEASON = /s\.number\s+DESC/gi;

/** Carries the shared predicate, or names s.status itself (the write paths do). */
const GUARDED = /\$\{SEASON_IS_PUBLISHED\}|s\.status/g;

const count = (re: RegExp, s: string) => (s.match(new RegExp(re.source, re.flags)) ?? []).length;

/**
 * The stated exception, in the same shape as `@season-scope: all-seasons`:
 * a marker is not enough, it has to carry a reason.
 */
const INCLUDES_DRAFT = /@draft-scope:\s*INCLUDES-DRAFT\s*(?:—|--|-)?\s*(\S.*)?/;

interface Site {
  rel: string; line: number;
  collapses: number; guards: number;
  declared: string | null;
}

function scan(): Site[] {
  const sites: Site[] = [];
  for (const path of sourceFiles(SRC)) {
    const raw = readFileSync(path, 'utf8');
    const rel = relative(SRC, path).split(sep).join('/');
    for (const { body, line } of templateLiterals(blankComments(raw))) {
      const collapses = count(COLLAPSES_BY_SEASON, body);
      if (collapses === 0) continue;
      // The marker lives in a comment ABOVE the literal, so look at the lines
      // just before it — and at the RAW source, since blankComments erased it.
      const before = raw.split('\n').slice(Math.max(0, line - 14), line).join('\n');
      const m = INCLUDES_DRAFT.exec(before);
      sites.push({
        rel, line, collapses,
        guards: count(GUARDED, body),
        declared: m ? (m[1] ?? '').trim() : null,
      });
    }
  }
  return sites;
}

describe('a draft season is not published data', () => {
  const sites = scan();

  it('finds the season collapses at all — a scan that matches nothing proves nothing', () => {
    expect(sites.length).toBeGreaterThanOrEqual(15);
  });

  it('every season collapse either excludes draft or declares why it does not', () => {
    const offenders = sites
      .filter((s) => s.guards < s.collapses && s.declared === null)
      .map((s) => `${s.rel}:${s.line} (${s.collapses} collapse(s), ${s.guards} guard(s))`);

    expect(offenders, offenders.length
      ? `these collapse by season without excluding draft rows — add ` +
        `\`AND \${SEASON_IS_PUBLISHED}\` to the seasons join, or declare ` +
        `\`@draft-scope: INCLUDES-DRAFT — <reason>\` above the literal:\n  ` +
        offenders.join('\n  ')
      : undefined).toEqual([]);
  });

  // An escape hatch nobody can enumerate is an escape hatch nobody reviews.
  it('exactly one site declares the exception, and it is the admin compose screen', () => {
    const declared = sites.filter((s) => s.declared !== null);
    expect(declared.map((s) => s.rel)).toEqual(['lib/seasonCompositionService.ts']);
  });

  it('the exception states a reason rather than just carrying the marker', () => {
    const declared = sites.filter((s) => s.declared !== null);
    for (const s of declared) {
      expect((s.declared ?? '').length, `${s.rel}:${s.line} declares the marker with no reason`)
        .toBeGreaterThan(20);
    }
  });
});

describe('SEASON_IS_PUBLISHED', () => {
  // 🔴 The distinction that makes this correct rather than merely restrictive.
  // `= 'open'` would ALSO hide a closed season, and after a changeover a
  // politician answered only in Season 1 would vanish from the compass rather
  // than show their Season 1 answer. That is ADR 0005 §1.4 — reads follow the
  // person, not the calendar. Draft is the one status that was never published.
  it("excludes draft only, never narrowing to the open season", () => {
    expect(SEASON_IS_PUBLISHED).toContain("<> 'draft'");
    expect(SEASON_IS_PUBLISHED).not.toContain("= 'open'");
  });

  it('is a bare predicate on the `s` alias, so it drops into a seasons join', () => {
    expect(SEASON_IS_PUBLISHED.trim()).toMatch(/^s\.status\b/);
    expect(SEASON_IS_PUBLISHED).not.toMatch(/\b(WHERE|AND|JOIN)\b/i);
  });
});
