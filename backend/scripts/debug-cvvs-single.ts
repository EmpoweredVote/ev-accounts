/**
 * debug-cvvs-single.ts — Fetch first window vote IDs, then parse one in detail
 */
import 'dotenv/config';
import { chromium } from 'playwright';

const CVVS_BASE = 'https://cityclerk.lacity.org/cvvs/search';

function normalizeVote(raw: string): string | null {
  const v = raw.trim().toUpperCase();
  const map: Record<string, string> = {
    'YES': 'YES', 'AYE': 'YES', 'NO': 'NO', 'NAY': 'NO',
    'ABSENT': 'ABSENT', 'ABSTAIN': 'ABSTAIN', 'ABSTAINED': 'ABSTAIN',
    'RECUSE': 'RECUSE', 'RECUSED': 'RECUSE', 'PRESENT': 'PRESENT',
  };
  return map[v] ?? null;
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ javaScriptEnabled: false });

  // ── Step 1: get vote IDs from the first window ────────────────────────────
  const searchPage = await context.newPage();
  await searchPage.goto(`${CVVS_BASE}/search.cfm`);
  await searchPage.evaluate(() => {
    (document.querySelector('input[name="startdate"]') as HTMLInputElement).value = '12/31/2024';
    (document.querySelector('input[name="enddate"]') as HTMLInputElement).value = '01/13/2025';
    (document.querySelector('form[name="form"]') as HTMLFormElement).submit();
  });
  await searchPage.waitForLoadState('networkidle');

  const html = await searchPage.content();
  const voteIds = [...new Set(
    [...html.matchAll(/votedetails\.cfm\?voteid=(\d+)/g)].map(m => parseInt(m[1], 10))
  )];
  console.log(`Found ${voteIds.length} vote IDs: first 10 = ${voteIds.slice(0, 10).join(', ')}`);
  await searchPage.close();

  if (voteIds.length === 0) {
    console.log('No vote IDs found — check if search form worked');
    await browser.close();
    return;
  }

  // ── Step 2: parse the first vote ID in detail ─────────────────────────────
  const testId = voteIds[0];
  console.log(`\n=== Detailed parse of vote ${testId} ===`);

  const page = await context.newPage();
  await page.goto(`${CVVS_BASE}/votedetails.cfm?voteid=${testId}`);
  await page.waitForLoadState('load');

  const text = await page.evaluate(() => document.body.innerText);
  console.log('\nFull innerText lines:');
  const lines = text.split('\n').map(l => l.trim()).filter(Boolean);
  lines.forEach((l, i) => console.log(`  [${i}] ${JSON.stringify(l)}`));

  // Date parsing
  const dateMatch = text.match(/Meeting Date:\s*(?:[A-Z]+\s+)?([A-Z]+ \d{1,2}, \d{4})/i);
  console.log('\ndateMatch:', dateMatch?.[1]);
  if (dateMatch) {
    const parsed = new Date(dateMatch[1]);
    console.log('  new Date result:', parsed.toString(), '| isNaN:', isNaN(parsed.getTime()));
    const y = parsed.getUTCFullYear();
    const m = String(parsed.getUTCMonth() + 1).padStart(2, '0');
    const d = String(parsed.getUTCDate()).padStart(2, '0');
    console.log('  UTC date:', `${y}-${m}-${d}`);
  }

  // Member vote parsing
  let inVoteSection = false;
  const memberVotes: any[] = [];
  for (const line of lines) {
    if (line.includes('Member Name')) { inVoteSection = true; continue; }
    if (line.includes('Vote Given') || line.match(/^\(\d+ - \d+ - \d+\)/)) continue;
    if (!inVoteSection) continue;
    const tokens = line.split(/\s{2,}|\t/).map(t => t.trim()).filter(Boolean);
    if (tokens.length < 3) {
      console.log(`  SKIPPED (${tokens.length} tokens): ${JSON.stringify(line)}`);
      continue;
    }
    const vote = normalizeVote(tokens[tokens.length - 1]);
    if (!vote) {
      console.log(`  SKIPPED (bad vote '${tokens[tokens.length - 1]}'): ${JSON.stringify(line)}`);
      continue;
    }
    const nameParts = tokens.slice(0, -2);
    const memberName = nameParts.join(' ').toUpperCase().trim();
    memberVotes.push({ memberName, vote });
  }

  console.log(`\nParsed ${memberVotes.length} member votes:`);
  memberVotes.forEach(mv => console.log(`  ${mv.memberName} → ${mv.vote}`));

  await page.close();
  await browser.close();
}

main().catch(err => { console.error(err); process.exit(1); });
