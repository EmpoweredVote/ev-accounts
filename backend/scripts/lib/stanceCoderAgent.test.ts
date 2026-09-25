import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const md = readFileSync(fileURLToPath(new URL('../../../.claude/agents/stance-coder.md', import.meta.url)), 'utf8');
const front = md.split('---')[1];

describe('stance-coder agent (ruling Q1, 2026-09-25)', () => {
  it('is named stance-coder', () => expect(front).toMatch(/^name: stance-coder$/m));
  it('has exactly the Write tool — no Read, Bash, WebFetch, WebSearch or MCP', () =>
    expect(front).toMatch(/^tools: Write$/m));
});
