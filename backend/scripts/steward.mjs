#!/usr/bin/env node
/**
 * steward — coordination for concurrent work in ev-accounts.
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md
 * Schema: backend/migrations/CC_0070_steward_schema.sql
 *
 *   npm run steward -- who
 *   npm run steward -- sync --seed [--dry-run]
 *   npm run steward -- slot CC --purpose "what it is for"
 *
 * 🔴 FAILURE BEHAVIOUR IS NOT UNIFORM, AND THAT IS DELIBERATE.
 *   `slot` FAILS CLOSED — it will never invent a number it cannot verify, because the
 *     alternative is the collision this whole thing exists to prevent.
 *   `who` FAILS OPEN — if the steward is unreachable it warns and exits 0. The worst case
 *     is the behaviour we had before it existed. Credentials here are known to rotate
 *     (a Supabase password reset moves `postgres` but not `ev_api`), and a coordination
 *     tool that blocks work when it is down would simply be switched off.
 */
import { execFileSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";
import dotenv from "dotenv";

import { historicalSlots } from "./lib/migration-slots.mjs";
import { slotsToSeed } from "./lib/steward-seed.mjs";

const backendDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = path.resolve(backendDir, "..");
dotenv.config({ path: path.join(backendDir, ".env"), quiet: true });

const argv = process.argv.slice(2);
const cmd = argv[0];
const has = (f) => argv.includes(f);
const opt = (f, d = null) => {
  const i = argv.indexOf(f);
  return i >= 0 && argv[i + 1] ? argv[i + 1] : d;
};

function identity() {
  let email = "";
  try {
    email = execFileSync("git", ["config", "user.email"], { encoding: "utf8" }).trim();
  } catch { /* not a repo, or no identity configured */ }
  return { who: email || process.env.USER || process.env.USERNAME || "unknown", machine: os.hostname() };
}

async function connect() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL is not set");
  const client = new pg.Client({ connectionString: url });
  await client.connect();
  return client;
}

const pad = (ns, num) => (ns ? `${ns}_${String(num).padStart(4, "0")}` : String(num));

/* ── who ─────────────────────────────────────────────────────────────────────────────── */
async function cmdWho() {
  let client;
  try {
    client = await connect();
  } catch (e) {
    // FAIL OPEN. Say so loudly, then get out of the way.
    console.warn(`steward: unreachable (${e.message}). Continuing without coordination.`);
    return 0;
  }
  try {
    const { rows: claims } = await client.query(`
      SELECT scope, label, holder, machine, expires_at
        FROM steward.claims
       WHERE released_at IS NULL AND expires_at > now()
       ORDER BY started_at`);
    const { rows: mine } = await client.query(`
      SELECT namespace, num, purpose
        FROM steward.migration_slots
       WHERE state = 'reserved'
       ORDER BY namespace, num`);

    if (!claims.length && !mine.length) {
      console.log("Steward · no active claims, no outstanding reservations");
    } else {
      console.log(`Steward · ${claims.length} active claim(s)`);
      for (const c of claims) {
        const when = new Date(c.expires_at).toISOString().slice(11, 16);
        console.log(`  ${c.scope.padEnd(18)} ${(c.label ?? "").padEnd(22)} ${c.holder}  ${c.machine}  expires ${when}Z`);
      }
      for (const s of mine) {
        console.log(`  reserved ${pad(s.namespace, s.num)}  ${s.purpose}`);
      }
    }
    return 0;
  } finally {
    await client.end();
  }
}

/* ── sync --seed ─────────────────────────────────────────────────────────────────────── */
async function cmdSync() {
  if (!has("--seed")) {
    console.error("steward sync: pass --seed (reconcile git history into the table)");
    return 2;
  }
  const dryRun = has("--dry-run");
  const historical = historicalSlots(repoRoot);
  if (!historical.length) {
    console.error("steward sync: git reported NO migration slots at all. Refusing to seed an "
      + "empty set — that would leave the allocator unguarded. Check you are in a repo with refs.");
    return 1;
  }

  const client = await connect();
  try {
    const { rows: existing } = await client.query("SELECT namespace, num FROM steward.migration_slots");
    const toInsert = slotsToSeed(historical, existing);

    console.log(`git knows ${historical.length} slot(s); table holds ${existing.length}; `
      + `${toInsert.length} to insert`);
    if (!toInsert.length) {
      console.log("steward sync: already in step, nothing to do");
      return 0;
    }
    for (const r of toInsert.slice(0, 5)) console.log(`  + ${pad(r.namespace, r.num)}  ${r.filename}`);
    if (toInsert.length > 5) console.log(`  … and ${toInsert.length - 5} more`);

    if (dryRun) {
      console.log("steward sync: --dry-run, nothing written");
      return 0;
    }

    // 🔴 ON CONFLICT DO NOTHING, never DO UPDATE. A row that appeared between the read above
    //    and this write must not be clobbered — it could be a live reservation.
    await client.query("BEGIN");
    let inserted = 0;
    for (const r of toInsert) {
      const res = await client.query(
        `INSERT INTO steward.migration_slots
           (namespace, num, state, claimed_by, purpose, filename)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (namespace, num) DO NOTHING`,
        [r.namespace, r.num, r.state, r.claimed_by, r.purpose, r.filename]);
      inserted += res.rowCount;
    }
    await client.query("COMMIT");
    console.log(`steward sync: inserted ${inserted}, skipped ${toInsert.length - inserted} (already held)`);
    return 0;
  } catch (e) {
    await client.query("ROLLBACK").catch(() => {});
    throw e;
  } finally {
    await client.end();
  }
}

/* ── slot ────────────────────────────────────────────────────────────────────────────── */
async function cmdSlot() {
  const ns = (argv[1] || "").toUpperCase();
  const purpose = opt("--purpose");
  if (!ns || ns.startsWith("--")) { console.error("steward slot: name a namespace, e.g. CC"); return 2; }
  if (!purpose) { console.error("steward slot: --purpose is required"); return 2; }

  const { who, machine } = identity();
  let branch = null;
  try {
    branch = execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], { encoding: "utf8" }).trim();
  } catch { /* detached or not a repo */ }

  // FAIL CLOSED: any error here must stop the caller, not fall back to guessing.
  const client = await connect();
  try {
    const { rows } = await client.query(
      "SELECT steward.claim_migration_slot($1,$2,$3,$4,$5) AS num",
      [ns, who, purpose, branch, machine]);
    const num = rows[0].num;
    console.log(pad(ns, num));
    console.error(`steward: reserved ${pad(ns, num)} for ${who} on ${machine}`);
    return 0;
  } finally {
    await client.end();
  }
}

const COMMANDS = { who: cmdWho, sync: cmdSync, slot: cmdSlot };

const run = COMMANDS[cmd];
if (!run) {
  console.error("usage: steward <who|sync|slot> [...]\n"
    + "  who                              show active claims and outstanding reservations\n"
    + "  sync --seed [--dry-run]          reconcile git history into steward.migration_slots\n"
    + "  slot <NS> --purpose \"...\"        reserve the next free migration number");
  process.exit(2);
}
run().then((code) => process.exit(code ?? 0)).catch((e) => {
  console.error(`steward ${cmd}: ${e.message}`);
  process.exit(1);
});
