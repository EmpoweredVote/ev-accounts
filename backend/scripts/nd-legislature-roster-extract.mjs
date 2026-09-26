#!/usr/bin/env node
/**
 * nd-legislature-roster-extract.mjs — Knight program, wave ND-2.
 *
 * Extracts the North Dakota Legislative Assembly roster from the Legislative Branch's own
 * `members-by-district` accordion, for one or more sessions of the 69th Assembly.
 *
 * 🔴 THERE ARE THREE ROSTERS, NOT ONE. ndlegis.gov publishes a separate member list for the
 * Regular Session, the January 2026 Special Session and the September 2026 Special Session.
 * They are snapshots of who sat at each convening, so the DIFF between them is a change-check
 * the state itself performed — but it is a change-check with gaps, because a member who left
 * between two special sessions appears in neither diff boundary. It is a starting point, not
 * a substitute for reading the member pages.
 *
 * 🔴 A 404 HERE IS A 70 KB STYLED PAGE. `/assembly/69-2025/members` returns HTTP 404 with a
 * full-size body, so size is not a validity signal on this host. Judge by status code, and
 * assert the parse found the number of districts it expected.
 *
 * Usage:
 *   node scripts/nd-legislature-roster-extract.mjs --out <dir> [--sessions regular,special,special-2]
 */
import fs from 'fs';
import path from 'path';
import https from 'https';

const argv = process.argv.slice(2);
const argOf = (f) => { const i = argv.indexOf(f); return i >= 0 ? argv[i + 1] : undefined; };
const OUT = argOf('--out') ?? '.';
const SESSIONS = (argOf('--sessions') ?? 'regular,special,special-2').split(',');

const LABEL = {
  regular: '69th Regular Session',
  special: '69th Jan 2026 Special Session',
  'special-2': '69th Sep 2026 Special Session',
};

/** The map ND-1 proved: 47 districts, District 4 split into House subdistricts 4A/4B. */
const EXPECTED_DISTRICTS = 47;
const EXPECTED_SENATORS = 47;
const EXPECTED_REPRESENTATIVES = 94;

function get(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: { 'User-Agent': 'ev-accounts/nd-slice12' } }, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          res.resume();
          const next = res.headers.location.startsWith('http')
            ? res.headers.location
            : new URL(res.headers.location, url).toString();
          return get(next).then(resolve, reject);
        }
        if (res.statusCode !== 200) {
          res.resume();
          return reject(new Error(`${url} -> HTTP ${res.statusCode}`));
        }
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (c) => (body += c));
        res.on('end', () => resolve(body));
      })
      .on('error', reject);
  });
}

const strip = (s) => s.replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();

/**
 * 🔴 HTML ENTITIES ARE NOT OPTIONAL. MN-2 found eight member names stored as `P&#233;rez-Vega`;
 * a raw capture writes mojibake into a voter-facing field. Decode named and numeric refs.
 */
function decodeEntities(s) {
  return s
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#039;|&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}

function parse(html, session) {
  // Each district is one accordion panel; members are <li class="member-item ...">.
  const panels = [
    ...html.matchAll(
      /<button[^>]*class="ac-trigger[^"]*"[^>]*>([^<]*District[^<]*)<\/button>\s*<\/h3>\s*<div class="ac-panel[^"]*"[^>]*>([\s\S]*?)<\/ul>/g,
    ),
  ];
  const members = [];
  const districtsSeen = [];
  for (const [, headingRaw, panel] of panels) {
    const heading = decodeEntities(strip(headingRaw));
    const dm = /District\s+(\d+[A-Z]?)/i.exec(heading);
    if (!dm) continue;
    const district = dm[1].toUpperCase();
    districtsSeen.push(district);
    for (const [, item] of panel.matchAll(/<li class="member-item[^"]*">([\s\S]*?)<\/li>/g)) {
      const bio = /href="(\/biography\/[^"]+)"/.exec(item)?.[1] ?? null;
      const photo = /<img[^>]+src="([^"]+)"/.exec(item)?.[1] ?? null;
      const chamber = decodeEntities(strip(/<div class="strong member-chamber">([\s\S]*?)<\/div>/.exec(item)?.[1] ?? ''));
      const name = decodeEntities(strip(/<div class="strong member-name">([\s\S]*?)<\/div>/.exec(item)?.[1] ?? ''));
      // `District 1 | <span class="sr-only">Republican</span>R`
      const districtBlock = /<div class="district">([\s\S]*?)<\/div>/.exec(item)?.[1] ?? '';
      const partyLong = decodeEntities(strip(/<span class="sr-only">([\s\S]*?)<\/span>/.exec(districtBlock)?.[1] ?? ''));
      const memberDistrict = /District\s+(\d+[A-Z]?)/i.exec(decodeEntities(strip(districtBlock)))?.[1]?.toUpperCase() ?? null;
      if (!name || !chamber) continue;
      members.push({
        session,
        district,
        // 🔴 The member's OWN district label, kept separately from the accordion heading.
        // House subdistricts 4A/4B are the one place these can legitimately differ.
        member_district: memberDistrict,
        chamber,
        name,
        party: partyLong || null,
        bio_url: bio ? `https://ndlegis.gov${bio}` : null,
        photo_url: photo ? `https://ndlegis.gov${photo.split('?')[0]}` : null,
      });
    }
  }
  return { members, districtsSeen };
}

