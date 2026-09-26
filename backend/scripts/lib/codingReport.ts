/**
 * codingReport — the SHADOW verdict for one politician's batch (spec §7 P1). It computes what the
 * P3 pipeline would do, and changes nothing: decidePublish is not consulted and not altered.
 * `would-publish-if-certified` still needs a certified stratum, which does not exist in P1.
 */
import { alphaNominal, chairCategory, type Unit } from './reliability.js';
import { validateCoderLabelFile, rowKey, type Passage, type CoderRow } from './coderLabel.js';
import { agree, consensusSlot, type AgreementOutcome, type CoderRowLabel } from './agreement.js';
import { confirmRowDetailed, type ConfirmFinding } from './confirm.js';
import type { SeatContext, PromptTopic } from './coderPrompt.js';
import { leadsById, type S1Lead } from './s1Leads.js';
import { resolveProfile, type SourceProfile } from './sourceProfiles.js';

export const EVIDENCE_CLASS_ORDER = ['statement-other', 'statement-answer', 'record'] as const; // weakest first
export function weakestClass(passages: Passage[]): 'record' | 'statement-answer' | 'statement-other' {
  for (const c of EVIDENCE_CLASS_ORDER) if (passages.some((p) => p.v3_class === c)) return c;
  return 'statement-other';
}

export interface RowReport {
  key: string;
  topic_key: string;
  outcome: AgreementOutcome;
  confirm: ConfirmFinding[];
  stratum: { level: string | null; evidence_class: string | null };
  shadow: 'would-publish-if-certified' | 'would-review';
  shadow_reasons: string[];
  /** Information only (spec §7 P1 fresh/stale seed) — never read by agree()/confirmRow() and never
   * changes `shadow` or `shadow_reasons`. 'none' when this topic has no Season 1 lead. */
  seed: 'fresh' | 'stale' | 'none';
  /** profile@version tags CONFIRM used for this row's record passages. `[]` when CONFIRM did not run. */
  profiles: string[];
}

export interface CodingReport {
  rows: RowReport[];
  m1: { alpha: number | null; units: number };
  needsSource: { key: string; requests: string[] }[];
  validity: { slot: number; fileErrors: string[]; rowErrors: number }[];
  /** Count of rows with a 'no-source-profile' finding, keyed by the URL host of each unmatched
   * record passage ('(no url)' when the snapshot has no URL at all). */
  noProfileHosts: Record<string, number>;
}

