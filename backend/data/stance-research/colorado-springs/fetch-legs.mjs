#!/usr/bin/env node
/**
 * Harvest Colorado legislator source pages. leg.colorado.gov has no WAF, so plain fetch works
 * and is far faster than the browser path harvest.mjs needs for cpr.org.
 *
 * For each legislator: the leg.colorado.gov member page (committees + current-session prime
 * sponsorships) and, if the member page links one, their caucus/personal site — which is
 * usually where an actual issues statement lives. Sponsorship gives direction reliably;
 * the issues page is what can name a chair.
 */
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

const HERE = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const OUT = path.join(HERE, 'sources');
await mkdir(OUT, { recursive: true });

const LEGS = [
  ['lynda-zamora-wilson', 'Lynda Zamora Wilson', 'Senate District 9'],
  ['larry-liston', 'Larry Liston', 'Senate District 10'],
  ['tony-exum', 'Tony Exum', 'Senate District 11'],
  ['marc-snyder', 'Marc Snyder', 'Senate District 12'],
  ['rod-pelton', 'Rod Pelton', 'Senate District 35'],
  ['ava-flanell', 'Ava Flanell', 'House District 14'],
  ['scott-bottoms', 'Scott Bottoms', 'House District 15'],
  ['rebecca-keltie', 'Rebecca Keltie', 'House District 16'],
  ['regina-english', 'Regina English', 'House District 17'],
  ['amy-paschal', 'Amy Paschal', 'House District 18'],
  ['jarvis-caldwell', 'Jarvis Caldwell', 'House District 20'],
  ['mary-bradfield', 'Mary Bradfield', 'House District 21'],
  ['ken-degraaf', 'Ken DeGraaf', 'House District 22'],
  ['chris-richardson', 'Chris Richardson', 'House District 56'],
];

const UA = { 'User-Agent': 'EmpoweredVote/1.0 (civic data; chris@empowered.vote)' };

/** Crude but adequate HTML → text. These are content pages, not apps. */
const toText = (html) =>
  html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, ' ')
    .replace(/<\/(p|div|li|tr|h[1-6]|section|article)>/gi, '\n')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&#039;|&apos;/g, "'")
    .replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/[ \t]{2,}/g, ' ')
    .replace(/\n\s*\n\s*\n+/g, '\n\n')
    .trim();

const get = async (url) => {
  const r = await fetch(url, { headers: UA, redirect: 'follow' });
  return { status: r.status, html: r.ok ? await r.text() : '' };
};

let ok = 0, fail = 0;
for (const [slug, name, seat] of LEGS) {
  const memberUrl = `https://leg.colorado.gov/legislators/${slug}`;
  try {
    const { status, html } = await get(memberUrl);
    if (status !== 200 || html.length < 5000) {
      console.log(`FAIL  ${slug.padEnd(22)} member page http=${status}`);
      fail++;
      continue;
    }
    const text = toText(html);

    // The member page links the member's caucus/personal site — usually the only place with a
    // real issues statement. Grab it too when it isn't a mailto/social link.
    const links = [...html.matchAll(/<a[^>]+href="(https?:\/\/[^"]+)"/gi)].map((m) => m[1]);
    const personal = links.find((h) =>
      /coloradohouserepublicans|cohousedems|coloradosenatedems|coloradosenategop|forcolorado|\.com\/|\.org\//i.test(h) &&
      !/twitter|facebook|instagram|youtube|linkedin|leg\.colorado\.gov|colorado\.gov\/pacific|google/i.test(h)
    );

    let extra = '';
    let personalStatus = null;
    if (personal) {
      try {
        const p = await get(personal);
        personalStatus = p.status;
        if (p.status === 200 && p.html.length > 2000) {
          extra = `\n\n---\n\n## Caucus / personal site\n\n- url: ${personal}\n- http_status: ${p.status}\n\n${toText(p.html).slice(0, 20000)}`;
        }
      } catch (e) { personalStatus = e.message.slice(0, 40); }
    }

    const head = [
      `# ${name} — Colorado ${seat}`,
      ``,
      `- source_url: ${memberUrl}`,
      `- harvested: 2026-08-21`,
      `- http_status: ${status}`,
      personal ? `- personal_site: ${personal} (http=${personalStatus})` : `- personal_site: none found`,
      `- note: leg.colorado.gov shows CURRENT-SESSION prime sponsorships only; there is no session`,
      `  selector on the member page. Sponsorship proves direction; it does not by itself prove`,
      `  which chair on that side applies.`,
      ``,
      `---`,
      ``,
      `## leg.colorado.gov member page`,
      ``,
    ].join('\n');

    await writeFile(path.join(OUT, `leg-${slug}.md`), head + text + extra, 'utf8');
    console.log(`OK    ${slug.padEnd(22)} ${String(text.length).padStart(6)} chars${personal ? ` +site(${personalStatus})` : ''}`);
    ok++;
  } catch (e) {
    console.log(`ERR   ${slug.padEnd(22)} ${e.message.slice(0, 60)}`);
    fail++;
  }
  await new Promise((r) => setTimeout(r, 800));
}
console.log(`\nLEGS ok=${ok} fail=${fail}`);
