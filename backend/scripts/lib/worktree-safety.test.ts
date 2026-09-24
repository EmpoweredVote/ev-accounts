import { describe, it, expect } from 'vitest';
import {
  verdictFor, IGNORABLE, parsePorcelain, isOurEnv, mainWorktreeRoot, canCompareEnv,
} from './worktree-safety.mjs';

// §9 rule 4: "Verify before deleting a worktree or branch: untracked-and-ignored count is zero,
// the branch is fully merged into origin/master, the merged content is byte-identical, and the
// repo stash count is unchanged. Run a positive control on any detector that reports 'nothing
// found' — on 2026-09-04 two such detectors were silently broken and only a control exposed
// them."
//
// 🔴 THE LITERAL RULE CANNOT PASS, WHICH IS WHY IT WAS NEVER RUN AS WRITTEN. Every worktree
//    here carries node_modules and a .env copy, so "untracked-and-ignored count is zero" is
//    false every single time. A checklist whose first item always fails is a checklist people
//    stop at — so the check asks the question the rule MEANS: is there anything here that
//    exists nowhere else? node_modules is regenerable and a .env verified byte-identical to the
//    main worktree's is a copy, and neither is unique content.

const ok = {
  upstream: 'ancestor',
  contentState: 'same',
  stashDelta: 0,
  untracked: [],
  envIdentical: true,
  controlPassed: true,
};

describe('verdictFor', () => {
  it('clears a worktree that is merged, identical, and holds nothing unique', () => {
    const v = verdictFor(ok);
    expect(v.safe).toBe(true);
    expect(v.blockers).toEqual([]);
  });

  it('refuses an unmerged branch', () => {
    const v = verdictFor({ ...ok, upstream: 'none' });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('not-merged');
  });

  it('refuses when the merged content is not byte-identical', () => {
    const v = verdictFor({ ...ok, contentState: 'differs' });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('content-differs');
  });

  // Stashes are shared across worktrees and are usually somebody else's. A change in the count
  // during your work means something of yours — or theirs — is sitting in one.
  it('refuses when the stash count moved in either direction', () => {
    expect(verdictFor({ ...ok, stashDelta: 1 }).safe).toBe(false);
    expect(verdictFor({ ...ok, stashDelta: -1 }).safe).toBe(false);
    expect(verdictFor({ ...ok, stashDelta: -1 }).blockers[0].kind).toBe('stash-changed');
  });

  it('ignores node_modules and a verified-identical .env, and says so', () => {
    const v = verdictFor({ ...ok, untracked: ['node_modules/x', 'backend/.env'] });
    expect(v.safe).toBe(true);
    expect(v.ignored).toHaveLength(2);
  });

  // 🔴 THE .env CARVE-OUT IS CONDITIONAL ON HAVING COMPARED IT. An unverified .env is treated
  //    as unique content, because the one in a worktree could hold a credential that exists
  //    nowhere else, and deleting that is unrecoverable.
  it('refuses a .env that was NOT verified identical', () => {
    const v = verdictFor({ ...ok, untracked: ['backend/.env'], envIdentical: false });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('unique-files');
  });

  // 🔴 A DEPENDENCY'S .env IS NOT OUR .env, AND TREATING IT AS ONE REFUSED A CLEAN WORKTREE.
  //    `node_modules/natural/.env` ships inside a published package: it matched the `.env` rule,
  //    which is conditional on a byte-comparison against the main checkout, so it was held to a
  //    test written for OUR credential file and reported as content that "exists nowhere else".
  //    Measured 2026-09-23 on a merged, content-identical worktree — the check refused it while
  //    four identical 544-byte copies sat in the other worktrees' node_modules. `node_modules`
  //    is regenerable from the lockfile WHATEVER a file inside it is called; that rule wins.
  it('ignores a .env that ships inside node_modules, compared or not', () => {
    const v = verdictFor({
      ...ok,
      untracked: ['backend/node_modules/natural/.env'],
      envIdentical: false,
    });
    expect(v.safe).toBe(true);
    expect(v.ignored).toEqual(['backend/node_modules/natural/.env']);
  });

  // ⚠ The narrowing must not reach our own file: one directory up is still ours.
  it('still refuses OUR unverified .env when a dependency also has one', () => {
    const v = verdictFor({
      ...ok,
      untracked: ['backend/node_modules/natural/.env', 'backend/.env'],
      envIdentical: false,
    });
    expect(v.safe).toBe(false);
    const b = v.blockers.find((x) => x.kind === 'unique-files');
    expect(b!.files).toEqual(['backend/.env']);
  });

  it('refuses any other untracked file, naming it', () => {
    const v = verdictFor({ ...ok, untracked: ['backend/data/notes.md'] });
    expect(v.safe).toBe(false);
    const b = v.blockers.find((x) => x.kind === 'unique-files');
    expect(b!.files).toEqual(['backend/data/notes.md']);
  });

  // 🔴 THE RULE'S OWN CLOSING SENTENCE, MADE STRUCTURAL. Two detectors were silently broken on
  //    2026-09-04 and only a positive control exposed them: an mtime scan whose threshold
  //    predated the checkout, and a curl sweep against a host that had begun 403-ing. A scan
  //    that reports "nothing found" is worthless until it has proved it can find something.
  it('refuses when the scan could not prove it detects anything', () => {
    const v = verdictFor({ ...ok, controlPassed: false });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('control-failed');
  });

  it('reports every blocker at once, not just the first', () => {
    const v = verdictFor({ upstream: 'none', contentState: 'differs', stashDelta: 2,
      untracked: ['a.txt'], envIdentical: true, controlPassed: false });
    expect(v.blockers).toHaveLength(5);
  });

  it('exposes what counts as ignorable so the caller can print it', () => {
    expect(IGNORABLE.some((r) => r.test('node_modules/foo/bar'))).toBe(true);
    expect(IGNORABLE.some((r) => r.test('backend/.env'))).toBe(true);
    expect(IGNORABLE.some((r) => r.test('backend/.envrc'))).toBe(false);
    expect(IGNORABLE.some((r) => r.test('notes.md'))).toBe(false);
  });
});

