/**
 * emit-fec-recommended-picks.ts — emit the recommended pick per review case as TSV,
 * using the SAME ranking the HTML review tool displays. Optional per-source overrides.
 *
 * Usage: tsx scripts/emit-fec-recommended-picks.ts <in.json> [<source_id>=<candidate_id> ...]
 * Output (stdout): <source_id>\t<candidate_id>\t<full_name>
 */
import { readFile } from 'node:fs/promises';

const CURRENT_CYCLE = 2026;
const IN = process.argv[2];
const overrides = new Map<string, string>();
for (const a of process.argv.slice(3)) {
  const [s, c] = a.split('=');
  if (s && c) overrides.set(s, c);
}

interface Opt { candidate_id: string; office_full: string | null; state: string | null; incumbent_challenge: string | null; cycles: number[]; score: number | null }
interface Case { source_id: string; full_name: string; source_system: string; representing_state: string; options: Opt[] }

function recommended(c: Case): string {
  const want = c.source_system === 'fec_senate' ? 'Senate' : 'House';
  const ranked = c.options.map(o => ({
    o,
    eligible: o.office_full === want && o.state === c.representing_state,
    incumbent: /incumbent/i.test(o.incumbent_challenge ?? ''),
    hasCurrent: o.cycles.includes(CURRENT_CYCLE),
  }));
  ranked.sort((a, b) => {
    if (a.eligible !== b.eligible) return a.eligible ? -1 : 1;
    if (a.incumbent !== b.incumbent) return a.incumbent ? -1 : 1;
    if (a.hasCurrent !== b.hasCurrent) return a.hasCurrent ? -1 : 1;
    if (b.o.cycles.length !== a.o.cycles.length) return b.o.cycles.length - a.o.cycles.length;
    return (b.o.score ?? 0) - (a.o.score ?? 0);
  });
  const top = ranked[0];
  return top && top.eligible ? top.o.candidate_id : '';
}

const cases: Case[] = JSON.parse(await readFile(IN!, 'utf8'));
let emitted = 0, skipped = 0;
for (const c of cases) {
  const pick = overrides.get(c.source_id) ?? recommended(c);
  if (!pick) { skipped++; process.stderr.write(`[skip] no recommendation: ${c.full_name} (${c.source_id})\n`); continue; }
  process.stdout.write(`${c.source_id}\t${pick}\t${c.full_name}\n`);
  emitted++;
}
process.stderr.write(`[emit] ${emitted} picks, ${skipped} skipped\n`);
