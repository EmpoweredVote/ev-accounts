/**
 * stanceResearchCsv — parse and write the two-CSV format produced by the
 * politician-stance-researcher agent.
 *
 *   stances.csv:  full_name, politician_id, topic_key, value, reasoning, evidence_type, source_urls
 *                 (written by stance-gate; source_urls = the row's research.csv source_url_1..3,
 *                 space-separated — a URL never contains a raw space. I1, 2026-09-24: the verifier
 *                 verifies only evidence on these URLs.)
 *   evidence.csv: full_name, topic_key, source_url, snippet, snippet_index
 *
 * Joined on (full_name, topic_key).
 */

import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';
import type { StanceRow, EvidenceRow } from './researchVerifier.js';

export function parseStancesCsv(text: string): StanceRow[] {
  const rows = parse(text, { columns: true, skip_empty_lines: true, relax_column_count: true }) as Record<string, string>[];
  return rows.map((r) => ({
    full_name: r.full_name ?? '',
    politician_id: r.politician_id ?? '',
    topic_key: r.topic_key ?? '',
    value: r.value && r.value.trim() !== '' ? Number(r.value) : null,
    reasoning: r.reasoning ?? '',
    // Absent column (a stances.csv written before 2026-09-24) stays undefined, so the caller can
    // tell "no restriction recorded" from "this row cites nothing".
    ...('source_urls' in r ? { source_urls: (r.source_urls ?? '').split(/\s+/).filter(Boolean) } : {}),
    ...('evidence_type' in r ? { evidence_type: (r.evidence_type ?? '').trim() } : {}),
  }));
}

export function parseEvidenceCsv(text: string): EvidenceRow[] {
  const rows = parse(text, { columns: true, skip_empty_lines: true, relax_column_count: true }) as Record<string, string>[];
  return rows.map((r) => ({
    full_name: r.full_name ?? '',
    topic_key: r.topic_key ?? '',
    source_url: r.source_url ?? '',
    snippet: r.snippet ?? '',
    snippet_index: Number(r.snippet_index ?? 0),
  }));
}

export function writeStancesCsv(rows: StanceRow[]): string {
  return stringify(rows.map((r) => ({
    ...r,
    evidence_type: r.evidence_type ?? '',
    source_urls: (r.source_urls ?? []).join(' '),
  })), {
    header: true,
    columns: ['full_name', 'politician_id', 'topic_key', 'value', 'reasoning', 'evidence_type', 'source_urls'],
  });
}

export function writeEvidenceCsv(rows: EvidenceRow[]): string {
  return stringify(rows, {
    header: true,
    columns: ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'],
  });
}
