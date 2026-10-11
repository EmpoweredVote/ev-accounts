import { describe, it, expect } from 'vitest';
import { renderAnnexSkeleton, annexPath } from './codebookAnnex.js';

const topic = {
  topic_id: 't1',
  topic_key: 'school-vouchers',
  served_revision_id: 'rev-9',
  question_text: 'How should vouchers work?',
  stances: [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value} text` })),
  roles: [{ level: 'state' }, { level: 'federal' }, { level: 'local', evidence_basis: 'own-words' }],
};

describe('renderAnnexSkeleton', () => {
  const md = renderAnnexSkeleton(topic, 'Season 2');
  it('heads the file with the topic key, served revision and season', () =>
    expect(md.split('\n')[0]).toBe('# school-vouchers — served revision rev-9 (Season 2)'));
  it('quotes every rung verbatim, in order', () => {
    for (const v of [1, 2, 3, 4, 5]) expect(md).toContain(`${v}. "rung ${v} text"`);
    expect(md.indexOf('1. "rung 1')).toBeLessThan(md.indexOf('5. "rung 5'));
  });
  it('leaves orientation explicitly unset (stance-program P4 is owed) rather than guessing', () =>
    expect(md).toContain('Orientation: UNSET'));
  it('lists the asked levels and the own-words ones (CA_0302)', () =>
    expect(md).toContain('Asked at: federal, local, state (compass_topic_roles). Own words only at: local'));
  it('marks every guidance field for a human to fill', () =>
    expect(md.match(/_fill: /g)?.length).toBe(5 * 5 + 2));
});

describe('annexPath', () => {
  // annexPath uses path.join, so the separator is the platform's. Comparing against a literal
  // '/'-joined string asserted the separator rather than the segments, and failed on Windows only.
  it('lives under docs/codebook/annex', () =>
    expect(annexPath('/repo', 'school-vouchers').replaceAll('\\', '/'))
      .toBe('/repo/docs/codebook/annex/school-vouchers.md'));
});
