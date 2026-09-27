/**
 * profileDivergence — the evidence that a source profile NEEDS its rule (source-profiles spec; ruling
 * 2026-09-26 "Add the detector"). The real-page controls prove each profile's rules give the right
 * answer; on the pages we had, the generic rules gave the same answer, so nothing showed a profile was
 * needed. This finds every real record group where the declared rules and GENERIC_RULES disagree.
 * Each one is a page worth adding to that profile as a control.
 *
 * It reads every VALID coder row (not only rows that reach CONFIRM, which most do not), so the evidence
 * builds up from ordinary batches. Information only: it changes no finding and no shadow decision.
 */
import { instrumentKey, type CoderRow, type Passage } from './coderLabel.js';
import { checkRecordGroup, seatChamber, type RecordFinding } from './recordBasis.js';
import { profileSeatChamber, profileTag, resolveProfile, type SourceProfile } from './sourceProfiles.js';

export interface ProfileDivergence {
  slot: number;
  topic_id: string;
  instrument: string;
  snapshots: { snapshot_id: string; url: string; profile: string }[];
  generic: RecordFinding[];
  profiled: RecordFinding[];
}

export function profileDivergences(i: {
  validRows: ReadonlyMap<number, CoderRow[]>;
  snapshotText: ReadonlyMap<string, string>;
  snapshotUrl: ReadonlyMap<string, string>;
  profiles: readonly SourceProfile[];
  fullName: string;
  officeTitle: string | null | undefined;
  /** Each snapshot's amendment_markup (snapshots.json). Absent reads as 'unknown', as in CONFIRM. */
  snapshotMarkup?: ReadonlyMap<string, 'kept' | 'none' | 'unknown'>;
}): ProfileDivergence[] {
  const out: ProfileDivergence[] = [];
  const genericChamber = seatChamber(i.officeTitle);
  for (const [slot, rows] of [...i.validRows].sort((a, b) => a[0] - b[0])) {
    for (const r of rows) {
      const groups = new Map<string, Passage[]>();
      for (const p of r.passages) {
        if (p.v3_class !== 'record') continue;
        const k = instrumentKey(p.instrument) ?? '∅';
        groups.set(k, [...(groups.get(k) ?? []), p]);
      }
      for (const [key, group] of groups) {
        const resolved = group.map((p) => {
          const url = i.snapshotUrl.get(p.snapshot_id);
          return { p, url, prof: url ? resolveProfile(i.profiles, url) : null };
        });
        // A page with no profile is CONFIRM's no-source-profile, not evidence about a profile's rule.
        if (resolved.some((x) => !x.prof)) continue;
        const byPassage = new Map(resolved.map((x) => [x.p, x.prof!]));
        const run = (profiled: boolean) => checkRecordGroup({
          passages: group, snapshotText: i.snapshotText, fullName: i.fullName, chamber: genericChamber,
          markupOf: (p) => i.snapshotMarkup?.get(p.snapshot_id) ?? 'unknown',
          profileOf: profiled ? (p) => { const pr = byPassage.get(p)!; return { rules: pr.rules, chamber: profileSeatChamber(pr, i.officeTitle) }; } : undefined,
        }).findings.sort();
        const generic = run(false);
        const profiled = run(true);
        if (generic.join('|') === profiled.join('|')) continue;
        out.push({
          slot, topic_id: r.topic_id, instrument: key,
          snapshots: resolved.map((x) => ({ snapshot_id: x.p.snapshot_id, url: x.url!, profile: profileTag(x.prof!) })),
          generic, profiled,
        });
      }
    }
  }
  return out;
}
