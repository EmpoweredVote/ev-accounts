/**
 * agreement — is a row unanimous? (spec §1.5, §5.5). Unanimous means all three coders valid, the
 * same chair (or the same BLANK reason), AND at least one snapshot all three rest on. Anything else
 * goes to a person. Order matters: a missing coder or a source request is decided before values
 * are compared, because neither is an agreement about the evidence the row will finally have.
 */
export interface CoderRowLabel {
  slot: number;
  valid: boolean;
  value: number | null;
  blank_reason: string | null;
  rests_on: string[];
  needs_source: string[];
}
export type AgreementOutcome =
  | { kind: 'unanimous-chair'; value: number; shared_sources: string[] }
  | { kind: 'unanimous-blank'; reason: string }
  | { kind: 'disjoint-sources'; value: number }
  | { kind: 'split'; values: (number | null)[] }
  | { kind: 'coder-missing'; missing: number[] }
  | { kind: 'needs-source'; requests: string[] };

export function agree(labels: CoderRowLabel[], expectedSlots: number[] = [1, 2, 3]): AgreementOutcome {
  const bySlot = new Map(labels.map((l) => [l.slot, l]));
  const missing = expectedSlots.filter((s) => !bySlot.get(s)?.valid);
  if (missing.length) return { kind: 'coder-missing', missing };
  const ls = expectedSlots.map((s) => bySlot.get(s)!);
  const requests = [...new Set(ls.flatMap((l) => l.needs_source))];
  if (requests.length) return { kind: 'needs-source', requests };
  const values = ls.map((l) => l.value);
  if (new Set(values).size > 1) return { kind: 'split', values };
  if (values[0] === null) {
    const reasons = new Set(ls.map((l) => l.blank_reason));
    return reasons.size === 1 ? { kind: 'unanimous-blank', reason: ls[0].blank_reason! } : { kind: 'split', values };
  }
  const shared = ls.slice(1).reduce((acc, l) => acc.filter((id) => l.rests_on.includes(id)), [...ls[0].rests_on]);
  return shared.length
    ? { kind: 'unanimous-chair', value: values[0], shared_sources: shared.sort() }
    : { kind: 'disjoint-sources', value: values[0] };
}

export function consensusSlot(labels: CoderRowLabel[], value: number): number {
  return labels
    .filter((l) => l.valid && l.value === value)
    .sort((a, b) => a.rests_on.length - b.rests_on.length || a.slot - b.slot)[0].slot;
}