const results = {};
for (const session of SESSIONS) {
  const url = `https://ndlegis.gov/assembly/69-2025/${session}/members/members-by-district`;
  const html = await get(url);
  const { members, districtsSeen } = parse(html, session);
  const senators = members.filter((m) => /senator/i.test(m.chamber));
  const reps = members.filter((m) => /representative/i.test(m.chamber));
  const other = members.filter((m) => !/senator|representative/i.test(m.chamber));
  console.log(
    `${LABEL[session] ?? session}: ${districtsSeen.length} district panels, ` +
    `${members.length} members — ${senators.length} senators, ${reps.length} representatives` +
    (other.length ? `, ⚠ ${other.length} with an unrecognised chamber: ${[...new Set(other.map((o) => o.chamber))].join(', ')}` : ''),
  );
  if (districtsSeen.length !== EXPECTED_DISTRICTS) {
    console.log(`  🔴 expected ${EXPECTED_DISTRICTS} district panels, parsed ${districtsSeen.length} — the parser or the page changed.`);
  }
  if (senators.length !== EXPECTED_SENATORS || reps.length !== EXPECTED_REPRESENTATIVES) {
    console.log(`  🔴 expected ${EXPECTED_SENATORS} senators and ${EXPECTED_REPRESENTATIVES} representatives.`);
  }
  const subdistricts = [...new Set(members.map((m) => m.member_district).filter((d) => d && /[A-Z]$/.test(d)))].sort();
  console.log(`  subdistricts named by members: ${subdistricts.length ? subdistricts.join(', ') : '(none)'}`);
  const perDistrict = {};
  for (const m of members) (perDistrict[m.district] ??= []).push(m);
  const odd = Object.entries(perDistrict).filter(([, ms]) => ms.length !== 3);
  console.log(`  districts not holding exactly 3 members (1 senator + 2 reps): ${odd.length ? odd.map(([d, ms]) => `${d}=${ms.length}`).join(', ') : 'none'}`);
  results[session] = members;
  fs.mkdirSync(OUT, { recursive: true });
  fs.writeFileSync(path.join(OUT, `nd-roster-${session}.json`), JSON.stringify(members, null, 2));
}

// ── The diff between sessions: the state's own change-check, with its gaps stated ──────────
const key = (m) => `${m.chamber}|${m.district}|${m.name}`;
const order = SESSIONS.filter((s) => results[s]);
for (let i = 1; i < order.length; i++) {
  const a = new Set(results[order[i - 1]].map(key));
  const b = new Set(results[order[i]].map(key));
  const gone = [...a].filter((k) => !b.has(k));
  const arrived = [...b].filter((k) => !a.has(k));
  console.log(`\nDIFF ${LABEL[order[i - 1]] ?? order[i - 1]} → ${LABEL[order[i]] ?? order[i]}`);
  console.log(`  left:    ${gone.length ? gone.join(' · ') : '(none)'}`);
  console.log(`  arrived: ${arrived.length ? arrived.join(' · ') : '(none)'}`);
}
console.log(`\nwrote ${order.length} roster file(s) to ${OUT}`);
