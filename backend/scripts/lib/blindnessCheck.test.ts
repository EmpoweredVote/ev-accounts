import { describe, it, expect } from 'vitest';
import { findForbiddenReads, scanTranscript } from './blindnessCheck.js';

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
});
