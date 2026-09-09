#!/usr/bin/env node
/**
 * floor-statement-sweep.mjs — find Congressional Record passages a named senator
 * actually SPOKE, on a given ladder's axis.
 *
 * The sponsorship sweep (`leads:congress`) is the wrong instrument for part of the
 * chamber on some topics. On border-security it reaches 43 of 100 senators and
 * every one of them is a Republican or Angus King, because the permissive caucus's
 * immigration bills are detention standards, visa caps and sponsor vetting rather
 * than asylum-eligibility restrictions. That is a fact about the instrument, not
 * the chamber. This script is the second instrument.
 *
 * 🔴 IT PRODUCES EVIDENCE, NOT CHAIRS. Every passage still needs a person to read
 * the whole turn and choose a rung, exactly as sponsorship leads do. CC_0074's
 * refusals are the standing proof that real evidence on the right topic can still
 * answer the wrong question.
 *
 * THE THREE GATES, and the second is the one nothing else supplies:
 *   1. search   surname + topic word co-occur in a granule. Worth nothing alone —
 *               a cosponsor list on an unrelated resolution satisfies it. Measured:
 *               Padilla had 90 such granules and spoke in 6.
 *   2. senate   granule id must carry -PgS. CREC covers both chambers plus
 *               Extensions of Remarks, and SMITH, SCOTT, JOHNSON and YOUNG all sit
 *               in both.
 *   3. turn     the senator must be the SPEAKER — the text between their
 *               attribution and the next member's. See lib/crec-turns.mjs.
 *
 * ⚠ THE VERIFIER CANNOT ENFORCE GATE 3. `verify-reresearch-rows` proves the claim
 * terms appear in the cited page's raw HTML, and a CREC page carries every senator
 * who spoke on it — so a row could pass while quoting somebody else. Any migration
 * built on these citations must run the attribution check itself.
 *
 * RUN:
 *   node scripts/floor-statement-sweep.mjs --names=<file> --out=<dir> [--depth=25]
 *   node scripts/floor-statement-sweep.mjs --names=<file> --out=<dir> --days=2024-05-22,2024-05-23
 *
 * --names is one full name per line, spelled as essentials.politicians spells it.
 * Needs CONGRESS_API_KEY (an api.data.gov key; the same one leads:congress uses).
 */
import 'dotenv/config';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import path from 'node:path';
import { turnsBy, isSenateGranule, recordSurname, SPEECH_AXIS } from './lib/crec-turns.mjs';

const args = process.argv.slice(2);
const flag = (n, d) => {
  const a = args.find((x) => x.startsWith(`--${n}=`));
  return a ? a.slice(n.length + 3) : d;
};

const namesFile = flag('names');
const outdir = flag('out');
const depth = Number(flag('depth', 25));
const days = (flag('days', '') || '').split(',').filter(Boolean);

if (!namesFile || !outdir) {
  console.error('usage: floor-statement-sweep.mjs --names=<file> --out=<dir> [--depth=N] [--days=a,b]');
  process.exit(1);
}
const KEY = process.env.CONGRESS_API_KEY;
if (!KEY) {
  console.error('floor-statement-sweep: CONGRESS_API_KEY is not set. Nothing was measured; this is not a pass.');
  process.exit(1);
}

const cacheDir = path.join(outdir, '.crec-cache');
mkdirSync(cacheDir, { recursive: true });

// A citation must point at the page a reader and a verifier both fetch.
const publicUrl = (id) => `https://www.govinfo.gov/content/pkg/${id.slice(0, id.indexOf('-pt'))}/html/${id}.htm`;

