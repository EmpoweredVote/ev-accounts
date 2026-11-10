// Parse Ballotpedia's "<State> state executive official elections, 2026" pages into a
// ballot per race: who was on it, their party, whether Ballotpedia calls them the incumbent,
// and their Ballotpedia article URL.
//
// 🔴 THIS PAGE IS AUTHORITATIVE FOR IDENTITY AND STALE FOR NUMBERS. Its counts were still
//    rising when read (Maine's governor: 261,518 here against AP's 382,760). Percentages are
//    captured ONLY so a later check can show the two sources are counting the same contest —
//    NOT ONE NUMBER FROM HERE IS WRITTEN TO THE DATABASE.
// ⚠ A page carries primary voteboxes too. Only "General election for ..." headers are taken.
import fs from 'node:fs';
const SP = process.argv[2];
const STATES = JSON.parse(fs.readFileSync(`${SP}/bp-states.json`, 'utf8'));

const ent = s => s.replace(/&#160;/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
  .replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>');
const text = s => ent(s.replace(/<[^>]*>/g, ' ')).replace(/\s+/g, ' ').trim();

const out = [];
for (const [st, name] of Object.entries(STATES)) {
  const html = fs.readFileSync(`${SP}/bp/${st}_exec.html`, 'utf8');
  // split on votebox headers, keeping each header with the block that follows it
  const parts = html.split(/<h5 class="votebox-header-election-type">/);
  let found = 0;
  for (let i = 1; i < parts.length; i++) {
    const blk = parts[i];
    const hdr = text(blk.slice(0, blk.indexOf('</h5>')));
    if (!/^General election for /i.test(hdr)) continue;      // skip primaries / runoffs
    // ⚠ Ballotpedia writes the state EITHER WAY: "Governor of Alabama" but "Alabama Secretary
    //   of State". Stripping only the suffix lost the Secretary of State table in six states
    //   and reported each as "no Ballotpedia table" — a silent false absence, not a real gap.
    let office = hdr.replace(/^General election for\s*/i, '').trim();
    office = office.replace(new RegExp(`\\s+of\\s+${name}$`, 'i'), '').replace(new RegExp(`^${name}\\s+`, 'i'), '').trim();
    const narrativeM = blk.match(/<p class="results_text">([\s\S]*?)<\/p>/);
    const narrative = narrativeM ? text(narrativeM[1]) : '';

    const rows = [...blk.matchAll(/<tr class="results_row( winner)?">([\s\S]*?)<\/tr>/g)];
    const cands = [];
    for (const m of rows) {
      const won = !!m[1];
      const cellM = m[2].match(/<td class="votebox-results-cell--text">([\s\S]*?)<\/td>/);
      if (!cellM) continue;
      const cell = cellM[1];
      const urlM = cell.match(/href="(https:\/\/ballotpedia\.org\/[^"]+)"/);
      const raw = text(cell);
      if (/^Other\/Write-in votes$/i.test(raw)) continue;    // a ballot aggregate, not a person
      const partyM = raw.match(/\(([^)]+)\)/g) || [];
      const writeIn = /\(Write-in\)/i.test(raw);
      // 🔴 A GOVERNOR AND LIEUTENANT GOVERNOR RUN AS ONE BALLOT LINE in many states, and
      //    Ballotpedia prints the pair: "Byron Donalds / Bryan Avila". AP names only the head
      //    of the ticket. Taking the whole string's last word pairs AP's governor against the
      //    RUNNING MATE's surname and reports every such race as a disagreement — it reported
      //    8 states' governors as absent from Ballotpedia before this split existed.
      const full = raw.replace(/\s*\([^)]*\)\s*/g, ' ').replace(/\s+/g, ' ').trim();
      const slash = full.split(/\s*\/\s*/);
      const cname = slash[0].trim();
      const runningMate = slash.length > 1 ? slash.slice(1).join(' / ').trim() : null;
      const party = partyM.length ? partyM[0].slice(1, -1) : null;
      const pctM = m[2].match(/<div class="percentage_number">([\d.]+)<\/div>/);
      const nums = [...m[2].matchAll(/<td class="votebox-results-cell--number">([^<]*)<\/td>/g)].map(x => text(x[1]));
      cands.push({
        name: cname, runningMate, party, writeIn, won, url: urlM ? urlM[1] : null,
        bpPct: pctM ? Number(pctM[1]) : null,
        bpVotes: nums.length ? Number(nums[nums.length - 1].replace(/,/g, '')) : null,
      });
    }
    if (!cands.length) continue;
    out.push({ st, office, header: hdr, narrative, candidates: cands });
    found++;
  }
  if (!found) console.log(`⚠ ${st}: NO general-election votebox parsed from the page`);
}
fs.writeFileSync(`${SP}/bp-ballots.json`, JSON.stringify(out, null, 1));
console.log(`general-election voteboxes parsed: ${out.length}`);
console.log(`states covered:                    ${new Set(out.map(r => r.st)).size} of ${Object.keys(STATES).length}`);
console.log(`named candidates:                  ${out.reduce((n, r) => n + r.candidates.length, 0)}`);
console.log(`with a Ballotpedia article URL:    ${out.reduce((n, r) => n + r.candidates.filter(c => c.url).length, 0)}`);
const noParty = out.flatMap(r => r.candidates.filter(c => !c.party).map(c => `${r.st} ${r.office}: ${c.name}`));
if (noParty.length) { console.log(`⚠ ${noParty.length} candidate(s) with no party parsed:`); for (const s of noParty.slice(0, 20)) console.log(`    ${s}`); }
