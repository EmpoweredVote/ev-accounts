#!/usr/bin/env node
/**
 * WA 2026 primary CERTIFICATION PASS, step 1 of 2 — build the top-two disposition for every
 * race on the WA 2026 Statewide General from the OFFICIAL (certified) results feeds.
 *
 * Produced migration 1842. Kept because the METHOD generalises to any top-two or runoff
 * state, and because two of its checks are the reason that migration is correct:
 *
 *   1. The cut-line check is a MARGIN test, not a tie test. RCW 29A.64.021 forces a recount
 *      under 2,000 votes AND 0.5% (machine) or 150 AND 0.25% (hand). LD 42 Senate came in
 *      FOUR votes apart — an exact-tie guard passes it green and ships a cull that deletes a
 *      candidate who may still make the ballot.
 *   2. Write-ins are excluded BY NAME. `ballotOptions.isWriteIn` is false on 3 of 137
 *      write-in lines in the statewide feed and 41 of 60 in the King feed.
 *
 *   node scripts/wa-cert-harvest.mjs [feed-dir]      -> disposition.json + a report
 *   node scripts/wa-cert-emit-migration.mjs          -> the migration SQL
 *
 * Matching is 1:1 and REFUSES to guess. Anything unmatched in either direction is
 * reported, never silently dropped. Reads DATABASE_URL from backend/.env.
 */
import fs from 'node:fs';
import pg from 'pg';
import { fileURLToPath } from 'node:url';

// Feed snapshot directory. Repo-local default (gitignored); override with argv[2].
//
//   mkdir -p backend/.tmp-wa-cert && cd backend/.tmp-wa-cert
//   B=https://results.votewa.gov/results/public/api/elections
//   curl -s "$B/washington/20260804/data"       -o wa-state.json
//   curl -s "$B/king-county-wa/20260804/data"   -o king.json
//   curl -s "$B/kitsap-county-wa/20260804/data" -o kitsap.json
//
/** Resolve a path relative to this script, Windows-drive-safe. */
const local = (rel) => fileURLToPath(new URL(rel, import.meta.url));

const SP = process.argv[2] || local('../.tmp-wa-cert');
const ELECTION = process.env.WA_CERT_ELECTION_ID || '51e7a875-bff9-4e96-adcf-41736454d25d';

// ── name normalisation: NFD-strip diacritics (combining marks DELETED, not spaced)
const norm = (s) =>
  s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/["'’`.]/g, '')
    .replace(/\([^)]*\)/g, ' ')
    .replace(/\bjr\b|\bsr\b|\bii\b|\biii\b|\biv\b/g, ' ')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();

// last name + first initial — the fallback key, used ONLY when it is unique on both sides
const lnfi = (s) => {
  const t = norm(s).split(' ').filter(Boolean);
  if (t.length < 2) return null;
  return t[t.length - 1] + '|' + t[0][0];
};

// ── load feeds
const feeds = {
  state: JSON.parse(fs.readFileSync(`${SP}/wa-state.json`, 'utf8')),
  king: JSON.parse(fs.readFileSync(`${SP}/king.json`, 'utf8')),
  kitsap: JSON.parse(fs.readFileSync(`${SP}/kitsap.json`, 'utf8')),
};
for (const [k, f] of Object.entries(feeds)) {
  if (f.election.isOfficialResults !== true)
    throw new Error(`${k} feed is NOT isOfficialResults — refusing to certify from a preliminary canvass`);
}

/** contest key -> {feed, name, voteTotal, options:[{name,votes,party,isWriteIn,isQualifiedWriteIn}]} */
const contests = new Map();
const addContest = (feedName, key, item) => {
  if (!item.summaryResults) return;
  if (contests.has(key)) throw new Error(`duplicate contest key ${key}`);
  contests.set(key, {
    feed: feedName,
    contestName: item.name[0].text,
    voteTotal: item.voteTotal,
    options: item.summaryResults.ballotOptions.map((o) => ({
      name: o.name[0].text,
      votes: o.voteCount,
      party: o.party ? o.party.abbreviation : null,
      isWriteIn: !!o.isWriteIn,
      isQualifiedWriteIn: !!o.isQualifiedWriteIn,
    })),
  });
};

