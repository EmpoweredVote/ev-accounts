// Classify each non-resolving cited host to migration 1548's evidence standard.
//
// 🔴 REWRITTEN AFTER THE FIRST RUN RETURNED "UNKNOWN" FOR EVERY HOST. The availability endpoint works
// perfectly when called alone -- it was being throttled by this script's own request rate, and three
// rounds per URL with no backoff turned every probe into a non-answer. The script was right to refuse to
// call that absence (memory: a throttled reply is indistinguishable from a real absence), but it produced
// nothing. So: CDX exact-URL match is now the PRIMARY method (it answers "was this URL ever captured?"
// directly and proved reliable in the same run), availability is the fallback, and every probe gets
// exponential backoff. Fewer, better-paced requests beat more rounds.
//
// 🔴 THE RESTRAINT THAT MATTERS. Most of these are SINGLE-CYCLE CAMPAIGN SITES, and a lapsed campaign
// domain is the NORMAL end state of a real campaign, so "does not resolve" is not evidence of anything.
// Same restraint already applied to octavioforwhittier.com, kennethforla.com, fairshareforma.com and the
// four thin hosts. Only two shapes carry weight: the cited URL IS archived (repointable), or the host has
// real archived presence while our exact paths were never captured.
//
// Emits a reading queue. Deletes nothing, proposes no deletion.
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'fs';
import { Pool } from 'pg';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const CAMPAIGNISH = /(^act\.)|((for|4)(congress|council|mayor|senate|house|whittier|prosper|bloomington|la|utah|missouri|iowa|kansas|lancaster|city))|^elect|^vote/i;

async function withBackoff(fn, label) {
  const waits = [0, 5000, 15000, 40000];
  for (let i = 0; i < waits.length; i++) {
    if (waits[i]) await sleep(waits[i]);
    try {
      const r = await fn();
      if (r.status === 200) return r;
      if (i === waits.length - 1) return { status: r.status, throttled: true };
    } catch (e) {
      if (i === waits.length - 1) return { status: 0, error: e.message.slice(0, 70) };
    }
  }
}

/** Was this EXACT url ever captured? CDX is authoritative and gives the capture count. */
async function cdxExact(url) {
  const q = `https://web.archive.org/cdx/search/cdx?url=${encodeURIComponent(url)}&output=json&fl=timestamp,statuscode&limit=8`;
  const r = await withBackoff(() => fetch(q, { headers: { 'user-agent': UA }, signal: AbortSignal.timeout(45000) }), url);
  if (r.status !== 200) return { verdict: 'UNKNOWN', why: `cdx ${r.status}${r.error ? ' ' + r.error : ''}` };
  let j;
  try { j = await r.json(); } catch { return { verdict: 'UNKNOWN', why: 'cdx unparseable' }; }
  const caps = (j || []).slice(1);
  return caps.length ? { verdict: 'ARCHIVED', captures: caps.length, first: caps[0]?.[0] } : { verdict: 'ABSENT' };
}

/** How much of the host was ever archived? */
async function siblings(host) {
  const q = `https://web.archive.org/cdx/search/cdx?url=${encodeURIComponent(host + '/*')}&output=json&fl=original&collapse=urlkey&limit=300`;
  const r = await withBackoff(() => fetch(q, { headers: { 'user-agent': UA }, signal: AbortSignal.timeout(60000) }), host);
  if (r.status !== 200) return { ok: false, why: `cdx ${r.status}` };
  let j;
  try { j = await r.json(); } catch { return { ok: false, why: 'unparseable' }; }
  const urls = (j || []).slice(1).map((x) => x[0]);
  // Parking/tracking artifacts are not editorial presence -- newtonobserver.com's 5 "captures" were these.
  const real = urls.filter((u) => !/\?(epl|utm_|fbclid|gclid)=/i.test(u));
  return { ok: true, n: urls.length, editorial: real.length, sample: real.slice(0, 3) };
}

const resolveJson = JSON.parse(readFileSync('data/stance-retirement/2026-08-04-citation-host-resolve.json', 'utf8'));
const genuine = resolveJson.no_dns_hosts.filter((h) => !h.host.includes('/') && !h.host.includes('#'));
// Real hosts whose DNS merely errored -- UNKNOWN, not absent -- plus the one that turned out live.
const errored = ['willametteweek.com', 'walthampatch.com', 'publicleadershipinstitute.org'];

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows: cites } = await pool.query(
  `SELECT lower(regexp_replace(s, '^https?://(www\\.)?([^/:]+).*$', '\\2')) AS host, s AS url,
          count(DISTINCT (c.politician_id, c.topic_id)) AS rows_citing
     FROM inform.politician_context c
     JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
     CROSS JOIN LATERAL unnest(c.sources) AS s
    GROUP BY 1, 2`);
await pool.end();
const byHost = cites.reduce((m, c) => { (m[c.host] = m[c.host] || []).push(c); return m; }, {});

const targets = [
  ...genuine.map((h) => ({ host: h.host, rows: h.rows_touched, control: false })),
  ...errored.map((h) => ({ host: h, rows: (byHost[h] || []).reduce((n, c) => n + Number(c.rows_citing), 0), control: false, dns: 'ERRORED' })),
  { host: 'figcitynews.com', rows: 0, control: true },
  { host: 'wweek.com', rows: 0, control: true },
];

