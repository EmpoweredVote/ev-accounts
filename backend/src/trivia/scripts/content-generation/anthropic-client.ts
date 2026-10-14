import 'dotenv/config';
import Anthropic from '@anthropic-ai/sdk';

// Model to use for content generation.
// Was 'claude-sonnet-4-5', which reaches end-of-life on 2026-11-30.
export const MODEL = 'claude-sonnet-5-5';

// Sonnet 5.5 runs adaptive thinking by default; 'low' keeps it short and
// skips it on most simple requests. Every call site passes this explicitly.
export const EFFORT = 'low' as const;

// Configured Anthropic client — SDK auto-detects ANTHROPIC_API_KEY from environment
export const client = new Anthropic({
  maxRetries: 3,
  timeout: 120000,
});

/**
 * The first text block of a response, or null if it has none.
 *
 * With adaptive thinking a response can begin with a `thinking` block, so
 * reading `content[0]` is wrong — find the text block by type. A response
 * with no text block (e.g. a refusal) returns null; callers treat that as
 * an unexpected response and log `describeContent()`.
 */
export function firstText(response: Anthropic.Message): string | null {
  const block = response.content.find(
    (b): b is Anthropic.TextBlock => b.type === 'text',
  );
  return block ? block.text : null;
}

/** Block types plus stop_reason, for logging a response with no text block. */
export function describeContent(response: Anthropic.Message): string {
  const types = response.content.map(b => b.type).join(',') || 'empty';
  return `${types} (stop_reason=${response.stop_reason})`;
}
