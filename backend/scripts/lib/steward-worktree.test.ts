import { describe, it, expect } from 'vitest';
import { canonicalWorktreeScope, worktreeNotices } from './steward-worktree.mjs';

// Collision B: a shared worktree's HEAD moves under a running session. It is machine-local, so
// the design handled it with a rule rather than a table — and then sequenced a `worktree:` claim
// scope last, "if still worth it by then", to make the rule VISIBLE rather than merely written.
//
// 🔴 IT IS STILL WORTH IT, MEASURED. `C:\EV-Accounts` changed branch three times under one
//    session on 2026-09-04, and changed again mid-session while this was being built — from
//    fix/federal-cohort-definition to feat/verify-politician-id-column. A rule that is written
//    down and still broken twice in one day is a rule that needs an observer.

describe('canonicalWorktreeScope', () => {
  // 🔴 THIS IS THE ONE THING THAT MUST BE RIGHT, AND IT IS SILENT WHEN IT IS WRONG. The
  //    exclusion constraint compares scope STRINGS. Two sessions in the same directory that
  //    register `worktree:C:/EV-Accounts` and `worktree:/c/ev-accounts` do not collide, do not
  //    warn, and the whole feature does nothing while appearing to work. Git Bash, PowerShell
  //    and `git rev-parse` all spell this machine's paths differently.
  it('folds the three spellings of one Windows path onto one scope', () => {
    const a = canonicalWorktreeScope('C:/EV-Accounts');
    const b = canonicalWorktreeScope('C:\\EV-Accounts');
    const c = canonicalWorktreeScope('/c/ev-accounts');
    expect(a).toBe(b);
    expect(b).toBe(c);
    expect(a).toBe('worktree:c:/ev-accounts');
  });

  it('strips a trailing separator and collapses repeats', () => {
    expect(canonicalWorktreeScope('C:\\EV-Accounts\\')).toBe('worktree:c:/ev-accounts');
    expect(canonicalWorktreeScope('C://EV-Accounts//')).toBe('worktree:c:/ev-accounts');
  });

  // 🔴 CASE IS FOLDED ONLY FOR A DRIVE-LETTER PATH. NTFS is case-insensitive, so on Windows
  //    two spellings are one directory. POSIX paths are case-SENSITIVE: /home/Chris and
  //    /home/chris are two different places, and folding them would merge two real worktrees
  //    into one scope — the inverse error, and just as silent.
  it('keeps POSIX case, because two POSIX paths differing in case are two directories', () => {
    expect(canonicalWorktreeScope('/home/Chris/repo')).toBe('worktree:/home/Chris/repo');
    expect(canonicalWorktreeScope('/home/chris/repo')).toBe('worktree:/home/chris/repo');
  });

  it('does not mistake a bare posix path for a drive path', () => {
    expect(canonicalWorktreeScope('/covid/Data')).toBe('worktree:/covid/Data');
  });

  // /c/foo is Git Bash's spelling of C:\foo. /cats/foo is not a drive: the segment must be a
  // SINGLE letter.
  it('reads /c/x as a drive path and /cats/x as an ordinary one', () => {
    expect(canonicalWorktreeScope('/c/x')).toBe('worktree:c:/x');
    expect(canonicalWorktreeScope('/cats/x')).toBe('worktree:/cats/x');
  });

  it('refuses an empty path rather than claiming scope "worktree:"', () => {
    expect(() => canonicalWorktreeScope('')).toThrow();
    expect(() => canonicalWorktreeScope(null as unknown as string)).toThrow();
  });
});

const prev = (over: Record<string, unknown> = {}) => ({
  holder: 'chris@empowered.vote',
  machine: 'DESKTOP-G6KDNN2',
  label: 'feat/steward',
  started_at: new Date('2026-09-04T19:00:00Z'),
  ...over,
});

const now = { holder: 'chris@empowered.vote', machine: 'DESKTOP-G6KDNN2', branch: 'feat/steward' };

describe('worktreeNotices', () => {
  it('says nothing when the same session restarts on the same branch', () => {
    expect(worktreeNotices(now, prev())).toEqual([]);
  });

  it('says nothing at all when the worktree has never been registered', () => {
    expect(worktreeNotices(now, null)).toEqual([]);
  });

  // This is the payload: the warning arrives at session start, BEFORE you touch anything.
  it('reports that HEAD moved since the last session registered here', () => {
    const n = worktreeNotices(now, prev({ label: 'fix/federal-cohort-definition' }));
    expect(n.map((x) => x.kind)).toEqual(['head-moved']);
    expect(n[0].was).toBe('fix/federal-cohort-definition');
    expect(n[0].now).toBe('feat/steward');
  });

  it('reports another session last seen in this directory', () => {
    const n = worktreeNotices(now, prev({ holder: 'candrews@empowered.vote' }));
    expect(n.map((x) => x.kind)).toEqual(['other-session']);
  });

  // 🔴 THE SAME EMAIL ON A DIFFERENT BOX IS A DIFFERENT SESSION. The design makes the holder
  //    (email, hostname) because one author's desktop and laptop are as likely to collide with
  //    each other as with a second person. A laptop cannot share a Windows worktree path with
  //    the desktop by accident — but it can hold the same POSIX path, and the notice is the
  //    only thing that would say so.
  it('treats the same person on another machine as another session', () => {
    const n = worktreeNotices(now, prev({ machine: 'MBP-2' }));
    expect(n.map((x) => x.kind)).toEqual(['other-session']);
  });

  it('reports both when another session left it on another branch', () => {
    const n = worktreeNotices(now, prev({ holder: 'candrews@empowered.vote', label: 'knight/ca-2' }));
    expect(n.map((x) => x.kind).sort()).toEqual(['head-moved', 'other-session']);
  });

  // A registration whose branch was never recorded cannot tell you HEAD moved. Reporting it as
  // "was null, now feat/x" would manufacture an alarm out of a missing field.
  it('does not invent a branch change when the previous row recorded no branch', () => {
    expect(worktreeNotices(now, prev({ label: null }))).toEqual([]);
  });

  it('does not report a branch change when only the previous branch is detached', () => {
    expect(worktreeNotices({ ...now, branch: null }, prev())).toEqual([]);
  });
});
