import { chmodSync, existsSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { LOCKDOWN_CONFIG, cleanEnv, dropUnusable, extractAssistantText, failCheck, familyOf, parseModelReply, prepareOutsidePrompt, runOpencode, secondOpinion, toCheck } from './summary-second-opinion.js';
import { mkdirSync } from 'node:fs';

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
  it('drops every OPENCODE_ variable so an inherited setting cannot override the deny', () => {
    const e = cleanEnv({ HOME: '/h', OPENCODE_CONFIG_CONTENT: '{}', OPENCODE_PERMISSION: '{}', OPENCODE_CONFIG: '/x', opencode_config_dir: '/y', PATH: '/p' });
    expect(Object.keys(e).sort()).toEqual(['HOME', 'PATH']);
  });
  it('family comes from the model id', () => {
    expect(familyOf('opencode-go/gpt-6-luna')).toBe('gpt');
    expect(familyOf('opencode-go/gemini-4-argon')).toBe('gemini');
    expect(familyOf('opencode/claude-x')).toBeNull();
  });
});

describe('lockdown and retry', () => {
  it('denies every tool permission', () => {
    expect(LOCKDOWN_CONFIG.permission).toEqual({ '*': 'deny' });
  });
  it('--retry-unusable removes only no-usable-reply lines and names their (sha, checker)', () => {
    const s = { politician_id: 'p', topic_key: 't', sha256: 'S1', cites: [['f']] };
    const unusable = JSON.stringify(failCheck(s, 'm1', 'gpt', 'timed out'));
    const judged = JSON.stringify({ ...failCheck(s, 'm2', 'gemini', 'x'), sentences: [{ index: 0, verdict: 'fail', reason: 'Finding f does not support it.' }] });
    const passed = JSON.stringify(toCheck(s, JSON.stringify(reply), 'm3', 'gpt'));
    const { kept, removed } = dropUnusable([unusable, judged, passed, '']);
    expect(kept).toEqual([judged, passed]);
    expect([...removed]).toEqual(['S1|m1']);
  });
});

describe('nothing local reaches an outside model', () => {
  const BATCH = '/Users/someone/work/summaries/b1';
  const claudeFile = [
    'Intro.', '', '## Output', '',
    'Write your JSON to the path given below and write nothing else (if you cannot write files, reply with the JSON only), exactly this shape.',
    '', '```json', '{}', '```', '', `Path to write your JSON to: ${BATCH}/claude-checks/1.json`, '',
  ].join('\n');

  it('strips the write instruction and the path', () => {
    const r = prepareOutsidePrompt(claudeFile, [BATCH, homedir()]);
    expect('text' in r).toBe(true);
    const t = (r as { text: string }).text;
    expect(t).not.toContain(BATCH);
    expect(t).not.toMatch(/write your json|path to write|claude-checks/i);
    expect(t).toContain('Reply with JSON only');
  });

  it('refuses a prompt that still holds the home or batch path', () => {
    const home = `Note: see ${homedir()}/x for context.`;
    expect(prepareOutsidePrompt(home, [homedir()])).toEqual({ why: 'local path in prompt' });
    expect(prepareOutsidePrompt(`See ${BATCH}/y`, [BATCH])).toEqual({ why: 'local path in prompt' });
  });

  it('runOpencode sends the stripped text, and sends nothing for a prompt with a local path', () => {
    const d = mkdtempSync(join(tmpdir(), 'fake-oc-'));
    const cap = join(d, 'captured.md');
    writeFileSync(join(d, 'opencode'), `#!/bin/sh\nwhile [ $# -gt 0 ]; do if [ "$1" = "-f" ]; then cp "$2" "${cap}"; fi; shift; done\n`);
    chmodSync(join(d, 'opencode'), 0o755);
    const env = { PATH: `${d}:${process.env.PATH}` };
    const f = join(d, 'c.md'); writeFileSync(f, claudeFile);
    runOpencode(f, 'opencode-go/gpt-6-luna', 20, env, [BATCH, homedir()]);
    const sent = readFileSync(cap, 'utf8');
    expect(sent).not.toMatch(/\/Users\/someone|write your json|path to write/i);
    const g = join(d, 'g.md'); writeFileSync(g, `${claudeFile}\nhome ${homedir()}/secret`);
    const before = existsSync(cap) ? readFileSync(cap, 'utf8') : '';
    writeFileSync(cap, '');
    const r = runOpencode(g, 'opencode-go/gpt-6-luna', 20, env, [BATCH, homedir()]);
    expect(r).toMatchObject({ text: '', why: 'local path in prompt' });
    expect(readFileSync(cap, 'utf8')).toBe('');
    expect(before).not.toContain(homedir());
  });
});

