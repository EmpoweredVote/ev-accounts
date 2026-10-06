#!/usr/bin/env node
/**
 * Diligence on WHO the Mississippi portrait request should go to.
 *
 * The rule the SD letter set: do not construct an address from a naming convention. Find a
 * PUBLISHED desk, or a named officer the body itself publishes a mailbox for. If neither exists,
 * the published desk is the right route rather than a guess.
 *
 * So this reads the Legislature's own pages for: a copyright notice naming a body, the Clerk of
 * the House, the Secretary of the Senate, the Legislative Reference Bureau, and any staff or
 * administration listing. Every candidate URL gets recorded with its status so a later reader can
 * see what was checked and what did not exist.
 */
import https from 'node:https';
import http from 'node:http';
import tls from 'node:tls';

const get = (u, a) => new Promise((res) => {
  const l = u.startsWith('http://') ? http : https;
  const q = l.get(u, { agent: a, headers: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' } }, (r) => {
    const c = [];
    r.on('data', (d) => c.push(d));
    r.on('end', () => res({ status: r.statusCode, body: Buffer.concat(c), url: u }));
  });
  q.on('error', (e) => res({ status: 'ERR', err: e.message, body: Buffer.alloc(0), url: u }));
  q.setTimeout(20000, () => q.destroy(new Error('timeout')));
});
const pem = (d) => `-----BEGIN CERTIFICATE-----\n${d.toString('base64').replace(/(.{64})/g, '$1\n')}\n-----END CERTIFICATE-----\n`;
const der = (await get('http://secure.globalsign.com/cacert/gsrsaovsslca2018.crt')).body;
const agent = new https.Agent({ ca: [...tls.rootCertificates, pem(der)], keepAlive: true });

const strip = (h) => h.replace(/<script[\s\S]*?<\/script>/gi, ' ').replace(/<style[\s\S]*?<\/style>/gi, ' ')
                      .replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#\d+;/g, "'")
                      .replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();

const CANDIDATES = [
  // billstatus -- the host that actually serves the portraits
  'https://billstatus.ls.state.ms.us/htms/contact.htm',
  'https://billstatus.ls.state.ms.us/htms/copyright.htm',
  'https://billstatus.ls.state.ms.us/htms/disclaimer.htm',
  'https://billstatus.ls.state.ms.us/htms/legislative_staff.htm',
  // legislature.ms.gov -- the public site
  'https://legislature.ms.gov/disclaimer/',
  'https://legislature.ms.gov/help/',
  'https://legislature.ms.gov/sitemap/',
  'https://legislature.ms.gov/general-information/',
  'https://legislature.ms.gov/about-the-capitol/',
  // the two chamber officers, and the Reference Bureau
  'https://legislature.ms.gov/house/clerk/',
  'https://legislature.ms.gov/senate/secretary/',
  'https://legislature.ms.gov/legislative-reference-bureau/',
  'https://www.house.ms.gov/',
  'https://www.senate.ms.gov/',
];

const ROLE_RX = /(Clerk of the House|House Clerk|Secretary of the Senate|Senate Secretary|Legislative Reference Bureau|Legislative Services|copyright|all rights reserved|permission)/gi;

for (const u of CANDIDATES) {
  const r = await get(u, agent);
  const html = r.body.toString('utf8');
  const text = strip(html);
  const emails = [...new Set(html.match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g) || [])]
    .filter((e) => !/\.(png|jpg|gif|css|js)$/i.test(e));
  const roles = [...new Set(text.match(ROLE_RX) || [])];
  console.log('='.repeat(76));
  console.log(`${r.status}  ${u}`);
  if (r.status !== 200) { if (r.err) console.log('   ' + r.err); continue; }
  if (emails.length) console.log('   emails: ' + emails.join(', '));
  if (roles.length) console.log('   mentions: ' + roles.join(' | '));
  // Pull the sentence around each role mention -- who is named, and in what capacity.
  for (const role of roles) {
    const i = text.toLowerCase().indexOf(role.toLowerCase());
    if (i >= 0) console.log(`     "${role}" -> ...${text.slice(Math.max(0, i - 120), i + 200)}...`);
  }
  if (!emails.length && !roles.length) console.log('   (nothing relevant; ' + text.length + ' chars of text)');
}

// The sitemap is the cheapest way to see whether a clerk/secretary page exists at all.
console.log('\n' + '='.repeat(76));
console.log('sitemap entries mentioning an officer or staff page:');
const sm = await get('https://legislature.ms.gov/sitemap/', agent);
if (sm.status === 200) {
  const html = sm.body.toString('utf8');
  const links = [...html.matchAll(/href\s*=\s*"([^"]+)"[^>]*>([^<]{2,70})</gi)]
    .filter((m) => /clerk|secretary|staff|reference|bureau|administration|contact|about|copyright|disclaim/i.test(m[1] + ' ' + m[2]))
    .map((m) => `  ${m[2].trim().padEnd(34)} ${m[1]}`);
  for (const l of [...new Set(links)]) console.log(l);
  if (!links.length) console.log('  (none)');
} else {
  console.log('  sitemap HTTP ' + sm.status);
}
