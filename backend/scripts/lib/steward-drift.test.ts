import { describe, it, expect } from 'vitest';
import {
  classifyBranchDrift,
  collectBranchDrift,
  driftLines,
  DEFAULT_STALE_BEHIND,
} from './steward-drift.mjs';

// The collision this file exists for, measured 2026-09-26:
//
//   Knight slice 11 (Michigan) held `state:mi`. Slice 12 (North Dakota) held `state:nd`.
//   Disjoint scopes, so the database had nothing to refuse. Slots CC_0138-0143 and
//   CC_0144-0149, so no slot collision. Separate worktrees, so no HEAD moved under anyone.
//   EVERY EXISTING STEWARD MECHANISM WORKED PERFECTLY AND THE BRANCHES STILL COLLIDED —
//   both slices edit `load-state-tiger-boundaries.ts`, because every state's load does.
//
//   PR #797 sat 64 behind master with 2 conflicting files for two days, unreported.
//
// 🔴 The steward's scopes describe the WORLD. That collision was in the REPO. So the unit of
//    warning here is a BRANCH, which the steward already records per worktree.

describe('classifyBranchDrift', () => {
  // 🔴 THE CASE THE FEATURE WAS BUILT FROM. It must name the files, because "you conflict"
  //    sends someone to go and look, and "you conflict in PROGRAM.md and the TIGER loader"
  //    tells them whether it is ten minutes or an afternoon.
  it('reports #797 as conflicting and names the files', () => {
    const { level, line } = classifyBranchDrift({
      branch: 'knight/mi-slice11',
      behind: 64,
      ahead: 5,
      conflicts: ['.planning/knight-foundation/PROGRAM.md', 'backend/scripts/load-state-tiger-boundaries.ts'],
      where: 'C:/ev-accounts-mi',
    });
    expect(level).toBe('conflicting');
    expect(line).toContain('knight/mi-slice11');
    expect(line).toContain('64 behind');
    expect(line).toContain('PROGRAM.md');
    expect(line).toContain('load-state-tiger-boundaries.ts');
    expect(line).toContain('C:/ev-accounts-mi');
  });

  // A conflict does not become a conflict at some distance — it is one immediately. Gating this
  // on the staleness threshold would have stayed silent for the first 39 commits of #797's life,
  // which is precisely the window in which the merge was still trivial.
  it('reports a conflict at any distance, well below the staleness threshold', () => {
    const { level } = classifyBranchDrift({ branch: 'x', behind: 2, ahead: 1, conflicts: ['a.ts'] });
    expect(level).toBe('conflicting');
  });

  // 🔴 A BRANCH WITH NOTHING ON IT IS NOT DRIFTING, IT IS JUST OLD. Every long-lived checkout of
  //    the default branch is hundreds behind and has nothing to land. Reporting those would bury
  //    the one row that matters — which is how a warning stops being read at all.
  it('says nothing about a branch that is far behind but has no work on it', () => {
    const { level, line } = classifyBranchDrift({ branch: 'master', behind: 400, ahead: 0, conflicts: [] });
    expect(level).toBe('ok');
    expect(line).toBeNull();
  });

  it('says nothing about a detached HEAD, which has no branch to land', () => {
    expect(classifyBranchDrift({ branch: null, behind: 90, ahead: 3, conflicts: ['a'] }).line).toBeNull();
  });

  // 🔴 THE DISTINCTION THIS REPO HAS NOW PAID FOR THREE TIMES: a probe that could not run must
  //    not read as a probe that found nothing. A blind untracked scan, a 503 archive probe and a
  //    WAF-blocked sweep each returned "nothing found" and each was wrong. null is NOT [].
  it('reports an uncomputed conflict state as unknown, never as clean', () => {
    const { level, line } = classifyBranchDrift({ branch: 'x', behind: 50, ahead: 2, conflicts: null });
    expect(level).toBe('unknown');
    expect(line).toContain('NOT COMPUTED');
  });

  it('is quiet for a clean branch cut recently, and speaks once it is stale', () => {
    expect(classifyBranchDrift({ branch: 'x', behind: 3, ahead: 2, conflicts: [] }).line).toBeNull();
    const stale = classifyBranchDrift({ branch: 'x', behind: DEFAULT_STALE_BEHIND, ahead: 2, conflicts: [] });
    expect(stale.level).toBe('stale');
  });
});

