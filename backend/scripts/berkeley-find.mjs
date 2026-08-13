#!/usr/bin/env node
/**
 * Search the Berkeley council corpus. Read-only.
 *   node scripts/berkeley-find.mjs "<regex>" [--member Name] [--full]
 *
 * ⚠ A keyword hit is a READING QUEUE entry, never a finding: on-topic by VOCABULARY is not on-topic
 * by RATIONALE, and the seated chair must be described by the instrument, not merely touched by it.
 */
import fs from 'node:fs';
import path from 'node:path';

const CACHE = path.join(process.env.TEMP || '/tmp', 'ev-stance-cache', 'berkeley');
const items = JSON.parse(fs.readFileSync(path.join(CACHE, 'berkeley-items.json'), 'utf8'));
const argv = process.argv.slice(2);
const flag = (n) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : null; };
const re = new RegExp(argv[0], 'i');
const member = flag('--member');
const FULL = argv.includes('--full');

let hits = items.filter((i) => re.test(i.title) || re.test(i.text));
if (member) hits = hits.filter((i) => i.roles[member] || new RegExp(`\\b${member}\\b`).test(i.vote));

console.log(`${hits.length} item(s)\n`);
for (const h of hits) {
  const roles = Object.entries(h.roles).map(([k, v]) => `${k}:${v}`).join(' ');
  console.log(`── ${h.date}${h.agenda_only ? ' [AGENDA-ONLY: no outcome recorded]' : ''} #${h.item}`);
  console.log(`   ${h.title.replace(/ From:.*/, '').slice(0, 200)}`);
  if (h.from) console.log(`   FROM: ${h.from.slice(0, 200)}`);
  if (roles) console.log(`   ROLES: ${roles}`);
  if (h.action) console.log(`   ACTION: ${h.action.slice(0, 320)}`);
  if (h.vote) console.log(`   VOTE: ${h.vote.slice(0, 320)}`);
  if (FULL) console.log(`   TEXT: ${h.text.slice(0, 1800)}`);
  console.log();
}
