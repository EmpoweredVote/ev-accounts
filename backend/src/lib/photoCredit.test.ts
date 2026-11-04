import { describe, it, expect } from 'vitest';
import { PHOTO_CREDIT_SELECT_SQL, creditIsIncomplete, type PhotoCredit } from './photoCredit.js';

const credit = (over: Partial<PhotoCredit> = {}): PhotoCredit => ({
  license: 'cc_by-sa_4.0', label: 'CC BY-SA 4.0',
  source_url: 'https://commons.wikimedia.org/wiki/File:X.jpg',
  attribution_required: true, ...over,
});

describe('creditIsIncomplete', () => {
  it('is false when a required credit has a source to point at', () => {
    expect(creditIsIncomplete(credit())).toBe(false);
  });

  it('is TRUE when attribution is required and we hold no source', () => {
    // The 43 rows CC_0326 could not recover. A research backlog, not a render bug.
    expect(creditIsIncomplete(credit({ source_url: '' }))).toBe(true);
  });

  it('is false when no attribution is owed, source or not', () => {
    expect(creditIsIncomplete(credit({ attribution_required: false, source_url: '' }))).toBe(false);
  });

  it('is false when there is no credit at all', () => {
    expect(creditIsIncomplete(null)).toBe(false);
    expect(creditIsIncomplete(undefined)).toBe(false);
  });
});

describe('PHOTO_CREDIT_SELECT_SQL', () => {
  it('labels every canonical token CC_0328 normalised to', () => {
    for (const t of ['cc0', 'cc_by_2.0', 'cc_by_3.0', 'cc_by_4.0',
                     'cc_by-sa_2.0', 'cc_by-sa_3.0', 'cc_by-sa_4.0', 'cc_by-sa']) {
      expect(PHOTO_CREDIT_SELECT_SQL).toContain(`pi.photo_license = '${t}'`);
    }
  });

  it('requires attribution for CC BY but NOT for CC0', () => {
    // Every CC licence except CC0 obliges a credit; CC0 is a public-domain dedication.
    // The pattern must therefore need the literal "by" and not merely "cc".
    const m = PHOTO_CREDIT_SELECT_SQL.match(/'attribution_required',\s*\(([^)]*)\)/);
    expect(m).not.toBeNull();
    expect(m![1]).toContain('cc[-_ ]?by');
    expect(m![1]).not.toMatch(/\^\\\\s\*cc['\s)]/);
  });

  it('refuses our own storage bucket as a source', () => {
    // 🔴 A CDN self-reference is not provenance: it presents our copy as its own licence page.
    expect(PHOTO_CREDIT_SELECT_SQL).toContain('kxsdzaojfaibhuzmclfq');
    expect(PHOTO_CREDIT_SELECT_SQL).toContain('supabase');
  });

  it('reads the DEFAULT image only, and is correlated on p alone', () => {
    // Correlating on `p` is what lets this constant drop into any query without colliding with
    // the caller's aliases — the same reason photoRestriction.ts is shaped this way.
    expect(PHOTO_CREDIT_SELECT_SQL).toContain("pi.type = 'default'");
    expect(PHOTO_CREDIT_SELECT_SQL).toContain('pi.politician_id = p.id');
  });

  it('yields nothing when no licence is recorded, rather than an empty credit', () => {
    expect(PHOTO_CREDIT_SELECT_SQL).toContain("btrim(coalesce(pi.photo_license, '')) <> ''");
  });

  it('does not disturb the photo_origin_url alias', () => {
    // 🔴 That alias is the image to DISPLAY (COALESCE over photo_custom_url). Serving provenance
    // through it would blank the portraits of everyone whose photo was never mirrored.
    expect(PHOTO_CREDIT_SELECT_SQL).not.toContain('AS photo_origin_url');
  });
});
