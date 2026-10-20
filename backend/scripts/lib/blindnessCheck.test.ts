import { describe, it, expect } from 'vitest';
import { findForbiddenReads, scanTranscript, summarise, isEmptyForbidden } from './blindnessCheck.js';

const HOME = '/Users/u';
const call = (name: string, input: Record<string, unknown>) =>
  JSON.stringify({ message: { role: 'assistant', content: [{ type: 'text', text: 'x' }, { type: 'tool_use', name, input }] } });
const T = (...lines: string[]) => lines.join('\n');
const S1 = '/Users/u/Documents/GitHub/.planning/research/x/stage1';

describe('findForbiddenReads', () => {
  it('clean transcript passes', () => {
    const t = T(call('Read', { file_path: '/Users/u/Documents/GitHub/ok.md' }), call('Bash', { command: 'ls' }));
    expect(findForbiddenReads(t, [S1], HOME)).toEqual([]);
  });
  it('detects Read of a forbidden file', () => {
    const t = T(call('Bash', { command: 'ls' }), call('Read', { file_path: `${S1}/FROZEN.md` }));
    expect(findForbiddenReads(t, [S1], HOME)).toEqual([{ line: 2, path: S1, tool: 'Read' }]);
  });
  it('detects the path inside a Bash command', () => {
    const t = call('Bash', { command: 'cat ~/Documents/GitHub/.planning/research/x/stage1/FROZEN.md' });
    const hits = findForbiddenReads(t, [S1], HOME);
    expect(hits).toHaveLength(1);
    expect(hits[0].tool).toBe('Bash');
  });
  it('detects encoded and escaped spaces', () => {
    const f = '/Users/u/Library/Application Support/Claude/frozen';
    const t = T(
      call('WebFetch', { url: 'file:///Users/u/Library/Application%20Support/Claude/frozen/a.md' }),
      call('Bash', { command: 'cat /Users/u/Library/Application\\ Support/Claude/frozen/a.md' }),
    );
    expect(findForbiddenReads(t, [f], HOME).map((h) => h.line)).toEqual([1, 2]);
  });
  it('does not flag a sibling with a shared prefix', () => {
    const t = T(call('Read', { file_path: `${S1}b/x.md` }), call('Read', { file_path: `${S1}.md` }));
    expect(findForbiddenReads(t, [S1], HOME)).toEqual([]);
  });
  it('matches the folder itself, a trailing slash, and Grep/Glob inputs', () => {
    const t = T(call('Grep', { pattern: 'x', path: S1 }), call('Glob', { pattern: `${S1}/**/*.md` }));
    expect(findForbiddenReads(t, [`${S1}/`], HOME)).toHaveLength(2);
  });
  it('scans nested and unnamed input values', () => {
    const t = call('FutureTool', { opts: { deep: [`${S1}/a`] } });
    expect(findForbiddenReads(t, [S1], HOME)[0].tool).toBe('FutureTool');
  });
  it('skips and counts unparseable lines', () => {
    const t = T('not json', call('Read', { file_path: `${S1}/a` }), '{"broken":');
    const r = scanTranscript(t, [S1], HOME);
    expect(r.skippedLines).toBe(2);
    expect(r.hits).toHaveLength(1);
  });
  it('counts scanned tool calls', () => {
    const t = T(call('Read', { file_path: '/ok' }), call('Bash', { command: 'ls' }));
    expect(scanTranscript(t, [S1], HOME).toolCalls).toBe(2);
  });
  it('resolves a relative path against the line cwd', () => {
    const line = JSON.stringify({ cwd: '/Users/u/Documents/GitHub', message: { content: [
      { type: 'tool_use', name: 'Bash', input: { command: 'cat .planning/research/x/stage1/FROZEN.md' } }] } });
    expect(findForbiddenReads(line, [S1], HOME)).toHaveLength(1);
    expect(findForbiddenReads(call('Bash', { command: 'cat .planning/research/x/stage1/F.md' }), [S1], HOME)).toEqual([]);
    expect(findForbiddenReads(call('Bash', { command: 'cat .planning/research/x/stage1/F.md' }), [S1], HOME,
      { cwd: '/Users/u/Documents/GitHub' })).toHaveLength(1);
  });
  it('resolves ../ and Read file_path relative to cwd', () => {
    const line = JSON.stringify({ cwd: '/Users/u/Documents/GitHub/ev-accounts', message: { content: [
      { type: 'tool_use', name: 'Read', input: { file_path: '../.planning/research/x/stage1/a.md' } }] } });
    expect(findForbiddenReads(line, [S1], HOME)).toHaveLength(1);
  });
  it('follows a leading cd X && command', () => {
    const mk = (command: string) => JSON.stringify({ cwd: '/Users/u', message: { content: [
      { type: 'tool_use', name: 'Bash', input: { command } }] } });
    expect(findForbiddenReads(mk(`cd ${S1.replace('/stage1', '')} && cat stage1/x`), [S1], HOME)).toHaveLength(1);
    expect(findForbiddenReads(mk(`cd ~/Documents/GitHub/.planning/research/x/stage1; ls`), [S1], HOME)).toHaveLength(1);
    expect(findForbiddenReads(mk(`cd ${S1.replace('/stage1', '')} && cat stage1b/x`), [S1], HOME)).toEqual([]);
  });
  it('summarise: PASS needs evidence', () => {
    const pass = summarise({ hits: [], skippedLines: 1, toolCalls: 3 });
    expect(pass).toMatchObject({ status: 'PASS', exitCode: 0, text: 'PASS (3 tool calls scanned, 1 lines skipped)' });
    const none = summarise({ hits: [], skippedLines: 0, toolCalls: 0 });
    expect(none).toMatchObject({ status: 'NO_EVIDENCE', exitCode: 3 });
    expect(none.text.startsWith('NO EVIDENCE:')).toBe(true);
    const allBad = summarise(scanTranscript('junk\nmore junk', [S1], HOME));
    expect(allBad.status).toBe('NO_EVIDENCE');
    expect(summarise({ hits: [{ line: 1, path: S1, tool: 'Read' }], skippedLines: 0, toolCalls: 1 }).exitCode).toBe(1);
  });
  it('flags empty forbidden entries', () => {
    expect(isEmptyForbidden('/', HOME)).toBe(true);
    expect(isEmptyForbidden('', HOME)).toBe(true);
    expect(isEmptyForbidden(S1, HOME)).toBe(false);
  });
});
