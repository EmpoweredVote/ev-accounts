// Does each cited host EXIST? DNS-only, every host, cheap.
//
// 🔴 WHY DNS AND NOT A NAME HEURISTIC. The first cut of the citation inventory ranked hosts by a
// "press-shaped name confined to one city" pattern derived from the six known invented outlets. It
// over-fired immediately: the top hits were missionlocal.org, timesofsandiego.com, sfstandard.com,
// dotnews.com, lbpost.com, webapi.legistar.com -- all real. That is the fourteenth first-cut detector
// on this workstream to be too broad, and the lesson is the same each time: match on the thing that
// actually distinguishes the defect. What all six invented outlets share is that **they do not resolve**.
//
// DNS is the cheap decisive funnel: 2,700 hosts in about a minute, and only the non-resolvers need the
// expensive Wayback + sibling-coverage work.
//
// ⚠ A NON-RESOLVING HOST IS NOT AUTOMATICALLY INVENTED. It can be a dead campaign site, a renamed
// outlet, or a lapsed domain that once carried the cited page. That is why this writes a QUEUE and the
// verdict still requires: reproduce absence (3 rounds x 3 query forms), check per-host sibling coverage,
// and verify a real control in the same run. Migration 1548's evidence standard, not a shortcut past it.
// ⚠ Conversely a RESOLVING host proves nothing about the cited path -- 403/paywall/parked all resolve.
//
// 🔴 AND A NON-RESOLVING HOST MAY NOT EVEN BE NON-RESOLVING. This script probed the inventory's
// FOLDED host (www. stripped) until 2026-08-07 and manufactured 8 dead hosts out of a 22-host queue;
// 14 of 30 "dead" URLs served HTTP 200. It now probes every authority the outlet is actually cited
// as. **Before trusting any NO_DNS verdict here, fetch the stored URL as stored** -- DNS on a
// reshaped name is not a test of the citation. See 2026-08-07-dead-host-repoint-pass.md.
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'fs';
import { Resolver } from 'node:dns/promises';

const inv = JSON.parse(readFileSync('data/stance-retirement/2026-08-04-citation-host-inventory.json', 'utf8'));
const hosts = inv.hosts;

const resolver = new Resolver({ timeout: 4000, tries: 2 });
resolver.setServers(['1.1.1.1', '8.8.8.8']);

// Resolve ONE authority string, exactly as given.
async function probeAuthority(name) {
  for (const fn of ['resolve4', 'resolve6']) {
    try {
      const a = await resolver[fn](name);
      if (a?.length) return { dns: 'RESOLVES', via: fn };
    } catch (e) {
      if (e.code === 'ENODATA' || e.code === 'ENOTFOUND') continue;
      return { dns: 'ERROR', code: e.code };
    }
  }
  // second opinion before calling it gone: a single NXDOMAIN can be a resolver hiccup
  try {
    const c = await resolver.resolveCname(name);
    if (c?.length) return { dns: 'RESOLVES', via: 'cname' };
  } catch { /* fall through */ }
  return { dns: 'NO_DNS' };
}

