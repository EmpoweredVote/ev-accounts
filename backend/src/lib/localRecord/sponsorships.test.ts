import { describe, expect, it } from 'vitest';
import type { NameFile, TermSpan } from './names.js';
import { resolveSponsorships, sponsorSubject, type SponsorFinding } from './sponsorships.js';

// Synthetic ids stand in for politician ids. No variant "PiedmontSmith" is listed, so the hyphen retry is tested.
const names: NameFile = {
  city: 'place:1805860',
  members: [
    { politicianId: 'p-piedmont', onboardId: null, variants: ['Isabel Piedmont-Smith', 'Piedmont-Smith'] },
    { politicianId: 'p-volan', onboardId: null, variants: ['Dave Rollo', 'Rollo'] },
    { politicianId: 'p-stosberg', onboardId: null, variants: ['Matt Flaherty', 'Flaherty'] },
    { politicianId: 'p-new', onboardId: null, variants: ['Isak Nti Asare', 'Nti Asare'] },
  ],
};
const terms: TermSpan[] = [
  { politicianId: 'p-piedmont', start: '2020-01-01', end: null },
  { politicianId: 'p-volan', start: '2020-01-01', end: null },
  { politicianId: 'p-stosberg', start: '2020-01-01', end: null },
  { politicianId: 'p-new', start: '2024-01-02', end: null },
];

function finding(over: Partial<SponsorFinding> & { names?: [string, 'sponsor' | 'cosponsor'][] }): SponsorFinding {
  const list = over.names ?? [['Rollo', 'sponsor']];
  return {
    itemNumber: 'Ord 2023-11',
    label: null,
    date: '2023-05-03',
    sourceKind: 'minutes',
    sourceDocumentId: null,
    found: {
      label: over.label ?? null,
      sentence: 'Sponsored by someone.',
      names: list.map(([printed, role]) => ({ printed, role })),
      placeholder: false,
    },
    ...over,
  } as SponsorFinding;
}

describe('sponsorSubject', () => {
  it('joins the item and the amendment label', () => {
    expect(sponsorSubject('Ord 2025-41', null)).toBe('Ord 2025-41');
    expect(sponsorSubject('Ord 2025-41', 'Amendment 01')).toBe('Ord 2025-41 / Amendment 01');
  });
});

