#!/usr/bin/env node
/**
 * miamidade-matter-detail.mjs — open a batch of leads and read who actually owns them.
 *
 * The third leg of the Miami-Dade toolchain. miamidade-sponsorship-leads.mjs finds
 * candidate instruments, miamidade-voting-record.mjs finds recorded votes, and this
 * opens the matter page — the only place that settles **attribution** and carries
 * the operative title.
 *
 * ── 🔴 WHY THIS EXISTS: THE SPONSOR REPORT IS NOT PROOF OF SPONSORSHIP ───────
 *
 * A matter appears in a commissioner's sponsor report for reasons including
 * "routed through their office". Two real cases, both caught the hard way:
 *
 *   · 261305 SAME DAY PERMIT PROGRAM sits in Bastien's report; its page reads
 *     "Sponsors: Anthony Rodriguez, Prime Sponsor"
 *   · R-678-26 sits in Steinberg's and Garcia's reports; it is Regalado's prime
 *     sponsorship and they are co-sponsors
 *
 * Reading a chair off the report alone credits people with each other's work.
 *
 * ── 🔴🔴 EVERY SPONSOR, NOT THE FIRST ────────────────────────────────────────
 *
 * Each sponsor sits in its OWN <tr>/<font> after the "Sponsors:" label. A
 * single-<font> regex returns exactly one name on every matter ever fetched —
 * a uniform answer, which is a broken detector until controlled. R-191-26 in
 * fact carries four: Cohen Higgins as Prime, plus Garcia, Lopez and Steinberg as
 * Co-Sponsors, and missing them nearly cost two correct rows.
 *
 * The role matters as much as the name. Prime and Co-Prime are initiative;
 * Co-Sponsor is endorsement; and an item with a department in `requester` and a
 * commissioner as sponsor may be the administration's work carried by that
 * member.
 *
 * ── THE URL NEEDS THREE PARAMS AND A YEAR FOLDER ─────────────────────────────
 *
 * matter.asp?matter=N is the citable form but 302s to a 492-byte JavaScript
 * bounce page, so a naive fetch reads as an empty record. The report wants
 * &file=false&fileAnalysis=false&yearFolder=Y20NN, the year taken from the
 * matter number's first two digits (251003 -> Y2025).
 *
 * RUN: node scripts/miamidade-matter-detail.mjs --from=data/stance-research/miamidade-sponsorship-leads.jsonl --topic=housing
 *      node scripts/miamidade-matter-detail.mjs --matters=241888,231881,260967
 *      node scripts/miamidade-matter-detail.mjs --from=... --topic=housing --resume
 *
 * No database and no API key.
 */
