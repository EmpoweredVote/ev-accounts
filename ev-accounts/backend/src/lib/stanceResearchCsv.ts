/**
 * stanceResearchCsv — parse and write the two-CSV format produced by the
 * politician-stance-researcher agent.
 *
 *   stances.csv:  full_name, politician_id, topic_key, value, reasoning
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
  return stringify(rows, {
    header: true,
    columns: ['full_name', 'politician_id', 'topic_key', 'value', 'reasoning'],
  });
}

export function writeEvidenceCsv(rows: EvidenceRow[]): string {
  return stringify(rows, {
    header: true,
    columns: ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'],
  });
}
