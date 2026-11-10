// Parse every Ballotpedia "<State> state executive official elections, 2026" page fetched
// 2026-11-06, fold in the two states that had to be read in Playwright, and emit one record
// per general-election votebox.
//
// 🔴 A ZERO-BYTE FILE PARSES CLEANLY AND YIELDS NOTHING, which reads as "that state held no
//    elections" — exactly the false absence this whole programme keeps paying for. WI and WY
//    answered curl HTTP 202 with an EMPTY body on three retries each. Every input file is
//    therefore size-checked before it is parsed, and a state that yields no votebox is named.
import fs from 'node:fs';
const SP = process.argv[2];
const STATES = JSON.parse(fs.readFileSync(`${SP}/all-states.json`, 'utf8'));
const PW = JSON.parse(fs.readFileSync(`${SP}/bp-playwright.json`, 'utf8'));

const ent = s => s.replace(/&#160;/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
  .replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>');
const text = s => ent(s.replace(/<[^>]*>/g, ' ')).replace(/\s+/g, ' ').trim();

function parseHtml(html) {
  const out = [];
  const parts = html.split(/<h5 class="votebox-header-election-type">/);
  for (let i = 1; i < parts.length; i++) {
    const blk = parts[i];
    const hdr = text(blk.slice(0, blk.indexOf('</h5>')));
    if (!/^General election for /i.test(hdr)) continue;
    const narM = blk.match(/<p class="results_text">([\s\S]*?)<\/p>/);
    const cands = [];
    for (const m of blk.matchAll(/<tr class="results_row( winner)?">([\s\S]*?)<\/tr>/g)) {
      const cellM = m[2].match(/<td class="votebox-results-cell--text">([\s\S]*?)<\/td>/);
      if (!cellM) continue;
      const raw = text(cellM[1]);
      if (/^Other\/Write-in votes$/i.test(raw)) continue;   // a ballot aggregate, not a person
      // ⚠ A TICKET CELL CARRIES TWO LINKS, one per person. Keeping only the first gave the
      //   governor's article to the lieutenant-governor candidate, and left nine running mates
      //   with no source URL at all. Capture them all and map them to the names positionally.
      const urls = [...cellM[1].matchAll(/href="(https:\/\/ballotpedia\.org\/[^"]+)"/g)].map(m => m[1]);
      const urlM = urls.length ? [null, urls[0]] : null;
      const partyM = raw.match(/\(([^)]+)\)/g) || [];
      const full = raw.replace(/\s*\([^)]*\)\s*/g, ' ').replace(/\s+/g, ' ').trim();
      const slash = full.split(/\s*\/\s*/);
      const pctM = m[2].match(/<div class="percentage_number">([\d.]+)<\/div>/);
      const nums = [...m[2].matchAll(/<td class="votebox-results-cell--number">([^<]*)<\/td>/g)].map(x => text(x[1]));
      const vRaw = nums.length ? nums[nums.length - 1].replace(/,/g, '') : '';
      cands.push({
        name: slash[0].trim(), runningMate: slash.length > 1 ? slash.slice(1).join(' / ').trim() : null,
        party: partyM.length ? partyM[0].slice(1, -1) : null,
        writeIn: /\(Write-in\)/i.test(raw), won: !!m[1],
        url: urlM ? urlM[1] : null,
        mateUrl: urls.length > 1 ? urls[1] : null,
        bpPct: pctM ? Number(pctM[1]) : null,
        bpVotes: /^\d+$/.test(vRaw) ? Number(vRaw) : null,
      });
    }
    if (cands.length) out.push({ header: hdr, narrative: narM ? text(narM[1]) : '', candidates: cands });
  }
  return out;
}

const out = [], noPage = [], noVotebox = [];
for (const [st, name] of Object.entries(STATES)) {
  let boxes;
  if (PW[st]) { boxes = PW[st]; }
  else {
    const p = `${SP}/bpall/${st}_exec.html`;
    const size = fs.existsSync(p) ? fs.statSync(p).size : 0;
    if (size === 0) throw new Error(`${st}: input file is ${size} bytes — refusing to read an empty fetch as "no elections"`);
    const html = fs.readFileSync(p, 'utf8');
    if (/"wgRelevantArticleId":0/.test(html)) { noPage.push(st); continue; }
    boxes = parseHtml(html);
  }
  if (!boxes.length) { noVotebox.push(st); continue; }
  for (const b of boxes) {
    // the office title, with the state stripped from WHICHEVER END it sits on
    let office = b.header.replace(/^General election for\s*/i, '').trim();
    office = office.replace(new RegExp(`\\s+of\\s+${name}$`, 'i'), '').replace(new RegExp(`^${name}\\s+`, 'i'), '').trim();
    out.push({ st, office, source: PW[st] ? 'playwright' : 'curl', ...b });
  }
}
fs.writeFileSync(`${SP}/bp-all-ballots.json`, JSON.stringify(out, null, 1));

console.log(`states asked for:            ${Object.keys(STATES).length}`);
console.log(`no Ballotpedia article:      ${noPage.length}  ${noPage.join(' ')}`);
console.log(`article but no votebox:      ${noVotebox.length}  ${noVotebox.join(' ')}`);
console.log(`general-election voteboxes:  ${out.length}`);
console.log(`states with at least one:    ${new Set(out.map(r => r.st)).size}`);
console.log(`candidate rows:              ${out.reduce((n, r) => n + r.candidates.length, 0)}`);
console.log(`voteboxes with a winner:     ${out.filter(r => r.candidates.some(c => c.won)).length}`);
console.log(`voteboxes with NO winner:    ${out.filter(r => !r.candidates.some(c => c.won)).length}`);
const multi = out.filter(r => r.candidates.filter(c => c.won).length > 1);
if (multi.length) { console.log(`🔴 ${multi.length} votebox(es) mark MORE THAN ONE winner:`); for (const r of multi) console.log(`   ${r.st} ${r.office}`); }
