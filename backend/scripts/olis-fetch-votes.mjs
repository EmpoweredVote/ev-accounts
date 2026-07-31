#!/usr/bin/env node
/**
 * Oregon Legislature (OLIS) per-member roll-call extractor.
 *
 * WHY THIS EXISTS. Migrations 1507 and 1508 retired 188 Oregon stance rows whose only citation was a
 * Ballotpedia bio page that does not contain the claim. Those officeholders are now queued for
 * re-research (their `last_stances_researched_at` was nulled). Re-researching them against the SAME
 * source would reproduce the same defect, so the replacement source is the legislature's own record.
 *
 * OLIS publishes a free OData v3 service at api.oregonlegislature.gov with `MeasureVotes` — one row
 * per member per roll call, back to 2007. The 2025 regular session alone has 72,752 vote rows, so
 * unlike Wisconsin (48 of 562 roll calls usable) coverage here is real.
 *
 * THE JOIN IS BY DISTRICT, NOT BY NAME. `Legislators.DistrictNumber` + `Chamber` maps onto our
 * `essentials.districts.ocd_id` as `.../sldl:N` (House) and `.../sldu:N` (Senate), which we hold
 * 60/30 with exactly one current holder each. Name is used only to CONFIRM the match and is reported
 * when it disagrees — never as the join key. This is the standing push rule, and it matters because
 * name matching in this project has failed repeatedly on real people.
 *
 * 🔴 THE OLIS ROSTER IS SESSION-SCOPED, OURS IS CURRENT — DO NOT ATTRIBUTE SESSION VOTES TO THE
 * CURRENT HOLDER. Verified on the 2025R1 roster: OLIS puts Christine Drazan in H51 and Daniel Bonham
 * in S26, while we hold Matt Bunch in H51 and Drazan in S26. Both are right. Drazan was appointed to
 * S26 on 2025-10-24 replacing Bonham, and Bunch took her House seat. H48 is the same shape (OLIS Hoa
 * Nguyen, ours Lamar Wise).
 *
 * A vote belongs to whoever held the seat WHEN IT WAS CAST. Mapping a session's votes onto today's
 * occupant would credit one member with another's record — exactly the class of error migrations
 * 1507/1508 just spent 188 rows cleaning up. So a district match is only a CANDIDATE; the authority
 * is the session roster identity (`LegislatorCode`), and any seat that changed hands must be resolved
 * against the vote's `ActionDate`, not assumed.
 *
 * OData v3 gotchas, all found the hard way:
 *   - Responses are `{"d": [ ... ]}` — an ARRAY directly under `d`, NOT `{"d":{"results":[...]}}`.
 *     Parsing for `.results` silently yields zero rows and looks like an empty dataset.
 *   - Dates arrive as `/Date(1730893967000)/`.
 *   - `$count` works; `$select` and `$filter` both work despite appearances.
 *   - `LegislatorCode` disambiguates duplicate surnames itself: `Rep Pham H` vs `Sen Pham`,
 *     `Rep Levy B` vs `Rep Levy E`, `Rep Smith G` vs `Sen Smith DB`. It equals `MeasureVotes.VoteName`.
 *
 * Usage:
 *   node scripts/olis-fetch-votes.mjs --session 2025R1 --roster        # map roster to our records
 *   node scripts/olis-fetch-votes.mjs --session 2025R1 --votes out.json
 */
import 'dotenv/config';
import dns from 'node:dns';
import { writeFileSync } from 'node:fs';
import { Pool } from 'pg';

// api.oregonlegislature.gov advertises AAAA but does not answer on it from here: Node's default
// "verbatim" resolution picks IPv6 and dies with UND_ERR_CONNECT_TIMEOUT after 10s, while curl
// falls back to IPv4 and succeeds. Force IPv4 first rather than raise the timeout — the connection
// is not slow, it is unanswerable.
dns.setDefaultResultOrder('ipv4first');

const BASE = 'https://api.oregonlegislature.gov/odata/odataservice.svc';
const arg = (k, d = null) => {
  const i = process.argv.indexOf(k);
  return i !== -1 && process.argv[i + 1] && !process.argv[i + 1].startsWith('--') ? process.argv[i + 1] : d;
};
const SESSION = arg('--session', '2025R1');

/** OData v3 returns the collection as a bare array under `d`. Tolerate both shapes, fail loudly on neither. */
function unwrap(json, what) {
  const rows = Array.isArray(json?.d) ? json.d : json?.d?.results;
  if (!Array.isArray(rows)) throw new Error(`unexpected OData shape for ${what}: ${JSON.stringify(json).slice(0, 200)}`);
  return rows;
}

