import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { cleanEnv, extractAssistantText, failCheck, familyOf, parseModelReply, toCheck } from './summary-second-opinion.js';

const here = dirname(fileURLToPath(import.meta.url));
const fixture = (n: string) => readFileSync(join(here, 'fixtures', n), 'utf8');
const STAMP = { checker: 'opencode-go/gpt-6-luna', family: 'gpt' as const, at: '2026-11-22T10:00:00Z' };
const reply = {
  politician_id: 'p1', topic_key: 'gun-policy', text_sha256: 'abc', family: 'gpt',
  sentences: [{ index: 0, verdict: 'pass', reason: 'Finding f1 shows the vote.' }], verdict: 'pass',
};

describe('parseModelReply', () => {
  it('parses JSON in a fenced block', () => {
    const r = parseModelReply('```json\n' + JSON.stringify(reply) + '\n```', STAMP);
    expect(r).toHaveLength(1);
    expect(r![0].checker).toBe(STAMP.checker);
    expect(r![0].verdict).toBe('pass');
  });
  it('parses JSON with prose around it, braces inside strings included', () => {
    const odd = { ...reply, sentences: [{ index: 0, verdict: 'pass', reason: 'quote "}" and { brace' }] };
    const r = parseModelReply(`Here is my answer:\n${JSON.stringify(odd)}\nHope that helps.`, STAMP);
    expect(r![0].sentences[0].reason).toContain('{ brace');
  });
  it('accepts an array of checks', () => {
    expect(parseModelReply(JSON.stringify([reply, reply]), STAMP)).toHaveLength(2);
  });
  it('returns null for empty, truncated, non-JSON and schema-invalid replies', () => {
    expect(parseModelReply('', STAMP)).toBeNull();
    expect(parseModelReply('   \n', STAMP)).toBeNull();
    expect(parseModelReply(JSON.stringify(reply).slice(0, 80), STAMP)).toBeNull();
    expect(parseModelReply('I cannot do that.', STAMP)).toBeNull();
    expect(parseModelReply(JSON.stringify({ ...reply, verdict: 'maybe' }), STAMP)).toBeNull();
    // schema refuses pass with a failing sentence
    expect(parseModelReply(JSON.stringify({ ...reply, sentences: [{ index: 0, verdict: 'fail', reason: 'x' }] }), STAMP)).toBeNull();
  });
});

describe('extractAssistantText', () => {
  it('joins the text parts of a real opencode event stream', () => {
    const r = extractAssistantText(fixture('opencode-run-ok.jsonl'));
    expect(r.error).toBeUndefined();
    expect(parseModelReply(r.text, STAMP)).not.toBeNull(); // a real Gemini reply to a checker prompt
    expect(r.text.trim().startsWith('{')).toBe(true);
  });
  it('reports an error event instead of text', () => {
    const r = extractAssistantText(fixture('opencode-run-error.jsonl'));
    expect(r.text).toBe('');
    expect(r.error).toMatch(/Insufficient balance/);
  });
  it('ignores non-JSON lines and returns empty text for an empty stream', () => {
    expect(extractAssistantText('warning: something\n')).toEqual({ text: '' });
    expect(extractAssistantText('')).toEqual({ text: '' });
  });
});

describe('recording', () => {
  const summary = { politician_id: 'p1', topic_key: 'gun-policy', sha256: 'REAL', cites: [['f1']] };
  it('a null reply is recorded as a fail check with reason "no usable reply"', () => {
    const c = failCheck(summary, 'opencode-go/gpt-6-luna', 'gpt', 'timed out after 180s');
    expect(c.verdict).toBe('fail');
    expect(c.sentences[0].reason).toMatch(/^no usable reply: timed out/);
    expect(c.text_sha256).toBe('REAL');
    expect(c.family).toBe('gpt');
  });
  it('stamps the summary sha, not the one the model echoed', () => {
    const c = toCheck(summary, JSON.stringify(reply), 'opencode-go/gpt-6-luna', 'gpt');
    expect(c.text_sha256).toBe('REAL');
    expect(c.verdict).toBe('pass');
  });
  it('a reply whose sentences do not cover every sentence of the summary is a fail', () => {
    const two = { ...summary, cites: [['f1'], ['f2']] };
    const c = toCheck(two, JSON.stringify(reply), 'm', 'gpt');
    expect(c.verdict).toBe('fail');
    expect(c.sentences[0].reason).toMatch(/no usable reply: .*sentence/);
  });
  it('an unparseable reply is a fail', () => {
    expect(toCheck(summary, 'nope', 'm', 'gemini').verdict).toBe('fail');
  });
});

describe('environment and family', () => {
  it('drops secrets and keeps what opencode needs', () => {
    const e = cleanEnv({ HOME: '/h', PATH: '/p', OPENAI_API_KEY: 'x', GH_TOKEN: 'x', DATABASE_URL: 'x', SUPABASE_URL: 'x', MY_SECRET: 'x', DB_PASSWORD: 'x', LANG: 'C' });
    expect(Object.keys(e).sort()).toEqual(['HOME', 'LANG', 'PATH']);
  });
  it('family comes from the model id', () => {
    expect(familyOf('opencode-go/gpt-6-luna')).toBe('gpt');
    expect(familyOf('opencode-go/gemini-4-argon')).toBe('gemini');
    expect(familyOf('opencode/claude-x')).toBeNull();
  });
});
