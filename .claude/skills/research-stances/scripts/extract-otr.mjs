#!/usr/bin/env node
/**
 * extract-otr.mjs — On the Record transcript extractor (tier-1 source discovery).
 *
 * Given a race, pulls every candidate's speaker-attributed turns across all of the
 * race's On the Record sources into one markdown file per candidate. Each source
 * section is headed with its YouTube URL and its OTR page URL so a researcher (or
 * the audit's source check) can trace and verify every quote.
 *
 * Pure Node built-ins (global fetch + node:fs/node:path) — no npm deps, no DB.
 * Run it from anywhere:
 *
 *   node .claude/skills/research-stances/scripts/extract-otr.mjs --race <race_id>
 *   node .../extract-otr.mjs --race <id> --out /abs/dir --base https://accounts-api.empowered.vote
 *
 * The OTR public API (authoritative transcript source):
 *   GET /api/people                              -> [{ politicianId, name, ... }]
 *   GET /api/meetings                            -> [{ id, title, sourceUrl, videoUrl, raceIds:[...], segmentCount, ... }]
 *   GET /api/meetings/{id}/transcript?page=N     -> { segments:[{ speakerName, politicianSlug, text, startTime, ... }], page, totalCount }
 *
 * NOTE: in the transcript payload `politicianSlug` carries the politician's UUID,
 * so segments are matched to candidates by that id (falling back to speakerName).
 */
import { writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join } from 'node:path';

const API_BASE = 'https://accounts-api.empowered.vote';
const OTR_PAGE_BASE = 'https://ontherecord.empowered.vote/meetings';
const PAGE_SIZE = 200; // segments per transcript page

function parseArgs(argv) {
  const a = { base: API_BASE };
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    if (k === '--race') a.race = argv[++i];
    else if (k === '--out') a.out = argv[++i];
    else if (k === '--base') a.base = argv[++i];
    else if (k === '--candidates') a.candidates = argv[++i].split(',').map(s => s.trim()).filter(Boolean);
  }
  return a;
}

async function getJSON(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`GET ${url} -> ${res.status} ${res.statusText}`);
  return res.json();
}

function youtubeUrl(m) {
  if (m.sourceUrl && /youtu/.test(m.sourceUrl)) return m.sourceUrl;
  if (m.audioSource && /youtu/.test(m.audioSource)) return m.audioSource;
  if (m.videoUrl) return `https://www.youtube.com/watch?v=${m.videoUrl}`;
  return m.sourceUrl || '(no video url)';
}

// Merge consecutive segments from the same speaker into one turn.
function toTurns(segments) {
  const turns = [];
  for (const s of segments) {
    const last = turns[turns.length - 1];
    const key = s.politicianSlug || s.speakerName;
    if (last && last._key === key) {
      last.text += ' ' + (s.text || '').trim();
    } else {
      turns.push({ _key: key, politicianSlug: s.politicianSlug || null,
        speakerName: s.speakerName || 'Unknown', startTime: s.startTime, text: (s.text || '').trim() });
    }
  }
  return turns;
}

async function fetchAllSegments(base, meetingId) {
  const first = await getJSON(`${base}/api/meetings/${meetingId}/transcript?page=1`);
  const total = first.totalCount ?? (first.segments || []).length;
  let segs = first.segments || [];
  const pages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  for (let p = 2; p <= pages; p++) {
    const pg = await getJSON(`${base}/api/meetings/${meetingId}/transcript?page=${p}`);
    segs = segs.concat(pg.segments || []);
  }
  return segs;
}

