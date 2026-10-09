#!/usr/bin/env node
/** Last diligence step: does the host that SERVES the portraits publish a staff directory or an
 *  officer mailbox anywhere? billstatus.ls.state.ms.us is a frameset, so its menu has to be read. */
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

const root = await get('https://billstatus.ls.state.ms.us/sessions.htm', agent);
console.log('root HTTP', root.status, root.body.length, 'bytes:\n');
console.log(root.body.toString('utf8').slice(0,600));

// Follow every frame/link the root names.
const html = root.body.toString('utf8');
const refs = [...new Set([...html.matchAll(/(?:src|href)\s*=\s*"([^"]+)"/gi)].map((m) => m[1]))];
console.log('\nfollowing', refs.length, 'reference(s) from the root:');
for (const ref of refs) {
  const u = new URL(ref, 'https://billstatus.ls.state.ms.us/').href;
  const r = await get(u, agent);
  const t = r.body.toString('utf8');
  const links = [...new Set([...t.matchAll(/href\s*=\s*"([^"]+)"[^>]*>([^<]{2,60})</gi)].map((m) => m[2].trim() + ' -> ' + m[1]))];
  console.log(`\n  ${r.status}  ${u}  (${r.body.length}B)`);
  for (const l of links) console.log('      ' + l);
  const em = [...new Set(t.match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g) || [])];
  if (em.length) console.log('      emails: ' + em.join(', '));
}
