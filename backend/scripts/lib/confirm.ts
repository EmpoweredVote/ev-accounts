/**
 * confirm — phase-1 CONFIRM (spec §1.6): code-only checks after the coders agree. Any finding
 * sends the row to a person. Identity guards against namesakes; dates guard pre-seating (§4.10)
 * and the statement cycle (ruling Q4); record passages are judged as one basis per instrument
 * group (via recordBasis.checkRecordGroup) — a vote or sponsorship record may span a vote/actor
 * page and a separate bill-text page, so the group as a whole must show the person acting, the
 * provision, and (for a vote) a readable, divided tally. Statements stay judged per passage.
 * 🟡 CAMPAIGN_LOOKBACK_DAYS is an implementation PROXY for "the current term, the current campaign,
 * or the campaign that seated them" — the operator may change it.
 */
import { normalizeText, checkNameProximity } from '../../src/lib/researchVerifier.js';
import type { Passage } from './coderLabel.js';
import type { PriorTerm, SeatContext } from './coderPrompt.js';
import { checkRecordGroup, instrumentKey, seatChamber, type PassageProfile } from './recordBasis.js';
import { resolveProfile, profileSeatChamber, profileTag, type SourceProfile } from './sourceProfiles.js';

export const CAMPAIGN_LOOKBACK_DAYS = 548;
export type ConfirmFinding =
  | 'identity-not-in-snapshot' | 'person-not-in-snapshot' | 'dates-imprecise' | 'record-before-term' | 'statement-out-of-cycle'
  | 'undated-evidence' | 'provision-missing' | 'record-not-this-office' | 'revision-drift' | 'rests-on-pointer'
  | 'instrument-mismatch' | 'vote-not-evidenced' | 'tally-unreadable' | 'near-unanimous-vote' | 'name-collision' | 'no-record-passage'
  | 'chamber-not-evidenced' | 'tally-other-vote' | 'no-source-profile' | 'amendment-markup-lost' | 'provision-deleted'
  | 'prior-service-unverified';

const escapeRe = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
/**
 * Word-boundary match on normalised text. A name of two characters or fewer never matches: a USPS
 * code ('in', 'ut') is on nearly every page, so it proves nothing about identity (final review item 1).
 */
export function namedOnPage(normalizedPage: string, name: string): boolean {
  const n = normalizeText(name);
  if (n.length <= 2) return false;
  return new RegExp(`(^|[^a-z0-9])${escapeRe(n)}($|[^a-z0-9])`).test(normalizedPage);
}

