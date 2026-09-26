#!/usr/bin/env node
/**
 * build-ky-legislature-roster.mjs — Knight program, wave KY-2.
 *
 * Builds the Kentucky General Assembly roster — 100 House + 38 Senate = 138 seats — by reading
 * EVERY member's own profile page, and cross-checks it against two independent list sources.
 *
 * 🔴🔴 THE LRC GIS LAYER CARRIES A STALE ROSTER, AND KY-1 USED THAT SAME LAYER AS ITS GEOMETRY
 * AUTHORITY. `Ky_Legislative_Districts_WGS84WM` serves `Legislator`/`Full_Name` beside the
 * polygons. Its GEOMETRY was proven correct 138/138 against TIGER in KY-1. Its ROSTER is not:
 * measured 2026-09-26, Senate District 37 reads "Yates, David" while the chamber's own list and
 * Clemons' own profile both read **Gary Clemons**, "Senate 2026 - Present".
 * ▶ A SOURCE CAN BE AUTHORITATIVE FOR ONE FIELD AND STALE FOR ANOTHER. Proving a layer's geometry
 * says nothing about the attributes riding along with it. Never inherit trust across fields.
 *
 * 🔴 A LIST PAGE IS NOT A CHANGE-CHECK (MN-2's rule, and it earned itself again here). The two
 * list sources disagree on 6 of 138 seats; 5 are name-form variance and 1 is a different human
 * being. Only the member's OWN page settles which. So all 138 pages are read, every time.
 *
 * THE THREE SOURCES:
 *   A  LRC GIS layer          kygisserver.ky.gov   (District, Legislator, Full_Name, PIC_URL)
 *   B  chamber list pages     apps.legislature.ky.gov/Legislators/{h,s}members_district.html
 *   C  per-member profiles    legislature.ky.gov/Legislators/Pages/Legislator-Profile.aspx
 * C is the authority. A and B exist to make C's answers falsifiable.
 *
 * 🔴 THE PROFILE URL SCHEME OFFSETS THE SENATE BY 100. House district N is DistrictNumber=N;
 * Senate district N is DistrictNumber=100+N. So Senate 1 is 101 and Senate 38 is 138, and a
 * naive `DistrictNumber=<district>` silently fetches a HOUSE member for every Senate seat.
 * The script asserts the returned title (Representative vs Senator) against the chamber it asked
 * for, so that substitution cannot pass.
 *
 * ⚠ `Service` GIVES A YEAR, NOT A DAY — "House 2005 - Present". Kentucky publishes no start date
 * on these pages, so terms generated from this file are `year` precision unless a day is sourced
 * elsewhere. Do not invent a day: CLAUDE.md's honesty rule makes that a guess written as fact.
 *
 * ⚠ PARTY IS PARSED BUT NEVER WRITTEN. It exists here only to make the source diff legible.
 * Party is antipartisan in this schema — it lives on `races.primary_party`, never on a person or
 * an office.
 *
 * Usage:
 *   node scripts/build-ky-legislature-roster.mjs --out backend/data/seed-ky-2026 [--delay 400]
 * Exit: 0 all assertions passed; 1 otherwise.
 */
import fs from 'fs';
import path from 'path';
import https from 'https';

const argv = process.argv.slice(2);
const argOf = (f) => {
  const i = argv.indexOf(f);
  return i >= 0 ? argv[i + 1] : undefined;
};
const OUT = argOf('--out') ?? '.';
const DELAY_MS = Number(argOf('--delay') ?? 400);

const EXPECTED = { House: 100, Senate: 38 };
const SENATE_URL_OFFSET = 100;
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function get(url) {
  return new Promise((resolve, reject) => {
    const go = (u, depth = 0) => {
      if (depth > 5) return reject(new Error(`too many redirects: ${url}`));
      https
        .get(u, { headers: { 'User-Agent': UA } }, (res) => {
          if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
            res.resume();
            return go(new URL(res.headers.location, u).toString(), depth + 1);
          }
          if (res.statusCode !== 200) {
            res.resume();
            return reject(new Error(`HTTP ${res.statusCode} for ${u}`));
          }
          const chunks = [];
          res.on('data', (d) => chunks.push(d));
          res.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
        })
        .on('error', reject);
    };
    go(url);
  });
}

const decode = (s) =>
  s
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCharCode(parseInt(n, 16)));

const plain = (html) => {
  let t = html.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '');
  t = decode(t.replace(/<[^>]+>/g, ' '));
  return t.replace(/\s+/g, ' ').trim();
};