// 🔴 RESOLVE THE HOST AS CITED, AND EVERY FORM IT IS CITED AS.
// This probed the inventory's FOLDED host (www. stripped) until 2026-08-07, and that single
// normalisation manufactured SEVEN dead hosts out of a 22-host queue: davidredkey4congress,
// tracinskiletter, bradknott, markhenderson, allenrwaters, cambridgeresidentsalliance and
// rightnowmn publish an A record only on `www`, which is the form their citations already use.
// (An eighth, publicleadershipinstitute.org, was never dead either but for a different reason -- it
// sat in the ERROR bucket while serving HTTP 200. ERROR is UNKNOWN; never read it as absence.)
// 14 of 30 supposedly-dead URLs returned HTTP 200 with real content.
// Verified after the fix: those 7 flip to RESOLVES, while boli.oregon.gov, octavioforwhittier.com
// and downeylegend.com correctly stay NO_DNS -- the fix must not resurrect a genuinely dead host.
// A host is dead only when EVERY form it is cited as fails. Same family as the scheme-less citations
// of 1549: a probe that reshapes the value before testing it measures something other than the
// citation.
async function probe(h) {
  const names = (h.cited_authorities?.length ? h.cited_authorities : [h.host]);
  const attempts = [];
  for (const name of names) {
    const r = await probeAuthority(name);
    attempts.push({ name, ...r });
    // Any single resolving form means the citation opens. Stop and record which one.
    if (r.dns === 'RESOLVES') return { ...h, dns: 'RESOLVES', via: r.via, resolved_as: name, attempts };
  }
  // An ERROR is UNKNOWN, not absence, and must not be downgraded to NO_DNS by a sibling's NXDOMAIN.
  const err = attempts.find((a) => a.dns === 'ERROR');
  if (err) return { ...h, dns: 'ERROR', code: err.code, attempts };
  return { ...h, dns: 'NO_DNS', attempts };
}

const out = [];
const LIMIT = 24;
let i = 0;
await Promise.all(Array.from({ length: LIMIT }, async () => {
  while (i < hosts.length) {
    const mine = hosts[i++];
    out.push(await probe(mine));
    if (out.length % 400 === 0) console.log(`  ...${out.length}/${hosts.length}`);
  }
}));

const dead = out.filter((h) => h.dns === 'NO_DNS').sort((a, b) => b.rows_touched - a.rows_touched);
const errs = out.filter((h) => h.dns === 'ERROR');

writeFileSync('data/stance-retirement/2026-08-04-citation-host-resolve.json',
  JSON.stringify({ generated: new Date().toISOString().slice(0, 10), total: out.length,
    resolves: out.filter((h) => h.dns === 'RESOLVES').length, no_dns: dead.length, errors: errs.length,
    no_dns_hosts: dead, error_hosts: errs }, null, 2));

let md = `# Cited hosts that do not resolve — probe queue for the citation-level re-sweep\n\n`;
md += `Generated ${inv.generated} → resolved ${new Date().toISOString().slice(0, 10)} by \`scripts/citation-host-resolve.mjs\`.\n\n`;
md += `${out.length} distinct cited hosts: **${out.filter((h) => h.dns === 'RESOLVES').length} resolve**, `;
md += `**${dead.length} have no DNS**, ${errs.length} errored.\n\n`;
md += `🔴 **A non-resolving host is NOT automatically invented** — it can be a dead campaign site, a renamed\n`;
md += `outlet, or a lapsed domain that really did carry the cited page. Each still needs reproduced absence,\n`;
md += `per-host sibling coverage, and a control verified in the same run (migration 1548's standard).\n\n`;
md += `| host | live rows | politicians | citations | sole-sourced cites | government |\n|---|---|---|---|---|---|\n`;
for (const h of dead) {
  md += `| \`${h.host}\` | ${h.rows_touched} | ${h.politicians} | ${h.citations} | ${h.on_sole_sourced_rows} | ${h.example_government ?? '—'} |\n`;
}
if (errs.length) {
  md += `\n## Resolver errors (UNKNOWN, not absent — re-run these)\n\n`;
  for (const h of errs) md += `- \`${h.host}\` (${h.code}) — ${h.rows_touched} rows\n`;
}
writeFileSync('data/stance-retirement/2026-08-04-citation-host-resolve.md', md);

console.log(`\nresolves ${out.filter((h) => h.dns === 'RESOLVES').length} · NO_DNS ${dead.length} · errors ${errs.length}`);
console.log(`live stance rows exposed to a non-resolving host: ${new Set(dead.flatMap((h) => h.host)).size} hosts / ${dead.reduce((n, h) => n + h.rows_touched, 0)} row-citations`);
console.log('\ntop non-resolving hosts by exposure:');
for (const h of dead.slice(0, 25)) console.log(`  ${String(h.rows_touched).padStart(4)} rows  ${String(h.politicians).padStart(3)} pols  ${h.host}  ${h.example_government ?? ''}`);
