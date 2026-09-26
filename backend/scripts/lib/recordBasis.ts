/**
 * recordBasis — CONFIRM for a RECORD basis (confirm-basis spec §2, defect D1). A vote is usually two
 * pages: a vote page that names the person but has no bill text, and the bill text that has the
 * provision but names no voters. So a record is judged as one GROUP of passages on one instrument:
 * one passage must show the person acting (actor_quote), some passage must carry the provision, and
 * a vote must come from a vote page with a readable, divided tally. The coders copy each fact
 * verbatim (codebook 0.3); code only checks and reads it. Fail closed: anything unreadable is a finding.
 */
import { normalizeText } from '../../src/lib/researchVerifier.js';
import { verbatimIn, type Passage } from './coderLabel.js';

export type RecordFinding =
  | 'person-not-in-snapshot' | 'provision-missing' | 'instrument-mismatch' | 'vote-not-evidenced'
  | 'tally-unreadable' | 'near-unanimous-vote' | 'name-collision';

export function parseTally(q: string): { ayes: number; noes: number } | null {
  const s = q.replace(/\s+/g, ' ');
  const ay = /\b(?:ayes|aye|yeas|yea)\b(?:\s+count)?\s*[:\-]?\s*(\d+)/i.exec(s);
  const no = /\b(?:noes|nays|nay|no)\b(?:\s+count)?\s*[:\-]?\s*(\d+)/i.exec(s);
  return ay && no ? { ayes: Number(ay[1]), noes: Number(no[1]) } : null;
}

export const isNearUnanimous = (t: { ayes: number; noes: number }): boolean =>
  t.ayes + t.noes > 0 && t.noes / (t.ayes + t.noes) < 0.1;

export function instrumentKey(s: string | null | undefined): string | null {
  if (!s || !s.trim()) return null;
  return s.toLowerCase().replace(/[–—]/g, '-').replace(/[\s.]/g, '');
}

const words = (s: string) => normalizeText(s).replace(/[^a-z0-9\s-]/g, ' ').split(/\s+/).filter(Boolean);
const lastNameOf = (full: string) => {
  const t = full.trim().split(/\s+/).filter((x) => !/^(jr|sr|ii|iii|iv)\.?$/i.test(x));
  return normalizeText(t[t.length - 1] ?? '');
};
const firstNameOf = (full: string) => normalizeText(full.trim().split(/\s+/)[0] ?? '');

export function checkRecordGroup(i: { passages: Passage[]; snapshotText: ReadonlyMap<string, string>; fullName: string }):
  { findings: RecordFinding[]; actorPassages: Passage[] } {
  const out = new Set<RecordFinding>();
  const last = lastNameOf(i.fullName);
  const first = firstNameOf(i.fullName);
  const textOf = (p: Passage) => i.snapshotText.get(p.snapshot_id) ?? '';

  // One instrument for the whole group.
  const keys = new Set(i.passages.map((p) => instrumentKey(p.instrument)));
  if (keys.size !== 1 || keys.has(null)) out.add('instrument-mismatch');

  // The actor: a verbatim actor_quote that names the person.
  const actorPassages = i.passages.filter((p) => p.actor_quote && verbatimIn(textOf(p), p.actor_quote) && words(p.actor_quote).includes(last));
  if (actorPassages.length === 0) out.add('person-not-in-snapshot');

  // A surname two members share on the page needs the first name or initial beside it.
  for (const p of actorPassages) {
    const pageCount = words(textOf(p)).filter((w) => w === last).length;
    if (pageCount < 2) continue;
    const aq = words(p.actor_quote!);
    const idx = aq.map((w, k) => (w === last ? k : -1)).filter((k) => k >= 0);
    const qualified = idx.some((k) => [aq[k - 1], aq[k + 1]].some((n) => n === first || n === first[0]));
    if (!qualified) out.add('name-collision');
  }

  // The provision is verbatim on some page of the group.
  if (!i.passages.some((p) => p.provision_quote && verbatimIn(textOf(p), p.provision_quote))) out.add('provision-missing');

  // A vote must come from a vote page, with a readable and divided tally.
  if (i.passages.some((p) => p.record_kind === 'vote')) {
    const votePages = actorPassages.filter((p) => p.record_kind === 'vote');
    if (votePages.length === 0) out.add('vote-not-evidenced');
    for (const p of votePages) {
      const t = p.tally_quote && verbatimIn(textOf(p), p.tally_quote) ? parseTally(p.tally_quote) : null;
      if (!t) out.add('tally-unreadable');
      else if (isNearUnanimous(t)) out.add('near-unanimous-vote');
    }
  }
  return { findings: [...out], actorPassages };
}
