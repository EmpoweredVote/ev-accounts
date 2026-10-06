#!/usr/bin/env node
/** Read the Legislature's own Terms / contact text in full: the licence question is answered by
 *  what the publisher states, not by what is customary. */
import https from 'node:https';
import http from 'node:http';
import tls from 'node:tls';

const get = (u, a) => new Promise((res, rej) => {
  const l = u.startsWith('http://') ? http : https;
  const q = l.get(u, { agent: a, headers: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' } }, (r) => {
    const c = [];
    r.on('data', (d) => c.push(d));
    r.on('end', () => res({ status: r.statusCode, body: Buffer.concat(c) }));
  });
  q.on('error', rej);
  q.setTimeout(20000, () => q.destroy(new Error('timeout')));
});
const pem = (d) => `-----BEGIN CERTIFICATE-----\n${d.toString('base64').replace(/(.{64})/g, '$1\n')}\n-----END CERTIFICATE-----\n`;
const der = (await get('http://secure.globalsign.com/cacert/gsrsaovsslca2018.crt')).body;
const agent = new https.Agent({ ca: [...tls.rootCertificates, pem(der)], keepAlive: true });

const strip = (h) => h.replace(/<script[\s\S]*?<\/script>/gi, ' ').replace(/<style[\s\S]*?<\/style>/gi, ' ')
                      .replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#\d+;/g, "'")
                      .replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();

for (const u of [
  'https://legislature.ms.gov/terms-and-conditions/',
  'https://legislature.ms.gov/terms/',
  'https://legislature.ms.gov/privacy-policy/',
  'https://legislature.ms.gov/contact/',
  'https://billstatus.ls.state.ms.us/htms/contact.htm',
]) {
  try {
    const r = await get(u, agent);
    const t = strip(r.body.toString('utf8'));
    console.log('='.repeat(74));
    console.log(u, 'HTTP', r.status, '-', t.length, 'chars of text');
    if (r.status !== 200) continue;
    // Print the part after the shared site navigation.
    const i = t.search(/Terms and Conditions|Privacy|Contact the|Contact Us/i);
    console.log(t.slice(i > 0 ? i : 0, (i > 0 ? i : 0) + 2200));
  } catch (e) { console.log(u, 'ERROR', e.message); }
}