// Sliced so the run fits inside a foreground timeout. 🔴 A nohup'd background run died with its parent
// shell after one host on this platform, silently and with no artifact -- so this script is meant to be
// run in chunks and its partial results merged, never fire-and-forget.
//   node scripts/classify-dead-cited-hosts.mjs --from 0 --to 13 --pace 1200 --maxurls 2
const arg = (n, d) => { const i = process.argv.indexOf(n); return i > -1 ? Number(process.argv[i + 1]) : d; };
const FROM = arg('--from', 0), TO = arg('--to', targets.length), PACE = arg('--pace', 2500), MAXURLS = arg('--maxurls', 6);
const slice = targets.slice(FROM, TO);

const out = [];
console.log(`classifying ${slice.length} of ${targets.length} targets (slice ${FROM}..${TO}), pace ${PACE}ms\n`);
for (const t of slice) {
  const sib = await siblings(t.host);
  await sleep(PACE);
  const urls = (byHost[t.host] || []).sort((a, b) => Number(b.rows_citing) - Number(a.rows_citing)).slice(0, MAXURLS);
  const probed = [];
  for (const u of urls) { probed.push({ url: u.url, rows: Number(u.rows_citing), ...(await cdxExact(u.url)) }); await sleep(PACE); }

  const archivedPaths = probed.filter((p) => p.verdict === 'ARCHIVED');
  const unknownPaths = probed.filter((p) => p.verdict === 'UNKNOWN');
  const editorial = sib.ok ? sib.editorial : null;
  let cls;
  if (t.control) cls = sib.ok && editorial > 20 ? 'CONTROL_OK' : 'CONTROL_FAILED';
  else if (!sib.ok && unknownPaths.length === probed.length) cls = 'UNKNOWN';
  else if (archivedPaths.length) cls = archivedPaths.length === probed.length ? 'REPOINTABLE_ALL' : 'REPOINTABLE_SOME';
  else if (editorial !== null && editorial >= 20) cls = 'HOST_ARCHIVED_PATHS_NEVER_CAPTURED';
  else if (CAMPAIGNISH.test(t.host)) cls = 'NO_ARCHIVE_CAMPAIGN_WEAK';
  else cls = 'NO_ARCHIVE_OTHER';

  out.push({ host: t.host, dns: t.dns ?? 'NO_DNS', control: t.control, rows: t.rows, class: cls,
    siblings_total: sib.ok ? sib.n : null, siblings_editorial: editorial, sibling_sample: sib.sample ?? null,
    cited: probed });
  console.log(`  ${cls.padEnd(34)} ${t.host.padEnd(32)} archived_siblings=${editorial ?? '?'} paths=[${probed.map((p) => p.verdict[0] + (p.captures ? p.captures : '')).join(' ')}]`);
  await sleep(PACE);
}

writeFileSync(`data/stance-retirement/2026-08-04-dead-host-classification.${FROM}-${TO}.json`,
  JSON.stringify({ generated: new Date().toISOString().slice(0, 10), method: 'CDX exact-URL primary, availability fallback, exponential backoff', hosts: out }, null, 2));

let md = `# Non-resolving cited hosts — classification\n\nGenerated ${new Date().toISOString().slice(0, 10)} by \`scripts/classify-dead-cited-hosts.mjs\`.\n\n`;
md += `Method: **CDX exact-URL match** as the primary test (was this URL ever captured?), host sibling\n`;
md += `coverage for presence, exponential backoff throughout. The first version used the availability API\n`;
md += `with three un-backed-off rounds per URL and throttled itself into UNKNOWN on every host.\n\n`;
md += `⚠ **A lapsed campaign domain is the normal end state of a real campaign site**, so \`NO_ARCHIVE_CAMPAIGN_WEAK\`\n`;
md += `is explicitly NOT evidence of fabrication. Only \`HOST_ARCHIVED_PATHS_NEVER_CAPTURED\` and\n`;
md += `\`NO_ARCHIVE_OTHER\` are candidates for the newtonobserver.com treatment, and each still needs a hand read.\n\n`;
md += `| host | rows | class | archived siblings | cited paths |\n|---|---|---|---|---|\n`;
for (const h of out.sort((a, b) => b.rows - a.rows)) {
  md += `| \`${h.host}\`${h.control ? ' *(control)*' : ''} | ${h.rows} | ${h.class} | ${h.siblings_editorial ?? '?'} | ${h.cited.map((c) => c.verdict).join(', ') || '—'} |\n`;
}
md += `\n## Per-host detail\n\n`;
for (const h of out.filter((x) => !x.control)) {
  md += `### \`${h.host}\` — ${h.class} (${h.rows} rows, dns ${h.dns})\n\n`;
  md += `- archived siblings: ${h.siblings_editorial ?? 'unknown'}${h.sibling_sample?.length ? ` (e.g. ${h.sibling_sample.map((s) => `\`${s}\``).join(', ')})` : ''}\n`;
  for (const c of h.cited) md += `- ${c.verdict}${c.captures ? ` (${c.captures} captures, first ${c.first})` : ''} — \`${c.url}\` (${c.rows} rows)\n`;
  md += `\n`;
}
writeFileSync(`data/stance-retirement/2026-08-04-dead-host-classification.${FROM}-${TO}.md`, md);

console.log('\n=== summary ===');
for (const [k, v] of Object.entries(out.reduce((m, r) => { m[r.class] = (m[r.class] || 0) + 1; return m; }, {}))) console.log(`  ${k}: ${v}`);