import { writeFileSync, appendFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';

const BASE = 'https://www.miamidade.gov/govaction';
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

const args = process.argv.slice(2);
const flag = (n) => { const h = args.find((a) => a.startsWith(`--${n}=`)); return h ? h.slice(n.length + 3) : null; };
const from = flag('from');
const topic = flag('topic');
const mattersArg = flag('matters');
const outFile = flag('out') ?? `data/stance-research/miamidade-matter-detail${topic ? '-' + topic : ''}.jsonl`;
const RESUME = args.includes('--resume');

const clean = (s) => s
  .replace(/<br\s*\/?>/gi, '\n').replace(/<[^>]+>/g, '')
  .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&#8217;/g, "'")
  .replace(/&#8220;|&#8221;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
  .replace(/\s+/g, ' ').trim();

/** A labelled field whose value sits in the SAME cell. */
export function field(html, label) {
  const m = new RegExp(`<strong>\\s*${label}:\\s*</strong>([\\s\\S]*?)</td>`, 'i').exec(html);
  return m ? clean(m[1]) : '';
}

/** A labelled field whose value sits in the NEXT cell — Title is one. */
export function nextCell(html, label) {
  const m = new RegExp(`<strong>\\s*${label}:\\s*</strong>[\\s\\S]*?</td>\\s*<td[^>]*>([\\s\\S]*?)</td>`, 'i').exec(html);
  return m ? clean(m[1]) : '';
}

/**
 * EVERY sponsor, with their role. See the header — this is the field that
 * settles attribution, and the reason this file exists.
 */
export function parseSponsors(html) {
  const lab = /<strong>\s*Sponsors:\s*<\/strong>/i.exec(html);
  if (!lab) return [];
  let tail = html.slice(lab.index + lab[0].length, lab.index + lab[0].length + 6000);
  for (const stop of ['Sunset Provision', 'Registered Lobbyist', 'Legislative History']) {
    const i = tail.indexOf(stop);
    if (i > -1) tail = tail.slice(0, i);
  }
  const out = [];
  for (const m of tail.matchAll(/<font[^>]*>([\s\S]*?)<\/font>/gi)) {
    const v = clean(m[1]);
    if (!v || !/sponsor/i.test(v)) continue;
    const parts = /^(.*?),\s*((?:Co-)?Prime Sponsor|Co-Sponsor|Sponsor)\s*$/i.exec(v);
    out.push(parts ? { name: parts[1].trim(), role: parts[2].trim() } : { name: v, role: null });
  }
  return out;
}

/** Recorded board actions: {body, date, action, pass_fail}. */
export function parseBoardActions(html) {
  const out = [];
  for (const tr of html.matchAll(/<tr>([\s\S]*?)<\/tr>/gi)) {
    const cells = [...tr[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map((c) => clean(c[1]));
    if (cells.length >= 8 && cells[0] && cells[3] && /\d{1,2}\/\d{1,2}\/\d{4}/.test(cells[1])) {
      out.push({ body: cells[0], date: cells[1], action: cells[3], pass_fail: cells[7] || null });
    }
  }
  return out;
}

export function parseMatter(html, matterId) {
  const sponsors = parseSponsors(html);
  const prime = sponsors.filter((s) => s.role && /prime/i.test(s.role)).map((s) => s.name);
  return {
    matter_id: matterId,
    file_type: field(html, 'File Type') || null,
    status: field(html, 'Status') || null,
    reference: field(html, 'Reference') || null,
    file_name: field(html, 'File Name') || null,
    requester: field(html, 'Requester') || null,
    agenda_date: field(html, 'Agenda Date') || null,
    final_action: field(html, 'Final Action') || null,
    title: nextCell(html, 'Title') || field(html, 'Title') || null,
    sponsors,
    prime_sponsors: prime,
    // An item the administration asked for, carried by a member, is weaker
    // evidence of that member's own position than one they originated.
    requester_is_department: !!field(html, 'Requester') && !/^NONE$/i.test(field(html, 'Requester')),
    board_actions: parseBoardActions(html),
    source_url: `${BASE}/matter.asp?matter=${matterId}`,
  };
}

async function fetchMatter(id) {
  const year = 'Y20' + String(id).slice(0, 2);
  const url = `${BASE}/matter.asp?matter=${id}&file=false&fileAnalysis=false&yearFolder=${year}`;
  const r = await fetch(url, { headers: { 'User-Agent': UA } });
  if (!r.ok) throw new Error(`HTTP ${r.status} for matter ${id}`);
  return new TextDecoder('utf-8').decode(await r.arrayBuffer());
}

async function main() {
  let ids = [];
  if (mattersArg) ids = mattersArg.split(',').map((s) => s.trim()).filter(Boolean);
  else if (from) {
    const seen = new Set();
    for (const line of readFileSync(from, 'utf8').split('\n').filter(Boolean)) {
      const rec = JSON.parse(line);
      for (const lead of rec.leads ?? rec.votes ?? []) {
        if (topic && !(lead.topics ?? []).includes(topic)) continue;
        seen.add(lead.matter_id);
      }
    }
    ids = [...seen];
  } else { console.error('need --from=<leads.jsonl> or --matters=a,b,c'); process.exit(1); }

  mkdirSync(dirname(outFile), { recursive: true });
  const done = new Set();
  if (RESUME && existsSync(outFile)) {
    for (const line of readFileSync(outFile, 'utf8').split('\n').filter(Boolean)) {
      try { done.add(JSON.parse(line).matter_id); } catch { /* partial */ }
    }
    console.log(`resuming — ${done.size} already read`);
  } else if (!RESUME) writeFileSync(outFile, '');

  console.log(`${ids.length} matter(s) to read${topic ? ` for topic=${topic}` : ''}`);
  let n = 0, failed = 0;
  for (const id of ids) {
    if (done.has(id)) continue;
    try {
      const rec = parseMatter(await fetchMatter(id), id);
      appendFileSync(outFile, JSON.stringify(rec) + '\n');
      n++;
      if (n % 20 === 0) console.log(`  ${n}/${ids.length}…`);
    } catch (e) { failed++; console.warn(`  ⚠ ${id}: ${e.message}`); }
  }
  console.log(`read ${n}, failed ${failed} -> ${outFile}`);
  console.log('🔴 prime_sponsors is the attribution. A name in a sponsor REPORT is not one.');
}

if (/miamidade-matter-detail\.mjs$/.test(process.argv[1] ?? '')) {
  main().catch((e) => { console.error(e); process.exit(1); });
}
