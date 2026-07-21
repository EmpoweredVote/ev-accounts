/**
 * Essentials location-search routes — place-name resolver + national-fallback
 * floor (Phase 212-05, RSLV-01/04/05/06/07).
 *
 * GET /api/essentials/location-search        — ranked candidate list (RSLV-01/07)
 * GET /api/essentials/location-search/resolve — national-fallback floor + single
 *                                                US House rep + CD-overlap note
 *                                                (RSLV-05/06)
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used directly — architecture.test.ts bans it
 *     from routes/; all database access goes through lib/locationSearchService.ts
 *     and lib/essentialsBrowseService.ts.
 *   - optionalAuth — both routes are public, unauthenticated reads.
 *   - RSLV-04: this file never imports the Census one-line address geocoding
 *     helper. Place-name resolution stays fully separate from street-address
 *     geocoding.
 *   - National-fallback wiring REUSES the existing, unmodified
 *     getStatewideOfficials / getFederalOfficials / getCongressionalOverlapNote /
 *     getPoliticiansByArea / getPoliticiansByGovernmentList functions — no new
 *     statewide/federal/House SQL is written here (212-RESEARCH.md Pattern 3).
 */

import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { searchPlaceNames, LocationSearchQueryTooShortError } from '../lib/locationSearchService.js';
import {
  getStatewideOfficials,
  getFederalOfficials,
  getCongressionalOverlapNote,
  getPoliticiansByArea,
  getPoliticiansByGovernmentList,
} from '../lib/essentialsBrowseService.js';
import type { Request, Response } from 'express';
import type { PoliticianFlatRecord } from '../lib/essentialsService.js';

const router = Router();

// ---------------------------------------------------------------------------
// pickHouseRep — 212-06 gap-closure fix (D-01 defect).
//
// getPoliticiansByArea(cdGeoId, 'G5200') resolves EVERY district that
// overlaps the CD's own geometry — city councils, state-leg seats, school
// boards, AND the CD's own US House seat — so `houseReps[0]` (ordered only by
// p.id) was an arbitrary local/state official, never guaranteed to be the
// actual House member (observed live: MA CD 2501 -> a MA state house rep;
// AZ CD 0406 -> a Marana city councilor instead of Rep. Juan Ciscomani).
//
// The real US House member is the one record whose district_type is
// 'NATIONAL_LOWER' (the MTFCC_DISTRICT_TYPE_GUARD pairing for 'G5200', see
// geoIdGuard.ts) AND whose geo_id matches the CD we asked about — extracted
// as a pure function so the selection logic is unit-testable without a DB.
// ---------------------------------------------------------------------------
export function pickHouseRep(
  records: PoliticianFlatRecord[],
  cdGeoId: string
): PoliticianFlatRecord | null {
  return (
    records.find((r) => r.district_type === 'NATIONAL_LOWER' && r.geo_id === cdGeoId) ?? null
  );
}

// ---------------------------------------------------------------------------
// Known MTFCC set the resolver's candidates emit (V5 Input Validation).
// '' is the state-tier sentinel: a State-type governments row has no paired
// geofence_boundaries row, so locationSearchService.ts's mapRow() emits
// `mtfcc: row.mtfcc ?? ''` for those candidates — an intentional, honest
// sentinel, not a missing value.
// ---------------------------------------------------------------------------
const KNOWN_MTFCCS = new Set<string>([
  '',
  'G4110', 'G4120', // City / place
  'G4020',          // County
  'G4040',          // Local (town/CCD)
  'G5200',          // Congressional district (current-officeholder vintage)
  'G5210',          // State senate (upper)
  'G5220',          // State house (lower)
  'G5400', 'G5410', 'G5420', // School districts
]);

// ---------------------------------------------------------------------------
// GET /api/essentials/location-search?q=&limit=
// Auth: optional — public place-name typeahead.
// Returns the resolver's ranked, disambiguated candidate list.
// Requires q >= 2 characters; returns 422 for shorter/invalid queries.
// ---------------------------------------------------------------------------