describe('resolveSponsorships', () => {
  it('resolves Smith to Piedmont-Smith when the printed text is "PiedmontSmith"', () => {
    const { sponsorships, problems } = resolveSponsorships(
      [finding({ names: [['PiedmontSmith', 'sponsor']] })],
      names,
      terms,
    );
    expect(problems).toEqual([]);
    expect(sponsorships).toHaveLength(1);
    expect(sponsorships[0]).toMatchObject({ politicianId: 'p-piedmont', role: 'sponsor', nameAsPrinted: 'PiedmontSmith' });
  });

  it('holds a whole sentence when one of two names is unknown', () => {
    const { sponsorships, problems } = resolveSponsorships(
      [
        finding({
          itemNumber: 'Ord 2023-11',
          label: 'Amendment 01',
          names: [['Rollo', 'sponsor'], ['Nobody', 'cosponsor']],
        }),
      ],
      names,
      terms,
    );
    expect(sponsorships).toEqual([]);
    expect(problems).toHaveLength(1);
    expect(problems[0].cause).toBe('sponsor_unresolved');
    expect(problems[0].subject).toBe('Ord 2023-11 / Amendment 01');
  });

  it('merges an amendment named in both the memorandum and the minutes into one row per member, kept from the minutes', () => {
    const base = { itemNumber: 'Ord 2023-11', label: 'Amendment 01' };
    const { sponsorships, problems } = resolveSponsorships(
      [
        finding({ ...base, sourceKind: 'memorandum', sourceDocumentId: 'doc-memo', names: [['Rollo', 'sponsor'], ['Flaherty', 'cosponsor']] }),
        finding({ ...base, sourceKind: 'minutes', sourceDocumentId: 'doc-min', names: [['Councilmember Rollo', 'sponsor'], ['Flaherty', 'cosponsor']] }),
        finding({ ...base, sourceKind: 'legislation_feed', names: [['Rollo', 'sponsor'], ['Flaherty', 'cosponsor']] }),
      ],
      names,
      terms,
    );
    expect(problems).toEqual([]);
    expect(sponsorships).toHaveLength(2);
    expect(sponsorships.every((s) => s.sourceKind === 'minutes' && s.sourceDocumentId === 'doc-min')).toBe(true);
    expect(sponsorships.map((s) => s.politicianId).sort()).toEqual(['p-stosberg', 'p-volan']);
  });

  it('raises sponsor_disagrees when the feed and the minutes name different sponsors', () => {
    const { sponsorships, problems } = resolveSponsorships(
      [
        finding({ sourceKind: 'legislation_feed', names: [['Rollo', 'sponsor']] }),
        finding({ sourceKind: 'minutes', names: [['Flaherty', 'sponsor']] }),
      ],
      names,
      terms,
    );
    expect(sponsorships).toEqual([]);
    expect(problems).toHaveLength(1);
    expect(problems[0]).toMatchObject({ cause: 'sponsor_disagrees', subject: 'Ord 2023-11' });
    expect((problems[0].detail as unknown[]).length).toBe(2);
  });

  it('raises sponsor_disagrees for the same label on different meeting dates with different names', () => {
    const { sponsorships, problems } = resolveSponsorships(
      [
        finding({ label: 'Amendment 01', date: '2023-05-03', names: [['Rollo', 'sponsor']] }),
        finding({ label: 'Amendment 01', date: '2023-06-07', names: [['Flaherty', 'sponsor']] }),
      ],
      names,
      terms,
    );
    expect(sponsorships).toEqual([]);
    expect(problems.map((p) => p.cause)).toEqual(['sponsor_disagrees']);
  });

  it('per sentence: an unresolved Minutes sentence is raised, and the clean feed sentence for the same subject is still written', () => {
    const { sponsorships, problems } = resolveSponsorships(
      [
        finding({ sourceKind: 'minutes', names: [['Nobodyknown', 'sponsor']], found: { label: null, sentence: 'Minutes: sponsored by Cm. Nobodyknown.', names: [{ printed: 'Nobodyknown', role: 'sponsor' }], placeholder: false } }),
        finding({ sourceKind: 'legislation_feed', sourceDocumentId: 'doc-feed', found: { label: null, sentence: 'This Ordinance, sponsored by Councilmember Rollo, amends a code.', names: [{ printed: 'Rollo', role: 'sponsor' }], placeholder: false } }),
      ],
      names,
      terms,
    );
    expect(problems).toEqual([
      expect.objectContaining({ cause: 'sponsor_unresolved', subject: 'Ord 2023-11', detail: expect.objectContaining({ reason: 'name', sentence: 'Minutes: sponsored by Cm. Nobodyknown.' }) }),
    ]);
    expect(sponsorships).toEqual([
      expect.objectContaining({ politicianId: 'p-volan', role: 'sponsor', sourceKind: 'legislation_feed', sourceDocumentId: 'doc-feed' }),
    ]);
  });

  it('the same person in different roles across two sources disagrees', () => {
    const { sponsorships, problems } = resolveSponsorships(
      [finding({ sourceKind: 'minutes' }), finding({ sourceKind: 'memorandum', names: [['Rollo', 'cosponsor']] })],
      names,
      terms,
    );
    expect(sponsorships).toEqual([]);
    expect(problems.map((p) => p.cause)).toEqual(['sponsor_disagrees']);
  });

  it('raises sponsor_unresolved for a placeholder', () => {
    const f = finding({});
    f.found = { label: null, sentence: 'Sponsored by [CM sponsor needed].', names: [], placeholder: true };
    const { sponsorships, problems } = resolveSponsorships([f], names, terms);
    expect(sponsorships).toEqual([]);
    expect(problems).toEqual([
      {
        cause: 'sponsor_unresolved',
        subject: 'Ord 2023-11',
        detail: { reason: 'placeholder', sentence: 'Sponsored by [CM sponsor needed].' },
      },
    ]);
  });

  it('a name not seated on the date is unresolved', () => {
    const { sponsorships, problems } = resolveSponsorships(
      [finding({ date: '2023-05-03', names: [['Nti Asare', 'sponsor']] })],
      names,
      terms,
    );
    expect(sponsorships).toEqual([]);
    expect(problems).toHaveLength(1);
    expect(problems[0].cause).toBe('sponsor_unresolved');
  });
});
