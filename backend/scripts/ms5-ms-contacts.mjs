#!/usr/bin/env node
/**
 * Find who to address the portrait permission request to, from the Legislature's OWN pages.
 * Names and addresses are read from the site, never from a search summary.
 */
import https from 'node:https';
import http from 'node:http';
import tls from 'node:tls';

const get = (u, a) => new Promise((res, rej) => {
  const l = u.startsWith('http://') ? http : https;
  const q = l.get(u, { agent: a, headers: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' } }, (r) => {
    const c = [];
    r.on('data', (d) => c.push(d));
    r.on('end', () => res({ status: r.statusCode, body: Buffer.concat(c), url: u }));
  });
  q.on('error', rej);
  q.setTimeout(20000, () => q.destroy(new Error('timeout')));
});
const pem = (d) => `-----BEGIN CERTIFICATE-----\n${d.toString('base64').replace(/(.{64})/g, '$1\n')}\n-----END CERTIFICATE-----\n`;
const der = (await get('http://secure.globalsign.com/cacert/gsrsaovsslca2018.crt')).body;
const agent = new https.Agent({ ca: [...tls.rootCertificates, pem(der)], keepAlive: true });

const URLS = [
  'https://billstatus.ls.state.ms.us/',
  'https://billstatus.ls.state.ms.us/htms/legcontact.htm',
  'https://billstatus.ls.state.ms.us/htms/contact.htm',
  'https://legislature.ms.gov/',
  'https://legislature.ms.gov/about/contact/',
  'https://legislature.ms.gov/contact/',
  'https://www.legislature.ms.gov/about/legislative-services/',
];
for (const u of URLS) {
  try {
    const r = await get(u, agent);
    const html = r.body.toString('utf8');
    const text = html.replace(/<script[\s\S]*?<\/script>/gi, ' ').replace(/<style[\s\S]*?<\/style>/gi, ' ')
                     .replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
    const emails = [...new Set(html.match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g) || [])];
    const phones = [...new Set(text.match(/\(?\d{3}\)?[-. ]\d{3}[-. ]\d{4}/g) || [])];
    const roles = [...new Set(text.match(/(Clerk of the House|Secretary of the Senate|Legislative Services|Webmaster|Copyright|Terms of Use|Privacy)[^.]{0,90}/gi) || [])];
    console.log('='.repeat(72));
    console.log(`${u}\n  HTTP ${r.status}, ${html.length} chars`);
    if (emails.length) console.log('  emails : ' + emails.join(', '));
    if (phones.length) console.log('  phones : ' + phones.slice(0, 5).join(', '));
    if (roles.length) for (const x of roles.slice(0, 6)) console.log('  role   : ' + x.trim());
    if (r.status === 200 && text.length > 60) console.log('  text   : ' + text.slice(0, 260));
  } catch (e) {
    console.log('='.repeat(72));
    console.log(`${u}\n  ERROR ${e.message}`);
  }
}
