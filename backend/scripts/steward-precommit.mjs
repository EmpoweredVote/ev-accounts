#!/usr/bin/env node
/**
 * §9 rules 1 and 3, observed at commit time. Run from `.githooks/pre-commit`.
 *
 * Logic: backend/scripts/lib/steward-precommit.mjs (pure, tested)
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§9)
 *
 * 🔴 IT NEVER BLOCKS A COMMIT. Every path here exits 0, including every error path. The design
 *    says this about the steward generally and it applies hardest to a git hook: "a coordination
 *    tool that blocks work when it is down would simply be switched off." A hook that can wedge
 *    someone's commit gets removed within the day, and then the rule has no observer at all.
 *    CLAUDE.md also forbids `--no-verify`, so the only honest way to keep that promise is to be
 *    a hook that is never worth bypassing.
 *
 * 🔴 IT MUST NOT HANG. A commit that stalls on a database is worse than an unobserved rule, so
 *    the connection and the query both carry short timeouts and any failure is silent-ish.
 */
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import pg from "pg";
import dotenv from "dotenv";

import { canonicalWorktreeScope } from "./lib/steward-worktree.mjs";
import { pathspecUsed, commitNotices } from "./lib/steward-precommit.mjs";

const backendDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
dotenv.config({ path: path.join(backendDir, ".env"), quiet: true });

const sh = (args) => {
  try {
    return execFileSync("git", args, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch { return null; }
};

async function main() {
  const pathspec = pathspecUsed(process.env.GIT_INDEX_FILE);
  const top = sh(["rev-parse", "--show-toplevel"]);
  if (!top) return;

  const me = {
    holder: sh(["config", "user.email"]) || process.env.USERNAME || "unknown",
    machine: (await import("node:os")).hostname(),
  };

  let markers = [];
  if (process.env.DATABASE_URL) {
    const client = new pg.Client({
      connectionString: process.env.DATABASE_URL,
      connectionTimeoutMillis: 1500,
      statement_timeout: 1500,
    });
    try {
      await client.connect();
      const { rows } = await client.query(
        `SELECT holder, machine, label, started_at
           FROM steward.claims
          WHERE scope = $1 AND released_at IS NULL AND expires_at > now()`,
        [canonicalWorktreeScope(top)]);
      markers = rows;
    } catch {
      // Unreachable, slow, or no such table. Fall through with what we have: the pathspec half
      // of the check needs no database at all, and still runs.
    } finally {
      await client.end().catch(() => {});
    }
  }

  for (const n of commitNotices({ pathspec, markers, me, nowMs: Date.now() })) {
    if (n.kind === "shared-worktree") {
      console.error(`  steward: another session was in this worktree recently — `
        + `${n.others.map((o) => `${o.holder} on ${o.machine}`).join(", ")}. `
        + "You used a pathspec, so this is information, not a problem.");
      continue;
    }
    if (n.severity === "alarm") {
      console.error("  🔴 steward: COMMITTED WITHOUT A PATHSPEC IN A SHARED WORKTREE.");
      for (const o of n.others) {
        const ago = Math.round((Date.now() - new Date(o.started_at).getTime()) / 60000);
        console.error(`       ${o.holder} on ${o.machine} was here ${ago}m ago`
          + `${o.label ? ` (branch ${o.label})` : ""}`);
      }
      console.error("       Staging carefully is not enough — it is the OTHER session's "
        + "`git add -A` that sweeps your files in.");
      console.error("       Next time: git commit -F msg -- <path>");
    } else {
      console.error("  steward: no pathspec on this commit. Alone in your own worktree that is "
        + "fine; `git commit -F msg -- <path>` is the habit that survives company.");
    }
  }
}

// 🔴 THE CATCH-ALL IS THE POINT, NOT SLOPPINESS. Whatever goes wrong in here — a missing
//    module, a bad DATABASE_URL, a schema that does not exist yet on somebody's checkout — the
//    commit proceeds. A hook that can fail a commit for a reason unrelated to the commit is a
//    hook that gets deleted.
main().catch(() => {}).finally(() => process.exit(0));
