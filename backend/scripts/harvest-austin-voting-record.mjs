#!/usr/bin/env node
/**
 * Harvest the City of Austin Council Voting Record into a per-topic worklist of
 * CONTESTED votes for the current council.
 *
 * Source: https://data.austintexas.gov/resource/3c89-i35a.json (Socrata, open, no
 * auth, no WAF). ~71,885 per-member roll-call rows from 2023 forward. This is the
 * attribution Legistar does not have -- webapi.legistar.com returns [] for
 * /eventitems/{id}/votes and /matters/{id}/sponsors and publishes no minutes.
 *
 * WHY ONLY CONTESTED ITEMS: 63,960 of 71,885 votes are "Yes". A unanimous vote
 * records consensus and cannot separate one member from another, so it is close to
 * useless for seating a compass chair. The signal is the ~380 items where somebody
 * dissented, and specifically the 143 where a CURRENT member did. Those discriminate.
 *
 * WHAT THIS IS AND IS NOT: a vote gives you an attributed position on a named
 * instrument, but no reasoning -- and most items are administrative contract
 * authorisations where a "No" may be about cost, process or timing rather than the
 * policy. Pair each hit with the member's Council Message Board post on the same
 * item (harvest-austin-council-board.mjs) before seating anything. The vote supplies
 * the instrument; the post supplies the why.
 *
 * Usage:
 *   node scripts/harvest-austin-voting-record.mjs [--out <dir>] [--since 2023-01-01]
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const API = 'https://data.austintexas.gov/resource/3c89-i35a.json';
const PAGE = 50000;

/** Exact voter_name strings as they appear in the dataset, mapped to seat. */
const MEMBERS = {
  'Kirk Watson': 'Mayor',
  'Natasha Harper-Madison': 'D1',
  'Vanessa Fuentes': 'D2',
  'José Velásquez': 'D3',
  'José "Chito" Vela': 'D4',
  'Ryan Alter': 'D5',
  'Krista Laine': 'D6',
  'Mike Siegel': 'D7',
  'Paige Ellis': 'D8',
  'Zohaib "Zo" Qadri': 'D9',
  'Marc Duchen': 'D10',
};

/** A dissent is a recorded position. Absent / Off Dais / Withdrawn are NOT positions. */
const POSITIONS = new Set(['Yes', 'No', 'Abstain', 'Recused']);
const DISSENT = new Set(['No', 'Abstain']);

/**
 * Topic detectors run against item_description. Case-SENSITIVE \bICE\b so it cannot
 * match "police" -- /ICE/i matching "polICE" silently inflated an earlier immigration
 * count from 8 real hits to 16.
 */
const TOPICS = {
  'residential-zoning': /zoning|rezon|land development code|compatibilit|density bonus|DB90|HOME phase|small lot|site plan|subdivi|accessory dwelling/i,
  housing: /affordable housing|housing trust|displacement|anti-displacement|community land trust|land bank/i,
  'transportation-priorities': /transit|mobility|parking|bike|bicycle|sidewalk|urban trail|I-35|Project Connect|CapMetro|rail|vision zero/i,
  'homelessness-response': /homeless|encampment|shelter|unhoused|permanent supportive housing/i,
  'public-safety-approach': /police|APD|public safety|cadet|police oversight|emergency medical|EMS|fire department/i,
  'local-environment': /water quality|watershed|creek|parkland|tree|drainage|flood|green infrastructure|preserve/i,
  'climate-change': /climate|Austin Energy|solar|battery|emission|renewable|generation plan/i,
  'economic-development': /economic development|chapter 380|incentive|convention center|airport|small business/i,
  'civil-rights': /civil right|surveillance|license plate|discriminat|LGBTQ|transgender/i,
  'local-immigration': /(\bICE\b|immigration|immigrant|undocumented)/,
  'rent-regulation': /tenant|renter|landlord|eviction|relocation/i,
  childcare: /child care|childcare|early childhood|pre-k/i,
  'city-sanitation': /Austin Resource Recovery|solid waste|recycling|litter|dumping/i,
  'jail-capacity': /jail|booking|magistration|diversion/i,
  abortion: /abortion|reproductive/i,
};

function arg(flag, fallback) {
  const i = process.argv.indexOf(flag);
  return i > -1 ? process.argv[i + 1] : fallback;
}
const OUT_DIR = resolve(arg('--out', 'data/stance-research/austin-voting-record'));
const SINCE = arg('--since', null);

async function fetchAll() {
  const rows = [];
  for (let offset = 0; ; offset += PAGE) {
    const where = SINCE ? `&$where=${encodeURIComponent(`meeting_date >= '${SINCE}'`)}` : '';
    const r = await fetch(`${API}?$limit=${PAGE}&$offset=${offset}${where}`);
    if (!r.ok) throw new Error(`Socrata ${r.status}`);
    const batch = await r.json();
    if (!batch.length) break;
    rows.push(...batch);
    process.stdout.write(`\r[..] fetched ${rows.length}`);
    if (batch.length < PAGE) break;
  }
  console.log(`\n[ok] ${rows.length} vote rows`);
  return rows;
}

