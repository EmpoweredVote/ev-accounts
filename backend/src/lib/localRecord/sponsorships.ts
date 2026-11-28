// Resolve and check council sponsorships.
//
// Takes the sponsor sentences found in the legislation feed, memorandums and minutes, and turns each printed name
// into a politician seated on the item's date. An exception is always preferred to a wrong sponsor: a sentence is
// written only when every name in it resolves, and a subject is written only when every source that names its
// sponsors agrees.
import { resolveName, type NameFile, type TermSpan } from './names.js';
import type { SponsorSentence } from './onboard/sponsors.js';

export interface SponsorFinding {
  itemNumber: string; // "Ord 2025-41"
  label: string | null;
  /** Seating date: the document's meeting date, or the feed's firstActionDate. */
  date: string;
  sourceKind: 'legislation_feed' | 'memorandum' | 'minutes';
  /** Set by the caller once the document is saved. */
  sourceDocumentId: string | null;
  found: SponsorSentence;
}

export interface Sponsorship {
  itemNumber: string;
  label: string | null;
  politicianId: string;
  role: 'sponsor' | 'cosponsor';
  nameAsPrinted: string;
  sentence: string;
  sourceKind: SponsorFinding['sourceKind'];
  sourceDocumentId: string | null;
}

export interface SponsorProblem {
  cause: 'sponsor_unresolved' | 'sponsor_disagrees';
  subject: string;
  detail: unknown;
}

export function sponsorSubject(itemNumber: string, label: string | null): string {
  return label ? `${itemNumber} / ${label}` : itemNumber;
}

/** Governing source first: minutes over memorandum over legislation feed. */
const RANK: Record<SponsorFinding['sourceKind'], number> = { minutes: 0, memorandum: 1, legislation_feed: 2 };

/** "PiedmontSmith" is "Piedmont-Smith" with the hyphen lost. Returns the hyphenated form, or null. */
function hyphenated(printed: string): string | null {
  const m = /^([A-Z][a-z]+)([A-Z][a-z]+)$/.exec(printed.trim());
  return m ? `${m[1]}-${m[2]}` : null;
}

function resolvePrinted(printed: string, date: string, names: NameFile, terms: TermSpan[]) {
  const first = resolveName(printed, date, names, terms);
  if ('politicianId' in first || first.error !== 'unknown_name') return first;
  const alt = hyphenated(printed);
  if (!alt) return first;
  const second = resolveName(alt, date, names, terms);
  return 'politicianId' in second ? second : first;
}

interface Resolved {
  finding: SponsorFinding;
  members: { politicianId: string; role: 'sponsor' | 'cosponsor'; printed: string }[];
}

export function resolveSponsorships(
  findings: SponsorFinding[],
  names: NameFile,
  terms: TermSpan[],
): { sponsorships: Sponsorship[]; problems: SponsorProblem[] } {
  const sponsorships: Sponsorship[] = [];
  const problems: SponsorProblem[] = [];

  const bySubject = new Map<string, SponsorFinding[]>();
  for (const f of findings) {
    const subject = sponsorSubject(f.itemNumber, f.label);
    const list = bySubject.get(subject);
    if (list) list.push(f);
    else bySubject.set(subject, [f]);
  }

  for (const [subject, group] of bySubject) {
    const resolved: Resolved[] = [];
    for (const finding of group) {
      const { found } = finding;
      if (found.placeholder) {
        problems.push({
          cause: 'sponsor_unresolved',
          subject,
          detail: { reason: 'placeholder', sentence: found.sentence },
        });
        continue;
      }
      const members: Resolved['members'] = [];
      const failures: { printed: string; error: string; detail: string }[] = [];
      for (const n of found.names) {
        const r = resolvePrinted(n.printed, finding.date, names, terms);
        if ('politicianId' in r) members.push({ politicianId: r.politicianId, role: n.role, printed: n.printed });
        else failures.push({ printed: n.printed, error: r.error, detail: r.detail });
      }
      if (failures.length > 0 || members.length === 0) {
        problems.push({
          cause: 'sponsor_unresolved',
          subject,
          detail: { reason: 'name', sentence: found.sentence, date: finding.date, failures },
        });
        continue;
      }
      resolved.push({ finding, members });
    }
    if (resolved.length === 0) continue;

    const keyOf = (r: Resolved) =>
      [...new Set(r.members.map((m) => `${m.politicianId}:${m.role}`))].sort().join('|');
    if (new Set(resolved.map(keyOf)).size > 1) {
      problems.push({
        cause: 'sponsor_disagrees',
        subject,
        detail: resolved.map((r) => ({
          sourceKind: r.finding.sourceKind,
          date: r.finding.date,
          sentence: r.finding.found.sentence,
          names: r.members.map((m) => ({ printed: m.printed, politicianId: m.politicianId, role: m.role })),
        })),
      });
      continue;
    }

    const governing = [...resolved].sort((a, b) => RANK[a.finding.sourceKind] - RANK[b.finding.sourceKind])[0];
    const seen = new Set<string>();
    for (const m of governing.members) {
      const k = `${m.politicianId}:${m.role}`;
      if (seen.has(k)) continue;
      seen.add(k);
      sponsorships.push({
        itemNumber: governing.finding.itemNumber,
        label: governing.finding.label,
        politicianId: m.politicianId,
        role: m.role,
        nameAsPrinted: m.printed,
        sentence: governing.finding.found.sentence,
        sourceKind: governing.finding.sourceKind,
        sourceDocumentId: governing.finding.sourceDocumentId,
      });
    }
  }
  return { sponsorships, problems };
}