/** Encode only the spaces/quotes OData needs; leave $ and = intact so the query still parses. */
const enc = (p) => p.replace(/ /g, '%20').replace(/'/g, '%27');

/**
 * The host refuses connections intermittently — undici's 10s connect timeout fires as
 * UND_ERR_CONNECT_TIMEOUT on maybe one call in three, and the identical request then succeeds. So
 * retry rather than lengthen the timeout: the connection is not slow, it is sporadically refused.
 * Fails loudly after the last attempt; a silent empty result here would look like an empty dataset.
 */
async function withRetry(fn, what, attempts = 5) {
  let last;
  for (let i = 1; i <= attempts; i++) {
    try { return await fn(); } catch (e) {
      last = e;
      if (i < attempts) await new Promise((r) => setTimeout(r, 1500 * i));
    }
  }
  throw new Error(`${what}: failed after ${attempts} attempts — ${last?.cause?.code || last?.message}`);
}

async function odata(path, what) {
  return withRetry(async () => {
    const res = await fetch(`${BASE}/${enc(path)}`, {
      headers: { Accept: 'application/json;odata=verbose' },
      signal: AbortSignal.timeout(120000),
    });
    if (!res.ok) throw new Error(`${what}: HTTP ${res.status}`);
    return unwrap(await res.json(), what);
  }, what);
}

async function count(path) {
  return withRetry(async () => {
    const res = await fetch(`${BASE}/${enc(path)}`, { signal: AbortSignal.timeout(120000) });
    if (!res.ok) throw new Error(`count: HTTP ${res.status}`);
    return parseInt((await res.text()).trim(), 10);
  }, 'count');
}

// Strip diacritics BEFORE dropping non-letters. Without the NFD pass "Nguyễn" normalises to "nguyn"
// and fails to match OLIS's "Nguyen", and "Trần"/"Tran" likewise — two false mismatches on real
// people whose names we store correctly and OLIS stores unaccented.
const norm = (s) => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z]/g, '');

async function roster(pool) {
  const legs = await odata(`Legislators?$filter=SessionKey eq '${SESSION}'`, 'Legislators');
  console.log(`OLIS ${SESSION}: ${legs.length} legislators (` +
    `H ${legs.filter((l) => l.Chamber === 'H').length} / S ${legs.filter((l) => l.Chamber === 'S').length})`);

  const ocdOf = (l) =>
    `ocd-division/country:us/state:or/${l.Chamber === 'H' ? 'sldl' : 'sldu'}:${l.DistrictNumber}`;

  const { rows: ours } = await pool.query(
    `SELECT d.ocd_id, p.id AS politician_id, p.full_name, o.title
       FROM essentials.districts d
       JOIN essentials.offices o ON o.district_id = d.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id
      WHERE lower(d.state) = 'or' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')`);
  const byOcd = new Map(ours.map((r) => [r.ocd_id, r]));

  const matched = [], nameMismatch = [], noSeat = [];
  for (const l of legs) {
    const ours1 = byOcd.get(ocdOf(l));
    if (!ours1) { noSeat.push(`${l.LegislatorCode} (${l.Chamber}${l.DistrictNumber})`); continue; }
    const rec = {
      legislatorCode: l.LegislatorCode, olisName: `${l.FirstName} ${l.LastName}`,
      chamber: l.Chamber, district: l.DistrictNumber, party: l.Party,
      email: l.EmailAddress, url: l.WebSiteUrl,
      politician_id: ours1.politician_id, ourName: ours1.full_name, ourTitle: ours1.title,
    };
    // Surname must agree. A disagreement is a REPORTABLE finding, never something to paper over:
    // it means either our roster or theirs is stale on that seat.
    if (norm(l.LastName) && norm(ours1.full_name).includes(norm(l.LastName))) matched.push(rec);
    else nameMismatch.push(rec);
  }

  console.log(`\nmapped by district → our current holder: ${matched.length}`);
  console.log(`name DISAGREES on the same seat        : ${nameMismatch.length}`);
  console.log(`OLIS seat we hold no district for      : ${noSeat.length}`);
  if (nameMismatch.length) {
    console.log('\n🔴 NAME MISMATCH — do not auto-trust these seats either way:');
    for (const m of nameMismatch) {
      console.log(`  ${m.chamber}${String(m.district).padEnd(3)} OLIS "${m.olisName}" vs ours "${m.ourName}"`);
    }
  }
  if (noSeat.length) console.log('\nno district row: ' + noSeat.join(', '));
  return { matched, nameMismatch, noSeat };
}

async function votes(outPath, map) {
  const total = await count(`MeasureVotes/$count?$filter=SessionKey eq '${SESSION}'`);
  console.log(`\nMeasureVotes for ${SESSION}: ${total}`);
  const byCode = new Map(map.matched.map((m) => [m.legislatorCode, m]));
  const out = [];
  const PAGE = 1000;
  for (let skip = 0; skip < total; skip += PAGE) {
    const rows = await odata(
      `MeasureVotes?$filter=SessionKey eq '${SESSION}'&$top=${PAGE}&$skip=${skip}`, 'MeasureVotes');
    if (!rows.length) break;
    for (const v of rows) {
      const m = byCode.get(v.VoteName);
      if (!m) continue; // unmapped member — excluded, and counted below
      out.push({
        politician_id: m.politician_id, legislatorCode: v.VoteName,
        measure: `${v.MeasurePrefix} ${v.MeasureNumber}`, vote: v.Vote, chamber: v.Chamber,
        actionText: v.ActionText,
        actionDate: v.ActionDate ? new Date(+String(v.ActionDate).replace(/\D/g, '')).toISOString().slice(0, 10) : null,
      });
    }
    process.stdout.write(`\r  fetched ${Math.min(skip + PAGE, total)}/${total}`);
  }
  console.log(`\nkept ${out.length} of ${total} vote rows (rest belong to unmapped members)`);
  const tally = {};
  out.forEach((v) => { tally[v.vote] = (tally[v.vote] || 0) + 1; });
  console.log('vote values:', JSON.stringify(tally));
  console.log('🔴 A "No Vote"/absent value is NOT a position — never read it as opposition.');
  writeFileSync(outPath, JSON.stringify({ session: SESSION, fetched: out.length, votes: out }, null, 1));
  console.log(`wrote ${outPath}`);
}

async function main() {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(1); }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const map = await roster(pool);
  const votesOut = arg('--votes');
  if (votesOut) await votes(votesOut, map);
  else console.log('\n(no --votes <path>: roster mapping only, nothing fetched)');
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
