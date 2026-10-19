import { describe, it, expect } from 'vitest';
import type Anthropic from '@anthropic-ai/sdk';
import { firstText, describeContent } from './anthropic-client.js';

function message(content: unknown[], stop_reason = 'end_turn'): Anthropic.Message {
  return { content, stop_reason } as unknown as Anthropic.Message;
}

describe('firstText', () => {
  it('skips a leading thinking block (adaptive thinking on Sonnet 5.5)', () => {
    const res = message([
      { type: 'thinking', thinking: '', signature: 'sig' },
      { type: 'text', text: '{"questions":[]}' },
    ]);
    expect(firstText(res)).toBe('{"questions":[]}');
  });

  it('returns the text of a text-only response', () => {
    expect(firstText(message([{ type: 'text', text: 'hi' }]))).toBe('hi');
  });

  it('returns null when there is no text block', () => {
    const res = message([{ type: 'thinking', thinking: '', signature: 'sig' }], 'refusal');
    expect(firstText(res)).toBeNull();
    expect(describeContent(res)).toBe('thinking (stop_reason=refusal)');
  });

  it('describes an empty response', () => {
    expect(describeContent(message([], 'max_tokens'))).toBe('empty (stop_reason=max_tokens)');
  });
});