for (const item of feeds.state.ballotItems) {
  const n = item.name[0].text;
  let m;
  if ((m = /^U\.S\. Representative - Congressional District (\d+)$/.exec(n))) addContest('state', `CD${+m[1]}`, item);
  else if ((m = /^State Representative Pos\. (\d) - Legislative District (\d+)$/.exec(n))) addContest('state', `HD${+m[2]}P${+m[1]}`, item);
  else if ((m = /^State Senator - Legislative District (\d+)$/.exec(n))) addContest('state', `SD${+m[1]}`, item);
}
for (const item of feeds.king.ballotItems) {
  const n = item.name[0].text;
  let m;
  if (/^Assessor$/.test(n)) addContest('king', 'KC-ASSESSOR', item);
  else if ((m = /^Metropolitan King County - Council District No\. (\d+)$/.exec(n))) addContest('king', `KC-COUNCIL${+m[1]}`, item);
  else if ((m = /^Seattle City Council - District No\. (\d+)$/.exec(n))) addContest('king', `SEA-COUNCIL${+m[1]}`, item);
}

for (const item of feeds.kitsap.ballotItems) {
  const n = item.name[0].text;
  let m;
  if ((m = /^Kitsap County (Assessor|Auditor|Clerk|Prosecuting Attorney|Sheriff|Treasurer)$/.exec(n)))
    addContest('kitsap', `KI-${m[1].toUpperCase().replace(/ /g, '')}`, item);
  else if ((m = /^Kitsap County Commissioner District (\d+) Comm Dist (\d+)$/.exec(n)) && m[1] === m[2])
    addContest('kitsap', `KI-COMM${+m[1]}`, item);
}

// ── our position_name -> contest key
const posKey = (p) => {
  let m;
  if ((m = /^U\.S\. Representative District (\d+)$/.exec(p))) return `CD${+m[1]}`;
  if ((m = /^WA House of Representatives Legislative District (\d+) Position (\d)$/.exec(p))) return `HD${+m[1]}P${+m[2]}`;
  if ((m = /^WA State Senate Legislative District (\d+)$/.exec(p))) return `SD${+m[1]}`;
  if (/^King County Assessor$/.test(p)) return 'KC-ASSESSOR';
  if ((m = /^King County Council District (\d+)$/.exec(p))) return `KC-COUNCIL${+m[1]}`;
  if ((m = /^Seattle City Council District (\d+)$/.exec(p))) return `SEA-COUNCIL${+m[1]}`;
  if ((m = /^Kitsap County (Assessor|Auditor|Clerk|Prosecuting Attorney|Sheriff|Treasurer)$/.exec(p)))
    return `KI-${m[1].toUpperCase().replace(/ /g, '')}`;
  if ((m = /^Kitsap County Commissioner District (\d+)$/.exec(p))) return `KI-COMM${+m[1]}`;
  return null;
};