describe('batch run: pairing by person, skipping checked pairs', () => {
  const MODELS = ['opencode-go/gpt-x', 'opencode-go/gemini-x'];
  const FAMS = MODELS.map((m) => familyOf(m)!);
  const checkerMd = (pid: string, sha: string) => `Check this.\n\n\`\`\`json\n{ "politician_id": "${pid}", "topic_key": "gun-policy", "text_sha256": "${sha}" }\n\`\`\`\n`;
  function batch(rows: { pid: string; sha: string; mdSha?: string }[], existing: object[] = []) {
    const dir = mkdtempSync(join(tmpdir(), 'so-batch-'));
    mkdirSync(join(dir, 'checker'));
    writeFileSync(join(dir, 'summaries.jsonl'), rows.map((r) => JSON.stringify({ politician_id: r.pid, topic_key: 'gun-policy', sha256: r.sha, cites: [['f']] })).join('\n') + '\n');
    for (const r of rows) writeFileSync(join(dir, 'checker', `${r.pid}.md`), checkerMd(r.pid, r.mdSha ?? r.sha));
    if (existing.length) writeFileSync(join(dir, 'checks.jsonl'), existing.map((c) => JSON.stringify(c)).join('\n') + '\n');
    const calls: string[] = [];
    const logs: string[] = [];
    const call = (file: string, model: string) => {
      const pid = /"politician_id": "([^"]+)"/.exec(readFileSync(file, 'utf8'))![1];
      calls.push(`${pid}|${model}`);
      return { text: JSON.stringify({ ...reply, politician_id: pid }), seconds: 0 };
    };
    const go = (retry = false) => secondOpinion({ dir, models: MODELS, families: FAMS, call, retry, log: (l) => logs.push(l) });
    const recorded = () => readFileSync(join(dir, 'checks.jsonl'), 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
    return { dir, calls, logs, go, recorded };
  }
  const prior = (pid: string, sha: string, model: string) => ({
    politician_id: pid, topic_key: 'gun-policy', text_sha256: sha, checker: model, family: familyOf(model), at: '2026-11-22T10:00:00Z',
    verdict: 'pass', sentences: [{ index: 0, verdict: 'pass', reason: 'ok' }],
  });

  it('reads checker/<politician_id>.md for each row and skips a (person, sha, model) already in checks.jsonl', () => {
    const b = batch([{ pid: 'p1', sha: 'S1' }, { pid: 'p2', sha: 'S2' }], [prior('p1', 'S1', MODELS[0])]);
    b.go();
    expect(b.calls.sort()).toEqual([`p1|${MODELS[1]}`, `p2|${MODELS[0]}`, `p2|${MODELS[1]}`].sort());
    expect(b.recorded()).toHaveLength(4);
    b.calls.length = 0;
    b.go();
    expect(b.calls).toEqual([]);
    expect(b.recorded()).toHaveLength(4);
  });

  it('after one person is rewritten, a whole-batch run checks only the new text and keeps the old lines', () => {
    const b = batch([{ pid: 'p1', sha: 'S1' }, { pid: 'p2', sha: 'S2' }]);
    b.go();
    // p1 rewritten: new sha in summaries.jsonl and in its checker file; p2 unchanged.
    writeFileSync(join(b.dir, 'summaries.jsonl'), [JSON.stringify({ politician_id: 'p1', topic_key: 'gun-policy', sha256: 'S1b', cites: [['f']] }), JSON.stringify({ politician_id: 'p2', topic_key: 'gun-policy', sha256: 'S2', cites: [['f']] })].join('\n') + '\n');
    writeFileSync(join(b.dir, 'checker', 'p1.md'), checkerMd('p1', 'S1b'));
    b.calls.length = 0;
    b.go();
    expect(b.calls.sort()).toEqual([`p1|${MODELS[0]}`, `p1|${MODELS[1]}`].sort());
    const r = b.recorded();
    expect(r).toHaveLength(6);
    expect(r.filter((c) => c.politician_id === 'p2')).toHaveLength(2);
    expect(r.filter((c) => c.text_sha256 === 'S1b')).toHaveLength(2);
  });

  it('refuses to send a checker file whose sha256 is not that person\'s row, records nothing and says so', () => {
    const b = batch([{ pid: 'p1', sha: 'S1' }, { pid: 'p2', sha: 'S2', mdSha: 'OLD' }]);
    b.go();
    expect(b.calls.every((c) => c.startsWith('p1|'))).toBe(true);
    expect(b.recorded().some((c) => c.politician_id === 'p2')).toBe(false);
    expect(b.logs.join('\n')).toMatch(/REFUSED p2.*OLD.*S2/);
  });

  it('refuses a checker file that names another person', () => {
    const b = batch([{ pid: 'p1', sha: 'S1' }]);
    writeFileSync(join(b.dir, 'checker', 'p1.md'), checkerMd('p9', 'S1'));
    b.go();
    expect(b.calls).toEqual([]);
    expect(existsSync(join(b.dir, 'checks.jsonl'))).toBe(false);
    expect(b.logs.join('\n')).toMatch(/REFUSED p1/);
  });

  it('--retry-unusable re-runs only the unusable calls and rewrites the file once', () => {
    const unusable = failCheck({ politician_id: 'p1', topic_key: 'gun-policy', sha256: 'S1' }, MODELS[0], 'gpt', 'timed out');
    const b = batch([{ pid: 'p1', sha: 'S1' }], [unusable, prior('p1', 'S1', MODELS[1])]);
    b.go(true);
    expect(b.calls).toEqual([`p1|${MODELS[0]}`]);
    const r = b.recorded();
    expect(r).toHaveLength(2);
    expect(r.every((c) => c.verdict === 'pass')).toBe(true);
  });
});

