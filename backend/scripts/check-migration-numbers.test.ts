import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Integration tests: the thing worth testing is whether the script can SEE a number
// claimed on a pushed-but-unmerged branch, which is a question about what it asks git.
// So each case builds a real origin repo + a real clone (so refs/remotes/origin/* exist)
// and runs the script as a subprocess, exactly as CI and a pre-push run do.

const SCRIPT = path.join(path.dirname(fileURLToPath(import.meta.url)), 'check-migration-numbers.mjs');
const MIGRATIONS = 'backend/migrations';

let root: string;
beforeAll(() => { root = mkdtempSync(path.join(tmpdir(), 'migcheck-')); });
afterAll(() => { rmSync(root, { recursive: true, force: true }); });

const git = (cwd: string, ...args: string[]) =>
  execFileSync('git', ['-c', 'user.email=t@t', '-c', 'user.name=t', '-c', 'commit.gpgsign=false', ...args],
    { cwd, encoding: 'utf8' });

function addMigration(repo: string, name: string) {
  mkdirSync(path.join(repo, MIGRATIONS), { recursive: true });
  writeFileSync(path.join(repo, MIGRATIONS, name), '-- test\n');
}

/**
 * Build an origin repo whose master holds `masterFiles`, plus one branch per entry in
 * `branches`, then clone it so the clone has remote-tracking refs for all of them.
 * Returns the clone path, with `mine` checked out and `myFiles` present but uncommitted.
 */
function scenario(label: string, opts: {
  masterFiles: string[];
  branches?: Record<string, string[]>;
  myFiles: string[];
  myBranchPushed?: boolean;
}): string {
  const origin = path.join(root, `${label}-origin`);
  mkdirSync(origin, { recursive: true });
  git(origin, 'init', '-q', '-b', 'master');
  for (const f of opts.masterFiles) addMigration(origin, f);
  git(origin, 'add', '-A');
  git(origin, 'commit', '-qm', 'master migrations');

  for (const [branch, files] of Object.entries(opts.branches ?? {})) {
    git(origin, 'checkout', '-q', '-b', branch);
    for (const f of files) addMigration(origin, f);
    git(origin, 'add', '-A');
    git(origin, 'commit', '-qm', `${branch} migrations`);
    git(origin, 'checkout', '-q', 'master');
  }

  const clone = path.join(root, `${label}-clone`);
  git(root, 'clone', '-q', origin, clone);
  git(clone, 'checkout', '-q', '-b', 'mine');
  for (const f of opts.myFiles) addMigration(clone, f);
  if (opts.myBranchPushed) {
    git(clone, 'add', '-A');
    git(clone, 'commit', '-qm', 'my migration');
    git(clone, 'push', '-q', 'origin', 'mine');
    git(clone, 'fetch', '-q', 'origin');
  }
  return clone;
}

function check(cwd: string): { code: number; out: string } {
  try {
    const out = execFileSync('node', [SCRIPT], { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
    return { code: 0, out };
  } catch (e: any) {
    return { code: e.status ?? 1, out: `${e.stdout ?? ''}${e.stderr ?? ''}` };
  }
}

describe('check-migration-numbers: numbers claimed on pushed branches', () => {
  it('fails when my new migration reuses a number claimed only on an unmerged pushed branch', () => {
    // This is the gap: 1500 is on origin/feat/theirs and NOT on master, so a base-only
    // comparison green-lights it. Verified against the real repo on 2026-08-21, where
    // 1827_austin_travis_offices.sql sits on origin/feat/austin-tx-deep-seed only.
    const repo = scenario('branchclaim', {
      masterFiles: ['1499_base.sql'],
      branches: { 'feat/theirs': ['1500_theirs.sql'] },
      myFiles: ['1500_mine.sql'],
    });
    const { code, out } = check(repo);
    expect(code).toBe(1);
    expect(out).toMatch(/1500/);
    expect(out).toMatch(/feat\/theirs/);
  });

  it('names the next free number above every claim, base and branch alike', () => {
    const repo = scenario('nextfree', {
      masterFiles: ['1499_base.sql'],
      branches: { 'feat/theirs': ['1500_theirs.sql', '1501_theirs_two.sql'] },
      myFiles: ['1500_mine.sql'],
    });
    expect(check(repo).out).toMatch(/1502/);
  });

  it('passes when my number is free on master and on every pushed branch', () => {
    const repo = scenario('clean', {
      masterFiles: ['1499_base.sql'],
      branches: { 'feat/theirs': ['1500_theirs.sql'] },
      myFiles: ['1501_mine.sql'],
    });
    const { code, out } = check(repo);
    expect(code).toBe(0);
    expect(out).toMatch(/OK/);
  });

  it('does not flag my own migration against its own pushed branch', () => {
    // Once I push, my file exists on refs/remotes/origin/mine too. Matching it against
    // itself would make the check fail permanently after the first push.
    const repo = scenario('selfpush', {
      masterFiles: ['1499_base.sql'],
      myFiles: ['1500_mine.sql'],
      myBranchPushed: true,
    });
    const { code, out } = check(repo);
    expect(code).toBe(0);
    expect(out).toMatch(/OK/);
  });

  it('still catches a collision with master', () => {
    const repo = scenario('baseclash', {
      masterFiles: ['1500_theirs.sql'],
      myFiles: ['1500_mine.sql'],
    });
    expect(check(repo).code).toBe(1);
  });
});

describe('check-migration-numbers: per-author namespace prefixes', () => {
  it('treats CA_1500 and 1500 as different slots', () => {
    // An opt-in per-author namespace is only safe if the checker understands it. Without
    // this, `CA_1500_x.sql` fails the ^(\d+)_ regex and is silently invisible to BOTH checks.
    const repo = scenario('ns-ok', {
      masterFiles: ['1500_theirs.sql'],
      myFiles: ['CA_1500_mine.sql'],
    });
    const { code, out } = check(repo);
    expect(code).toBe(0);
    expect(out).toMatch(/OK/);
  });

  it('still catches two migrations sharing a number inside the same namespace', () => {
    const repo = scenario('ns-clash', {
      masterFiles: ['CA_1500_theirs.sql'],
      myFiles: ['CA_1500_mine.sql'],
    });
    expect(check(repo).code).toBe(1);
  });
});