const minusDays = (iso: string, days: number): string => {
  const d = new Date(`${iso.slice(0, 10)}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - days);
  return d.toISOString().slice(0, 10);
};

export function earliestStatementDate(seat: SeatContext): string | null {
  const anchor = seat.mode === 'seated' ? seat.term_start : seat.election_date;
  return anchor ? minusDays(anchor, CAMPAIGN_LOOKBACK_DAYS) : null;
}

/** A coder date may be YYYY, YYYY-MM or YYYY-MM-DD; compare on its earliest possible day. */
const floorDate = (d: string): string => (d.length === 4 ? `${d}-01-01` : d.length === 7 ? `${d}-01` : d.slice(0, 10));
/**
 * Stance-program §4.10: "if the dates cannot settle it → review". A term start known only to its
 * year (or month) still settles a record from a LATER year (or month) — Glick, seated 2010 (year),
 * SB 1(ss) on 2022-08-05 — and a record from an EARLIER one; only the same year (month), or an
 * unknown start, cannot be settled. `d` is the record's floored date.
 */
function recordVsTermStart(d: string, start: string | null | undefined, precision: string | null | undefined): 'in' | 'before' | 'unsettled' {
  if (!start) return 'unsettled';
  const cut = precision === 'day' ? 10 : precision === 'month' ? 7 : precision === 'year' ? 4 : 0;
  if (cut === 0) return 'unsettled';
  const a = d.slice(0, cut), b = start.slice(0, cut);
  if (a > b) return 'in';
  if (a < b) return 'before';
  return cut === 10 ? 'in' : 'unsettled';
}

/**
 * Regular term length in years, by state and chamber (the states with source profiles, plus UT used in
 * tests): CA Const. art. IV §2 (Assembly 2, Senate 4); IN Const. art. 4 §3 (House 2, Senate 4); AZ Const.
 * art. IV pt. 2 §21 (both 2); UT Const. art. VI §3 (House 2, Senate 4). A state not listed has no
 * last-term rule, so an unknown start there stays strict.
 */
const TERM_YEARS: Record<string, { upper: number; lower: number }> = {
  CA: { upper: 4, lower: 2 }, IN: { upper: 4, lower: 2 }, AZ: { upper: 2, lower: 2 }, UT: { upper: 4, lower: 2 },
};
const minusYears = (iso: string, years: number): string => {
  const d = new Date(`${iso.slice(0, 10)}T00:00:00Z`);
  d.setUTCFullYear(d.getUTCFullYear() - years);
  return d.toISOString().slice(0, 10);
};

/**
 * Is `d` (a floored date) inside this closed term? Imprecise ends fail closed (never 'in').
 * An UNKNOWN start (OpenStates often records only when an earlier role ended) still covers the span's
 * final regular term — decision 2026-09-27 (b), Chris Andrews: a span that ended on a known day was held
 * for at least its last term, so a record dated within one term length before the end counts. Anything
 * earlier, or a state/chamber with no term-length rule, stays unsettled. (Known limit: a member who
 * resigned mid-term.)
 */
function inTerm(d: string, t: PriorTerm): boolean {
  if (t.term_end === null) return false;
  const end = t.term_end.slice(0, 10);
  if (d > end) return false;
  const v = recordVsTermStart(d, t.term_start, t.start_precision);
  if (v === 'in') return true;
  if (t.term_start !== null && t.start_precision !== 'unknown') return false;
  const chamber = t.chamber ?? seatChamber(t.office_title);
  const years = chamber ? TERM_YEARS[t.state_usps.toUpperCase()]?.[chamber] : undefined;
  return years !== undefined && d >= minusYears(end, years);
}

/**
 * Codebook V5 option B (ruling 2026-09-27, Chris Andrews): a record from before the current term
 * still counts when it was made in EITHER chamber of the same legislature. The source profile says
 * which body printed it (`body: legislature`, `scope: state:<USPS>`); the seat must itself be a
 * legislative seat of that state. Earlier service must be ON FILE (a closed term covering the date):
 * `{ covering }` supplies that term (the chamber check then uses its title), `{ unverified }` means the
 * route applies but nothing proves the person sat there then → prior-service-unverified. `null`
 * means the route does not apply (another body, another state, no profile) → record-before-term.
 */
function priorChamberRoute(d: string, seat: SeatContext, prof: SourceProfile | null):
  { covering: PriorTerm } | { unverified: true } | null {
  if (!prof || prof.body !== 'legislature' || !seat.state_usps) return null;
  if (prof.scope.toUpperCase() !== `STATE:${seat.state_usps.toUpperCase()}`) return null;
  if (!seatChamber(seat.office_title) && !profileSeatChamber(prof, seat.office_title)) return null;
  const covering = (seat.prior_terms ?? []).find((t) => t.state_usps.toUpperCase() === seat.state_usps!.toUpperCase() && inTerm(d, t));
  return covering ? { covering } : { unverified: true };
}

/** Extract lastName from full_name, dropping common suffixes like Jr, Sr, II, III, IV. */
const extractLastName = (fullName: string): string => {
  const parts = fullName.trim().split(/\s+/);
  if (parts.length === 0) return '';
  let lastName = parts[parts.length - 1];
  if (/^(jr|sr|ii|iii|iv)\.?$/i.test(lastName)) {
    lastName = parts.length > 1 ? parts[parts.length - 2] : lastName;
  }
  return lastName;
};

export interface ConfirmInput {
  seat: SeatContext;
  restsOnPassages: Passage[];
  snapshotText: ReadonlyMap<string, string>;
  /** snapshot_id -> source_kind (from snapshots.json). An id missing here counts as a pointer (fail closed). */
  sourceKind: ReadonlyMap<string, string>;
  rowServedRevisionId: string;
  bundleServedRevisionId: string;
  /** snapshot_id -> original URL (snapshots.json). Used only with `profiles`. */
  snapshotUrl?: ReadonlyMap<string, string>;
  /** Loaded source profiles. Given → every record passage must resolve one, else no-source-profile. */
  profiles?: readonly SourceProfile[];
  /** snapshot_id -> amendment_markup (snapshots.json, amendment-markup spec §3/§4). A snapshot
   * missing here (an older snapshots.json with no such field) reads as 'unknown' — fail closed. */
  snapshotMarkup?: ReadonlyMap<string, 'kept' | 'none' | 'unknown'>;
}

export function confirmRow(i: ConfirmInput): ConfirmFinding[] { return confirmRowDetailed(i).findings; }

export function confirmRowDetailed(i: ConfirmInput): { findings: ConfirmFinding[]; profiles: string[] } {
  const out = new Set<ConfirmFinding>();
  const names = [...i.seat.jurisdiction_names, i.seat.office_title].filter(Boolean);
  const identityOk = i.restsOnPassages.some((p) => {
    const t = normalizeText(i.snapshotText.get(p.snapshot_id) ?? '');
    return names.some((n) => namedOnPage(t, n));
  });
  if (!identityOk) out.add('identity-not-in-snapshot');
  // Spec §5.4: a pointer is never evidence — a chair may not rest on one.
  if (i.restsOnPassages.some((p) => (i.sourceKind.get(p.snapshot_id) ?? 'pointer') === 'pointer')) out.add('rests-on-pointer');
  const cycleStart = earliestStatementDate(i.seat);
  const lastName = extractLastName(i.seat.full_name);

  // Records are judged as one basis per instrument (confirm-basis spec §2, defect D1): a vote or
  // sponsorship record may span a vote/actor page and a separate bill-text page.
  const records = i.restsOnPassages.filter((p) => p.v3_class === 'record');
  const statements = i.restsOnPassages.filter((p) => p.v3_class !== 'record');
  const groups = new Map<string, Passage[]>();
  for (const p of records) {
    const key = instrumentKey(p.instrument) ?? '∅';
    const group = groups.get(key) ?? [];
    group.push(p);
    groups.set(key, group);
  }

  // Every record passage must resolve a source profile when `i.profiles` is given (fail closed);
  // memoised per snapshot_id so a passage shared across groups is only looked up once.
  const used = new Set<string>();
  const profileCache = new Map<string, PassageProfile | null>();
  const profileOf = (p: Passage): PassageProfile | null => {
    if (!i.profiles) return null;
    if (profileCache.has(p.snapshot_id)) return profileCache.get(p.snapshot_id)!;
    const url = i.snapshotUrl?.get(p.snapshot_id);
    const prof = url ? resolveProfile(i.profiles, url) : null;
    let result: PassageProfile | null;
    if (!prof) { out.add('no-source-profile'); result = null; }
    else { used.add(profileTag(prof)); result = { rules: prof.rules, chamber: profileSeatChamber(prof, i.seat.office_title) }; }
    profileCache.set(p.snapshot_id, result);
    return result;
  };
  for (const p of records) profileOf(p);

  // V5 option B: a seated person's record dated before the current term, from the same legislature.
  // Decided per passage before the group check, because its chamber check must use the chamber of
  // the EARLIER term (or be skipped when no earlier term is on file — prior-service-unverified then
  // fails the row closed on its own).
  const rawProfile = (p: Passage): SourceProfile | null => {
    const url = i.snapshotUrl?.get(p.snapshot_id);
    return i.profiles && url ? resolveProfile(i.profiles, url) : null;
  };
  const priorRoute = new Map<Passage, { covering: PriorTerm } | { unverified: true } | null>();
  for (const p of records) {
    if (!p.date) continue;
    const d = floorDate(p.date);
    // Seated: only a record from BEFORE the current term needs the route. Candidate (V5 B extended to
    // candidates, ruling 2026-09-27): every record does — a candidate holds no term of this office.
    if (i.seat.mode === 'seated' && recordVsTermStart(d, i.seat.term_start, i.seat.start_precision) !== 'before') continue;
    priorRoute.set(p, priorChamberRoute(d, i.seat, rawProfile(p)));
  }
  const groupProfileOf = (p: Passage): PassageProfile | null => {
    const base = profileOf(p);
    const route = priorRoute.get(p);
    if (!base || !route) return base;
    if ('covering' in route) return { ...base, chamber: route.covering.chamber ?? profileSeatChamber(rawProfile(p)!, route.covering.office_title) };
    return { ...base, chamber: null };
  };

  for (const group of groups.values()) {
    const { findings, actorPassages } = checkRecordGroup({
      passages: group, snapshotText: i.snapshotText, fullName: i.seat.full_name, chamber: seatChamber(i.seat.office_title), profileOf: groupProfileOf,
      markupOf: (p) => i.snapshotMarkup?.get(p.snapshot_id) ?? 'unknown' });
    for (const f of findings) out.add(f);
    const datePassages = actorPassages.length > 0 ? actorPassages : group;
    for (const p of datePassages) {
      if (!p.date) { out.add('undated-evidence'); continue; }
      const d = floorDate(p.date);
      if (i.seat.mode === 'candidate') {
        const route = priorRoute.get(p);
        if (!route) out.add('record-not-this-office');
        else if ('unverified' in route) out.add('prior-service-unverified');
      } else if (i.seat.mode === 'seated') {
        const v = recordVsTermStart(d, i.seat.term_start, i.seat.start_precision);
        if (v === 'unsettled') out.add('dates-imprecise');
        else if (v === 'before') {
          const route = priorRoute.get(p);
          if (!route) out.add('record-before-term');
          else if ('unverified' in route) out.add('prior-service-unverified');
        }
      }
    }
  }

  for (const p of statements) {
    const snapshotText = i.snapshotText.get(p.snapshot_id) ?? '';
    const normalizedText = normalizeText(snapshotText);

    // Check person name proximity for all passages (fail closed: all must verify).
    let personVerified = false;
    if (p.provision_quote && normalizedText.includes(normalizeText(p.provision_quote))) {
      // If provision found, use its position as offset.
      const offset = normalizedText.indexOf(normalizeText(p.provision_quote));
      const verdict = checkNameProximity({ fullName: i.seat.full_name, lastName, pageText: snapshotText, matchOffsetInNormalized: offset });
      personVerified = verdict.verdict === 'verified';
    } else {
      // Scan offsets 0, 500, 1000, ... to ensure full coverage (windows overlap and tile).
      for (let offset = 0; offset < normalizedText.length; offset += 500) {
        const verdict = checkNameProximity({ fullName: i.seat.full_name, lastName, pageText: snapshotText, matchOffsetInNormalized: offset });
        if (verdict.verdict === 'verified') {
          personVerified = true;
          break;
        }
      }
    }
    if (!personVerified) out.add('person-not-in-snapshot');

    // Date checks (skip if no date, but person/identity checks already completed).
    if (!p.date) { out.add('undated-evidence'); continue; }
    const d = floorDate(p.date);

    if (i.seat.mode === 'seated' && i.seat.start_precision !== 'day') {
      out.add('dates-imprecise');
    } else if (!cycleStart) {
      out.add('dates-imprecise');
    } else if (d < cycleStart) {
      out.add('statement-out-of-cycle');
    }
  }
  if (i.rowServedRevisionId !== i.bundleServedRevisionId) out.add('revision-drift');
  return { findings: [...out], profiles: [...used].sort() };
}
