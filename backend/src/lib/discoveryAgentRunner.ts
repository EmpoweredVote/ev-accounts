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
  prefetchedContent?: string | null; // pre-rendered page text (skips web_search when provided)
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

// AnthropicAvailability — result of checkAnthropicAvailability()'s one-shot
// pre-flight canary. `detail` is built only from `.status`/`.type`/`.message`
// — never from the raw ANTHROPIC_API_KEY value.
export type AnthropicAvailability =
  | { available: true }
  | { available: false; reason: 'missing_key' | 'unusable'; detail: string };

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

  // When pre-fetched content is provided, skip web_search entirely — Claude
  // extracts candidates directly from the rendered page text.
  const hasPrefetch = !!input.prefetchedContent;

  const webSearchTool = {
    type: 'web_search_20250305' as const,
    name: 'web_search',
    max_uses: input.sourceUrl ? 1 : 2,
    ...(input.allowedDomains && input.allowedDomains.length > 0
      ? { allowed_domains: input.allowedDomains }
      : {}),
  };

  // Agentic loop: web_search_20250305 is a server-side tool that pauses mid-turn
  // (stop_reason='pause_turn'). We append the assistant response and continue until
  // Claude calls report_candidates or exhausts its search quota.
  // When prefetchedContent is set, we skip straight to report_candidates (no search needed).
  const messages: any[] = [{ role: 'user', content: prompt }];
  let totalInputTokens = 0;
  let totalOutputTokens = 0;
  let lastModel = 'claude-sonnet-4-6';
  let lastStopReason: string | null = null;
  const MAX_TURNS = 5; // safety cap: 1 search turn + up to 4 continuations

  for (let turn = 0; turn < MAX_TURNS; turn++) {
    // On the first turn Claude may search; on continuations strip web_search so
    // max_uses doesn't reset per-request and Claude is forced to report.
    // If pre-fetched content was provided, always force report_candidates directly.
    const isFirstTurn = turn === 0;
    const response = await client.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 4096,
      tools: isFirstTurn && !hasPrefetch
        ? [webSearchTool as any, REPORT_CANDIDATES_TOOL as any]   // search or report
        : [REPORT_CANDIDATES_TOOL as any],                        // report only
      tool_choice: (isFirstTurn && !hasPrefetch)
        ? ({ type: 'any' } as any)                                // let Claude pick
        : ({ type: 'tool', name: 'report_candidates' } as any),   // must report now
      messages,
    });

    lastModel = response.model;
    lastStopReason = response.stop_reason ?? null;
    totalInputTokens += response.usage.input_tokens;
    totalOutputTokens += response.usage.output_tokens;

    // Check for report_candidates in this turn's content.
    const toolUseBlock = response.content.find(
      (block: any) => block.type === 'tool_use' && block.name === 'report_candidates'
    );

    if (toolUseBlock) {
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
        model: lastModel,
        inputTokens: totalInputTokens,
        outputTokens: totalOutputTokens,
        candidates: validated,
        stopReason: lastStopReason,
      };
    }

    // pause_turn means the model executed a server-side tool and paused.
    // Append its response and continue so it can process results.
    if (response.stop_reason === 'pause_turn') {
      messages.push({ role: 'assistant', content: response.content });
      continue;
    }

    // Any other stop reason (end_turn, max_tokens, etc.) without report_candidates
    // is a BENIGN outcome (per OPS-03) — the model searched and found nothing
    // reportable, or exhausted its turn budget. Log and return zero candidates
    // rather than throwing; discoveryService.ts already treats zero candidates
    // as a valid completed run.
    console.warn(
      '[discoveryAgentRunner] Model turn ended without invoking report_candidates; ' +
        'treating as a zero-candidate result. stop_reason=' + String(lastStopReason)
    );
    return {
      model: lastModel,
      inputTokens: totalInputTokens,
      outputTokens: totalOutputTokens,
      candidates: [],
      stopReason: lastStopReason,
    };
  }

  // MAX_TURNS exhausted without report_candidates and without a final non-pause_turn
  // response (shouldn't normally happen since every loop iteration either returns or
  // continues, but kept as a defensive fallback matching the original function's contract).
  console.warn(
    '[discoveryAgentRunner] Exhausted MAX_TURNS without invoking report_candidates; ' +
      'treating as a zero-candidate result. stop_reason=' + String(lastStopReason)
  );
  return {
    model: lastModel,
    inputTokens: totalInputTokens,
    outputTokens: totalOutputTokens,
    candidates: [],
    stopReason: lastStopReason,
  };
}