// ── PORCELAIN PARSING ────────────────────────────────────────────────────────────────────────
//
// 🔴 THESE PIN A BUG THAT CORRUPTED A FILENAME IN A REAL VERDICT (2026-09-12, /c/ev-accounts-in).
//    The runner trimmed the WHOLE `git status --porcelain` output and then took `slice(3)` of
//    each line. A leading space is significant in porcelain — ` M path` means "tracked, modified
//    in the worktree" — so trimming ate it on the first line only, and slice(3) then ate the
//    first character of the path. The blocker printed
//    `ackend/data/seed-in-local-headshots-2026/harvest.json`, a path that does not exist.
//
// 🔴 AND IT WAS UNDER THE WRONG HEADING. A tracked file with uncommitted edits is not untracked.
//    It blocked as "unique-files: these exist nowhere else", which misdescribes the risk: the
//    file IS in git, it is the EDIT that exists nowhere else. Different fact, different fix.

describe('parsePorcelain', () => {
  it('keeps the first path intact when the first line is a tracked modification', () => {
    const out = ' M backend/data/harvest.json\n?? backend/data/_scratch.png\n';
    const s = parsePorcelain(out);
    expect(s.modified).toEqual(['backend/data/harvest.json']);
    expect(s.untracked).toEqual(['backend/data/_scratch.png']);
  });

  it('separates tracked modifications from untracked and ignored paths', () => {
    const out = [
      ' M tracked-modified.json',
      'M  tracked-staged.json',
      ' D tracked-deleted.json',
      '?? untracked.png',
      '!! node_modules/foo/index.js',
    ].join('\n');
    const s = parsePorcelain(out);
    expect(s.modified.sort()).toEqual(
      ['tracked-deleted.json', 'tracked-modified.json', 'tracked-staged.json'],
    );
    expect(s.untracked.sort()).toEqual(['node_modules/foo/index.js', 'untracked.png']);
  });

  it('unquotes a path that git escaped, and handles a rename', () => {
    const out = String.raw`?? "backend/data/caf\303\251.png"` + '\n' + 'R  old/name.ts -> new/name.ts\n';
    const s = parsePorcelain(out);
    expect(s.untracked).toEqual(['backend/data/café.png']);
    expect(s.modified).toEqual(['new/name.ts']);
  });

  it('returns empty lists for empty output', () => {
    expect(parsePorcelain('')).toEqual({ untracked: [], modified: [] });
  });
});