export function buildCodingReport(i: {
  context: { batch_id: string; seat: SeatContext; topics: PromptTopic[] };
  files: Map<number, unknown>;
  snapshotText: ReadonlyMap<string, string>;
  /** snapshot_id -> source_kind, from snapshots.json (final review item 3). */
  sourceKind: ReadonlyMap<string, string>;
  /** Season 1 leads (build-s1-leads.ts), for the information-only `seed` flag. Never affects the
   * agreement/confirm/publish computation below — only which value `seed` takes on the row. */
  s1Leads?: S1Lead[];
  /** snapshot_id -> original URL (snapshots.json). Passed through to confirmRowDetailed. */
  snapshotUrl?: ReadonlyMap<string, string>;
  /** Loaded source profiles (sourceProfiles.ts). Passed through to confirmRowDetailed. */
  profiles?: readonly SourceProfile[];
}): CodingReport {
  const { seat, topics } = i.context;
  const leads = leadsById(i.s1Leads ?? []);
  const validity: { slot: number; fileErrors: string[]; rowErrors: number }[] = [];
  const bySlot = new Map<number, Map<string, { row: CoderRow | null; valid: boolean }>>();
  for (const slot of [1, 2, 3]) {
    const raw = i.files.get(slot);
    const rows = new Map<string, { row: CoderRow | null; valid: boolean }>();
    if (raw === undefined) { validity.push({ slot, fileErrors: ['file missing'], rowErrors: 0 }); bySlot.set(slot, rows); continue; }
    const v = validateCoderLabelFile(raw, { snapshotText: i.snapshotText, expectedSlot: slot });
    validity.push({ slot, fileErrors: v.fileErrors, rowErrors: v.rows.filter((r) => r.errors.length).length });
    // Duplicate (politician, office, topic) keys within one coder file: keep the first occurrence
    // only, so the report is consistent with what --apply will store (fix round 1, item 4).
    for (const r of v.rows) if (!rows.has(r.key)) rows.set(r.key, { row: r.row, valid: v.fileErrors.length === 0 && r.errors.length === 0 });
    bySlot.set(slot, rows);
  }
  const units: Unit[] = [];
  const needsSource: { key: string; requests: string[] }[] = [];
  const noProfileHosts: Record<string, number> = {};
  const rows: RowReport[] = topics.map((t) => {
    const key = rowKey({ politician_id: seat.politician_id, office_id: seat.office_id, topic_id: t.topic_id });
    const labels: CoderRowLabel[] = [];
    const rowsBySlot = new Map<number, CoderRow>();
    for (const slot of [1, 2, 3]) {
      const got = bySlot.get(slot)!.get(key);
      if (!got) continue;
      if (got.row) rowsBySlot.set(slot, got.row);
      labels.push({ slot, valid: got.valid, value: got.row?.v6_value ?? null, blank_reason: got.row?.v6_blank_reason ?? null,
        rests_on: got.row?.rests_on ?? [], needs_source: got.row?.needs_source ?? [] });
    }
    units.push([1, 2, 3].map((s) => { const l = labels.find((x) => x.slot === s); return l?.valid ? chairCategory(l.value) : null; }));
    const outcome = agree(labels);
    const reasons: string[] = [];
    let confirm: ConfirmFinding[] = [];
    let evidenceClass: string | null = null;
    let profiles: string[] = [];
    if (outcome.kind === 'needs-source') { reasons.push('needs-source'); needsSource.push({ key, requests: outcome.requests }); }
    else if (outcome.kind === 'coder-missing') reasons.push('coder-missing');
    else if (outcome.kind === 'split' || outcome.kind === 'disjoint-sources') reasons.push('coder-split');
    else if (outcome.kind === 'unanimous-blank') reasons.push('unanimous-blank-no-write');
    else {
      const cRow = rowsBySlot.get(consensusSlot(labels, outcome.value))!;
      const restsOn = cRow.passages.filter((p) => outcome.shared_sources.includes(p.snapshot_id));
      evidenceClass = weakestClass(restsOn);
      const detailed = confirmRowDetailed({ seat, restsOnPassages: restsOn, snapshotText: i.snapshotText, sourceKind: i.sourceKind, rowServedRevisionId: cRow.served_revision_id, bundleServedRevisionId: t.served_revision_id, snapshotUrl: i.snapshotUrl, profiles: i.profiles });
      confirm = detailed.findings;
      profiles = detailed.profiles;
      if (confirm.length) reasons.push('confirm-failed');
      if (evidenceClass === 'statement-other') reasons.push('statement-other');
      // A chair whose every source is a news excerpt goes to a person (spec §5.4).
      if (restsOn.length > 0 && restsOn.every((p) => i.sourceKind.get(p.snapshot_id) === 'news')) reasons.push('news-only-basis');
      if (i.profiles && confirm.includes('no-source-profile')) {
        const hosts = new Set<string>();
        for (const p of restsOn) {
          if (p.v3_class !== 'record') continue;
          const url = i.snapshotUrl?.get(p.snapshot_id);
          if (!url) { hosts.add('(no url)'); continue; }
          if (!resolveProfile(i.profiles, url)) { try { hosts.add(new URL(url).host); } catch { hosts.add('(no url)'); } }
        }
        for (const host of hosts) noProfileHosts[host] = (noProfileHosts[host] ?? 0) + 1;
      }
    }
    const publishable = outcome.kind === 'unanimous-chair' && reasons.length === 0;
    const seed = leads.get(t.topic_id)?.seed ?? 'none';
    return { key, topic_key: t.topic_key, outcome, confirm, stratum: { level: seat.level, evidence_class: evidenceClass },
      shadow: publishable ? 'would-publish-if-certified' : 'would-review', shadow_reasons: reasons, seed, profiles };
  });
  const a = alphaNominal(units);
  return { rows, m1: { alpha: a.alpha, units: a.units }, needsSource, validity, noProfileHosts };
}