function fmtTime(t) {
  if (t == null) return '';
  const s = Math.floor(t), m = Math.floor(s / 60), sec = s % 60;
  return `[${m}:${String(sec).padStart(2, '0')}]`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.race) {
    console.error('Usage: extract-otr.mjs --race <race_id> [--out <dir>] [--candidates id,id] [--base <url>]');
    process.exit(2);
  }
  const here = dirname(fileURLToPath(import.meta.url));                 // .../research-stances/scripts
  const evRoot = resolve(here, '..', '..', '..', '..');                 // .../ev-accounts
  const outDir = args.out
    ? resolve(args.out)
    : join(evRoot, 'backend', 'data', 'stance-research', 'otr-transcripts', args.race);
  mkdirSync(outDir, { recursive: true });

  console.log(`OTR extract for race ${args.race}`);
  const [people, meetings] = await Promise.all([
    getJSON(`${args.base}/api/people`),
    getJSON(`${args.base}/api/meetings`),
  ]);
  const nameById = new Map(people.map(p => [p.politicianId, p.name]));

  const sources = meetings.filter(m => (m.raceIds || []).includes(args.race));
  if (!sources.length) {
    console.log('No OTR sources found for this race. (Race may not be on the platform yet.)');
    console.log('OTR_SOURCES=0');
    return;
  }
  console.log(`Found ${sources.length} OTR source(s). Fetching transcripts…`);

  // candidateId -> { name, sources: [{ meeting, turns }] }
  const byCandidate = new Map();
  const restrict = args.candidates ? new Set(args.candidates) : null;

  for (const m of sources) {
    let segments;
    try { segments = await fetchAllSegments(args.base, m.id); }
    catch (e) { console.error(`  ! ${m.id} transcript fetch failed: ${e.message}`); continue; }
    const turns = toTurns(segments);
    // group this source's turns by candidate id
    const perCand = new Map();
    for (const t of turns) {
      const cid = t.politicianSlug;
      if (!cid) continue;                       // only speaker-attributed (tracked politician) turns
      if (restrict && !restrict.has(cid)) continue;
      if (!perCand.has(cid)) perCand.set(cid, []);
      perCand.get(cid).push(t);
    }
    for (const [cid, cturns] of perCand) {
      if (!byCandidate.has(cid)) byCandidate.set(cid, { name: nameById.get(cid) || cturns[0].speakerName || cid, sources: [] });
      byCandidate.get(cid).sources.push({ meeting: m, turns: cturns });
    }
    console.log(`  ✓ ${m.title || m.id} — ${perCand.size} candidate(s), ${turns.length} turns`);
  }

  if (!byCandidate.size) {
    console.log('Sources found but no speaker-attributed candidate turns. Nothing written.');
    console.log('OTR_SOURCES=' + sources.length + ' OTR_CANDIDATES=0');
    return;
  }

  const written = [];
  for (const [cid, data] of byCandidate) {
    const slug = (data.name || cid).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || cid;
    const file = join(outDir, `${slug}.md`);
    const lines = [`# On the Record — ${data.name} (${cid})`, `Race: ${args.race}`,
      `Sources: ${data.sources.length}`, ''];
    for (const { meeting, turns } of data.sources) {
      lines.push(`## ${meeting.title || '(untitled source)'}`);
      lines.push(`- YouTube: ${youtubeUrl(meeting)}`);
      lines.push(`- OTR page: ${OTR_PAGE_BASE}/${meeting.id}`);
      lines.push(`- Date: ${meeting.date || 'n/a'} · Type: ${meeting.meetingType || meeting.eventKind || 'n/a'}`);
      lines.push('');
      for (const t of turns) lines.push(`${fmtTime(t.startTime)} ${t.text}`);
      lines.push('');
    }
    writeFileSync(file, lines.join('\n'));
    written.push({ name: data.name, cid, file, sources: data.sources.length });
    console.log(`  → wrote ${file} (${data.sources.length} sources)`);
  }
  console.log(`\nDone. ${written.length} candidate file(s) in ${outDir}`);
  console.log('OTR_SOURCES=' + sources.length + ' OTR_CANDIDATES=' + written.length);
}

main().catch(e => { console.error('FATAL:', e.message); process.exit(1); });