// ── load our field
const env = fs.readFileSync(local('../.env'), 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(
  `SELECT r.id AS race_id, r.position_name, r.seats,
          rc.id AS rc_id, rc.full_name, rc.is_incumbent, rc.candidate_status,
          rc.result, rc.provisional_until::text AS provisional_until
     FROM essentials.races r
     JOIN essentials.race_candidates rc ON rc.race_id = r.id
    WHERE r.election_id = $1
    ORDER BY r.position_name, rc.full_name`,
  [ELECTION],
);
await pool.end();

const races = new Map();
for (const row of rows) {
  if (!races.has(row.race_id))
    races.set(row.race_id, { race_id: row.race_id, position_name: row.position_name, seats: row.seats, cands: [] });
  races.get(row.race_id).cands.push(row);
}

// ── disposition
const out = { advanced: [], not_nominated: [], races: [], problems: [] };

for (const race of [...races.values()].sort((a, b) => a.position_name.localeCompare(b.position_name))) {
  const key = posKey(race.position_name);
  const contest = key ? contests.get(key) : null;
  const rec = { position_name: race.position_name, key, contest: contest ? contest.contestName : null, feed: contest ? contest.feed : null, n_ours: race.cands.length };

  if (!contest) {
    rec.status = key ? 'NO_CONTEST_IN_FEED' : 'UNMAPPED_POSITION_NAME';
    out.races.push(rec);
    out.problems.push({ race: race.position_name, why: rec.status, ours: race.cands.map((c) => c.full_name) });
    continue;
  }

  // Real candidates only. 🔴 `isWriteIn` IS NOT RELIABLE — 3 of 137 write-in options in the
  // statewide feed and 41 of 60 in the King feed carry isWriteIn=false. Detect by NAME as well;
  // an actually-qualified write-in is listed under the person's own name, never as "Write-In".
  const isWI = (o) => (o.isWriteIn && !o.isQualifiedWriteIn) || /^write.?in\b/i.test(o.name);
  const real = contest.options.filter((o) => !isWI(o));
  const writeIns = contest.options.filter(isWI);
  rec.writein_votes = writeIns.reduce((a, o) => a + o.votes, 0);

  const ranked = [...real].sort((a, b) => b.votes - a.votes);
  rec.feed_field = ranked.map((o) => `${o.name} ${o.votes}${o.party ? ' ' + o.party : ''}`);
  rec.ranked_votes = ranked.map((o) => o.votes);

  // 🔴 A CERTIFIED CUT LINE INSIDE THE MANDATORY-RECOUNT MARGIN IS NOT FINAL.
  // RCW 29A.64.021: machine recount when the difference between the two candidates is
  // < 2,000 votes AND < 0.5% of their combined total; hand recount at < 150 and < 0.25%.
  if (ranked.length > 2) {
    const [, second, third] = rec.ranked_votes;
    const diff = second - third;
    const pct = (diff / (second + third)) * 100;
    if (diff < 2000 && pct < 0.5) {
      rec.recount_risk = { second, third, diff, pct: +pct.toFixed(4), kind: diff < 150 && pct < 0.25 ? 'hand' : 'machine' };
      out.problems.push({ race: race.position_name, why: 'CUT_LINE_IN_MANDATORY_RECOUNT_RANGE', ...rec.recount_risk });
    }
  }

  // top two, with an explicit tie check at the cut line
  const cut = ranked[1] ? ranked[1].votes : null;
  const tiedAtCut = cut != null ? ranked.filter((o) => o.votes === cut).length : 0;
  const advancers = ranked.slice(0, 2);
  if (cut != null && ranked.length > 2 && tiedAtCut > 1) {
    rec.status = 'TIE_AT_CUT_LINE';
    out.races.push(rec);
    out.problems.push({ race: race.position_name, why: 'TIE_AT_CUT_LINE', cut, ranked: rec.feed_field });
    continue;
  }

  // 1:1 name match, ours -> feed
  const feedByNorm = new Map();
  for (const o of real) {
    const k = norm(o.name);
    if (feedByNorm.has(k)) { out.problems.push({ race: race.position_name, why: 'FEED_NAME_COLLISION', name: o.name }); }
    feedByNorm.set(k, o);
  }
  const feedByLnfi = new Map();
  for (const o of real) {
    const k = lnfi(o.name);
    if (!k) continue;
    feedByLnfi.set(k, (feedByLnfi.get(k) || []).concat(o));
  }

  const matched = new Map(); // rc_id -> feed option
  const unmatchedOurs = [];
  for (const c of race.cands) {
    const k = norm(c.full_name);
    let o = feedByNorm.get(k);
    let how = 'exact';
    if (!o) {
      const lk = lnfi(c.full_name);
      const cands = lk ? feedByLnfi.get(lk) || [] : [];
      const ourSameLnfi = race.cands.filter((x) => lnfi(x.full_name) === lk);
      if (cands.length === 1 && ourSameLnfi.length === 1) { o = cands[0]; how = 'lastname+initial'; }
    }
    if (!o) { unmatchedOurs.push(c); continue; }
    if ([...matched.values()].includes(o)) { out.problems.push({ race: race.position_name, why: 'DOUBLE_MATCH', name: c.full_name, feed: o.name }); continue; }
    matched.set(c.rc_id, { c, o, how });
  }

  const matchedFeed = new Set([...matched.values()].map((m) => m.o));
  const unmatchedFeed = real.filter((o) => !matchedFeed.has(o));

  rec.matched = matched.size;
  rec.unmatched_ours = unmatchedOurs.map((c) => c.full_name);
  rec.unmatched_feed = unmatchedFeed.map((o) => `${o.name} ${o.votes}`);
  rec.fuzzy = [...matched.values()].filter((m) => m.how !== 'exact').map((m) => `${m.c.full_name} -> ${m.o.name}`);

  if (unmatchedOurs.length) out.problems.push({ race: race.position_name, why: 'OURS_NOT_IN_CERTIFIED_CANVASS', names: rec.unmatched_ours, feed: rec.feed_field });
  // a feed candidate we never seeded who ADVANCED is a missing-row defect, not just noise
  const missingAdvancer = unmatchedFeed.filter((o) => advancers.includes(o));
  if (missingAdvancer.length) out.problems.push({ race: race.position_name, why: 'ADVANCER_MISSING_FROM_OUR_FIELD', names: missingAdvancer.map((o) => `${o.name} ${o.votes}`) });

  const src = certSource(contest, ranked, advancers);
  for (const { c, o } of matched.values()) {
    const disp = advancers.includes(o) ? 'advanced' : 'not_nominated';
    const target = { rc_id: c.rc_id, race: race.position_name, name: c.full_name, votes: o.votes, feed_name: o.name, status: c.candidate_status, was: c.result, source: src };
    out[disp].push(target);
  }
  rec.status = 'OK';
  rec.advancers = advancers.map((o) => `${o.name} ${o.votes}`);
  out.races.push(rec);
}

function certSource(contest, ranked, advancers) {
  const feedUrl = {
    king: 'results.votewa.gov/results/public/api/elections/king-county-wa/20260804/data',
    kitsap: 'results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data',
    state: 'results.votewa.gov/results/public/api/elections/washington/20260804/data',
  }[contest.feed];
  const cert = {
    king: 'King County Canvassing Board certification, feed lastUpdated 2026-08-18T21:36:40Z',
    kitsap: 'Kitsap County Canvassing Board certification, feed lastUpdated 2026-08-18T00:01:49Z',
    state: 'WA Secretary of State certification, feed lastUpdated 2026-08-19T13:39:21Z',
  }[contest.feed];
  const tally = ranked.map((o) => `${o.name}${o.party ? ' (' + o.party + ')' : ''} ${o.votes.toLocaleString('en-US')}`).join(' / ');
  return `CERTIFIED canvass of the 2026-08-04 WA top-two primary, "${contest.contestName}" (${feedUrl}, isOfficialResults=true, ${cert}; fetched 2026-08-20). Top two advance to the 2026-11-03 general: ${advancers.map((o) => o.name).join(' and ')}. Full certified tally: ${tally}. Total ${contest.voteTotal.toLocaleString('en-US')} votes.`;
}

fs.writeFileSync(`${SP}/disposition.json`, JSON.stringify(out, null, 2));

// ── report
const byStatus = {};
for (const r of out.races) byStatus[r.status] = (byStatus[r.status] || 0) + 1;
console.log('RACES:', out.races.length, JSON.stringify(byStatus));
console.log('advanced:', out.advanced.length, ' not_nominated:', out.not_nominated.length, ' untouched:', rows.length - out.advanced.length - out.not_nominated.length);
console.log('\n=== PROBLEMS (' + out.problems.length + ') ===');
for (const p of out.problems) console.log(JSON.stringify(p));
console.log('\n=== FUZZY MATCHES ===');
for (const r of out.races) if (r.fuzzy && r.fuzzy.length) console.log(r.position_name, '::', r.fuzzy.join(' ; '));
console.log('\n=== LOCAL (King / Seattle / Kitsap) DETAIL ===');
for (const r of out.races)
  if (/King County|Seattle|Kitsap/.test(r.position_name))
    console.log(
      r.status.padEnd(22),
      r.position_name.padEnd(38),
      'ADV: ' + (r.advancers || []).join(' + '),
      (r.feed_field || []).length > 2 ? ' || OUT: ' + r.feed_field.slice(2).join(', ') : '',
    );
