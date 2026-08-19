#!/usr/bin/env node
/**
 * Harvest the City of Austin Council Message Board (austincouncilforum.org) into a
 * per-member corpus for stance research.
 *
 * WHY A BROWSER: the board sits behind Incapsula. curl gets a JS interstitial
 * ("Request unsuccessful. Incapsula incident ID: ...") at HTTP 200 -- never judge by
 * status. Playwright passes; all inner requests are then issued as in-page fetch()
 * so they reuse the WAF cookie.
 *
 * WHY AUTHORSHIP IS SPLIT: posting is limited to council members AND authorized staff,
 * and roughly half the board is staff-authored. Attribution is keyed on the exact phpBB
 * username, never a surname match -- "Alison Alter", a former D10 member, is not Ryan
 * Alter. Staff posts are still harvested, because some carry an officeholder's voice by
 * proxy: the Mayor's chief of staff opens threads in the first person ("I've proposed
 * ...") and members reply "Mayor, ...". That is evidence ABOUT the Mayor, not his own
 * words, so it lands in a separate labelled corpus and is never merged into a member
 * file.
 *
 * Usage:
 *   node scripts/harvest-austin-council-board.mjs [--out <dir>] [--since YYYY-MM-DD]
 */

import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const ORIGIN = 'https://austincouncilforum.org';
const NBSP = / /g;

/** Exact phpBB usernames of the 11 current City of Austin seats. */
const MEMBERS = {
  'Natasha Harper-Madison': 'D1',
  'Vanessa Fuentes': 'D2',
  'Jose Velasquez': 'D3',
  'Jose Chito Vela': 'D4',
  'Ryan Alter': 'D5',
  'Krista Laine': 'D6',
  'Mike Siegel': 'D7',
  'Paige Ellis': 'D8',
  'Zo Qadri': 'D9',
  'Marc Duchen': 'D10',
  'Kirk Watson': 'Mayor', // 0 first-person posts as of 2026-08-19; see staff proxy note
};

function arg(flag, fallback) {
  const i = process.argv.indexOf(flag);
  return i > -1 ? process.argv[i + 1] : fallback;
}

const OUT_DIR = resolve(arg('--out', 'data/stance-research/austin-council-board'));
const SINCE = arg('--since', null);
const slug = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const parseWhen = (w) => {
  const m = (w || '').match(/»\s*(.+)$/);
  const d = m ? new Date(m[1].trim()) : new Date(NaN);
  return isNaN(d) ? null : d;
};

