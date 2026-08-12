#!/usr/bin/env node
/**
 * Turn the on-topic candidate lists into a READING QUEUE short enough to actually read.
 *
 * 🔑 THE BROAD NET IS FOR RECALL; THIS IS FOR PRECISION. Benson's healthcare net matched 308 bills.
 * Nobody reads 308, and skimming them is how a plausible-but-wrong citation gets shipped. Two signals
 * cut it down without hiding anything:
 *   · LEAD SPONSORSHIP. The corpus records each bill's FIRST sponsor. Being the lead sponsor of a bill
 *     is a position; being one of 30 co-sponsors on a consensus bill is much weaker evidence.
 *   · A CORE pattern per topic, tighter than the recall net. "Health Occupations - Podiatrist Licensure"
 *     matches the healthcare net and says nothing about a HEALTHCARE ACCESS chair, which is about
 *     coverage and affordability.
 *
 * ⚠ NOTHING IS DROPPED SILENTLY — every row reports how many candidates were ranked below the cut, and
 * the full list stays in the input JSON. A rank is a reading order, not a verdict.
 *
 * ⚠ A title is still only a title. Direction ("Rent Stabilization - PREEMPTION of Local Authority")
 * and whether the member is really the lead sponsor are settled by opening the bill page, not here.
 */
import fs from 'node:fs';
import { TOPIC_CORE as CORE } from './lib/md-topic-nets.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const TOP = parseInt(flag('--top', '8'), 10);
const ONLY_TOPIC = flag('--topic');

const R = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-md-member-legislation.json', 'utf8'));

/** tighter than the recall net: what the CHAIR is actually about */

const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)\.?$/i, '').trim().split(/\s+/).pop().toLowerCase();

const corpus = JSON.parse(fs.readFileSync('C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/mdcorpus/md-bill-corpus.json', 'utf8'));
const leadOf = {};
for (const b of corpus.bills) if (b.title && b.title.length > 5) leadOf[`${b.session}:${b.slug}`] = b.sponsor || '';

let rows = R.rows;
if (ONLY_TOPIC) rows = rows.filter((r) => r.topic.startsWith(ONLY_TOPIC));

for (const r of rows) {
  const sur = surnameOf(r.name);
  const core = CORE[r.topic];
  const scored = r.candidates.map((c) => {
    const lead = new RegExp(`^(Delegate|Senator)s?\\s+${sur}$`, 'i').test((leadOf[c.key] || '').trim());
    return { ...c, lead, isCore: core.test(c.title) };
  }).sort((a, b) => (b.lead - a.lead) || (b.isCore - a.isCore) || b.session.localeCompare(a.session));

  const shown = scored.slice(0, TOP);
  const nLead = scored.filter((c) => c.lead).length;
  const nCore = scored.filter((c) => c.isCore).length;
  console.log(`\n${'='.repeat(104)}`);
  console.log(`${r.name} | ${r.topic} | chair ${r.chair}`);
  console.log(`  claim: ${r.reasoning}`);
  console.log(`  ${r.n_on_topic} on-topic (${nLead} lead-sponsored, ${nCore} core); showing top ${shown.length}, ${Math.max(0, scored.length - shown.length)} ranked below the cut`
    + (r.sessions_unreadable.length ? `; ⚠ ${r.sessions_unreadable.length} session(s) UNREADABLE (${r.sessions_unreadable.join(',')})` : ''));
  for (const c of shown) {
    console.log(`   ${c.lead ? 'LEAD' : '    '} ${c.isCore ? 'core' : '    '} ${c.session} ${c.number}  ${c.title.slice(0, 96)}`);
  }
}
