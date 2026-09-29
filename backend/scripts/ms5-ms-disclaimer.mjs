#!/usr/bin/env node
/** Read the Legislature's disclaimer and help pages IN FULL, plus the chamber mail domains.
 *  The Terms page is unwritten boilerplate; the disclaimer might carry the real statement, and if
 *  it does, the claim "there are no terms" is wrong and has to be corrected. */
import https from 'node:https';
import http from 'node:http';
import tls from 'node:tls';

const get = (u, a) => new Promise((res) => {
  const l = u.startsWith('http://') ? http : https;
  const q = l.get(u, { agent: a, headers: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' } }, (r) => {
    const c = [];
    r.on('data', (d) => c.push(d));
    r.on('end', () => res({ status: r.statusCode, body: Buffer.concat(c) }));
  });
  q.on('error', (e) => res({ status: 'ERR', err: e.message, body: Buffer.alloc(0) }));
  q.setTimeout(20000, () => q.destroy(new Error('timeout')));
});
const pem = (d) => `-----BEGIN CERTIFICATE-----\n${d.toString('base64').replace(/(.{64})/g, '$1\n')}\n-----END CERTIFICATE-----\n`;
const der = (await get('http://secure.globalsign.com/cacert/gsrsaovsslca2018.crt')).body;
const agent = new https.Agent({ ca: [...tls.rootCertificates, pem(der)], keepAlive: true });

const NAV_END = 'Search the site';  // the shared chrome ends here on every page

for (const u of ['https://legislature.ms.gov/disclaimer/', 'https://legislature.ms.gov/help/',
                 'https://legislature.ms.gov/general-information/']) {
  const r = await get(u, agent);
  let t = r.body.toString('utf8')
    .replace(/<script[\s\S]*?<\/script>/gi, ' ').replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#\d+;/g, "'")
    .replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();
  const i = t.indexOf(NAV_END);
  if (i >= 0) t = t.slice(i + NAV_END.length).trim();
  console.log('='.repeat(76));
  console.log(u, r.status);
  console.log(t.slice(0, 1800));
  console.log('');
}

console.log('='.repeat(76));
console.log('chamber and legislative-services hosts:');
for (const h of ['https://house.ms.gov/', 'https://senate.ms.gov/', 'https://ls.ms.gov/',
                 'https://www.ls.ms.gov/', 'https://lrb.ms.gov/', 'https://ls.state.ms.us/']) {
  const r = await get(h, agent);
  const t = r.body.toString('utf8').replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
  console.log(`  ${String(r.status).padEnd(5)} ${String(r.body.length).padStart(8)}B  ${h}` +
    (r.err ? '  ' + r.err : '') + (r.status === 200 ? '  :: ' + t.slice(0, 110) : ''));
}