describe('verdictFor — uncommitted tracked edits', () => {
  it('blocks on a tracked file with uncommitted changes, under its own kind', () => {
    const v = verdictFor({ ...ok, modified: ['backend/data/harvest.json'] });
    expect(v.safe).toBe(false);
    const b = v.blockers.find((x) => x.kind === 'dirty-tracked');
    expect(b).toBeTruthy();
    expect(b.files).toEqual(['backend/data/harvest.json']);
    // It must NOT be misreported as something that exists nowhere else.
    expect(v.blockers.map((x) => x.kind)).not.toContain('unique-files');
  });

  it('is quiet when there are no tracked modifications', () => {
    expect(verdictFor({ ...ok, modified: [] }).safe).toBe(true);
  });
});

// ── SQUASH MERGES, AND THE VACUOUS "yes" ─────────────────────────────────────────────────────
//
// 🔴 ANCESTRY IS NOT THE ONLY WAY WORK REACHES MASTER, AND IT IS NOT THE WAY THIS REPO USES.
//    A squash merge replays the branch as ONE NEW COMMIT, so the branch tip is never an ancestor
//    of master. `merge-base --is-ancestor` therefore answers NO for a branch that is fully,
//    permanently merged — and the check blocked deletion of #486's own worktree minutes after
//    #486 landed. The last three merges before it were all squashes. This is the common case.
//
// 🔴 AND THE SECOND FAILURE WAS WORSE, BECAUSE IT REASSURED. The content comparison lived inside
//    `if (merged)`, so when ancestry said NO it never ran — and `identicalContent` kept its
//    initial `true`. The report printed `content identical : yes` for a test that had not been
//    performed. A measurement that cannot be made must say so; it must never inherit a pass.
//    Hence `contentState` is a TRI-STATE and 'unknown' BLOCKS.

describe('verdictFor — how the work reached master', () => {
  it('clears a branch that master contains by ancestry', () => {
    expect(verdictFor({ ...ok, upstream: 'ancestor' }).safe).toBe(true);
  });

  it('clears a SQUASH-merged branch, whose tip is deliberately not an ancestor', () => {
    const v = verdictFor({ ...ok, upstream: 'squash' });
    expect(v.safe).toBe(true);
    expect(v.blockers).toEqual([]);
  });

  it('refuses a branch whose work is upstream by neither route', () => {
    const v = verdictFor({ ...ok, upstream: 'none' });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('not-merged');
  });
});

describe('verdictFor — content comparison is never inherited', () => {
  it('accepts a measured match', () => {
    expect(verdictFor({ ...ok, contentState: 'same' }).safe).toBe(true);
  });

  it('refuses a measured mismatch', () => {
    const v = verdictFor({ ...ok, contentState: 'differs' });
    expect(v.blockers.map((b) => b.kind)).toContain('content-differs');
  });

  it('🔴 BLOCKS when the comparison could not be made, rather than passing it', () => {
    const v = verdictFor({ ...ok, contentState: 'unknown' });
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('content-unknown');
  });

  it('🔴 treats an ABSENT contentState as unknown, never as a pass', () => {
    const { contentState, ...withoutIt } = ok;
    const v = verdictFor(withoutIt);
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('content-unknown');
  });

  it('🔴 treats an ABSENT upstream as none, never as a pass', () => {
    const { upstream, ...withoutIt } = ok;
    const v = verdictFor(withoutIt);
    expect(v.safe).toBe(false);
    expect(v.blockers.map((b) => b.kind)).toContain('not-merged');
  });
});

