import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { historicalSlots } from './migration-slots.mjs';

// The seeder's whole job is to find EVERY slot the repo has ever claimed, so the
// allocator never hands out a taken number. The interesting question is not parsing
// — that is covered next door — but whether the scan reaches slots that live only on
// a branch nobody merged, or only on a LOCAL branch in another worktree.
//
// 🔴 The local-branch case is not hypothetical. check-migration-numbers.mjs scanned
// only refs/remotes/ until 2026-09-02, and a knight worktree took CC_0045/0046/0047
// on an unpushed local branch while the compass stream took CC_0045 fifteen minutes
// later. Both were applied to production. So these build real repos and real clones.

const MIGRATIONS = 'backend/migrations';
let root: string;

beforeAll(() => { root = mkdtempSync(path.join(tmpdir(), 'stewardseed-')); });
afterAll(() => { rmSync(root, { recursive: true, force: true }); });

const git = (cwd: string, ...args: string[]) =>
  execFileSync('git', ['-c', 'user.email=t@t', '-c', 'user.name=t', '-c', 'commit.gpgsign=false', ...args],
    { cwd, encoding: 'utf8' });

function commitMigration(repo: string, name: string) {
  mkdirSync(path.join(repo, MIGRATIONS), { recursive: true });
  writeFileSync(path.join(repo, MIGRATIONS, name), '-- test\n');
  git(repo, 'add', '-A');
  git(repo, 'commit', '-m', `add ${name}`);
}

/** An origin with one migration on master and one on an unmerged pushed branch, then a clone. */
function buildRepo(tag: string) {
  const origin = path.join(root, `${tag}-origin`);
  mkdirSync(origin, { recursive: true });
  git(origin, 'init', '-b', 'master');
  commitMigration(origin, 'CC_0001_on_master.sql');
  git(origin, 'checkout', '-b', 'someone-else');
  commitMigration(origin, 'CC_0002_pushed_not_merged.sql');
  git(origin, 'checkout', 'master');

  const clone = path.join(root, `${tag}-clone`);
  git(root, 'clone', origin, clone);
  return clone;
}

describe('historicalSlots', () => {
  it('finds a slot claimed on master', () => {
    const repo = buildRepo('a');
    const keys = historicalSlots(repo).map((s) => s.key);
    expect(keys).toContain('CC_1');
  });

  it('finds a slot claimed only on a pushed but unmerged branch', () => {
    const repo = buildRepo('b');
    const keys = historicalSlots(repo).map((s) => s.key);
    expect(keys).toContain('CC_2');
  });

  it('finds a slot claimed only on an UNPUSHED local branch', () => {
    const repo = buildRepo('c');
    git(repo, 'checkout', '-b', 'local-only');
    commitMigration(repo, 'CC_0003_never_pushed.sql');
    const keys = historicalSlots(repo).map((s) => s.key);
    expect(keys).toContain('CC_3');
  });

  it('reports the filename and the refs that claim each slot', () => {
    const repo = buildRepo('d');
    const row = historicalSlots(repo).find((s) => s.key === 'CC_1');
    expect(row?.filename).toBe('CC_0001_on_master.sql');
    expect(row?.refs.length).toBeGreaterThan(0);
  });

  it('splits the namespace from the number, ready for the allocator', () => {
    const repo = buildRepo('e');
    const row = historicalSlots(repo).find((s) => s.key === 'CC_2');
    expect(row?.namespace).toBe('CC');
    expect(row?.num).toBe(2);
  });

  it('returns each slot once even when several refs carry the same file', () => {
    const repo = buildRepo('f');
    const ones = historicalSlots(repo).filter((s) => s.key === 'CC_1');
    expect(ones).toHaveLength(1);
  });
});
