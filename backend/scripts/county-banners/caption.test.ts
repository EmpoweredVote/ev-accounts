import { describe, it, expect } from 'vitest';
import { captionNamesPlace, confirmByCaption, registrableDomain, type PlaceNames } from './caption.js';
import type { CandidateFile } from './types.js';

const DELAWARE: PlaceNames = {
  county: 'Kent County',
  state: 'Delaware',
  stateUsps: 'DE',
  places: [],
  placeListAvailable: false,
};

const NEBRASKA_WITH_PLACES: PlaceNames = {
  county: 'Dawson County',
  state: 'Nebraska',
  stateUsps: 'NE',
  places: ['Lexington', 'Cozad', 'Gothenburg'],
  placeListAvailable: true,
};

function file(over: Partial<CandidateFile> = {}): CandidateFile {
  return {
    title: 'File:Courthouse.jpg', url: 'https://upload.wikimedia.org/a/b.jpg',
    width: 3000, height: 2000, licence: 'cc0', author: 'Someone',
    date: null, sourceCategory: 'Category:Kent County, Delaware', lat: null, lon: null,
    caption: null, creditUrl: null,
    ...over,
  } as CandidateFile;
}

describe('captionNamesPlace', () => {
  it('matches a caption naming the county and the state', () => {
    expect(captionNamesPlace('Old State House, Kent County, Delaware', DELAWARE))
      .toBe('Kent County');
  });

  it('matches a caption naming a place inside the county', () => {
    expect(captionNamesPlace('Grain elevator at Cozad, Nebraska', NEBRASKA_WITH_PLACES))
      .toBe('Cozad');
  });

  it('matches the USPS code as well as the state name', () => {
    expect(captionNamesPlace('Courthouse, Lexington, NE', NEBRASKA_WITH_PLACES)).toBe('Lexington');
  });

  it('refuses a caption that names the place but NOT the state', () => {
    // 🔴 There is a Dawson County in six states and a Lexington in dozens. A bare place name
    // is the Colorado-photograph-on-a-Nebraska-county failure wearing a caption.
    expect(captionNamesPlace('Main Street, Lexington', NEBRASKA_WITH_PLACES)).toBeNull();
  });

  it('refuses a caption naming a DIFFERENT state', () => {
    expect(captionNamesPlace('Lexington, Kentucky', NEBRASKA_WITH_PLACES)).toBeNull();
  });

  it('falls back to the file\'s own category leaf when we hold no place list', () => {
    // 20 of 52 states have no place polygons at all, Delaware among them.
    expect(captionNamesPlace('The refuge at Bombay Hook, Delaware', {
      ...DELAWARE, categoryLeaf: 'Bombay Hook',
    })).toBe('Bombay Hook');
  });

  it('ignores case and accents', () => {
    expect(captionNamesPlace('COZAD, NEBRASKA', NEBRASKA_WITH_PLACES)).toBe('Cozad');
  });

  it('does not match a place name embedded in a longer word', () => {
    expect(captionNamesPlace('Cozadium Hall, Nebraska', NEBRASKA_WITH_PLACES)).toBeNull();
  });
});

describe('registrableDomain', () => {
  it('reduces a host to its last two labels', () => {
    expect(registrableDomain('https://www.flickr.com/photos/x')).toBe('flickr.com');
    expect(registrableDomain('https://commons.wikimedia.org/wiki/File:A.jpg')).toBe('wikimedia.org');
  });

  it('returns null for something that is not a url', () => {
    expect(registrableDomain('own work')).toBeNull();
  });
});

describe('confirmByCaption', () => {
  const ok = async () => 'A photograph taken at Cozad, Nebraska in 2019.';

  it('locates a file whose caption and confirming source agree', async () => {
    const r = await confirmByCaption(
      file({ caption: 'Grain elevator at Cozad, Nebraska', creditUrl: 'https://www.flickr.com/photos/x' }),
      NEBRASKA_WITH_PLACES, { fetchText: ok },
    );
    expect(r.located).toBe(true);
    expect(r.matchedPlace).toBe('Cozad');
    expect(r.confirmingSourceUrl).toBe('https://www.flickr.com/photos/x');
    expect(r.captionSourceUrl).toContain('commons.wikimedia.org/wiki/');
  });

  it('refuses when there is no caption at all', async () => {
    const r = await confirmByCaption(file({ caption: null }), NEBRASKA_WITH_PLACES, { fetchText: ok });
    expect(r.located).toBe(false);
    expect(r.reason).toMatch(/no caption/i);
  });

  it('refuses when the confirming source shares a registrable domain with the caption', async () => {
    // 🔴 Commons citing Commons is one source twice, not two sources.
    const r = await confirmByCaption(
      file({ caption: 'Cozad, Nebraska', creditUrl: 'https://upload.wikimedia.org/x.jpg' }),
      NEBRASKA_WITH_PLACES, { fetchText: ok },
    );
    expect(r.located).toBe(false);
    expect(r.reason).toMatch(/independent/i);
  });

  it('refuses when the confirming page does not name the matched place', async () => {
    const r = await confirmByCaption(
      file({ caption: 'Cozad, Nebraska', creditUrl: 'https://www.flickr.com/photos/x' }),
      NEBRASKA_WITH_PLACES, { fetchText: async () => 'A photograph of a barn.' },
    );
    expect(r.located).toBe(false);
    expect(r.reason).toMatch(/does not name/i);
  });

  it('returns located:false with a reason when the confirming fetch throws, never throws itself', async () => {
    const r = await confirmByCaption(
      file({ caption: 'Cozad, Nebraska', creditUrl: 'https://www.flickr.com/photos/x' }),
      NEBRASKA_WITH_PLACES, { fetchText: async () => { throw new Error('ETIMEDOUT'); } },
    );
    expect(r.located).toBe(false);
    expect(r.reason).toMatch(/could not read/i);
  });

  it('carries placeListAvailable through, so the operator is told what could not be checked', async () => {
    const r = await confirmByCaption(
      file({ caption: 'Bombay Hook, Delaware', creditUrl: 'https://www.flickr.com/photos/x' }),
      { ...DELAWARE, categoryLeaf: 'Bombay Hook' },
      { fetchText: async () => 'Bombay Hook National Wildlife Refuge.' },
    );
    expect(r.located).toBe(true);
    expect(r.placeListAvailable).toBe(false);
  });
});
