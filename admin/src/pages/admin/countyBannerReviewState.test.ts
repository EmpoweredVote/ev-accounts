import { describe, it, expect } from 'vitest';
import {
  emptyKind, keepBlocker, savingLineText, saveStampText, frameStatus, creditLine,
  type CountyReviewRow, type CandidateRow,
} from './countyBannerReviewState';

function candidate(over: Partial<CandidateRow> = {}): CandidateRow {
  return {
    commonsTitle: 'File:A.jpg', rankPosition: 0, frameUrl: 'https://x/f.jpg',
    sourcePageUrl: 'https://commons.wikimedia.org/wiki/File:A.jpg',
    width: 3000, height: 2000, licence: 'cc0', author: 'Someone',
    locatedBy: 'geometry', captionText: null, captionSourceUrl: null,
    confirmingSourceUrl: null, placeListAvailable: null, ...over,
  };
}

function county(over: Partial<CountyReviewRow> = {}): CountyReviewRow {
  return {
    geoid: '10001', stateUsps: 'DE', countyName: 'Kent County', status: 'pending',
    chosenTitle: null, verticalAnchor: null, focus: null, captionSighted: false,
    swept: true, filesSwept: 231, categoriesFound: 4, categoryErrors: 0,
    geometryCandidates: 5, captionCandidates: 0, rejected: {},
    decidedAt: null, decidedBy: null, candidates: [candidate()], ...over,
  };
}

describe('emptyKind — a county with no candidates must say WHICH kind of zero it is', () => {
  it('is null when the county has candidates', () => {
    expect(emptyKind(county())).toBeNull();
  });

  it('says never swept when nobody has looked', () => {
    const k = emptyKind(county({ swept: false, candidates: [], filesSwept: 0, categoriesFound: 0 }));
    expect(k!.kind).toBe('not_swept');
    expect(k!.text).toMatch(/not been swept/i);
  });

  it('says the sweep LOST categories when it errored, which is not an empty county', () => {
    // 🔴 This is the WAF-challenge case. "I looked and there was nothing" over a hole in the
    // search is the one claim this surface must never make.
    const k = emptyKind(county({ swept: false, candidates: [], categoryErrors: 2 }));
    expect(k!.kind).toBe('sweep_failed');
    expect(k!.text).toMatch(/2 categor/i);
    expect(k!.text).not.toMatch(/no photograph/i);
  });

  it('says the category title probably missed when the sweep found no categories at all', () => {
    // Virginia's "Richmond city" — a real county whose Commons category is named differently.
    const k = emptyKind(county({ candidates: [], categoriesFound: 0, filesSwept: 0 }));
    expect(k!.kind).toBe('no_categories');
    expect(k!.text).toMatch(/categor/i);
  });

  it('says genuinely no usable photograph when the sweep worked and found none', () => {
    const k = emptyKind(county({ candidates: [], categoriesFound: 3, filesSwept: 40, rejected: { too_small: 40 } }));
    expect(k!.kind).toBe('no_usable_photograph');
    expect(k!.text).toMatch(/40 file/i);
  });

  it('names the commonest rejection reason, so a round 2 knows what to look for', () => {
    const k = emptyKind(county({
      candidates: [], categoriesFound: 3, filesSwept: 40,
      rejected: { too_small: 31, author_absent: 9 },
    }));
    expect(k!.text).toMatch(/too small/i);
  });
});

describe('keepBlocker — the page refuses for the same reasons the service does', () => {
  it('blocks a keep with nothing selected', () => {
    expect(keepBlocker(county(), null, false)).toMatch(/choose/i);
  });

  it('blocks a keep whose focus is not set', () => {
    expect(keepBlocker(county({ focus: null, verticalAnchor: 0.3 }), 'File:A.jpg', false))
      .toMatch(/crop/i);
  });

  it('blocks a caption-located option until the operator confirms they looked', () => {
    const c = county({
      focus: '50% 30%', verticalAnchor: 0.3,
      candidates: [candidate({ locatedBy: 'caption', captionText: 'The courthouse, Dover' })],
    });
    expect(keepBlocker(c, 'File:A.jpg', false)).toMatch(/confirm/i);
    expect(keepBlocker(c, 'File:A.jpg', true)).toBeNull();
  });

  it('allows a geometry-located keep with a crop set', () => {
    expect(keepBlocker(county({ focus: '50% 30%', verticalAnchor: 0.3 }), 'File:A.jpg', false))
      .toBeNull();
  });

  it('blocks a keep naming a candidate this county does not have', () => {
    expect(keepBlocker(county({ focus: '50% 30%', verticalAnchor: 0.3 }), 'File:GONE.jpg', false))
      .toMatch(/not .*option/i);
  });
});

describe('savingLineText — visible from load, never hidden until something breaks', () => {
  it('says saving is on', () => {
    expect(savingLineText({ writable: true })).toMatch(/saving is on/i);
  });

  it('says saving is OFF loudly when the API says so', () => {
    expect(savingLineText({ writable: false })).toMatch(/NOT be saved/);
  });

  it('says it could not tell, rather than assuming writable, before the probe answers', () => {
    expect(savingLineText(null)).toMatch(/checking/i);
  });
});

describe('saveStampText — per item, with a time or a reason', () => {
  it('reports a save with the time the DATABASE returned', () => {
    expect(saveStampText({ kind: 'saved', decidedAt: '2026-11-20T10:00:00.000Z' }))
      .toMatch(/Saved 2026-11-20/);
  });

  it('reports NOT SAVED with the reason', () => {
    const t = saveStampText({ kind: 'failed', reason: 'A county that needs another look ships blank.' });
    expect(t).toMatch(/NOT SAVED/);
    expect(t).toContain('ships blank');
  });

  it('says nothing has been saved yet when there is no decision', () => {
    expect(saveStampText({ kind: 'none' })).toMatch(/not decided/i);
  });

  it('says saving rather than saved while the write is in flight', () => {
    // 🔴 The 2026-11-19 failure looked exactly like success. "Saving..." must never read as done.
    expect(saveStampText({ kind: 'saving' })).toMatch(/saving/i);
    expect(saveStampText({ kind: 'saving' })).not.toMatch(/\bSaved\b/);
  });
});

describe('frameStatus — a frame that did not load is a failure, never an empty box', () => {
  it('is ok for a frame with a url and no load error', () => {
    expect(frameStatus(candidate(), new Set())).toBe('ok');
  });

  it('is missing when the importer stored no url', () => {
    expect(frameStatus(candidate({ frameUrl: '' }), new Set())).toBe('missing');
  });

  it('is broken when the browser failed to load it', () => {
    expect(frameStatus(candidate(), new Set(['https://x/f.jpg']))).toBe('broken');
  });
});

describe('creditLine — Commons Artist is HTML and the operator must be able to read it', () => {
  it('strips tags and the anchor the field was truncated inside', () => {
    const stored = '<div class="fn value">\n<a rel="nofollow" class="external text" href="https://500px.com/chasemartin">Charles Skip Martin<';
    expect(creditLine(stored)).toBe('Charles Skip Martin');
  });

  it('leaves a plain author alone', () => {
    expect(creditLine('Jane Roe')).toBe('Jane Roe');
  });

  it('says so, rather than showing nothing, when the field strips to empty', () => {
    expect(creditLine('<div></div>')).toMatch(/unreadable/i);
  });
});