const plain = (html) => String(html || '')
  .replace(/<[^>]+>/g, ' ')
  .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&nbsp;/g, ' ').replace(/&quot;/g, '"').replace(/&#39;/g, "'")
  .replace(/[ \t]+/g, ' ');

async function granule(id) {
  const f = path.join(cacheDir, `${id}.htm`);
  if (existsSync(f)) return readFileSync(f, 'utf8');
  const r = await fetch(publicUrl(id), { headers: { 'User-Agent': 'EV-Compass research' } });
  if (!r.ok) return null;
  const t = await r.text();
  writeFileSync(f, t);
  return t;
}

async function search(query, mark = '*') {
  // Shell quoting mangles this body; it is built here for that reason.
  const r = await fetch(`https://api.govinfo.gov/search?api_key=${KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, pageSize: 25, offsetMark: mark, sorts: [{ field: 'publishdate', sortOrder: 'DESC' }] }),
  });
  const text = await r.text();
  try {
    const j = JSON.parse(text);
    return j.message ? { error: j.message } : j;
  } catch {
    return { error: `${r.status} ${text.slice(0, 160)}` };
  }
}

const names = readFileSync(namesFile, 'utf8').split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
const bySurname = new Map(names.map((n) => [recordSurname(n), n]));
const found = new Map(names.map((n) => [n, new Map()]));

const record = (name, id, date, turn) => {
  const flat = turn.body.replace(/\s+/g, ' ').trim();
  const i = flat.search(SPEECH_AXIS);
  const key = `${id}|${flat.slice(0, 60)}`;
  if (found.get(name).has(key)) return;
  found.get(name).set(key, {
    date, granuleId: id, url: publicUrl(id),
    asylumMentions: turn.asylumMentions, turnChars: flat.length,
    quote: flat.slice(Math.max(0, i - 350), i + 750),
  });
};

if (days.length) {
  // Whole debate days. On a day the chamber argued the question, one granule can
  // carry several members, where a per-senator search spends a fetch on at most one.
  for (const day of days) {
    let offset = 0, ids = [];
    for (;;) {
      const r = await fetch(`https://api.govinfo.gov/packages/CREC-${day}/granules?offset=${offset}&pageSize=100&api_key=${KEY}`);
      if (!r.ok) break;
      const j = await r.json();
      ids = ids.concat((j.granules || []).map((g) => g.granuleId).filter(isSenateGranule));
      offset += 100;
      if (offset >= (j.count || 0)) break;
    }
    let n = 0;
    for (const id of ids) {
      const html = await granule(id);
      if (!html) continue;
      const text = plain(html);
      for (const [sur, name] of bySurname) {
        for (const t of turnsBy(text, sur)) {
          if (!t.onAxis) continue;
          record(name, id, day, t);
          n++;
        }
      }
    }
    console.log(`${day}: ${ids.length} senate granules, ${n} on-axis turn(s)`);
  }
} else {
  for (const name of names) {
    const sur = recordSurname(name);
    let mark = '*', read = 0, hits = 0;
    while (read < depth) {
      const r = await search(`collection:CREC AND "${sur}" AND asylum`, mark);
      if (r.error) { console.log(`!! ${name}: ${r.error}`); break; }
      const res = (r.results || []).filter((x) => isSenateGranule(x.granuleId));
      if (!res.length && !r.offsetMark) break;
      for (const x of res) {
        if (read >= depth) break;
        read++;
        const html = await granule(x.granuleId);
        if (!html) continue;
        for (const t of turnsBy(plain(html), sur)) {
          if (!t.onAxis) continue;
          record(name, x.granuleId, x.dateIssued, t);
          hits++;
        }
      }
      mark = r.offsetMark;
      if (!mark) break;
    }
    console.log(`${name.padEnd(24)} ${String(read).padStart(3)} senate granules read | ${hits} on-axis turn(s)`);
  }
}

const rows = names.map((name) => {
  const hits = [...found.get(name).values()].sort((a, b) => b.asylumMentions - a.asylumMentions || (a.date < b.date ? 1 : -1));
  return { name, turns: hits.length, hits };
});
mkdirSync(outdir, { recursive: true });
writeFileSync(path.join(outdir, 'evidence.json'), JSON.stringify(rows, null, 1));

const covered = rows.filter((r) => r.turns).length;
console.log(`\n${covered} of ${names.length} have at least one on-axis speaking turn.`);
console.log('none:', rows.filter((r) => !r.turns).map((r) => r.name).join(', ') || '(all covered)');
console.log('\n🔴 These are candidate passages, not chairs. Read the turn, then choose a rung.');
