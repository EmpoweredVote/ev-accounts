#!/usr/bin/env node
/**
 * Exact inventory of Mississippi legislative portraits, so the permission request states a
 * measured number rather than an estimate.
 *
 * Reads the cached member XML pages for <IMG_NAME>, resolves each against the directory the
 * probe established, and HEADs every one. A control path that must NOT exist is included in
 * the same sweep, so a run that reports "all present" can be told apart from a blind one.
 */
import fs from 'node:fs';
import https from 'node:https';
import http from 'node:http';
import tls from 'node:tls';

const PAGES = 'data/seed-ms-2026/_pages';
const BASE = 'https://billstatus.ls.state.ms.us/members/';

function rawReq(url, agent, method) {
  const lib = url.startsWith('http://') ? http : https;
  return new Promise((resolve, reject) => {
    const req = lib.request(url, { method, agent, headers: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' } }, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: Buffer.concat(chunks) }));
    });
    req.on('error', reject);
    req.setTimeout(20000, () => req.destroy(new Error('timeout')));
    req.end();
  });
}
const pem = (der) => `-----BEGIN CERTIFICATE-----\n${der.toString('base64').replace(/(.{64})/g, '$1\n')}\n-----END CERTIFICATE-----\n`;

const der = (await rawReq('http://secure.globalsign.com/cacert/gsrsaovsslca2018.crt', undefined, 'GET')).body;
const agent = new https.Agent({ ca: [...tls.rootCertificates, pem(der)], keepAlive: true, maxSockets: 6 });

const targets = [];
for (const f of fs.readdirSync(PAGES).filter((f) => f.endsWith('.xml'))) {
  const xml = fs.readFileSync(`${PAGES}/${f}`, 'latin1');
  const img = /<IMG_NAME>([^<]*)<\/IMG_NAME>/.exec(xml);
  const name = /<DISP_NAME>([^<]*)<\/DISP_NAME>/.exec(xml);
  const dist = /<DISTRICT>([^<]*)<\/DISTRICT>/.exec(xml);
  const chamber = f.startsWith('senate') ? 'senate' : 'house';
  targets.push({ file: f, chamber, district: dist ? dist[1].trim() : null,
                 person: name ? name[1].trim() : null,
                 img: img && img[1].trim() ? img[1].trim() : null });
}
// Control: must NOT exist, swept exactly like the rest.
targets.push({ file: 'CONTROL', chamber: 'house', district: null, person: 'CONTROL', img: 'zzzznosuchmember.jpg', isControl: true });

const withImg = targets.filter((t) => t.img);
console.log(`${targets.length - 1} cached member pages, ${withImg.length - 1} carry an IMG_NAME\n`);

let ok = 0, missing = 0, ctl = null;
const queue = [...withImg];
async function worker() {
  while (queue.length) {
    const t = queue.shift();
    const url = BASE + t.chamber + '/' + t.img;
    try {
      const r = await rawReq(url, agent, 'HEAD');
      t.status = r.status;
      t.bytes = Number(r.headers['content-length'] || 0);
      t.type = r.headers['content-type'] || '';
    } catch (e) { t.status = 'ERR'; t.err = e.message; }
    if (t.isControl) ctl = t;
    else if (t.status === 200) ok++;
    else { missing++; console.log(`  MISSING  ${t.chamber} d${t.district} ${t.person} -> ${t.img} (${t.status})`); }
  }
}
await Promise.all([worker(), worker(), worker(), worker(), worker(), worker()]);

console.log(`\npresent: ${ok}   missing: ${missing}`);
console.log(`CONTROL ${ctl.img}: HTTP ${ctl.status} ` +
  (ctl.status === 200 ? '-- SOFT-404, the counts above are meaningless' : '-- correctly absent'));

const byChamber = {};
for (const t of withImg) {
  if (t.isControl) continue;
  byChamber[t.chamber] = byChamber[t.chamber] || { present: 0, total: 0 };
  byChamber[t.chamber].total++;
  if (t.status === 200) byChamber[t.chamber].present++;
}
for (const [c, v] of Object.entries(byChamber)) console.log(`  ${c}: ${v.present} of ${v.total}`);
fs.writeFileSync('data/seed-ms-2026/_assets/ms-legislature-portraits.json', JSON.stringify(withImg, null, 2));