describe('driftLines', () => {
  // ⚠ SILENCE IS A FEATURE. `who` runs at every session start. A section that always prints
  //   something is a section that gets scrolled past on the day it matters.
  it('prints nothing at all when every branch is fine', () => {
    expect(driftLines([
      { branch: 'a', behind: 0, ahead: 1, conflicts: [] },
      { branch: 'master', behind: 300, ahead: 0, conflicts: [] },
    ])).toEqual([]);
  });

  it('puts the conflicting branch above the merely stale one', () => {
    const out = driftLines([
      { branch: 'stale-one', behind: 99, ahead: 1, conflicts: [] },
      { branch: 'broken-one', behind: 5, ahead: 1, conflicts: ['x.ts'] },
    ]);
    const broken = out.findIndex((l) => l.includes('broken-one'));
    const stale = out.findIndex((l) => l.includes('stale-one'));
    expect(broken).toBeGreaterThan(-1);
    expect(broken).toBeLessThan(stale);
  });

  // 🔴 A STALE BASE REF UNDERSTATES EVERY NUMBER, SILENTLY. CLAUDE.md's most common recorded
  //    collision is trusting a stale worktree — one read 1424 when upstream was at 1464.
  it('warns that the counts are floors when the base ref is old', () => {
    const out = driftLines([{ branch: 'x', behind: 50, ahead: 1, conflicts: ['a'] }], { baseAgeHours: 30 });
    expect(out.join('\n')).toContain('git fetch origin');
    expect(out.join('\n')).toContain('floors, not truths');
  });

  it('does not nag about a fresh base ref', () => {
    const out = driftLines([{ branch: 'x', behind: 50, ahead: 1, conflicts: ['a'] }], { baseAgeHours: 1 });
    expect(out.join('\n')).not.toContain('git fetch origin');
  });

  // The advice is specific because the generic version is what went wrong: someone fixing this
  // in the OTHER session's worktree would break the rule the steward exists to enforce.
  it('tells you to merge in the branch\'s own worktree, only when something conflicts', () => {
    const conflicting = driftLines([{ branch: 'x', behind: 5, ahead: 1, conflicts: ['a'] }]).join('\n');
    expect(conflicting).toContain('ITS OWN worktree');
    const stale = driftLines([{ branch: 'x', behind: 99, ahead: 1, conflicts: [] }]).join('\n');
    expect(stale).not.toContain('ITS OWN worktree');
  });
});

describe('collectBranchDrift', () => {
  const fakeGit = (responses: Record<string, string | (() => string)>) => (args: string[]) => {
    const key = args.join(' ');
    const hit = Object.entries(responses).find(([k]) => key.includes(k));
    if (!hit) throw new Error(`unexpected git: ${key}`);
    const v = hit[1];
    return typeof v === 'function' ? v() : v;
  };

  it('reads behind/ahead and a clean merge as conflicts: []', () => {
    const git = fakeGit({
      'rev-list': '7\t2\n',
      'merge-tree': 'abc123def\n',
    });
    const [row] = collectBranchDrift(git, { branches: [{ branch: 'feat/x' }] });
    expect(row.behind).toBe(7);
    expect(row.ahead).toBe(2);
    expect(row.conflicts).toEqual([]);
  });

  // 🔴 `git merge-tree` EXITS NON-ZERO WHEN IT CONFLICTS. That is the NORMAL path, not an error
  //    path — and the paths are on stdout of the throwing call. Treating the throw as "could not
  //    check" would report every genuinely conflicting branch as unknown, i.e. would fail
  //    exactly when it is needed.
  it('parses the conflicted paths out of a merge-tree that exits non-zero', () => {
    const git = fakeGit({
      'rev-list': '64\t5\n',
      'merge-tree': () => {
        const e: any = new Error('exit 1');
        e.stdout = 'treeoid\n.planning/knight-foundation/PROGRAM.md\nbackend/scripts/load-state-tiger-boundaries.ts\n\nAuto-merging .planning/knight-foundation/PROGRAM.md\nCONFLICT (content): Merge conflict in PROGRAM.md\n';
        throw e;
      },
    });
    const [row] = collectBranchDrift(git, { branches: [{ branch: 'knight/mi-slice11' }] });
    expect(row.behind).toBe(64);
    expect(row.ahead).toBe(5);
    expect(row.conflicts).toEqual([
      '.planning/knight-foundation/PROGRAM.md',
      'backend/scripts/load-state-tiger-boundaries.ts',
    ]);
  });

  it('reports a missing ref as unknown rather than clean', () => {
    const git = fakeGit({ 'rev-list': () => { throw new Error('unknown revision'); } });
    const [row] = collectBranchDrift(git, { branches: [{ branch: 'gone' }] });
    expect(row.conflicts).toBeNull();
    expect(classifyBranchDrift(row).level).not.toBe('ok');
  });

  // A branch with no work needs no merge computed, and asking would cost a merge-tree per
  // session start for every checkout of the default branch.
  it('skips the merge computation entirely when there is nothing ahead', () => {
    let mergeTreeCalls = 0;
    const git = (args: string[]) => {
      if (args[0] === 'rev-list') return '120\t0\n';
      mergeTreeCalls++;
      return '';
    };
    const [row] = collectBranchDrift(git, { branches: [{ branch: 'master' }] });
    expect(mergeTreeCalls).toBe(0);
    expect(row.conflicts).toEqual([]);
  });
});