// ── WHICH .env IS OURS, AND WHERE THE OTHER ONE LIVES ────────────────────────────────────────
//
// 🔴 BOTH DEFECTS BELOW WERE IN THE SAME FIVE LINES, AND THEY FAIL IN OPPOSITE DIRECTIONS.
//    A dependency's .env was read as ours and REFUSED a clean worktree (noise, and noise is
//    what teaches people to --force past a checker). The main checkout's .env was located
//    relative to `process.cwd()`, so running the check from inside the worktree being judged
//    pointed it at THAT worktree's own file — a comparison of a file against itself, which
//    reports "identical" and would CLEAR a worktree holding the only copy of a credential.
//    The second is the one that loses data.
describe('isOurEnv', () => {
  it('is true for the .env we copy into a worktree', () => {
    expect(isOurEnv('backend/.env')).toBe(true);
    expect(isOurEnv('.env')).toBe(true);
  });

  it('is false for one that ships inside a package', () => {
    expect(isOurEnv('backend/node_modules/natural/.env')).toBe(false);
    expect(isOurEnv('node_modules/.env')).toBe(false);
  });

  it('is false for a file that merely starts with .env', () => {
    expect(isOurEnv('backend/.envrc')).toBe(false);
    expect(isOurEnv('backend/.env.example')).toBe(false);
  });

  it('reads a Windows separator the same way', () => {
    expect(isOurEnv('backend\\node_modules\\natural\\.env')).toBe(false);
    expect(isOurEnv('backend\\.env')).toBe(true);
  });
});

describe('mainWorktreeRoot', () => {
  // `git rev-parse --path-format=absolute --git-common-dir` answers the MAIN checkout's .git
  // from inside any linked worktree — which is the fact we want, and unlike process.cwd() it
  // does not change with where the command was typed.
  it('is the parent of the common .git directory', () => {
    expect(mainWorktreeRoot('C:/EV-Accounts/.git')).toBe('C:/EV-Accounts');
    expect(mainWorktreeRoot('/home/x/repo/.git/')).toBe('/home/x/repo');
  });

  it('is null for a bare repo, which has no worktree to compare against', () => {
    expect(mainWorktreeRoot('C:/mirrors/repo.git')).toBe(null);
    expect(mainWorktreeRoot('')).toBe(null);
    expect(mainWorktreeRoot(null)).toBe(null);
  });
});

describe('canCompareEnv', () => {
  it('is true for two different paths', () => {
    expect(canCompareEnv('C:/wt/backend/.env', 'C:/EV-Accounts/backend/.env')).toBe(true);
  });

  // 🔴 A FILE EQUALS ITSELF. That is not evidence a second copy exists, and it is exactly what
  //    `npm run check:deletable` produced: npm sets cwd to the package directory of the
  //    worktree you are standing in, so `cwd/../backend/.env` WAS the file under test.
  it('is false when both sides resolve to the same file', () => {
    expect(canCompareEnv('C:/wt/backend/.env', 'C:/wt/backend/.env')).toBe(false);
    expect(canCompareEnv('C:/wt/backend/../backend/.env', 'C:/wt/backend/.env')).toBe(false);
  });

  // Fails SAFE: on a case-sensitive filesystem two files differing only in case are distinct,
  // and calling them the same blocks a deletion rather than clearing one.
  it('is false when the paths differ only in case', () => {
    expect(canCompareEnv('C:/WT/backend/.env', 'C:/wt/backend/.env')).toBe(false);
  });

  it('is false when either side is missing', () => {
    expect(canCompareEnv(null, 'C:/EV-Accounts/backend/.env')).toBe(false);
    expect(canCompareEnv('C:/wt/backend/.env', null)).toBe(false);
  });
});