async function main() {
  mkdirSync(OUT_DIR, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' });

  await page.goto(`${ORIGIN}/index.php`, { waitUntil: 'domcontentloaded' });

  // 1. Discover forums. This doubles as the WAF check: assert the POSITIVE fact that
  //    real board content came back. Do NOT sniff for the string "Incapsula" -- the
  //    _Incapsula_Resource script tag is present on SUCCESSFUL pages too, so that test
  //    false-positives and blocks a working session.
  const forums = await page.evaluate(() => {
    const ids = new Set();
    for (const a of document.querySelectorAll('a[href*="viewforum.php?f="]')) {
      const m = a.getAttribute('href').match(/[?&]f=(\d+)/);
      if (m) ids.add(Number(m[1]));
    }
    return [...ids].sort((a, b) => a - b);
  });
  if (!forums.length) {
    throw new Error(`No forum links on the index -- WAF block or markup change (title: "${await page.title()}")`);
  }
  console.log(`[ok] through the WAF -- "${await page.title()}"`);
  const forumIds = forums;
  console.log(`[ok] forums: ${forumIds.join(', ')}`);

  // 2. Walk every listing page, collecting topic ids.
  //    Termination is by "no NEW ids", not by an empty batch: like viewtopic.php, this
  //    board CLAMPS an out-of-range `start` and re-serves the last page forever, so an
  //    empty-batch break never fires and the crawl spins (observed at start=21400 still
  //    reporting rows). Bound it on progress instead.
  const topics = new Set();
  for (const f of forumIds) {
    for (let start = 0; ; start += 25) {
      const before = topics.size;
      const batch = await page.evaluate(
        async ([origin, f, start]) => {
          const r = await fetch(`${origin}/viewforum.php?f=${f}&start=${start}`, { credentials: 'include' });
          const doc = new DOMParser().parseFromString(await r.text(), 'text/html');
          return [...doc.querySelectorAll('.topiclist.topics li, ul.topics li')]
            .map((li) => {
              const t = li.querySelector('a.topictitle');
              const m = t && t.getAttribute('href').match(/[?&]t=(\d+)/);
              return m ? Number(m[1]) : null;
            })
            .filter(Boolean);
        },
        [ORIGIN, f, start]
      );
      if (!batch.length) break;
      for (const t of batch) topics.add(t);
      if (topics.size === before) break; // clamped to a repeat page -- end of forum
      process.stdout.write(`\r[..] f=${f} start=${start} -- ${topics.size} topics`);
    }
  }
  console.log(`\n[ok] ${topics.size} topics indexed`);

  // 3. Fetch each topic, capturing EVERY post. Member replies inside staff-started
  //    threads matter as much as member-started threads.
  const posts = [];
  const ids = [...topics];
  const CONCURRENCY = 5;
  let done = 0;

  for (let i = 0; i < ids.length; i += CONCURRENCY) {
    const chunk = ids.slice(i, i + CONCURRENCY);
    const got = await page.evaluate(
      async ([origin, chunk]) => {
        const out = [];
        await Promise.all(
          chunk.map(async (tid) => {
            // PAGINATION QUIRK: `start` alone is SILENTLY IGNORED on viewtopic.php --
            // ?t=X&start=25 re-serves page 1, so a bare offset loop drops the tail of any
            // thread over 25 posts (and can spin). `start` only takes effect when `ppp` is
            // ALSO supplied. Verified on t=1492 (44 posts): bare start=25 -> the same 25
            // page-1 posts; start=25&ppp=25 -> the remaining 19.
            const PPP = 25;
            let declared = null;
            let collected = 0;
            for (let start = 0; ; start += PPP) {
              const r = await fetch(`${origin}/viewtopic.php?t=${tid}&ppp=${PPP}&start=${start}`, { credentials: 'include' });
              if (!r.ok) break;
              const doc = new DOMParser().parseFromString(await r.text(), 'text/html');
              const blocks = [...doc.querySelectorAll('div.post')];
              if (!blocks.length) break;
              if (declared === null) {
                const m = (doc.body ? doc.body.innerText : '').match(/(\d+)\s+posts?\b/);
                declared = m ? Number(m[1]) : null;
              }
              for (const b of blocks) {
                const au = b.querySelector('.author a.username, .author a.username-coloured, p.author a.username');
                const author = au ? au.textContent.trim() : '';
                if (!author) continue;
                const body = b.querySelector('.content');
                const subj = b.querySelector('.postbody h3 a, .postbody h3');
                const time = b.querySelector('.author time, .author');
                out.push({
                  topicId: tid,
                  author,
                  subject: subj ? subj.textContent.trim() : '',
                  when: time ? time.textContent.replace(/\s+/g, ' ').trim() : '',
                  text: body ? body.innerText.trim() : '',
                });
              }
              collected += blocks.length;
              if (blocks.length < PPP) break;
              if (declared !== null && collected >= declared) break;
            }
            if (declared !== null && collected < declared) {
              out.push({ topicId: tid, _short: true, _declared: declared, _got: collected });
            }
          })
        );
        return out;
      },
      [ORIGIN, chunk]
    );
    posts.push(...got);
    done += chunk.length;
    process.stdout.write(`\r[..] topics ${done}/${ids.length} -- ${posts.length} posts`);
  }
  await browser.close();

  // Completeness gate: a silently truncated corpus reads exactly like a complete one.
  const short = posts.filter((p) => p._short);
  for (let i = posts.length - 1; i >= 0; i--) if (posts[i]._short) posts.splice(i, 1);
  for (const p of posts) p.text = p.text.replace(NBSP, ' ');

  const isMember = (a) => Object.prototype.hasOwnProperty.call(MEMBERS, a);
  console.log(`\n[ok] ${posts.length} posts (${posts.filter((p) => isMember(p.author)).length} by member accounts)`);

  if (short.length) {
    console.warn(`\n:warning: INCOMPLETE -- ${short.length} topic(s) captured fewer posts than declared:`);
    for (const s of short.slice(0, 20)) console.warn(`   t=${s.topicId}: got ${s._got} of ${s._declared}`);
  } else {
    console.log('[ok] completeness: every topic captured its full declared post count');
  }

  // 4. Emit corpora.
  const render = (heading, provenance, rows) =>
    [
      `# ${heading}`,
      '',
      ...provenance,
      '',
      `Posts: ${rows.length}${SINCE ? ` (since ${SINCE})` : ''}`,
      '',
      ...rows.flatMap((r) => [
        `## ${r.subject || '(no subject)'}`,
        `- author: ${r.author}`,
        `- when: ${r.when}`,
        `- source_url: ${ORIGIN}/viewtopic.php?t=${r.topicId}`,
        '',
        r.text,
        '',
        '---',
        '',
      ]),
    ].join('\n');

  const cut = SINCE ? new Date(SINCE) : null;
  const keep = (r) => {
    if (!cut) return true;
    const d = parseWhen(r.when);
    return d ? d >= cut : true; // keep undated rather than silently drop
  };

  const byAuthor = new Map();
  for (const p of posts) {
    if (!byAuthor.has(p.author)) byAuthor.set(p.author, []);
    byAuthor.get(p.author).push(p);
  }

  const summary = [];
  for (const [name, seat] of Object.entries(MEMBERS)) {
    const rows = (byAuthor.get(name) || []).filter(keep).sort((a, b) => a.topicId - b.topicId);
    const file = resolve(OUT_DIR, `${slug(name)}.md`);
    writeFileSync(
      file,
      render(`${name} -- ${seat}, Austin City Council`, [
        `Source: City of Austin Council Message Board (${ORIGIN}) -- posting is restricted`,
        `to council members and authorized staff.`,
        '',
        `EVERY post below was authored by the **${name}** account itself. Staff-authored`,
        `posts are excluded from this file and must never be attributed to this member.`,
      ], rows),
      'utf8'
    );
    summary.push({ seat, name, posts: rows.length });
  }

  // Staff corpus -- quarantined, for review only.
  const staffDir = resolve(OUT_DIR, '_staff-authored');
  mkdirSync(staffDir, { recursive: true });
  const staff = [];
  for (const [name, rows] of byAuthor) {
    if (isMember(name)) continue;
    const kept = rows.filter(keep).sort((a, b) => a.topicId - b.topicId);
    if (!kept.length) continue;
    writeFileSync(
      resolve(staffDir, `${slug(name)}.md`),
      render(`${name} -- STAFF / NON-MEMBER account`, [
        `Source: City of Austin Council Message Board (${ORIGIN}).`,
        '',
        `:warning: NOT A COUNCIL MEMBER. These posts must NOT be used to seat anyone in a`,
        `compass chair as their own words. Some staff accounts write in the first person on`,
        `an officeholder's behalf (the Mayor's chief of staff opens threads as "I", and`,
        `members reply "Mayor, ..."). Treat that as evidence ABOUT the officeholder that`,
        `needs a human judgment call, never as a quote from them.`,
      ], kept),
      'utf8'
    );
    staff.push({ name, posts: kept.length });
  }

  staff.sort((a, b) => b.posts - a.posts);
  writeFileSync(resolve(OUT_DIR, '_summary.json'), JSON.stringify({ members: summary, staff }, null, 2), 'utf8');
  console.table(summary);
  console.log('\ntop staff/non-member accounts:');
  console.table(staff.slice(0, 10));
  console.log(`\nBOARD_MEMBER_POSTS=${summary.reduce((a, b) => a + b.posts, 0)} BOARD_STAFF_POSTS=${staff.reduce((a, b) => a + b.posts, 0)}`);
  console.log(`corpus -> ${OUT_DIR}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