router.get('/', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const qRaw = req.query.q;
    const q = typeof qRaw === 'string' ? qRaw.trim() : '';

    if (q.length < 2) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'q must be at least 2 characters',
      });
      return;
    }

    const limitRaw = req.query.limit;
    const parsedLimit = typeof limitRaw === 'string' ? parseInt(limitRaw, 10) : NaN;
    const limit = Number.isFinite(parsedLimit) && parsedLimit > 0 ? Math.min(parsedLimit, 50) : 10;

    const candidates = await searchPlaceNames(q, limit);
    res.setHeader('Cache-Control', 'public, max-age=30');
    res.status(200).json(candidates);
  } catch (err) {
    if (err instanceof LocationSearchQueryTooShortError) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: err.message });
      return;
    }
    console.error('[GET /essentials/location-search] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/location-search/resolve?geo_id=&mtfcc=&state=
// Auth: optional — public national-fallback floor.
//
// Guarantees (RSLV-05/06, 212-CONTEXT.md D-01/D-02/D-03):
//   - statewide + federal ALWAYS run once `state` is known — the guaranteed
//     nationwide floor, even for a Gazetteer-only candidate with no seeded
//     local roster.
//   - congressional.representative is populated with the ACTUAL US House
//     member when exactly one CD overlaps (needsExactAddress===false); when
//     more than one CD overlaps, the full cdGeoIds list is returned with
//     needsExactAddress===true and NO auto-picked rep.
//   - county is best-effort: populated only where a county government has
//     been deep-seeded; an honest empty array otherwise (D-03 — never
//     fabricated).
//
// `state` MUST be the caller-supplied resolved candidate's own state (as
// returned by GET / above) — never re-derived from a name string (RSLV-07).
// ---------------------------------------------------------------------------

router.get('/resolve', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const geoIdRaw = req.query.geo_id;
    const mtfccRaw = req.query.mtfcc;
    const stateRaw = req.query.state;

    const geoId = typeof geoIdRaw === 'string' ? geoIdRaw.trim() : '';
    const mtfcc = typeof mtfccRaw === 'string' ? mtfccRaw.trim() : undefined;
    const state = typeof stateRaw === 'string' ? stateRaw.trim() : '';

    if (!geoId) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'geo_id is required' });
      return;
    }
    if (mtfcc === undefined || !KNOWN_MTFCCS.has(mtfcc)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'mtfcc must be a known MTFCC value' });
      return;
    }
    if (!/^[A-Z]{2}$/.test(state)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'state must be a 2-letter uppercase abbreviation' });
      return;
    }

    // D-01 floor: US Senators + Governor/state execs + US House — statewide
    // and federal run unconditionally on the resolved candidate's own state.
    const [statewide, federal, overlapNote, county] = await Promise.all([
      getStatewideOfficials(state),
      getFederalOfficials(),
      getCongressionalOverlapNote(geoId, mtfcc),
      // D-03: county officials are best-effort — only populated where a
      // county government row has been deep-seeded; honest empty array
      // otherwise. Never gated on area_type — getPoliticiansByGovernmentList
      // itself returns [] when no chamber exists for this geo_id.
      getPoliticiansByGovernmentList([geoId], state),
    ]);

    // D-02: the single US House guarantee. When exactly one CD overlaps and
    // the note says we don't need an exact address, fetch that district's
    // actual House representative via the existing getPoliticiansByArea
    // pattern (RESEARCH Pattern 3) rather than fabricating a placeholder.
    let representative = null;
    if (!overlapNote.needsExactAddress && overlapNote.cdGeoIds.length === 1) {
      const houseReps = await getPoliticiansByArea(overlapNote.cdGeoIds[0], 'G5200');
      representative = pickHouseRep(houseReps, overlapNote.cdGeoIds[0]);
    }

    res.status(200).json({
      statewide,
      federal,
      county,
      congressional: {
        cdGeoIds: overlapNote.cdGeoIds,
        needsExactAddress: overlapNote.needsExactAddress,
        representative,
      },
    });
  } catch (err) {
    console.error('[GET /essentials/location-search/resolve] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
