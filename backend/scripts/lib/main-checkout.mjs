/**
 * Borrowing the MAIN checkout's node_modules and .env from a linked worktree — the pure half.
 * The side-effecting half is ./main-checkout-fallback.mjs, the `node --import` preload the steward
 * hooks run through.
 *
 * WHY: both steward hooks (SessionStart in .claude/settings.json, and .githooks/pre-commit) used to
 * start with `[ -d backend/node_modules ] && …`, and a linked worktree usually has no
 * backend/node_modules: 10 of 17 worktrees on 2026-09-23. So in most sessions the board never
 * printed, the worktree marker was never recorded (no HEAD-MOVED notice could ever fire), and the
 * pathspec observer never ran — all silently. Node resolves `import pg` relative to the importing
 * FILE, so a worktree's script cannot find the main checkout's packages without help.
 */
import path from "node:path";

// path.win32 / path.posix by the platform ARGUMENT, not the host, so the Windows case is testable here.
const pathFor = (platform) => (platform === "win32" ? path.win32 : path.posix);
const norm = (p, platform) => {
  const r = pathFor(platform).resolve(p);
  return platform === "win32" ? r.toLowerCase() : r;
};

/**
 * What this checkout should borrow from the main one.
 *   here      — this checkout's backend directory
 *   commonDir — `git rev-parse --path-format=absolute --git-common-dir` (the main checkout's .git)
 *   exists    — fs.existsSync, injected so this stays pure
 * The main checkout itself borrows nothing, and nothing is borrowed that this checkout already has
 * or that the main checkout lacks.
 */
export function mainCheckoutPlan({ here, commonDir, exists, platform = process.platform }) {
  const P = pathFor(platform);
  const mainBackend = P.join(P.dirname(commonDir), "backend");
  if (norm(mainBackend, platform) === norm(here, platform)) {
    return { mainBackend, modules: false, env: false };
  }
  return {
    mainBackend,
    modules: !exists(P.join(here, "node_modules")) && exists(P.join(mainBackend, "node_modules")),
    env: !exists(P.join(here, ".env")) && exists(P.join(mainBackend, ".env")),
  };
}

/**
 * Whether a failed resolution should be retried from the main checkout: only a BARE package
 * specifier that was not found. Relative, absolute, file:, node: and data: specifiers name a
 * specific file or a builtin, so retrying them elsewhere would load the wrong thing.
 */
export function shouldRetryFromMain(specifier, code) {
  if (code !== "ERR_MODULE_NOT_FOUND" && code !== "MODULE_NOT_FOUND") return false;
  return !/^(\.|\/|[A-Za-z]:[\\/]|file:|node:|data:)/.test(specifier);
}
