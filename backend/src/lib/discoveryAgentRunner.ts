/**
 * discoveryAgentRunner — pure Anthropic SDK wrapper for candidate discovery.
 *
 * WHY THIS FILE EXISTS:
 * Single point of contact with the Anthropic API for the v2.1 candidate
 * discovery pipeline. Its only job is to take a jurisdiction context and
 * return a citation-backed list of candidates found on official sources.
 * No database access — all DB writes happen in discoveryService.ts.
 *
 * WHY tool_choice: { type: 'any' }:
 * Forces Claude to call at least one tool, but lets it choose which.
 * Claude calls web_search first (server-side, handled by Anthropic), processes
 * the results, then calls report_candidates with structured output.
 * tool_choice: { type: 'tool', name: 'report_candidates' } was tried first but
 * forces Claude to call report_candidates IMMEDIATELY, skipping web search
 * entirely — resulting in 0 candidates every time.
 *
 * WHY server-side web_search_20250305:
 * Claude executes it internally, returns citation URLs in its chain of thought
 * without us implementing any fetch, HTML parsing, or headless browser.
 * Org-wide web search must be enabled in the Claude Console before this works
 * (console.anthropic.com/settings/privacy).
 */

import Anthropic from '@anthropic-ai/sdk';
import { env } from './env.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface DiscoveredCandidate {
  full_name: string;
  citation_url: string;
  race_hint: string;
}

export interface DiscoveryAgentInput {
  jurisdictionName: string;       // e.g. "Los Angeles"
  state: string;                   // two-letter, e.g. "CA"
  electionDate: string;            // ISO date, e.g. "2026-11-03"
  sourceUrl?: string | null;       // optional starting URL
  allowedDomains?: string[] | null; // optional allowlist for web_search bias
  knownRaces?: Array<{             // context only — agent finds ALL candidates, not just these
    position_name: string;
    primary_party?: string | null;
  }>;
}

export interface DiscoveryAgentResult {
  model: string;
  inputTokens: number;
  outputTokens: number;
  candidates: DiscoveredCandidate[];
  stopReason: string | null;
}

// ---------------------------------------------------------------------------
// Tool definition
// ---------------------------------------------------------------------------

const REPORT_CANDIDATES_TOOL = {
  name: 'report_candidates',
  description:
    'Report ALL candidates you found on the official source(s). Include every candidate name that appears on the page — do not filter to only the races provided in the context. For each candidate, include the exact URL where their name appears verbatim. If you cannot find a verbatim citation URL for a candidate, DO NOT include them.',
  input_schema: {
    type: 'object',
    properties: {
      candidates: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            full_name: {
              type: 'string',
              description: 'The candidate name exactly as it appears on the source page.',
            },
            citation_url: {
              type: 'string',
              description:
                'The exact URL where full_name appears verbatim. Must be a URL you actually fetched or that web_search returned — never synthesize.',
            },
            race_hint: {
              type: 'string',
              description:
                'Free-text description of the race this candidate is running in, e.g. "Los Angeles Mayor" or "City Council District 3". Use the wording from the source page when possible.',
            },
          },
          required: ['full_name', 'citation_url', 'race_hint'],
        },
      },
    },
    required: ['candidates'],
  },
} as const;

// ---------------------------------------------------------------------------
// Main function
// ---------------------------------------------------------------------------

export async function runDiscoveryAgent(
  input: DiscoveryAgentInput
): Promise<DiscoveryAgentResult> {
  if (!env.ANTHROPIC_API_KEY) {
    throw new Error(
      '[discoveryAgentRunner] ANTHROPIC_API_KEY is not configured. Set it in the backend environment and enable web search in the Claude Console (console.anthropic.com/settings/privacy).'
    );
  }

  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

  const prompt = buildPrompt(input);

  const webSearchTool = {
    type: 'web_search_20250305' as const,
    name: 'web_search',
    max_uses: input.sourceUrl ? 1 : 2,
    ...(input.allowedDomains && input.allowedDomains.length > 0
      ? { allowed_domains: input.allowedDomains }
      : {}),
  };

  const response = await client.messages.create({
    model: 'claude-opus-4-6',
    max_tokens: 4096,
    tools: [
      webSearchTool as any,           // SDK type union does not yet include server-side tool types
      REPORT_CANDIDATES_TOOL as any,
    ],
    tool_choice: { type: 'any' } as any,
    messages: [{ role: 'user', content: prompt }],
  });

  // Extract the report_candidates tool_use block. Claude searches first via
  // web_search, then calls report_candidates with structured results. If it's
  // absent, Claude finished without reporting (prompt or web search failure).
  const toolUseBlock = response.content.find(
    (block: any) => block.type === 'tool_use' && block.name === 'report_candidates'
  );

  if (!toolUseBlock || toolUseBlock.type !== 'tool_use') {
    throw new Error(
      '[discoveryAgentRunner] Claude did not invoke report_candidates. ' +
        'Raw stop_reason: ' + String(response.stop_reason)
    );
  }

  const toolInput = (toolUseBlock as any).input as { candidates?: DiscoveredCandidate[] };
  const candidates = Array.isArray(toolInput.candidates) ? toolInput.candidates : [];

  // Belt-and-suspenders: drop any candidate missing citation_url.
  // The input_schema marks it required, but a schema drift or bad shim
  // would otherwise let a hallucination through.
  const validated = candidates.filter(
    (c) =>
      c &&
      typeof c.full_name === 'string' &&
      typeof c.citation_url === 'string' &&
      c.citation_url.trim().length > 0 &&
      typeof c.race_hint === 'string'
  );

  return {
    model: response.model,
    inputTokens: response.usage.input_tokens,
    outputTokens: response.usage.output_tokens,
    candidates: validated,
    stopReason: response.stop_reason ?? null,
  };
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

function buildPrompt(input: DiscoveryAgentInput): string {
  const knownRacesBlock =
    input.knownRaces && input.knownRaces.length > 0
      ? `\n\nRaces we already have on file for this jurisdiction (MATCHING CONTEXT ONLY — you must NOT limit your results to these; report every candidate you find):\n` +
        input.knownRaces
          .map(
            (r) =>
              `  - ${r.position_name}${r.primary_party ? ` (primary party: ${r.primary_party})` : ''}`
          )
          .join('\n')
      : '';

  const sourceBlock = input.sourceUrl
    ? `\n\nStarting source URL (fetch this page; follow direct same-domain links one level deep if they lead to candidate rosters):\n  ${input.sourceUrl}`
    : `\n\nNo starting URL provided. Use web_search (max 2 searches) to locate the official ` +
      `election authority page for ${input.jurisdictionName}, ${input.state} — typically a Secretary of State, ` +
      `county registrar, city clerk, or election commissioner domain. Prefer .gov results.`;

  return (
    `You are a candidate-discovery agent for a nonpartisan voter-information app.\n` +
    `Your job is to find EVERY candidate listed for the upcoming ${input.electionDate} election in ` +
    `${input.jurisdictionName}, ${input.state}.\n\n` +
    `Rules:\n` +
    `1. Only report candidates whose names appear verbatim on an official source page.\n` +
    `2. Record the EXACT URL where the name appears. If you cannot produce a citation URL, DO NOT report that candidate.\n` +
    `3. Report candidates for ALL races you find — not just the ones in the context list below.\n` +
    `4. When you have finished gathering candidates, call the report_candidates tool.` +
    sourceBlock +
    knownRacesBlock
  );
}
