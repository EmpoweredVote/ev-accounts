import fs from 'node:fs';
const rows = JSON.parse(fs.readFileSync('roster-named.json','utf8'));
const q = s => "'" + String(s).replace(/'/g, "''") + "'";

// how_started: a December 1 arrival is the constitutional term start, i.e. elected.
// Anything else is a mid-term gubernatorial appointment — Idaho never fills a legislative
// vacancy by special election (Idaho Code 59-904A).
// For the four YEAR-ONLY arrivals the day is unknown, so the EVEN/ODD year decides it:
// Idaho elects legislators only in even years, so an odd-year arrival cannot be an election.
function started(r) {
  if (r.start_precision === 'day') return /-12-01$/.test(r.term_start) ? 'elected' : 'appointed';
  const yr = Number(r.term_start.slice(0,4));
  return yr % 2 === 0 ? 'elected' : 'appointed';
}

const lines = rows.map(r => {
  const ch = r.chamber === 'Senate' ? 'S' : 'H';
  const how = started(r);
  const seatTxt = r.seat ? `, Seat ${r.seat}` : '';
  const why = r.start_precision === 'year'
    ? `Ballotpedia gives the YEAR only, so start_precision is 'year' at ${r.term_start} and the day is not invented. ${Number(r.term_start.slice(0,4)) % 2 === 0 ? 'An even year, and Idaho legislative terms begin 1 December of even years, so this is an election.' : 'An ODD year — Idaho elects legislators only in even years, so this arrival can only be a gubernatorial appointment.'}`
    : (how === 'elected'
        ? 'A 1 December arrival, which is the constitutional term start (Idaho Const. Art. III sec. 3), so this is an election.'
        : 'NOT a 1 December date, so this is a mid-term gubernatorial appointment — Idaho fills a legislative vacancy by appointment from three names submitted by the district central committee (Idaho Code sec. 59-904A), never by special election.');
  const src = `legislature.idaho.gov ${r.chamber} membership roster and ballotpedia.org, both read 2026-10-30 (CC_0310): listed for Legislative District ${r.district}${seatTxt}. Both sources agree on the person, the district, the seat and the party; term_start is Ballotpedia's date assumed office, which is continuous occupancy of this chamber rather than the current term. ${why}`;
  return `  (${q(ch)}, ${r.district}, ${r.seat ? q(r.seat) : 'NULL'}, ${q(r.full_name)}, ${q(r.first_name)}, ${q(r.last_name)}, ${r.suffix ? q(r.suffix) : 'NULL'}, DATE ${q(r.term_start)}, ${q(r.start_precision)}, ${q(how)}, ${q(src)})`;
});

const counts = {
  total: rows.length,
  senate: rows.filter(r => r.chamber === 'Senate').length,
  house: rows.filter(r => r.chamber === 'House').length,
  elected: rows.filter(r => started(r) === 'elected').length,
  appointed: rows.filter(r => started(r) === 'appointed').length,
  day: rows.filter(r => r.start_precision === 'day').length,
  year: rows.filter(r => r.start_precision === 'year').length,
};
fs.writeFileSync('_cc0310_values.sql', lines.join(',\n') + ';');
fs.writeFileSync('_cc0310_counts.json', JSON.stringify(counts, null, 2));
console.log(JSON.stringify(counts, null, 2));
