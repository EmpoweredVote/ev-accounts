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

// 🔴 WHICH NAME A RENAMED SLOT REPORTS USED TO DEPEND ON REF SCAN ORDER, and that made the
// board itself wrong. `for-each-ref` returns refs sorted by refname, the scan kept the FIRST
// filename it met per slot, and so a branch whose name sorts before 'master' won. Measured on
// the real repo 2026-09-09: CA_0077 was recorded as CA_0077_pin_education_topics_season2.sql,
// the loser of a collision PR #367 had already resolved in master's favour, because the seed
// ran where a stale branch was scanned first. `steward sync` then reported drift on one
// machine and nothing on another, for the same row and the same repo.
//
// The base ref is the answer to "what does this slot MEAN", because that is the tree everyone
// shares. A slot living only on branches has no such answer, so the fallback has to be
// deterministic rather than first-seen.

/**
 * master carries `newName`; LOCAL branches listed in `staleBranches` keep `oldName`.
 *
 * ⚠ THE STALE BRANCHES MUST BE LOCAL HEADS. `for-each-ref refs/heads/ refs/remotes/` lists
 *   heads first, so a stale branch left in an origin and reached as refs/remotes/origin/…
 *   sorts AFTER refs/heads/master and first-seen picks master by luck — the control passes
 *   while the bug is present. 'aaa-stale' as a local head is what actually reproduces it.
 */
function buildRenamed(tag: string, oldName: string, newName: string, staleBranches = ['aaa-stale']) {
  const repo = path.join(root, `${tag}-repo`);
  mkdirSync(repo, { recursive: true });
  git(repo, 'init', '-b', 'master');
  commitMigration(repo, oldName);
  for (const b of staleBranches) {
    git(repo, 'branch', b);          // each pins the pre-rename tree
  }
  git(repo, 'mv', `${MIGRATIONS}/${oldName}`, `${MIGRATIONS}/${newName}`);
  git(repo, 'commit', '-m', `rename ${oldName} -> ${newName}`);
  return repo;
}

describe('historicalSlots — a slot whose filename changed', () => {
  it('reports the name the BASE REF carries, not the first one scanned', () => {
    const repo = buildRenamed('g', 'CA_0077_pin_education_topics_season2.sql',
      'CA_0077_growth_and_development_chairs_45_refork_substantive.sql');
    const row = historicalSlots(repo).find((s) => s.key === 'CA_77');
    expect(row?.filename).toBe('CA_0077_growth_and_development_chairs_45_refork_substantive.sql');
  });

  it('gives the same answer whichever side of master the stale branch sorts on', () => {
    // 'zzz-stale' sorts AFTER master, 'aaa-stale' before it. First-seen would flip; the base
    // ref does not, which is the whole point.
    const repo = buildRenamed('h', 'CA_0077_pin_education_topics_season2.sql',
      'CA_0077_growth_and_development_chairs_45_refork_substantive.sql', ['aaa-stale', 'zzz-stale']);
    const row = historicalSlots(repo).find((s) => s.key === 'CA_77');
    expect(row?.filename).toBe('CA_0077_growth_and_development_chairs_45_refork_substantive.sql');
    expect(row?.onBase).toBe(true);
  });

  it('reports every name the slot carries, with the refs behind each', () => {
    const repo = buildRenamed('i', 'CA_0077_old.sql', 'CA_0077_new.sql');
    const row = historicalSlots(repo).find((s) => s.key === 'CA_77');
    expect(row?.names.map((n) => n.filename).sort())
      .toEqual(['CA_0077_new.sql', 'CA_0077_old.sql']);
    for (const n of row!.names) expect(n.refs.length).toBeGreaterThan(0);
  });

  it('leaves a single-name slot with one name and onBase true', () => {
    const repo = buildRepo('j');
    const row = historicalSlots(repo).find((s) => s.key === 'CC_1');
    expect(row?.names).toHaveLength(1);
    expect(row?.filename).toBe('CC_0001_on_master.sql');
    expect(row?.onBase).toBe(true);
  });

  it('for a slot on no base ref, picks the name the most refs carry — never the first seen', () => {
    // CC_0009 exists only on branches: two carry 'b_wins', one carries 'a_loses'. 'a_loses'
    // sorts first, so first-seen would pick it.
    const repo = buildRepo('k');
    git(repo, 'checkout', '-b', 'aaa-one');
    commitMigration(repo, 'CC_0009_a_loses.sql');
    git(repo, 'checkout', 'master');
    git(repo, 'checkout', '-b', 'bbb-two');
    commitMigration(repo, 'CC_0009_b_wins.sql');
    git(repo, 'checkout', '-b', 'ccc-three');   // a second ref carrying b_wins
    git(repo, 'checkout', 'master');
    const row = historicalSlots(repo).find((s) => s.key === 'CC_9');
    expect(row?.filename).toBe('CC_0009_b_wins.sql');
    expect(row?.onBase).toBe(false);
  });

  it('breaks a tie by name, so two equally-carried names still answer the same every run', () => {
    const repo = buildRepo('l');
    git(repo, 'checkout', '-b', 'zzz-late');
    commitMigration(repo, 'CC_0008_zebra.sql');
    git(repo, 'checkout', 'master');
    git(repo, 'checkout', '-b', 'aaa-early');
    commitMigration(repo, 'CC_0008_apple.sql');
    git(repo, 'checkout', 'master');
    const row = historicalSlots(repo).find((s) => s.key === 'CC_8');
    expect(row?.filename).toBe('CC_0008_apple.sql');
  });
});
