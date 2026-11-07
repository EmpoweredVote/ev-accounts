import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it, expect } from 'vitest';
import { fillTemplate, formatLadderText, templateSlots, TemplateFillError } from './stage5Template.js';

const templates = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..', '.claude', 'skills', 'season-topic-prep', 'templates');
const themeTemplate = readFileSync(join(templates, 'stage5-theme-prompt.md'), 'utf8');
const rungs = [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value} words` }));

describe('fillTemplate', () => {
  it('fills every slot and deletes the orchestrator comment', () => {
    const out = fillTemplate('<!-- Orchestrator: fill every {{…}}. -->\n\n# {{A}} and {{B}}, {{A}} again', { A: 'x', B: 'y' });
    expect(out).toBe('# x and y, x again');
  });

  it('refuses a slot with no value, naming it', () => {
    expect(() => fillTemplate('{{A}} {{LADDER_TEXT}}', { A: 'x' })).toThrow(/no value for \{\{LADDER_TEXT\}\}/);
  });

  it('refuses an empty value', () => {
    expect(() => fillTemplate('{{LADDER_TEXT}}', { LADDER_TEXT: '  \n' })).toThrow(/empty value for \{\{LADDER_TEXT\}\}/);
  });

  it('refuses a value that fills no slot (a misspelt key)', () => {
    expect(() => fillTemplate('{{LADDER_TEXT}}', { LADDER_TEXT: 'l', LADER_TEXT: 'l' })).toThrow(/value given for no slot: LADER_TEXT/);
  });

  it('refuses a result that still holds {{', () => {
    expect(() => fillTemplate('{{A}}', { A: 'see {{B}}' })).toThrow(TemplateFillError);
    expect(() => fillTemplate('{{A}} {{ not-a-slot }}', { A: 'x' })).toThrow(/left in the result/);
  });
});

describe('the theme template', () => {
  it('asks for the ladder, and the filler fills all of it', () => {
    expect(templateSlots(themeTemplate)).toEqual(['TOPIC_KEY', 'DATE', 'LADDER_TEXT', 'NOTES_FILE']);
    const out = fillTemplate(themeTemplate, {
      TOPIC_KEY: 'voting-rights', DATE: '2026-11-06', NOTES_FILE: '/abs/notes.jsonl',
      LADDER_TEXT: formatLadderText('Should voters show ID?', rungs),
    });
    expect(out).toContain('Question: Should voters show ID?\n\n1. rung 1 words');
    expect(out).toContain('5. rung 5 words');
    expect(out).not.toMatch(/\{\{|<!--/);
  });

  it('without the ladder it is refused (the Mississippi theme pass, 2026-11-05)', () => {
    expect(() => fillTemplate(themeTemplate, { TOPIC_KEY: 'voting-rights', DATE: '2026-11-05', NOTES_FILE: '/n' }))
      .toThrow(/no value for \{\{LADDER_TEXT\}\}/);
  });
});

describe('formatLadderText', () => {
  it('orders the rungs by value', () => {
    expect(formatLadderText('Q?', [...rungs].reverse())).toBe(
      'Question: Q?\n\n1. rung 1 words\n2. rung 2 words\n3. rung 3 words\n4. rung 4 words\n5. rung 5 words');
  });

  it('refuses a partial ladder, a blank sentinel row or an empty rung', () => {
    expect(() => formatLadderText('Q?', rungs.slice(0, 4))).toThrow(/expected rungs 1-5/);
    expect(() => formatLadderText('Q?', [{ value: 0, text: 'blank' }, ...rungs])).toThrow(/expected rungs 1-5/);
    expect(() => formatLadderText('Q?', rungs.map((r) => (r.value === 3 ? { ...r, text: ' ' } : r)))).toThrow(/rung 3/);
    expect(() => formatLadderText(' ', rungs)).toThrow(/question text is empty/);
  });
});
