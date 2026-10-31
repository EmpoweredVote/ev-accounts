/**
 * legiscan-rollcalls — map official roll-call pages to LegiScan roll calls by state, bill, chamber and counts.
 *
 *   npx tsx --env-file=.env scripts/stage5/legiscan-rollcalls.ts <ST> <vote-pages.json> <out.json>
 *
 * vote-pages.json: [{ url, bill: "SB0010", year: 2025, chamber: "H"|"S", yea, nay }] (yea < 0 matches any count).
 * Prints one line per page with every candidate LegiScan roll call; pick by date and motion, and check the
 * person-level votes later with the cross-check (STAGE5 step 7.7). Every LegiScan call counts against the cap.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { pool } from '../../src/lib/db.js';
import { legiscanQuery } from '../../src/lib/legiscan/client.js';

const [st, inp, outp] = process.argv.slice(2);
const key = process.env.LEGISCAN_API_KEY;
if (!st || !inp || !outp || !key) {
  console.error('usage: legiscan-rollcalls.ts <ST> <vote-pages.json> <out.json>   (needs LEGISCAN_API_KEY)');
  process.exit(2);
}
const pages: any[] = JSON.parse(readFileSync(inp, 'utf8'));
const memo = new Map<string, any>();
const q = async (op: string, p: Record<string, string>) => {
  const k = op + JSON.stringify(p);
  if (!memo.has(k)) memo.set(k, await legiscanQuery(key, op, p));
  return memo.get(k);
};
const sessions: any[] = (await q('getSessionList', { state: st })).sessions;
const out: any[] = [];
for (const pg of pages) {
  const cands = sessions.filter((s) => Number(s.year_start) === pg.year || Number(s.year_start) === pg.year + 1);
  const hits: any[] = [];
  for (const s of cands) {
    const list = (await q('getMasterListRaw', { id: String(s.session_id) })).masterlist ?? {};
    for (const [k, b] of Object.entries<any>(list)) {
      if (k === 'session' || b?.number !== pg.bill) continue;
      const bill = (await q('getBill', { id: String(b.bill_id) })).bill;
      for (const v of bill.votes ?? []) {
        if (v.chamber === pg.chamber && (pg.yea < 0 || (Number(v.yea) === pg.yea && Number(v.nay) === pg.nay))) {
          hits.push({ session: s.session_name, roll_call_id: v.roll_call_id, date: v.date, desc: v.desc, yea: v.yea, nay: v.nay, bill_url: bill.url });
        }
      }
    }
  }
  out.push({ ...pg, hits });
  console.log(pg.url.slice(-14), pg.bill, hits.map((h) => `${h.roll_call_id} ${h.date} ${h.desc} ${h.yea}-${h.nay} [${h.session}]`).join(' | ') || 'NONE');
}
writeFileSync(outp, JSON.stringify(out, null, 1));
await pool.end();