/** Departure language the chamber uses when a member has gone. Absence is not proof of presence —
 *  the `- Present` assertion below is what actually carries that. */
const DEPARTURE_MARKERS = [
  /\bresigned\b/i,
  /\bvacant\b/i,
  /\bvacancy\b/i,
  /\bdeceased\b/i,
  /\bpassed away\b/i,
  /\bno longer\b/i,
];

async function readProfile(chamber, district) {
  const dn = chamber === 'Senate' ? district + SENATE_URL_OFFSET : district;
  const url =
    `https://legislature.ky.gov/Legislators/Pages/Legislator-Profile.aspx?DistrictNumber=${dn}`;
  const raw = await get(url);
  const t = plain(raw);
  const m = t.match(/Legislator-Profile\s+(Representative|Senator)\s+(.*?)\s+\(([RDI])\)/);
  const svc = t.match(/\bService\b(.*?)\bCommittees\b/);
  const service = svc ? svc[1].trim() : '';
  return {
    chamber,
    district,
    urlDistrictNumber: dn,
    url,
    title: m ? m[1] : null,
    name: m ? m[2].trim() : null,
    party: m ? m[3] : null, // recorded for the diff only; never written to the database
    service,
    servicePresent: /-\s*Present\b/i.test(service),
    serviceStartYear: (service.match(/\b(19|20)\d{2}\b/) || [null])[0],
    departureHits: DEPARTURE_MARKERS.filter((re) => re.test(t)).map((re) => re.source),
    bytes: raw.length,
  };
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const rows = [];
  const failures = [];

  for (const chamber of ['House', 'Senate']) {
    for (let d = 1; d <= EXPECTED[chamber]; d++) {
      try {
        const r = await readProfile(chamber, d);
        rows.push(r);
        if (!r.name) failures.push(`${chamber} ${d}: no name parsed from ${r.url}`);
        // 🔴 The offset guard: asking for Senate N must return a Senator, not a Representative.
        const wantTitle = chamber === 'Senate' ? 'Senator' : 'Representative';
        if (r.title !== wantTitle) {
          failures.push(
            `${chamber} ${d}: page titles the member '${r.title}', expected '${wantTitle}' ` +
              `(DistrictNumber=${r.urlDistrictNumber}) — the Senate +100 offset may be wrong`,
          );
        }
        if (!r.servicePresent) {
          failures.push(
            `${chamber} ${d}: Service does not end in '- Present' (${JSON.stringify(r.service)}) ` +
              `— this seat may have turned over`,
          );
        }
        if (r.departureHits.length) {
          failures.push(
            `${chamber} ${d}: departure language on the page: ${r.departureHits.join(', ')}`,
          );
        }
      } catch (e) {
        failures.push(`${chamber} ${d}: ${e.message}`);
      }
      process.stdout.write(
        `\r  read ${rows.length}/${EXPECTED.House + EXPECTED.Senate} profiles…`,
      );
      await sleep(DELAY_MS);
    }
  }
  process.stdout.write('\n');

  const counts = {
    House: rows.filter((r) => r.chamber === 'House').length,
    Senate: rows.filter((r) => r.chamber === 'Senate').length,
  };
  for (const c of ['House', 'Senate']) {
    if (counts[c] !== EXPECTED[c]) failures.push(`${c}: read ${counts[c]}, expected ${EXPECTED[c]}`);
  }

  // A person holding two seats would be a real defect, not a name clash — assert it.
  const byName = new Map();
  for (const r of rows) {
    if (!r.name) continue;
    byName.set(r.name, (byName.get(r.name) ?? 0) + 1);
  }
  for (const [name, n] of byName) {
    if (n > 1) failures.push(`'${name}' appears on ${n} seats`);
  }

  const outFile = path.join(OUT, 'ky-roster-profiles.json');
  fs.writeFileSync(
    outFile,
    JSON.stringify(
      { measured: new Date().toISOString(), counts, rows, failures },
      null,
      2,
    ),
  );

  console.log(`\nHouse ${counts.House}/${EXPECTED.House} · Senate ${counts.Senate}/${EXPECTED.Senate}`);
  console.log(`distinct people: ${byName.size}`);
  console.log(`written: ${outFile}`);
  if (failures.length) {
    console.log(`\n🔴 ${failures.length} finding(s) — each needs settling before any migration:`);
    for (const f of failures) console.log(`   ${f}`);
    process.exit(1);
  }
  console.log('\n✅ all 138 profiles read, every seat reads "- Present", no departure language.');
})().catch((e) => {
  console.error(`\n🔴 ${e.message}`);
  process.exit(1);
});