// ---------------------------------------------------------------------------
// Pre-flight canary (OPS-01)
// ---------------------------------------------------------------------------

/**
 * checkAnthropicAvailability — one-shot, cheap pre-flight check for callers
 * (e.g. the weekly discovery-sweep orchestrator) that need to confirm
 * Anthropic is usable BEFORE spending per-jurisdiction paid calls.
 *
 * There is no Anthropic API endpoint that reports remaining credit balance,
 * so this makes one minimal, no-tools canary `messages.create` call to prove
 * the key + credit are usable. Only a canary failure with a conclusive
 * account-level status (401 unauthenticated / 402 billing / 403 permission)
 * is reported as `unusable`; any other failure (429, 5xx, network fault) is
 * inconclusive and is re-thrown so the caller can log it and proceed —
 * treating an ambiguous canary failure as "unusable" would cause a
 * false-positive whole-sweep skip (see 173-RESEARCH.md Pitfall 3).
 *
 * NOTE: if this Anthropic account ever rejects `claude-haiku-4-5` as an
 * unrecognized/disabled model, switch the canary model below to the
 * production model (`claude-sonnet-4-6`) — either satisfies OPS-01 since
 * 401/402/403 are account-level, not model-level, signals.
 */
export async function checkAnthropicAvailability(): Promise<AnthropicAvailability> {
  if (!env.ANTHROPIC_API_KEY) {
    return {
      available: false,
      reason: 'missing_key',
      detail: 'ANTHROPIC_API_KEY is not configured.',
    };
  }

  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

  try {
    await client.messages.create({
      model: 'claude-haiku-4-5',
      max_tokens: 1,
      messages: [{ role: 'user', content: 'ping' }],
    });
    return { available: true };
  } catch (err) {
    if (
      err instanceof Anthropic.APIError &&
      typeof err.status === 'number' &&
      [401, 402, 403].includes(err.status)
    ) {
      return {
        available: false,
        reason: 'unusable',
        detail: `${err.status} ${err.type ?? ''}: ${err.message}`,
      };
    }
    // Any other error (network blip, 5xx, timeout) is inconclusive — re-throw
    // so the caller can log a warning and let the sweep proceed rather than
    // treating an ambiguous canary failure as a conclusive "unusable" signal.
    throw err;
  }
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

  // When pre-fetched content is provided, embed it directly and skip web_search.
  if (input.prefetchedContent) {
    return (
      `You are a candidate-discovery agent for a nonpartisan voter-information app.\n` +
      `Your job is to find EVERY candidate listed for the upcoming ${input.electionDate} election in ` +
      `${input.jurisdictionName}, ${input.state}.\n\n` +
      `The following is the full text content of the official source page at ${input.sourceUrl ?? 'the election authority website'}, ` +
      `rendered by a headless browser (JavaScript executed):\n\n` +
      `<source_content>\n${input.prefetchedContent}\n</source_content>\n\n` +
      `Rules:\n` +
      `1. Only report candidates whose names appear verbatim in the source content above.\n` +
      `2. Use ${input.sourceUrl ?? 'the source URL'} as the citation_url for every candidate — it is the page where their names appear.\n` +
      `3. Report candidates for ALL races you find — not just the ones in the context list below.\n` +
      `4. Call the report_candidates tool with all candidates you found.` +
      knownRacesBlock
    );
  }

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
