import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, it, expect } from 'vitest';
import { SUMMARY_JOB_HEADING, coderSummary, summaryJobSection, takeSummary, usableCoderDraft, withSummaryJob } from './stage5CoderSummary.js';

const WRITER = readFileSync(join(__dirname, '../../../.claude/skills/season-topic-prep/templates/stage5-summary-writer.md'), 'utf8');
const sentences = [{ text: 'She has voted for limits on guns.', lead: true }, { text: 'She voted for a red flag bill.', cites: ['f1'] }];

describe('the summary job in a coder brief', () => {
  it("is cut from the real writer template: the writer's rules, its sides filled, no slot left, no People section", () => {
    const job = summaryJobSection(WRITER, '1,2,3/4,5');
    expect(job.startsWith(SUMMARY_JOB_HEADING)).toBe(true);
    expect(job).toContain('A summary is one short paragraph');
    expect(job).toContain('### Writing rules'); // demoted one level, so it sits under the job's own heading
    expect(job).toContain('(`sides`: 1,2,3/4,5)');
    expect(job).toContain('Two bills in one part');
    expect(job).toContain('"summary": { "sentences": [');
    expect(job).not.toMatch(/\{\{\w+\}\}/);
    expect(job).not.toContain('## People');
    expect(job).not.toContain("listed under each person's findings");
  });

  it('refuses a writer template that has lost its landmarks, rather than send a brief with no rules', () => {
    expect(() => summaryJobSection('# Writer\n\n## People\n', null)).toThrow(/no longer holds/);
    expect(() => summaryJobSection('A summary is one short paragraph. {{NEW_SLOT}}\n\n## People\n', null)).toThrow(/NEW_SLOT/);
  });

  it('goes before the rulings, which stay last; at the end when the brief has no rulings heading', () => {
    const out = withSummaryJob('# Brief\n\n## Output\n\nshape\n\n## Rulings and notes for this batch\n\nr1\n', 'JOB\n');
    expect(out.indexOf('JOB')).toBeGreaterThan(out.indexOf('## Output'));
    expect(out.indexOf('JOB')).toBeLessThan(out.indexOf('## Rulings and notes for this batch'));
    expect(withSummaryJob('# Brief\n', 'JOB\n').endsWith('JOB\n')).toBe(true);
  });
});

describe("a coder's summary beside its code", () => {
  it('is split off the entry, so it never reaches the code file', () => {
    const t = takeSummary({ politician_id: 'p', outcome: 'seated', value: 3, summary: { sentences } });
    expect(t.entry).toEqual({ politician_id: 'p', outcome: 'seated', value: 3 });
    expect(t.sentences).toEqual(sentences); expect(t.problem).toBeNull();
    expect(takeSummary({ politician_id: 'p', outcome: 'no-stance' })).toEqual({ entry: { politician_id: 'p', outcome: 'no-stance' }, sentences: null, problem: null });
  });

  it('drops a malformed summary with a reason, and still returns the code entry without it', () => {
    for (const bad of [{ sentences: 'text' }, { sentences: [] }, 'a paragraph', { sentences: [{ text: 1 }] }]) {
      const t = takeSummary({ politician_id: 'p', outcome: 'seated', summary: bad });
      expect(t.sentences).toBeNull(); expect(t.problem).toMatch(/not kept/); expect('summary' in t.entry).toBe(false);
    }
  });

  it('is stored only for seated and doesnt-fit', () => {
    expect(coderSummary({ politician_id: 'p', topic_key: 't', outcome: 'seated', value: 3 } as never, sentences, 'nv-01'))
      .toEqual({ politician_id: 'p', topic_key: 't', outcome: 'seated', value: 3, batch: 'nv-01', sentences });
    expect(coderSummary({ politician_id: 'p', topic_key: 't', outcome: 'doesnt-fit' } as never, sentences, 'nv-01')?.value).toBeNull();
    expect(coderSummary({ politician_id: 'p', topic_key: 't', outcome: 'no-stance' } as never, sentences, 'nv-01')).toBeNull();
  });

  it('is used only while the code is the one it was written for', () => {
    const stored = { politician_id: 'p', topic_key: 't', outcome: 'doesnt-fit', value: null, batch: 'nv-01', sentences };
    expect(usableCoderDraft(stored, { outcome: 'doesnt-fit' } as never).draft).toEqual({ politician_id: 'p', topic_key: 't', sentences });
    // A review seated the person after coding: the summary was written for no seat, so the writer takes over.
    const stale = usableCoderDraft(stored, { outcome: 'seated', value: 4 } as never);
    expect(stale.draft).toBeNull(); expect(stale.why).toBe('written for doesnt-fit; the code is now seated 4');
    expect(usableCoderDraft({ ...stored, outcome: 'seated', value: 3 }, { outcome: 'seated', value: 4 } as never).draft).toBeNull();
    expect(usableCoderDraft(undefined, { outcome: 'seated', value: 4 } as never)).toEqual({ draft: null, why: 'no coder summary on file' });
  });
});
