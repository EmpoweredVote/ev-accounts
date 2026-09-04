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
 *   npm run steward -- claim place:0642468 --label "Lomita occupancy"
 *   npm run steward -- release place:0642468
 *   npm run steward -- extend place:0642468 --hours 4
 *
 * 🔴 FAILURE BEHAVIOUR IS NOT UNIFORM, AND THAT IS DELIBERATE.
 *   `slot` FAILS CLOSED — it will never invent a number it cannot verify, because the
 *     alternative is the collision this whole thing exists to prevent.
 *   `who`, `claim`, `release` and `extend` FAIL OPEN — if the steward is unreachable they
 *     warn and exit 0. The worst case is the behaviour we had before they existed.
 *     Credentials here are known to rotate (a Supabase password reset moves `postgres` but
 *     not `ev_api`), and a coordination tool that blocks work when it is down would simply
 *     be switched off.
 *   ⚠ ONE EXCEPTION, AND IT IS THE CALLER'S OWN REQUEST: `claim --if-held fail` exits
 *     non-zero when the steward is unreachable. That mode exists for scripted work that
 *     must not guess, so answering "I could not check, carry on" would be the one wrong
 *     reply. warn and skip still fail open.
 */
import { execFileSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";
import dotenv from "dotenv";

import { historicalSlots } from "./lib/migration-slots.mjs";
import { slotsToSeed } from "./lib/steward-seed.mjs";
import { parseScope, containmentWarnings, chooseScope, SKIP_BLOCKED } from "./lib/steward-claims.mjs";
import { canonicalWorktreeScope, worktreeNotices } from "./lib/steward-worktree.mjs";

/**
 * How long a worktree marker stays on the board.
 *
 * ⚠ A GUESS, LIKE THE 8-HOUR LEASE, AND THE TRADE-OFF RUNS BOTH WAYS. Too short and a session
 *   that has genuinely been running all day drops off the board, so "nobody is in that
 *   directory" becomes wrong. Too long and last night's finished sessions look present. A
 *   working day is the compromise: it spans one, and it clears overnight.
 */
const WORKTREE_MARKER_HOURS = 12;

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

/** Flags that consume the next word. Anything else beginning `--` is a boolean. */
const VALUE_FLAGS = new Set(["--purpose", "--label", "--notes", "--hours", "--if-held"]);

/**
 * The bare arguments after the command, with flag values removed.
 *
 * ⚠ `claim` takes a LIST of scopes for `--if-held skip`, so a naive
 *   `filter(a => !a.startsWith('--'))` would swallow `--label`'s value as a candidate
 *   jurisdiction and then try to claim it. Values are skipped by position, not by shape.
 */
function positionals() {
  const out = [];
  for (let i = 1; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith("--")) {
      if (VALUE_FLAGS.has(a)) i++;
      continue;
    }
    out.push(a);
  }
  return out;
}

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
    const { rows: rows } = await client.query(`
      SELECT scope, label, holder, machine, started_at, expires_at
        FROM steward.claims
       WHERE released_at IS NULL AND expires_at > now()
       ORDER BY started_at`);
    const { rows: mine } = await client.query(`
      SELECT namespace, num, purpose
        FROM steward.migration_slots
       WHERE state = 'reserved'
       ORDER BY namespace, num`);

    // 🔴 WORKTREE MARKERS ARE LISTED SEPARATELY AND SAY "SEEN", NOT "EXPIRES". Mixed in with
    //    jurisdiction leases they would outnumber them — one per session start — and drown the
    //    thing the board exists to show. And they are not leases: nothing releases one when a
    //    terminal closes, so the only honest word for the timestamp is when a session was last
    //    seen there. Calling it an expiry would assert a session is running that may have ended
    //    hours ago.
    const claims = rows.filter((r) => !r.scope.startsWith("worktree:"));
    const trees = rows.filter((r) => r.scope.startsWith("worktree:"));

    if (!rows.length && !mine.length) {
      console.log("Steward · no active claims, no outstanding reservations");
    } else {
      const parts = [`${claims.length} jurisdiction claim(s)`];
      if (trees.length) parts.push(`${trees.length} worktree(s) seen`);
      if (mine.length) parts.push(`${mine.length} slot(s) reserved`);
      console.log(`Steward · ${parts.join(" · ")}`);
      for (const c of claims) {
        const when = new Date(c.expires_at).toISOString().slice(11, 16);
        console.log(`  ${c.scope.padEnd(18)} ${(c.label ?? "").padEnd(22)} ${c.holder}  ${c.machine}  expires ${when}Z`);
      }
      for (const s of mine) {
        console.log(`  reserved ${pad(s.namespace, s.num)}  ${s.purpose}`);
      }
      for (const t of trees) {
        const seen = new Date(t.started_at).toISOString().slice(11, 16);
        console.log(`  ~ ${t.scope.slice("worktree:".length).padEnd(24)} ${(t.label ?? "detached").padEnd(34)} `
          + `${t.holder}  ${t.machine}  seen ${seen}Z`);
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
  const nsArg = (argv[1] || "").toUpperCase();
  const purpose = opt("--purpose");
  if (!nsArg || nsArg.startsWith("--")) {
    console.error("steward slot: name a namespace, e.g. CC — or `shared` for the plain NNNN_ sequence");
    return 2;
  }
  // 🔴 THE SHARED SEQUENCE NEEDS A NAME YOU CAN TYPE. Its namespace is the EMPTY STRING, and
  //    `steward slot ""` fails the argument check above, so before this word existed there was
  //    no way to allocate 1853 — while the reservation check enforces that sequence like any
  //    other. A check that demands something the tool cannot do is just a wall.
  const ns = nsArg === "SHARED" ? "" : nsArg;
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

/* ── claims: shared plumbing ──────────────────────────────────────────────────────────── */

/**
 * Connect, or return null having said so. The fail-open half of the failure table: `who`,
 * `claim`, `release` and `extend` must never be the reason work stops, or they get switched
 * off and the steward becomes a thing people used to run.
 */
async function connectOrWarn(what) {
  try {
    return await connect();
  } catch (e) {
    console.warn(`steward ${what}: unreachable (${e.message}). Continuing WITHOUT coordination — `
      + "nobody else can see what you are about to work on.");
    return null;
  }
}

/** Live claims: not released, not expired. An expired lease is free to take, by design. */
async function liveClaims(client) {
  const { rows } = await client.query(`
    SELECT id, scope, label, holder, machine, started_at, expires_at, notes
      FROM steward.claims
     WHERE released_at IS NULL AND expires_at > now()
     ORDER BY started_at`);
  return rows;
}

/**
 * place geo_id -> county geo_id, for the places in play only.
 *
 * 🔴 A ROW WITH A NULL county_geo_id IS LEFT OUT OF THE MAP ON PURPOSE. `relate` reads a
 *    missing key as "unknown" and reports it; putting a null in would read as an answer.
 *    `check:child-county` is the CI gate that keeps this matview from lagging its source.
 *
 * Fails soft to an empty map: without it, state-level containment still works and
 * county⊃place degrades to "unknown", which is the direction that reports rather than
 * reassures.
 */
async function childCountyFor(client, scopes) {
  const places = [...new Set(scopes.filter((s) => s.kind === "place").map((s) => s.id))];
  if (!places.length) return new Map();
  try {
    const { rows } = await client.query(
      `SELECT child_geo_id, county_geo_id FROM essentials.geofence_child_county
        WHERE child_geo_id = ANY($1::text[]) AND county_geo_id IS NOT NULL`, [places]);
    return new Map(rows.map((r) => [r.child_geo_id, r.county_geo_id]));
  } catch (e) {
    console.warn(`steward: could not read essentials.geofence_child_county (${e.message}). `
      + "City-inside-county overlap will report as UNKNOWN rather than clear.");
    return new Map();
  }
}

const RELATION_PROSE = {
  same: "already claimed",
  "a-contains-b": "sits inside the scope you are claiming",
  "b-contains-a": "contains the scope you are claiming",
  unknown: "MAY overlap — the child→county mapping cannot say",
};

function printWarnings(warnings) {
  for (const w of warnings) {
    const until = new Date(w.claim.expires_at).toISOString().slice(0, 16).replace("T", " ");
    console.warn(`  ⚠ ${w.claim.scope} ${RELATION_PROSE[w.relation]} — ${w.claim.holder} on `
      + `${w.claim.machine}${w.claim.label ? ` ("${w.claim.label}")` : ""}, until ${until}Z`);
  }
}

function hoursOpt(dflt) {
  const raw = opt("--hours");
  if (raw === null) return dflt;
  const n = Number(raw);
  // A lease wants to be longer than a working session and shorter than a weekend (design §10).
  // A week is the outer bound at which "abandoned session holds Lomita forever" comes back.
  if (!Number.isFinite(n) || n <= 0 || n > 168) throw new Error(`--hours ${raw}: give 1–168`);
  return n;
}

/* ── claim ───────────────────────────────────────────────────────────────────────────────── */
async function cmdClaim() {
  const scopeArgs = positionals();
  const mode = (opt("--if-held", "warn") || "warn").toLowerCase();
  if (!["warn", "fail", "skip"].includes(mode)) {
    console.error(`steward claim: --if-held ${mode}: use warn, fail or skip`); return 2;
  }
  if (!scopeArgs.length) {
    console.error("steward claim: name a scope, e.g. place:0642468 (several, with --if-held skip)");
    return 2;
  }
  if (scopeArgs.length > 1 && mode !== "skip") {
    console.error("steward claim: several candidates only make sense with --if-held skip — "
      + "one command takes one lease.");
    return 2;
  }
  const hours = hoursOpt(null);
  const label = opt("--label");
  const notes = opt("--notes");
  const takeover = has("--takeover");
  const { who, machine } = identity();

  const client = await connectOrWarn("claim");
  if (!client) {
    // The one place fail-open is wrong is the mode whose entire purpose is not to guess.
    return mode === "fail" ? 1 : 0;
  }
  try {
    const live = await liveClaims(client);
    const candidates = scopeArgs.map(parseScope);
    const childCounty = await childCountyFor(client, [...candidates, ...live.map((c) => {
      try { return parseScope(c.scope); } catch { return { kind: "other" }; }
    })]);

    const picked = mode === "skip"
      ? chooseScope(scopeArgs, live, childCounty)
      : (() => {
        const scope = candidates[0];
        return { scope, warnings: containmentWarnings(scope, live, childCounty), skipped: [], reason: null };
      })();

    // Skipping is REPORTED, always. A skip that says nothing is indistinguishable from an
    // empty work list, and a caller cannot tell "done" from "blocked".
    for (const s of picked.skipped) {
      console.warn(`steward claim: skipping ${s.scope.canonical} — held by ${s.heldBy.holder} on ${s.heldBy.machine}`);
    }
    if (!picked.scope) {
      console.error(`steward claim: every candidate is held (${picked.reason}); nothing claimed.`);
      return mode === "fail" ? 1 : 3;   // 3 == "nothing to do", distinct from an error
    }

    const scope = picked.scope;
    const exact = picked.warnings.find((w) => w.relation === "same");
    if (picked.warnings.length) {
      console.warn(`steward claim: ${scope.canonical} overlaps ${picked.warnings.length} live claim(s):`);
      printWarnings(picked.warnings);
    }

    if (exact && !takeover) {
      // 🔴 warn DOES NOT SILENTLY STEAL THE LEASE. The design's one-line table says warn
      //    "names the holder, proceeds", and there are two readings: proceed to take the
      //    claim, or proceed with the work. Taking it means writing released_at onto
      //    somebody else's live row, and the tool must not do that as a DEFAULT — it would
      //    make the board lie about who holds what, which is the one thing it is for.
      //    So warn tells you who holds it and gets out of the way; `--takeover` is the
      //    deliberate act, and it is recorded on the row it displaces.
      const msg = `steward claim: ${scope.canonical} is held by ${exact.claim.holder} on ${exact.claim.machine}. `
        + "Nothing claimed. Use --takeover to displace it (recorded), or --if-held skip to move on.";
      if (mode === "fail") { console.error(msg); return 1; }
      console.warn(msg);
      return 0;
    }

    await client.query("BEGIN");
    if (exact) {
      // now() is transaction time, and the exclusion range is '[)', so the displaced lease
      // ends at exactly the instant the new one starts and the two do not overlap.
      await client.query(
        // $2 is CAST because concat_ws is variadic "any": without it Postgres cannot infer the
        // parameter's type and the whole takeover fails with 42P18, rolling back to no claim
        // at all. Found by running it (2026-09-04) — it typechecks nowhere.
        `UPDATE steward.claims
            SET released_at = now(),
                notes = concat_ws(' | ', notes, $2::text)
          WHERE id = $1`,
        [exact.claim.id, `taken over by ${who} on ${machine}`]);
      console.warn(`steward claim: displaced ${exact.claim.holder}'s lease on ${scope.canonical} (recorded on their row)`);
    }
    const { rows } = await client.query(
      `INSERT INTO steward.claims (scope, label, holder, machine, session_ref, expires_at, notes)
       VALUES ($1, $2, $3, $4, $5, now() + make_interval(hours => $6), $7)
       RETURNING id, expires_at`,
      [scope.canonical, label, who, machine, process.env.CLAUDE_SESSION_ID ?? null, hours ?? 8, notes]);
    await client.query("COMMIT");

    // stdout carries the scope alone, so `--if-held skip` is scriptable; the human line
    // goes to stderr. Same split as `slot`.
    console.log(scope.canonical);
    const until = new Date(rows[0].expires_at).toISOString().slice(0, 16).replace("T", " ");
    console.error(`steward: claimed ${scope.canonical}${label ? ` ("${label}")` : ""} for ${who} on ${machine}, until ${until}Z`);
    return 0;
  } catch (e) {
    await client.query("ROLLBACK").catch(() => {});
    throw e;
  } finally {
    await client.end();
  }
}

/* ── release ─────────────────────────────────────────────────────────────────────────────── */
async function cmdRelease() {
  const scopeArg = argv[1];
  if (!scopeArg || scopeArg.startsWith("--")) { console.error("steward release: name a scope"); return 2; }
  const scope = parseScope(scopeArg);
  const { who, machine } = identity();

  const client = await connectOrWarn("release");
  if (!client) return 0;
  try {
    // 🔴 MATCH THE MACHINE, NOT JUST THE EMAIL. The design makes the holder (email, hostname)
    //    because one author's desktop and laptop "are as likely to collide with each other as
    //    with a second person". Letting the desktop release the laptop's lease silently
    //    re-creates exactly that collision, under the author's own name.
    const { rows } = await client.query(
      `UPDATE steward.claims SET released_at = now()
        WHERE scope = $1 AND released_at IS NULL AND expires_at > now()
          AND ($4 OR (holder = $2 AND machine = $3))
        RETURNING holder, machine`,
      [scope.canonical, who, machine, has("--force")]);
    if (rows.length) {
      for (const r of rows) {
        const mine = r.holder === who && r.machine === machine;
        console.error(`steward: released ${scope.canonical}${mine ? "" : ` (was ${r.holder} on ${r.machine}) — --force`}`);
      }
      return 0;
    }
    const live = (await liveClaims(client)).filter((c) => c.scope === scope.canonical);
    if (!live.length) { console.error(`steward release: no live claim on ${scope.canonical} — nothing to do`); return 0; }
    for (const c of live) {
      console.error(`steward release: ${scope.canonical} is held by ${c.holder} on ${c.machine}, not by `
        + `${who} on ${machine}. Pass --force to release it anyway, or claim --takeover to hold it yourself.`);
    }
    return 1;
  } finally {
    await client.end();
  }
}

/* ── extend ──────────────────────────────────────────────────────────────────────────────── */
async function cmdExtend() {
  const scopeArg = argv[1];
  if (!scopeArg || scopeArg.startsWith("--")) { console.error("steward extend: name a scope"); return 2; }
  const scope = parseScope(scopeArg);
  const hours = hoursOpt(4);
  const { who, machine } = identity();

  const client = await connectOrWarn("extend");
  if (!client) return 0;
  try {
    // An EXPIRED lease is not extended, it is re-claimed. Extending one would resurrect a
    // scope that the board has already shown as free, possibly to somebody else.
    const { rows } = await client.query(
      `UPDATE steward.claims
          SET expires_at = expires_at + make_interval(hours => $4)
        WHERE scope = $1 AND released_at IS NULL AND expires_at > now()
          AND holder = $2 AND machine = $3
        RETURNING expires_at`,
      [scope.canonical, who, machine, hours]);
    if (!rows.length) {
      console.error(`steward extend: you hold no live claim on ${scope.canonical}. If it has expired, `
        + "claim it again rather than extending — the board has already shown it as free.");
      return 1;
    }
    const until = new Date(rows[0].expires_at).toISOString().slice(0, 16).replace("T", " ");
    console.error(`steward: ${scope.canonical} extended by ${hours}h, now until ${until}Z`);
    return 0;
  } finally {
    await client.end();
  }
}

/* ── worktree ────────────────────────────────────────────────────────────────────────────── */

/**
 * Record that a session started in this directory, and report what moved since the last one.
 *
 * 🔴 THIS IS A MARKER, NOT A LEASE, AND THE DIFFERENCE IS THE WHOLE DESIGN. Nothing releases
 *    it when a terminal closes, so a live row means "a session STARTED here at T" and never "a
 *    session is running here now". The board therefore prints LAST SEEN, and registration takes
 *    the marker over unconditionally — the newest session really is the newest thing to have
 *    started there, so there is no holder whose work is being displaced.
 *
 *    That is the opposite of `claim`, where `--if-held warn` refuses to steal. The fact being
 *    recorded is different: for a jurisdiction it is "I am working here, don't"; here it is
 *    "who most recently started". What would otherwise be lost — that another session was there,
 *    on another branch — is REPORTED rather than discarded.
 */
async function cmdWorktree() {
  const top = (() => {
    try {
      return execFileSync("git", ["rev-parse", "--show-toplevel"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
    } catch { return null; }
  })();
  // Not a git worktree at all. Nothing to record, and nothing worth saying about it.
  if (!top) return 0;

  let branch = null;
  try {
    branch = execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch { /* no HEAD yet */ }
  if (branch === "HEAD") branch = null;             // detached; a name would be a lie

  const scope = canonicalWorktreeScope(top);
  const { who, machine } = identity();
  const hours = hoursOpt(WORKTREE_MARKER_HOURS);

  const client = await connectOrWarn("worktree");
  if (!client) return 0;
  try {
    const { rows: prevRows } = await client.query(
      `SELECT id, holder, machine, label, started_at
         FROM steward.claims
        WHERE scope = $1 AND released_at IS NULL AND expires_at > now()
        ORDER BY started_at DESC LIMIT 1`, [scope]);
    const previous = prevRows[0] ?? null;
    const notices = worktreeNotices({ who, holder: who, machine, branch }, previous);

    await client.query("BEGIN");
    if (previous) {
      await client.query(
        `UPDATE steward.claims SET released_at = now(), notes = concat_ws(' | ', notes, $2::text)
          WHERE id = $1`,
        [previous.id, `superseded by ${who} on ${machine}`]);
    }
    await client.query(
      `INSERT INTO steward.claims (scope, label, holder, machine, session_ref, expires_at, notes)
       VALUES ($1, $2, $3, $4, $5, now() + make_interval(hours => $6), $7)`,
      [scope, branch, who, machine, process.env.CLAUDE_SESSION_ID ?? null, hours,
        "session-start worktree marker"]);
    await client.query("COMMIT");

    for (const n of notices) {
      const seen = new Date(n.previous.started_at).toISOString().slice(0, 16).replace("T", " ");
      if (n.kind === "head-moved") {
        console.warn(`  🔴 HEAD MOVED in ${scope.slice("worktree:".length)} — it was on `
          + `${n.was} when a session last started here (${seen}Z), and is now on ${n.now}. `
          + "If that was not you, another session may be mid-task on this checkout.");
      } else {
        console.warn(`  ⚠ another session was last seen in ${scope.slice("worktree:".length)} at `
          + `${seen}Z — ${n.previous.holder} on ${n.previous.machine}`
          + `${n.previous.label ? ` (branch ${n.previous.label})` : ""}. `
          + "Do not checkout or switch here; make your own worktree.");
      }
    }
    console.log(scope);
    return 0;
  } catch (e) {
    await client.query("ROLLBACK").catch(() => {});
    // 🔴 FAIL OPEN. A session must never fail to start because a marker could not be written.
    console.warn(`steward worktree: could not record this worktree (${e.message}). Continuing.`);
    return 0;
  } finally {
    await client.end();
  }
}

const COMMANDS = {
  who: cmdWho, sync: cmdSync, slot: cmdSlot,
  claim: cmdClaim, release: cmdRelease, extend: cmdExtend, worktree: cmdWorktree,
};

const run = COMMANDS[cmd];
if (!run) {
  console.error("usage: steward <who|sync|slot|claim|release|extend> [...]\n"
    + "  who                              show active claims and outstanding reservations\n"
    + "  sync --seed [--dry-run]          reconcile git history into steward.migration_slots\n"
    + "  slot <NS|shared> --purpose \"...\"  reserve the next free migration number (shared == the plain NNNN_ sequence)\n"
    + "  claim <scope> [<scope>...]       take a jurisdiction lease (8h by default)\n"
    + "        --label \"...\"                 what you are doing there, for the board\n"
    + "        --hours N                     lease length, 1-168\n"
    + "        --if-held warn|fail|skip      held: name the holder (default) | stop | try the next candidate\n"
    + "        --takeover                    displace a live lease, recorded on the row it displaces\n"
    + "  release <scope> [--force]        end your lease early (--force: somebody else's)\n"
    + "  extend <scope> [--hours N]       push your lease out, 4h by default\n"
    + "  worktree                         record that a session started here, and report what moved\n"
    + "\n"
    + "  A scope is place:<geoid> | county:<fips> | state:<usps>. Exact collisions are refused by\n"
    + "  the database; a city inside a claimed county is a WARNING, because the strings differ.\n"
    + "  worktree:<path> is a 12h MARKER, not a lease — it says a session started there, not that\n"
    + "  one is running. The SessionStart hook records it for you.");
  process.exit(2);
}
run().then((code) => process.exit(code ?? 0)).catch((e) => {
  console.error(`steward ${cmd}: ${e.message}`);
  process.exit(1);
});