async function main() {
  mkdirSync(OUT_DIR, { recursive: true });
  const rows = await fetchAll();

  // Name reconciliation. Assert every configured member actually appears, and report
  // any unmatched name rather than silently seating nobody -- a name that stops
  // matching after a dataset edit would otherwise look exactly like "no dissents".
  const seen = new Set(rows.map((r) => r.voter_name).filter(Boolean));
  const missing = Object.keys(MEMBERS).filter((n) => !seen.has(n));
  if (missing.length) {
    console.warn(`\n:warning: configured members with NO rows (name drift?): ${missing.join(' | ')}`);
    console.warn(`   names present in dataset: ${[...seen].sort().join(' | ')}`);
  } else {
    console.log('[ok] all 11 configured member names matched the dataset exactly');
  }

  // Group into items.
  const items = new Map();
  for (const r of rows) {
    if (!items.has(r.item_id)) {
      items.set(r.item_id, {
        item_id: r.item_id,
        date: (r.meeting_date || '').slice(0, 10),
        description: r.item_description || '',
        action: r.action_taken || '',
        votes: [],
      });
    }
    items.get(r.item_id).votes.push({ name: r.voter_name, cast: r.vote_cast });
  }

  // Keep only items where a CURRENT member cast a recorded dissent.
  const contested = [...items.values()].filter((it) =>
    it.votes.some((v) => v.name in MEMBERS && DISSENT.has(v.cast))
  );
  console.log(`[ok] ${contested.length} items with a current-member dissent (of ${items.size} items)`);

  // Classify and emit one worklist per topic.
  const byTopic = new Map();
  let unclassified = 0;
  for (const it of contested) {
    const hits = Object.entries(TOPICS).filter(([, re]) => re.test(it.description));
    if (!hits.length) { unclassified++; continue; }
    for (const [topic] of hits) {
      if (!byTopic.has(topic)) byTopic.set(topic, []);
      byTopic.get(topic).push(it);
    }
  }

  const summary = [];
  for (const [topic, list] of [...byTopic.entries()].sort((a, b) => b[1].length - a[1].length)) {
    list.sort((a, b) => b.date.localeCompare(a.date));
    const md = [
      `# ${topic} — contested Austin council votes`,
      '',
      `Source: City of Austin Council Voting Record, https://data.austintexas.gov/resource/3c89-i35a`,
      '',
      `Only items where a sitting council member cast a recorded **No** or **Abstain** are listed;`,
      `unanimous items cannot distinguish members and are excluded. Absent / Off Dais / Withdrawn`,
      `are not positions and are not counted as dissent.`,
      '',
      `:warning: A vote names the instrument and the member's position but carries NO reasoning, and`,
      `many items are contract authorisations where a No may be about cost, process or timing rather`,
      `than the policy. Confirm intent against the member's Council Message Board post on the same`,
      `item before seating a chair.`,
      '',
      `Items: ${list.length}`,
      '',
      ...list.flatMap((it) => {
        const pos = it.votes.filter((v) => v.name in MEMBERS && POSITIONS.has(v.cast));
        const no = pos.filter((v) => DISSENT.has(v.cast));
        const yes = pos.filter((v) => v.cast === 'Yes');
        return [
          `## ${it.date} — ${it.item_id}`,
          `${it.description}`,
          '',
          `- action: ${it.action}`,
          `- **dissent:** ${no.map((v) => `${v.name} (${v.cast}, ${MEMBERS[v.name]})`).join('; ') || '—'}`,
          `- in favour: ${yes.map((v) => MEMBERS[v.name]).join(', ') || '—'}`,
          '',
        ];
      }),
    ].join('\n');
    writeFileSync(resolve(OUT_DIR, `${topic}.md`), md, 'utf8');
    summary.push({ topic, items: list.length });
  }

  // Per-member dissent tally, so the thinnest compasses can be targeted first.
  const tally = {};
  for (const it of contested) {
    for (const v of it.votes) {
      if (v.name in MEMBERS && DISSENT.has(v.cast)) tally[v.name] = (tally[v.name] || 0) + 1;
    }
  }

  writeFileSync(
    resolve(OUT_DIR, '_summary.json'),
    JSON.stringify({ totalVoteRows: rows.length, totalItems: items.size, contestedItems: contested.length, unclassified, byTopic: summary, dissentsByMember: tally }, null, 1),
    'utf8'
  );
  console.table(summary);
  console.log(`unclassified contested items: ${unclassified}`);
  console.table(Object.entries(tally).sort((a, b) => b[1] - a[1]).map(([name, n]) => ({ member: name, seat: MEMBERS[name], dissents: n })));
  console.log(`\nVOTE_ITEMS=${contested.length} worklists -> ${OUT_DIR}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
