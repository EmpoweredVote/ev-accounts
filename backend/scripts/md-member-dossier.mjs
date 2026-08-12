#!/usr/bin/env node
/**
 * Fetch the shortlisted bills per row and pull what actually decides the citation: the SYNOPSIS
 * (direction) and the SPONSOR HYPERLINK (identity).
 *
 * 🔑 A TITLE CANNOT CARRY A CITATION. "Rent Stabilization - Preemption of Local Authority" is on
 * topic and points the opposite way; "Premium Cigar Lounge Alcoholic Beverages License" matched a
 * health net and means nothing at all. Only the synopsis settles what a bill does.
 *
 * 🔑 IDENTITY COMES FROM THE SLUG, NOT THE SURNAME. The bill page links every sponsor to
 * /Members/Details/<slug>; the landmark pass proved a surname alone credits the wrong Washington.
 * ⚠ Slugs rot — an older bill can link to a retired slug — so a missing slug is reported, never
 * silently treated as "not a sponsor".
 *
 * 🔴 Reads only. Emits dossiers to be READ.
 *   node scripts/md-member-dossier.mjs --out <dossier.json> [--per-row 4]
 */
import fs from 'node:fs';
import { TOPIC_CORE as CORE } from './lib/md-topic-nets.mjs';
import path from 'node:path';
import { UA, sponsorSlugs, sponsorsOf } from './lib/md-rollcall.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-md-member-dossier.json');
const PER_ROW = parseInt(flag('--per-row', '4'), 10);
const IN = flag('--in', 'data/stance-retirement/2026-08-12-md-member-legislation.json');

const CACHE = 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/mdcorpus';
const BILLS = path.join(CACHE, 'bill-cache');
fs.mkdirSync(BILLS, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));


const corpus = JSON.parse(fs.readFileSync(path.join(CACHE, 'md-bill-corpus.json'), 'utf8'));
const leadOf = {};
for (const b of corpus.bills) if (b.title && b.title.length > 5) leadOf[`${b.session}:${b.slug}`] = b.sponsor || '';
const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)\.?$/i, '').trim().split(/\s+/).pop().toLowerCase();

async function billHtml(slug, session) {
  const f = path.join(BILLS, `${slug}-${session}.html`);
  if (fs.existsSync(f) && fs.statSync(f).size > 5000) return fs.readFileSync(f, 'utf8');
  const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`, { headers: { 'User-Agent': UA } });
  const body = await res.text();
  await sleep(1100);
  if (!res.ok || body.length < 20000) return null;
  fs.writeFileSync(f, body);
  return body;
}
const textOf = (h) => h.replace(/<[^>]*>/g, ' ').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ');

const R = JSON.parse(fs.readFileSync(IN, 'utf8'));
const out = [];
for (const r of R.rows) {
  const sur = surnameOf(r.name);
  const core = CORE[r.topic];
  const ranked = r.candidates.map((c) => ({
    ...c,
    lead: new RegExp(`^(Delegate|Senator)s?\\s+${sur}$`, 'i').test((leadOf[c.key] || '').trim()),
    isCore: core ? core.test(c.title) : false,
  })).sort((a, b) => (b.lead - a.lead) || (b.isCore - a.isCore) || b.session.localeCompare(a.session));

  const picks = [];
  for (const c of ranked.slice(0, PER_ROW)) {
    const h = await billHtml(c.slug, c.session);
    if (!h) { picks.push({ ...c, error: 'bill page unavailable' }); continue; }
    const t = textOf(h);
    const i = t.indexOf('Synopsis');
    const synopsis = i > -1 ? t.slice(i + 8, i + 620).replace(/\s*Committees.*/, '').trim() : null;
    // ⚠ "Status" also appears in the site nav, and anchoring on the first hit returned menu text
    // ("Agendas Senate Index House Index Follow…") for every bill. Anchor AFTER the sponsor block.
    const sp = t.indexOf('Sponsored by');
    const j = sp > -1 ? t.indexOf('Status', sp) : -1;
    const status = j > -1 ? t.slice(j + 6, j + 130).replace(/\s*Analysis.*/, '').trim() : null;
    const slugs = sponsorSlugs(h);
    const mine = r.member_slug ? slugs.find((s) => s.slug === r.member_slug) : null;
    picks.push({ ...c, synopsis, status,
      sponsor_count: (sponsorsOf(h) || []).length,
      slug_confirms: !!mine, slug_label: mine ? mine.label : null,
      all_sponsor_slugs: slugs.map((s) => s.slug),
      lead_sponsor_field: leadOf[c.key] || null });
  }
  out.push({ ...r, candidates: undefined, n_candidates: r.candidates.length, picks });
  console.log(`  ${r.name} / ${r.topic}: ${picks.length} dossier(s)`);
}
fs.writeFileSync(OUT, JSON.stringify({ pass: 'MD member bill dossiers for reading', rows: out }, null, 1));
console.log(`wrote ${OUT}`);
