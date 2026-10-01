#!/usr/bin/env node
/**
 * Find where the Mississippi Legislature actually serves member portraits.
 *
 * Each member's XML page carries <IMG_NAME>surname.jpg</IMG_NAME> but no path, so the directory
 * has to be established rather than guessed at write time.
 *
 * TLS: billstatus.ls.state.ms.us sends only its leaf certificate, so Node cannot build a chain.
 * The intermediate named in the leaf's own AIA extension (GlobalSign RSA OV SSL CA 2018) is
 * fetched and added to the trust store. Verification is never disabled.
 * CONTROLS: a request WITHOUT the intermediate must fail, and a nonexistent image must not
 * return an image -- otherwise a 200 here proves nothing.
 */
import https from 'node:https';
import http from 'node:http';
import tls from 'node:tls';

const INTERMEDIATE = 'http://secure.globalsign.com/cacert/gsrsaovsslca2018.crt';

function rawGet(url, agent) {
  const lib = url.startsWith('http://') ? http : https;
  return new Promise((resolve, reject) => {
    const req = lib.get(url, { agent, headers: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' } }, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => resolve({ status: res.statusCode, body: Buffer.concat(chunks), headers: res.headers }));
    });
    req.on('error', reject);
    req.setTimeout(20000, () => req.destroy(new Error('timeout')));
  });
}

function derToPem(der) {
  const b64 = der.toString('base64').replace(/(.{64})/g, '$1\n');
  return `-----BEGIN CERTIFICATE-----\n${b64}\n-----END CERTIFICATE-----\n`;
}

const isJpeg = (b) => b.length > 3 && b[0] === 0xff && b[1] === 0xd8;
function dims(b) {
  if (!isJpeg(b)) return null;
  let o = 2;
  while (o < b.length - 9) {
    if (b[o] !== 0xff) { o++; continue; }
    const mk = b[o + 1];
    if (mk >= 0xc0 && mk <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(mk))
      return { h: b.readUInt16BE(o + 5), w: b.readUInt16BE(o + 7) };
    o += 2 + b.readUInt16BE(o + 2);
  }
  return null;
}

const der = (await rawGet(INTERMEDIATE)).body;
const agent = new https.Agent({ ca: [...tls.rootCertificates, derToPem(der)], keepAlive: true });

// CONTROL 1 -- the chain fix must be NECESSARY. Without the intermediate this must fail.
process.stdout.write('CONTROL chain: without the intermediate ... ');
try {
  await rawGet('https://billstatus.ls.state.ms.us/members/hr_membs.xml', new https.Agent({ keepAlive: true }));
  console.log('SUCCEEDED -- the fix is NOT necessary, re-read this');
} catch (e) {
  console.log('failed as required (' + e.code + ')');
}

const BASE = 'https://billstatus.ls.state.ms.us/members/';
const CANDIDATES = [
  'house/aguirre.jpg', 'house/photos/aguirre.jpg', 'house/pics/aguirre.jpg',
  'photos/aguirre.jpg', 'pics/aguirre.jpg', 'images/aguirre.jpg', 'aguirre.jpg',
  'house/images/aguirre.jpg', 'housepics/aguirre.jpg', 'memberpics/aguirre.jpg',
];
console.log('\nlooking for House member "aguirre.jpg":');
let found = null;
for (const c of CANDIDATES) {
  try {
    const r = await rawGet(BASE + c, agent);
    const d = dims(r.body);
    console.log('  ' + String(r.status).padEnd(4) + String(r.body.length).padStart(8) + 'B  ' +
      (d ? `JPEG ${d.w}x${d.h}` : '').padEnd(16) + BASE + c);
    if (d && !found) found = BASE + c;
  } catch (e) {
    console.log('  ERR  ' + e.message.slice(0, 40).padEnd(24) + BASE + c);
  }
}

if (found) {
  // CONTROL 2 -- a nonexistent member in the SAME directory must not return an image.
  const ctl = found.replace(/[^/]+\.jpg$/, 'zzzznosuchmember.jpg');
  const r = await rawGet(ctl, agent);
  const d = dims(r.body);
  console.log(`\nCONTROL path: ${ctl}\n  -> HTTP ${r.status}, ${r.body.length}B, ` +
    (d ? 'RETURNED AN IMAGE -- the directory soft-404s and the hit above proves nothing' : 'not an image (correct)'));
  console.log('\nPORTRAIT DIRECTORY: ' + found.replace(/[^/]+\.jpg$/, ''));
} else {
  console.log('\nno portrait directory found among the candidates tried');
}
