/**
 * confirm — phase-1 CONFIRM (spec §1.6): code-only checks after the coders agree. Any finding
 * sends the row to a person. Identity guards against namesakes; dates guard pre-seating (§4.10)
 * and the statement cycle (ruling Q4); the vote ladder requires the operative provision on the page.
 * 🟡 CAMPAIGN_LOOKBACK_DAYS is an implementation PROXY for "the current term, the current campaign,
 * or the campaign that seated them" — the operator may change it.
 */
import { normalizeText, checkNameProximity } from '../../src/lib/researchVerifier.js';
import { verbatimIn, type Passage } from './coderLabel.js';
import type { SeatContext } from './coderPrompt.js';
import { checkRecordGroup, instrumentKey } from './recordBasis.js';

export const CAMPAIGN_LOOKBACK_DAYS = 548;
export type ConfirmFinding =
  | 'identity-not-in-snapshot' | 'person-not-in-snapshot' | 'dates-imprecise' | 'record-before-term' | 'statement-out-of-cycle'
  | 'undated-evidence' | 'provision-missing' | 'record-not-this-office' | 'revision-drift' | 'rests-on-pointer'
  | 'instrument-mismatch' | 'vote-not-evidenced' | 'tally-unreadable' | 'near-unanimous-vote' | 'name-collision';

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

export function confirmRow(i: {
  seat: SeatContext;
  restsOnPassages: Passage[];
  snapshotText: ReadonlyMap<string, string>;
  /** snapshot_id -> source_kind (from snapshots.json). An id missing here counts as a pointer (fail closed). */
  sourceKind: ReadonlyMap<string, string>;
  rowServedRevisionId: string;
  bundleServedRevisionId: string;
}): ConfirmFinding[] {
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
  for (const group of groups.values()) {
    const { findings, actorPassages } = checkRecordGroup({ passages: group, snapshotText: i.snapshotText, fullName: i.seat.full_name });
    for (const f of findings) out.add(f);
    const datePassages = actorPassages.length > 0 ? actorPassages : group;
    for (const p of datePassages) {
      if (!p.date) { out.add('undated-evidence'); continue; }
      const d = floorDate(p.date);
      if (i.seat.mode === 'candidate') {
        out.add('record-not-this-office');
      } else if (i.seat.mode === 'seated') {
        if (!i.seat.term_start || i.seat.start_precision !== 'day') out.add('dates-imprecise');
        else if (d < i.seat.term_start) out.add('record-before-term');
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
  return [...out];
}
