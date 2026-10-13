import { describe, it, expect } from 'vitest';
import {
  resolveByline, TEAM_BYLINE,
  type JournalAuthor, type JournalAttribution,
} from './journalAttribution.js';

const connected = (over: Partial<JournalAuthor> = {}): JournalAuthor =>
  ({ displayName: 'riverkeeper', legalName: 'Dana Reyes', isEmpowered: false, ...over });
const empowered = (over: Partial<JournalAuthor> = {}): JournalAuthor =>
  ({ displayName: 'riverkeeper', legalName: 'Dana Reyes', isEmpowered: true, ...over });

describe('resolveByline — the author tier sets the ceiling', () => {
  it('renders the handle for a Connected author who asked for one', () => {
    expect(resolveByline('handle', connected())).toBe('riverkeeper');
  });

  // 🔴 THE RULE THE WHOLE DESIGN RESTS ON. A Connected account's default is
  // privacy to the world. If their legal name rendered here while Focused
  // Communities rendered their handle, the two surfaces together would
  // de-anonymise them — on entries about abortion and the 2020 election.
  it('CLAMPS a Connected author who asked for their real name', () => {
    expect(resolveByline('real', connected())).toBe('riverkeeper');
  });

  // An Empowered account has already published the link between its name and
  // its activity — anyone may view its public compass. Nothing is left to leak,
  // so the preference is honoured.
  it('renders the legal name for an Empowered author who asked for it', () => {
    expect(resolveByline('real', empowered())).toBe('Dana Reyes');
  });

  it('still renders the handle for an Empowered author who asked for one', () => {
    expect(resolveByline('handle', empowered())).toBe('riverkeeper');
  });

  it('renders the team byline when attribution is none, at either tier', () => {
    expect(resolveByline('none', connected())).toBe(TEAM_BYLINE);
    expect(resolveByline('none', empowered())).toBe(TEAM_BYLINE);
  });
});

describe('resolveByline — fallbacks never leak a blank or a null', () => {
  it('falls back to the team byline when the handle is missing', () => {
    expect(resolveByline('handle', connected({ displayName: null }))).toBe(TEAM_BYLINE);
  });

  it('treats a whitespace-only handle as missing', () => {
    expect(resolveByline('handle', connected({ displayName: '   ' }))).toBe(TEAM_BYLINE);
  });

  // legal_name is populated on only 9 of the 12 Connected profiles, so an
  // Empowered author with no legal name on file is reachable, not theoretical.
  it('falls back to the handle when an Empowered author has no legal name', () => {
    expect(resolveByline('real', empowered({ legalName: null }))).toBe('riverkeeper');
  });

  it('falls back to the team byline when an Empowered author has neither', () => {
    expect(resolveByline('real', empowered({ legalName: '', displayName: null })))
      .toBe(TEAM_BYLINE);
  });

  it('never returns an empty string', () => {
    const all: JournalAttribution[] = ['none', 'handle', 'real'];
    for (const a of all) {
      for (const isEmpowered of [true, false]) {
        const out = resolveByline(a, { displayName: null, legalName: null, isEmpowered });
        expect(out.length).toBeGreaterThan(0);
      }
    }
  });
});

// ⚠ PIN THIS, OR SOMEONE WILL "FIX" IT. Tier is read live, so an author who
// demotes after publishing drops from legal name to handle on entries already
// out. That is correct — the undertaking ended — and the alternative is
// denormalising a legal name into the row, which the design forbids.
describe('resolveByline is a function of CURRENT tier, not of publish time', () => {
  it('the same row renders differently once its author demotes', () => {
    const row = { attribution: 'real' as const, displayName: 'riverkeeper', legalName: 'Dana Reyes' };
    expect(resolveByline(row.attribution, { ...row, isEmpowered: true })).toBe('Dana Reyes');
    expect(resolveByline(row.attribution, { ...row, isEmpowered: false })).toBe('riverkeeper');
  });
});
