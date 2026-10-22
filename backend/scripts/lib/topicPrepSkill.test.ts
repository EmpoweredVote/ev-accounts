/**
 * topicPrepSkill.test.ts — structural checks on the season-topic-prep skill folder.
 *
 * The skill is Markdown, so nothing compiles it. These checks catch the drift that would make a run
 * stall or go wrong: a purpose that is no longer the first thing a session reads (spec §1), a link to
 * a companion file that was renamed, an `npm run` name that no longer exists, Monday ids that do not
 * parse, a Stage 4 SQL template that lost a placeholder or the guidance step, and the equity R1 reading
 * drifting out of the topic-scoped section of the rulebook. Filesystem reads only.
 */
import { describe, it, expect } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { BLANK_CLASSES } from './seatRate.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const skillDir = resolve(backendDir, '..', '.claude', 'skills', 'season-topic-prep');
const read = (rel: string) => readFileSync(join(skillDir, rel), 'utf8');

describe('season-topic-prep SKILL.md', () => {
  it('has name season-topic-prep and a description', () => {
    const md = read('SKILL.md');
    const fm = md.match(/^---\n([\s\S]*?)\n---/);
    expect(fm).not.toBeNull();
    expect(fm![1]).toMatch(/^name: season-topic-prep$/m);
    const desc = fm![1].match(/^description: (.+)$/m);
    expect(desc).not.toBeNull();
    expect(desc![1].length).toBeGreaterThan(40);
  });

  it('opens with the purpose', () => {
    const md = read('SKILL.md');
    const sections = md.split(/^## /m).slice(1);
    expect(sections.length).toBeGreaterThan(0);
    const first = sections[0];
    expect(first.split('\n')[0].trim()).toBe('Purpose');
    expect(first).toMatch(/seat/);
  });

  it('every file SKILL.md links to exists', () => {
    const md = read('SKILL.md');
    const links = [...md.matchAll(/\]\(([^)\s]+)\)/g)].map((m) => m[1]).filter((l) => !/^(https?:|mailto:|#)/.test(l));
    expect(links.length).toBeGreaterThan(0);
    for (const l of links) {
      const p = resolve(skillDir, l.split('#')[0]);
      expect(existsSync(p), `missing link target ${l}`).toBe(true);
    }
  });

  it('every npm script SKILL.md names exists in backend/package.json', () => {
    const md = read('SKILL.md');
    const scripts = JSON.parse(readFileSync(join(backendDir, 'package.json'), 'utf8')).scripts as Record<string, string>;
    const names = [...new Set([...md.matchAll(/npm run ([a-z:-]+)/g)].map((m) => m[1]))];
    expect(names.length).toBeGreaterThan(0);
    for (const n of names) expect(scripts[n], `npm script ${n}`).toBeDefined();
  });
});

describe('season-topic-prep companion files', () => {
  const files = ['SKILL.md', 'STAGE4-RECIPE.md', 'SOURCE-STORE.md', 'ADVERSARIAL-CHECK.md', 'RULINGS.md',
    'templates/drafter-prompt.md', 'templates/BRIEF-census-local.md', 'templates/BRIEF-census-state.md', 'templates/BRIEF-stage1.md'];

  it('every npm script any of them names exists, and every link resolves', () => {
    const scripts = JSON.parse(readFileSync(join(backendDir, 'package.json'), 'utf8')).scripts as Record<string, string>;
    for (const f of files) {
      const md = read(f);
      for (const m of md.matchAll(/npm run ([a-z:-]+)/g)) expect(scripts[m[1]], `${f}: npm script ${m[1]}`).toBeDefined();
      const base = dirname(join(skillDir, f));
      for (const m of md.matchAll(/\]\(([^)\s]+)\)/g)) {
        if (/^(https?:|mailto:|#)/.test(m[1])) continue;
        expect(existsSync(resolve(base, m[1].split('#')[0])), `${f}: missing link target ${m[1]}`).toBe(true);
      }
    }
  });

  it('SKILL.md lists exactly the blank classes topic:seat-rate accepts', () => {
    const md = read('SKILL.md');
    const line = md.split('\n').find((l) => l.includes('`blank_class` is'));
    expect(line, 'the rows.tsv columns paragraph').toBeDefined();
    const para = md.slice(md.indexOf(line!), md.indexOf(line!) + 300);
    for (const c of BLANK_CLASSES) expect(para, c).toContain(`\`${c}\``);
  });

  it('the Stage 4 recipe re-audits carried seats and the facts template counts voter answer rows', () => {
    expect(read('STAGE4-RECIPE.md')).toMatch(/reaudit\/carry\.json/);
    expect(read('templates/stage4-facts.sql')).toMatch(/voter_answer_rows[\s\S]*inform\.compass_responses/);
    expect(read('templates/stage4-revision.sql')).toContain('as answer rows: {{EXPECTED_DISPOSITIONS}}');
  });
});

describe('season-topic-prep config.json', () => {
  it('parses and has boardId 18417210762 and groupId group_mm46qn8m, with three status labels', () => {
    const c = JSON.parse(read('config.json'));
    expect(c.monday.boardId).toBe('18417210762');
    expect(c.monday.groupId).toBe('group_mm46qn8m');
    for (const k of ['working', 'stuck', 'done']) {
      expect(typeof c.monday.statusLabels[k]).toBe('string');
      expect(c.monday.statusLabels[k].length).toBeGreaterThan(0);
    }
  });
});

describe('season-topic-prep stage4-revision.sql', () => {
  it('has every placeholder and sets guidance on the draft row', () => {
    const sql = read('templates/stage4-revision.sql');
    const placeholders = [
      'SLOT', 'TOPIC_KEY', 'TOPIC_ID', 'REV_PREV_ID', 'TITLE', 'SHORT_TITLE', 'QUESTION', 'GUIDANCE',
      'RUNG_1', 'RUNG_2', 'RUNG_3', 'RUNG_4', 'RUNG_5', 'RUNG_MAP', 'RATIONALE', 'PUBLIC_NOTE', 'REVIEW_REF',
      'S2_COUNT', 'S3_COUNT',
    ];
    for (const p of placeholders) expect(sql, `{{${p}}}`).toContain(`{{${p}}}`);
    expect(sql).toContain('UPDATE inform.compass_topic_revisions SET guidance');
  });

  it('sets guidance before approving (guidance is not a propose parameter)', () => {
    const sql = read('templates/stage4-revision.sql');
    const update = sql.indexOf('UPDATE inform.compass_topic_revisions SET guidance');
    const approve = sql.indexOf('PERFORM inform.admin_approve_topic_revision');
    expect(update).toBeGreaterThan(-1);
    expect(approve).toBeGreaterThan(-1);
    expect(update).toBeLessThan(approve);
  });
});

describe('season-topic-prep RULINGS.md', () => {
  it('lists equity R1 under topic-scoped readings', () => {
    const md = read('RULINGS.md');
    const sec = md.split(/^## /m).find((s) => /^topic-scoped readings/i.test(s));
    expect(sec, 'a "Topic-scoped readings" section').toBeDefined();
    expect(sec!).toMatch(/education-equity-programs/);
    expect(sec!).toMatch(/\bR1\b/);
  });
});
