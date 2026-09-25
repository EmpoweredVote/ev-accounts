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

export const CAMPAIGN_LOOKBACK_DAYS = 548;
export type ConfirmFinding =
  | 'identity-not-in-snapshot' | 'person-not-in-snapshot' | 'dates-imprecise' | 'record-before-term' | 'statement-out-of-cycle'
  | 'undated-evidence' | 'provision-missing' | 'record-not-this-office' | 'revision-drift';

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
  rowServedRevisionId: string;
  bundleServedRevisionId: string;
}): ConfirmFinding[] {
  const out = new Set<ConfirmFinding>();
  const names = [...i.seat.jurisdiction_names, i.seat.office_title].map((n) => normalizeText(n)).filter(Boolean);
  const identityOk = i.restsOnPassages.some((p) => {
    const t = normalizeText(i.snapshotText.get(p.snapshot_id) ?? '');
    return names.some((n) => t.includes(n));
  });
  if (!identityOk) out.add('identity-not-in-snapshot');
  const cycleStart = earliestStatementDate(i.seat);
  const lastName = extractLastName(i.seat.full_name);
  for (const p of i.restsOnPassages) {
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

    if (p.v3_class === 'record') {
      if (i.seat.mode === 'candidate') {
        out.add('record-not-this-office');
      } else if (i.seat.mode === 'seated') {
        if (!i.seat.term_start || i.seat.start_precision !== 'day') out.add('dates-imprecise');
        else if (d < i.seat.term_start) out.add('record-before-term');
      }
      if (!p.provision_quote || !verbatimIn(snapshotText, p.provision_quote)) out.add('provision-missing');
    } else {
      if (i.seat.mode === 'seated' && i.seat.start_precision !== 'day') {
        out.add('dates-imprecise');
      } else if (!cycleStart) {
        out.add('dates-imprecise');
      } else if (d < cycleStart) {
        out.add('statement-out-of-cycle');
      }
    }
  }
  if (i.rowServedRevisionId !== i.bundleServedRevisionId) out.add('revision-drift');
  return [...out];
}
