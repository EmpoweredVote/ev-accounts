#!/usr/bin/env node
/**
 * Fail if a migration file added on this branch sits in a slot its author never reserved.
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§5, §6 step 5)
 * Verdicts: backend/scripts/lib/migration-reservations.mjs (pure, tested)
 *
 *   node scripts/check-migration-reservations.mjs [--verbose]
 *   BASE_REF=origin/master node scripts/check-migration-reservations.mjs
 *
 * ── WHAT THIS ADDS TO THE REF SCAN, AND WHY BOTH EXIST ───────────────────────────────────────
 *
 * `check-migration-numbers.mjs` asks *does this slot collide with any ref?* It is a complete
 * answer to everything a repository can observe, and it names its own blind spot: a number
 * another session has DECIDED to use is invisible until it pushes, so no scan can ever see it.
 * That is the 1681 collision, and on 2026-09-04 two of one author's sessions came within one
 * step of it twice with the correct procedure followed both times.
 *
 * The steward closes that hole by making the reservation the observable event. This check is
 * what makes reserving compulsory: without it the allocator is opt-in, and a number taken by
 * hand still sets up the next `steward slot` call to hand the same number out again.
 *
 * 🔴 THIS DOES NOT REPLACE THE REF SCAN AND MUST NOT. That one needs no network and no
 *    credentials, so it works when the steward does not, and it catches anyone who bypassed
 *    the steward entirely. Allocator plus auditor; two independent detectors is what keeps the
 *    steward from becoming a single point of failure.
 *
 * ── FAILURE BEHAVIOUR ────────────────────────────────────────────────────────────────────────
 *
 * 🔴 NO DATABASE_URL -> SKIP, exit 0. Forks get no secrets, and a red wall on every outside
 *    PR would be a worse outcome than the collision.
 * 🔴 STEWARD UNREACHABLE -> DEGRADE, exit 0 with a warning. Credentials here are known to
 *    rotate (a Supabase password reset moves `postgres` but not `ev_api`), and a credential
 *    rotation must not red-wall every PR in the organisation. The ref scan still ran.
 *
 * ⚠ BOTH OF THOSE ARE SILENT-PASS PATHS, so each one SAYS SO ON STDOUT. A check that skips
 *   without printing why is the shape of a detector that has quietly stopped working — and two
 *   detectors in this repo were broken exactly that way on 2026-09-04, found only by a control.
 */
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import pg from "pg";
import dotenv from "dotenv";

import { slotOf, resolveBase, addedMigrationFiles, authorOfAddedFile } from "./lib/migration-slots.mjs";
import { classifyReservation, ENFORCED_ABOVE } from "./lib/migration-reservations.mjs";

const backendDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
dotenv.config({ path: path.join(backendDir, ".env"), quiet: true });

const VERBOSE = process.argv.includes("--verbose");
const repoRoot = execFileSync("git", ["rev-parse", "--show-toplevel"], { encoding: "utf8" }).trim();

const ceilings = Object.entries(ENFORCED_ABOVE)
  .map(([ns, n]) => `${ns || "shared"}>${n}`).join(" ");

const base = resolveBase(repoRoot);
if (!base) {
  console.log("No base ref to diff against; no added migrations to check. (The ref scan in "
    + "check-migration-numbers.mjs covers the working tree unconditionally.)");
  process.exit(0);
}

const added = addedMigrationFiles(repoRoot, base).filter((f) => slotOf(f));
if (!added.length) {
  console.log(`Migration reservations OK — no migrations added vs ${base}.`);
  process.exit(0);
}

if (!process.env.DATABASE_URL) {
  console.log(`SKIPPED: DATABASE_URL is not set, so the ${added.length} added migration(s) could not `
    + "be checked against steward.migration_slots. Forks get no secrets; this is a deliberate green "
    + "skip, not a pass. The ref scan in check-migration-numbers.mjs still ran.");
  process.exit(0);
}

const wanted = added.map((file) => ({
  file,
  filename: path.basename(file),
  slot: slotOf(file),
  author: authorOfAddedFile(repoRoot, base, file),
}));

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
try {
  await client.connect();
} catch (e) {
  console.log(`DEGRADED: the steward is unreachable (${e.message}), so the ${added.length} added `
    + "migration(s) were not checked against steward.migration_slots. Passing with a warning — a "
    + "credential rotation must not red-wall every PR. The ref scan in check-migration-numbers.mjs "
    + "still ran, and it needs no database.");
  process.exit(0);
}

let verdicts;
try {
  // A cross product of the namespaces and numbers in play, narrowed to exact pairs in JS. The
  // added-file count is a handful, so this is cheaper than building a VALUES list.
  const { rows } = await client.query(
    `SELECT namespace, num, state, claimed_by, machine, purpose, branch, filename
       FROM steward.migration_slots
      WHERE namespace = ANY($1::text[]) AND num = ANY($2::int[])`,
    [[...new Set(wanted.map((w) => w.slot.ns))], [...new Set(wanted.map((w) => Number(w.slot.num)))]]);
  const bySlot = new Map(rows.map((r) => [r.namespace ? `${r.namespace}_${r.num}` : String(r.num), r]));
  verdicts = wanted.map((w) => ({ ...w, ...classifyReservation({ ...w, row: bySlot.get(w.slot.key) ?? null }) }));
} finally {
  await client.end();
}

const bad = verdicts.filter((v) => !v.ok);
for (const v of verdicts) {
  if (!v.ok) console.error(`  🔴 ${v.message}`);
  else if (VERBOSE) console.log(`  ✓  ${v.message}`);
}

if (bad.length) {
  console.error(`\n${bad.length} of ${verdicts.length} added migration(s) sit in a slot nobody reserved `
    + "for their author.\n"
    + "Reserving is not a formality: a number decided in one session is invisible to every other "
    + "until it is pushed, so the allocator is the only place two sessions can see the same claim.\n"
    + `Enforced above: ${ceilings} — at or below those, a slot predates the allocator and passes.`);
  process.exit(1);
}

console.log(`Migration reservations OK — ${verdicts.length} added migration(s) vs ${base}, each in a `
  + `slot its author reserved or predating the allocator (enforced above ${ceilings}).`);
