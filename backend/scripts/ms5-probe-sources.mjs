#!/usr/bin/env node
/**
 * MS-5 stage 1: probe the Biloxi and Harrison County publishers BEFORE trusting any of them.
 *
 * Every trap this guards against has cost a real failure somewhere in the programme:
 *   - a clean HTTP 200 that is a parked domain (~114 bytes), a soft-404 at full length,
 *     or a truncated body;
 *   - a WAF that refuses a Node TLS fingerprint carrying a Chrome UA while accepting a
 *     bare fetch -- and the inverse;
 *   - a detector that reports "nothing found" because it is blind, not because the thing
 *     is absent.
 *
 * So each target is fetched under THREE personas, and each host also gets a NEGATIVE
 * CONTROL: a URL that must NOT exist. A control that returns 200 means the host soft-404s
 * and every other 200 from it is uninterpretable.
 */
const PERSONAS = {
  bare:    {},
  chrome:  { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36' },
  project: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' },
};

async function probe(url, persona) {
  const t0 = Date.now();
  try {
    const r = await fetch(url, { headers: PERSONAS[persona], redirect: 'follow' });
    const buf = Buffer.from(await r.arrayBuffer());
    return {
      persona, ok: r.ok, status: r.status, bytes: buf.length,
      type: r.headers.get('content-type'), finalUrl: r.url,
      ms: Date.now() - t0,
      head: buf.subarray(0, 4).toString('hex'),
    };
  } catch (e) {
    return { persona, error: String(e.message || e), ms: Date.now() - t0 };
  }
}

const TARGETS = [
  ['biloxi-council-page',  'https://biloxi.ms.us/city-council/',                  false],
  ['biloxi-CONTROL-404',   'https://biloxi.ms.us/this-page-does-not-exist-ms5/',  true ],
  ['hc-home',              'https://www.harrisoncountyms.gov/',                    false],
  ['hc-CONTROL-404',       'https://www.harrisoncountyms.gov/no-such-page-ms5',     true ],
  ['hcso-home',            'https://www.harrisoncountysheriff.com/',               false],
  ['hcso-CONTROL-404',     'https://www.harrisoncountysheriff.com/no-such-ms5',     true ],
];

const rows = [];
for (const [name, url, isControl] of TARGETS) {
  for (const persona of Object.keys(PERSONAS)) {
    const r = await probe(url, persona);
    rows.push({ name, url, isControl, ...r });
    const flag = r.error ? 'ERR' : (r.status === 200 ? '200' : String(r.status));
    console.log(
      (isControl ? 'CTRL ' : '     ') + name.padEnd(22) + persona.padEnd(9) +
      flag.padEnd(5) + String(r.bytes ?? '-').padStart(8) + 'B  ' +
      (r.type || r.error || '').slice(0, 48) +
      (r.finalUrl && r.finalUrl !== url ? '  -> ' + r.finalUrl.slice(0, 60) : '')
    );
  }
  console.log('');
}

// The verdict the controls license.
console.log('--- CONTROL READING ---');
for (const [name, , isControl] of TARGETS.filter(t => t[2])) {
  const got = rows.filter(r => r.name === name);
  const any200 = got.some(r => r.status === 200);
  console.log(`${name}: ${any200 ? 'SOFT-404 -- a 200 from this host proves NOTHING' : 'honest 404 -- a 200 from this host is meaningful'}`);
}

const fs = await import('node:fs');
fs.writeFileSync('data/seed-ms-2026/_assets/probe.json', JSON.stringify(rows, null, 2));
process.exitCode = 0;
