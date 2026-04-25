/**
 * deidentifyQuotes.ts — Read-Rank quote deidentification pipeline.
 *
 * Three subcommands operate on a single review markdown file:
 *
 *   1. scan   → finds quotes lacking deidentified_text, flags reveal patterns,
 *               writes a structured review file with one section per flagged quote.
 *   2. draft  → reads review file, calls Claude API on each unrewritten section,
 *               appends a Suggested rewrite. Uses prompt caching on the system
 *               prompt (rewrite rules are identical across calls).
 *   3. apply  → reads review file, parses APPROVED/EDIT decisions, UPDATEs
 *               essentials.quotes.deidentified_text. Originals (quote_text)
 *               are never touched.
 *
 * Detection categories (lighter-touch — bare state names alone don't qualify):
 *   - Office titles tied to current role ("as Senator", "I'm a commissioner")
 *   - Acts only one office can do ("I signed an executive order", "directing the state")
 *   - Party self-ID ("our Democratic Party", "Indiana Republicans drew")
 *   - Specific districts/jurisdictions narrow enough to identify
 *   - Self-naming or proper-noun hits matching the politician's record
 *
 * Reveals NOT flagged: bare state names ("California", "Indiana", "Hoosier"),
 * generic "we", broad policy advocacy without office claim.
 *
 * Convention: brackets [] mark substitutions in the rewrite. Pure deletions
 * are unbracketed. Originals always preserved in quote_text.
 *
 * Usage (from ev-accounts root):
 *   DATABASE_URL="..." ANTHROPIC_API_KEY="..." \
 *     npx tsx backend/scripts/deidentifyQuotes.ts scan --out review.md
 *
 *   ... edit review.md if needed, or pipe straight into draft ...
 *
 *   npx tsx backend/scripts/deidentifyQuotes.ts draft --in review.md
 *   ... open review.md, mark each section APPROVED or write EDIT: <text> or SKIP ...
 *   npx tsx backend/scripts/deidentifyQuotes.ts apply --in review.md --confirm
 */

import 'dotenv/config';
import fs from 'fs';
import pg from 'pg';
import Anthropic from '@anthropic-ai/sdk';

const { Pool } = pg;

const MODEL = process.env.DEIDENTIFY_MODEL ?? 'claude-sonnet-4-6';
const MAX_TOKENS = 600;

// ---------------------------------------------------------------------------
// Detection patterns — case-insensitive substring/regex tests
// ---------------------------------------------------------------------------

interface PatternHit {
  category: 'office' | 'jurisdiction' | 'party' | 'propnoun';
  match: string;
}

const OFFICE_PATTERNS: RegExp[] = [
  /\b(as|i'?m|i am)\s+(a\s+|the\s+)?(senator|governor|lieutenant governor|mayor|commissioner|councilor|councilmember|representative|congressman|congresswoman|judge|sheriff|prosecutor|delegate|chair)\b/i,
  /\bin (the )?(senate|house|congress|legislature|council|state house|statehouse)\b/i,
  /\bsince i (came|came to|joined) (the )?(senate|congress|house|council)\b/i,
  /\bmy time as\b/i,
  /\bwhen i (was|served) (a |the )?\b/i,
  /\b(i|we) (signed|directed|declared|am declaring|are signing|directing) (an? )?(executive order|state of emergency|directive)\b/i,
];

const JURISDICTION_PATTERNS: RegExp[] = [
  /\b(monroe county|santa clarita valley|antelope valley|iu bloomington|marion county|lake county)\b/i, // narrow places
  /\bin my district\b/i,
  /\b(my|our) constituents\b/i,
];

const PARTY_PATTERNS: RegExp[] = [
  /\bour (own )?(democratic|republican) party\b/i,
  /\b(indiana|california|texas|new york|florida|ohio|pennsylvania|illinois) (democrats?|republicans?)\b/i,
  /\bour party'?s\b/i,
  /\b(my|our) caucus\b/i,
  /\b(my|our) administration\b/i,
];

function detectReveals(quoteText: string, politicianName: string): PatternHit[] {
  const hits: PatternHit[] = [];

  for (const pattern of OFFICE_PATTERNS) {
    const m = quoteText.match(pattern);
    if (m) hits.push({ category: 'office', match: m[0] });
  }
  for (const pattern of JURISDICTION_PATTERNS) {
    const m = quoteText.match(pattern);
    if (m) hits.push({ category: 'jurisdiction', match: m[0] });
  }
  for (const pattern of PARTY_PATTERNS) {
    const m = quoteText.match(pattern);
    if (m) hits.push({ category: 'party', match: m[0] });
  }

  // Proper-noun match against politician's own first/last name
  const parts = politicianName.split(/\s+/).filter((p) => p.length >= 3 && !['the', 'jr', 'sr', 'iii'].includes(p.toLowerCase()));
  for (const part of parts) {
    const re = new RegExp(`\\b${part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'i');
    if (re.test(quoteText)) hits.push({ category: 'propnoun', match: part });
  }

  return hits;
}

// ---------------------------------------------------------------------------
// System prompt for Claude rewrites — long enough to cache, stable across calls
// ---------------------------------------------------------------------------

const REWRITE_SYSTEM_PROMPT = `You are deidentifying political quotes for a blind-ranking application called Read-Rank. Users rank candidate quotes WITHOUT knowing who said them; the speaker is revealed only after ranking. Your job is to rewrite quotes that contain identity-revealing phrases so the speaker is no longer obvious, while preserving meaning, tone, and stance.

# Core principles

1. **Minimum change.** Edit as little as possible. If only one phrase reveals identity, only modify that phrase. Do not rephrase or restructure unaffected sentences.

2. **Brackets [] mark substitutions.** When you replace one phrase with another, wrap the replacement in square brackets so a reader can see the editorial change. Example: "I [have] fought for expanded coverage." Pure deletions (removing a phrase that wasn't replaced with anything) do NOT need brackets.

3. **Preserve stance and emotional tone.** If the original is forceful, keep it forceful. If reflective, keep it reflective.

4. **Preserve grammar.** The rewrite must be a natural-sounding sentence.

5. **Lighter touch — don't over-scrub.** Bare state names ("California", "Indiana", "Texas") and demographic terms ("Hoosier", "Californian") are NOT identifying on their own — many politicians come from each state. Leave them alone unless paired with a narrowing reveal.

# What TO scrub

- **Explicit office claims:** "As Lieutenant Governor of California", "since I came to the Senate", "as long as I'm a commissioner".
- **Acts only one office can do:** "I signed an executive order" (governor), "I am declaring a state of emergency" (mayor), "We are signing 17 bills today" (governor).
- **Party self-ID:** "our own Democratic Party", "Indiana Republicans drew maps", "our caucus".
- **Specific districts:** "Santa Clarita Valley and the Antelope Valley" (narrows to one House district), "Monroe County" combined with role context.
- **Vote claims + state combo:** "I voted yes on the USMCA. It is a better deal for Indiana farmers..." — voted = member of Congress; state narrows.
- **Body memberships:** "I was on the affordable housing commission in this county" — committee + jurisdiction = identifiable.

# What NOT to scrub

- Bare state name without office claim ("California must build more homes").
- Generic "we" referring to a state or community.
- Bill numbers (AB 2099, Prop 1, USMCA) without authorship claim.
- Broad policy advocacy without role claim.
- Fourth Amendment, Constitution, etc. — content references, not identity.

# Output format

Respond with ONLY the rewritten quote text. No preamble, no quotes around it, no commentary. If the quote needs no change, respond with the literal token KEEP_ORIGINAL.

# Examples

Original: "As Lieutenant Governor of California, I will do everything in my power to protect reproductive rights in our state."
Reveals: office=lieutenant governor, propnoun=california+title combo
Rewrite: I will do everything in my power to protect reproductive rights in our state.

Original: "Today I signed an executive order ensuring Indiana continues to be a state that protects life."
Reveals: act-only-governor=I signed an executive order
Rewrite: [We are ensuring] Indiana continues to be a state that protects life.

Original: "Indiana Republicans drew maps that reflect this state's conservative values."
Reveals: party=Indiana Republicans
Rewrite: [Indiana lawmakers] drew maps that reflect this state's conservative values.

Original: "California is leading on AI accountability."
Reveals: none (bare state name only — not identifying)
Rewrite: KEEP_ORIGINAL`;

// ---------------------------------------------------------------------------
// Review file format
// ---------------------------------------------------------------------------
//
// Each quote section looks like:
//
// ## QUOTE <uuid>
// **Politician:** <name>
// **Topic:** <topic_key>
// **Reveals:** office=..., party=...
// **Original:** <text>
// **Suggested:** <claude-drafted text or empty until draft step>
// **Decision:** <APPROVED | EDIT: <new text> | SKIP | (blank)>
//
// ---
//
// `apply` reads each section's Decision line:
//   APPROVED → use Suggested as deidentified_text
//   EDIT: ... → use the EDIT text as deidentified_text
//   SKIP → no change
//   blank → skipped (no decision yet)

interface ReviewSection {
  id: string;
  politician: string;
  topic: string;
  reveals: string;
  original: string;
  suggested: string;
  decision: string;
}

function formatSection(s: ReviewSection): string {
  return [
    `## QUOTE ${s.id}`,
    `**Politician:** ${s.politician}`,
    `**Topic:** ${s.topic}`,
    `**Reveals:** ${s.reveals}`,
    `**Original:** ${s.original}`,
    `**Suggested:** ${s.suggested}`,
    `**Decision:** ${s.decision}`,
    '',
    '---',
    '',
  ].join('\n');
}

function parseReviewFile(content: string): ReviewSection[] {
  const sections: ReviewSection[] = [];
  const blocks = content.split(/^## QUOTE /m).slice(1); // skip preamble
  for (const block of blocks) {
    const lines = block.split('\n');
    const id = lines[0].trim();
    const get = (label: string) => {
      const line = lines.find((l) => l.startsWith(`**${label}:**`));
      return line ? line.replace(`**${label}:**`, '').trim() : '';
    };
    sections.push({
      id,
      politician: get('Politician'),
      topic: get('Topic'),
      reveals: get('Reveals'),
      original: get('Original'),
      suggested: get('Suggested'),
      decision: get('Decision'),
    });
  }
  return sections;
}

function writeReviewFile(path: string, sections: ReviewSection[], header?: string): void {
  const preamble =
    header ??
    `# Deidentification review

For each quote: review **Suggested**, then set **Decision** to one of:
- \`APPROVED\` — use the Suggested text as-is
- \`EDIT: <your version>\` — use your version instead
- \`SKIP\` — leave original unchanged (no deidentified_text written)

Then run: \`tsx backend/scripts/deidentifyQuotes.ts apply --in <this-file> --confirm\`

---

`;
  fs.writeFileSync(path, preamble + sections.map(formatSection).join(''));
}

// ---------------------------------------------------------------------------
// DB
// ---------------------------------------------------------------------------

function getPool(): pg.Pool {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is required');
  }
  return new Pool({ connectionString: process.env.DATABASE_URL });
}

async function fetchUnrewrittenQuotes(pool: pg.Pool): Promise<
  Array<{ id: string; quote_text: string; topic_key: string; politician_name: string }>
> {
  const { rows } = await pool.query(`
    SELECT q.id, q.quote_text, q.topic_key, p.full_name AS politician_name
    FROM essentials.quotes q
    JOIN essentials.politicians p ON p.id = q.politician_id
    WHERE q.deidentified_text IS NULL
    ORDER BY p.full_name, q.topic_key
  `);
  return rows;
}

// ---------------------------------------------------------------------------
// Subcommands
// ---------------------------------------------------------------------------

async function cmdScan(outPath: string): Promise<void> {
  const pool = getPool();
  try {
    const quotes = await fetchUnrewrittenQuotes(pool);
    console.log(`Scanned ${quotes.length} quotes lacking deidentified_text.`);

    const sections: ReviewSection[] = [];
    for (const q of quotes) {
      const hits = detectReveals(q.quote_text, q.politician_name);
      if (hits.length === 0) continue;
      const reveals = hits.map((h) => `${h.category}="${h.match}"`).join(', ');
      sections.push({
        id: q.id,
        politician: q.politician_name,
        topic: q.topic_key,
        reveals,
        original: q.quote_text,
        suggested: '',
        decision: '',
      });
    }

    writeReviewFile(outPath, sections);
    console.log(`Flagged ${sections.length} quotes. Review file written to ${outPath}.`);
    console.log(`Next: tsx backend/scripts/deidentifyQuotes.ts draft --in ${outPath}`);
  } finally {
    await pool.end();
  }
}

async function cmdDraft(inPath: string, outPath?: string): Promise<void> {
  if (!process.env.ANTHROPIC_API_KEY) {
    throw new Error('ANTHROPIC_API_KEY is required for draft');
  }
  const content = fs.readFileSync(inPath, 'utf-8');
  const sections = parseReviewFile(content);
  console.log(`Loaded ${sections.length} sections from ${inPath}.`);

  const todo = sections.filter((s) => !s.suggested.trim() && !s.decision.trim());
  console.log(`${todo.length} need draft suggestions (already-drafted or already-decided sections skipped).`);

  if (todo.length === 0) {
    console.log('Nothing to do.');
    return;
  }

  const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

  let cacheHits = 0;
  let cacheMisses = 0;

  for (const section of todo) {
    const userMessage = `Politician: ${section.politician}
Topic: ${section.topic}
Reveals detected: ${section.reveals}
Original: ${section.original}

Rewrite per the rules. Respond with ONLY the rewritten quote (or KEEP_ORIGINAL).`;

    try {
      const response = await client.messages.create({
        model: MODEL,
        max_tokens: MAX_TOKENS,
        system: [
          {
            type: 'text',
            text: REWRITE_SYSTEM_PROMPT,
            cache_control: { type: 'ephemeral' },
          },
        ],
        messages: [{ role: 'user', content: userMessage }],
      });

      const usage = response.usage as unknown as { cache_read_input_tokens?: number; cache_creation_input_tokens?: number };
      if (usage.cache_read_input_tokens && usage.cache_read_input_tokens > 0) cacheHits++;
      else cacheMisses++;

      const block = response.content[0];
      const text = block && block.type === 'text' ? block.text.trim() : '';

      if (text === 'KEEP_ORIGINAL' || !text) {
        section.suggested = '';
        section.decision = 'SKIP';
        console.log(`  [${section.id.slice(0, 8)}] KEEP_ORIGINAL`);
      } else {
        section.suggested = text;
        console.log(`  [${section.id.slice(0, 8)}] drafted (${text.length} chars)`);
      }
    } catch (err) {
      console.error(`  [${section.id.slice(0, 8)}] ERROR:`, err instanceof Error ? err.message : err);
      section.suggested = `<<ERROR: ${err instanceof Error ? err.message : 'unknown'}>>`;
    }
  }

  const writeTo = outPath ?? inPath;
  writeReviewFile(writeTo, sections);
  console.log(`\nDrafts written to ${writeTo}.`);
  console.log(`Prompt-cache stats: ${cacheHits} hits, ${cacheMisses} misses.`);
  console.log(`Next: open ${writeTo}, mark each Decision (APPROVED / EDIT: ... / SKIP), then run apply.`);
}

async function cmdApply(inPath: string, confirm: boolean): Promise<void> {
  const content = fs.readFileSync(inPath, 'utf-8');
  const sections = parseReviewFile(content);

  const updates: Array<{ id: string; text: string; source: 'APPROVED' | 'EDIT' }> = [];
  const skipped: string[] = [];
  const undecided: string[] = [];

  for (const s of sections) {
    const decision = s.decision.trim();
    if (!decision) {
      undecided.push(s.id);
      continue;
    }
    if (decision === 'SKIP') {
      skipped.push(s.id);
      continue;
    }
    if (decision === 'APPROVED') {
      if (!s.suggested.trim()) {
        console.warn(`  [${s.id.slice(0, 8)}] APPROVED but no Suggested text — skipping`);
        continue;
      }
      updates.push({ id: s.id, text: s.suggested.trim(), source: 'APPROVED' });
      continue;
    }
    if (decision.startsWith('EDIT:')) {
      const text = decision.slice('EDIT:'.length).trim();
      if (!text) {
        console.warn(`  [${s.id.slice(0, 8)}] EDIT: but no text after marker — skipping`);
        continue;
      }
      updates.push({ id: s.id, text, source: 'EDIT' });
      continue;
    }
    console.warn(`  [${s.id.slice(0, 8)}] unrecognized decision: ${decision.slice(0, 60)}`);
  }

  console.log(`Plan: ${updates.length} UPDATE(s), ${skipped.length} explicit SKIP(s), ${undecided.length} undecided.`);
  if (updates.length === 0) {
    console.log('Nothing to apply.');
    return;
  }

  if (!confirm) {
    console.log('\nDry-run only (pass --confirm to apply). Preview:');
    for (const u of updates) {
      console.log(`  [${u.id.slice(0, 8)}] (${u.source}) ${u.text.slice(0, 100)}${u.text.length > 100 ? '...' : ''}`);
    }
    return;
  }

  const pool = getPool();
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const u of updates) {
      await client.query('UPDATE essentials.quotes SET deidentified_text = $1 WHERE id = $2', [u.text, u.id]);
    }
    const { rows } = await client.query(
      'SELECT COUNT(*) FILTER (WHERE deidentified_text IS NOT NULL) AS deid, COUNT(*) AS total FROM essentials.quotes'
    );
    await client.query('COMMIT');
    console.log(`\nApplied ${updates.length} updates. essentials.quotes now: ${rows[0].deid}/${rows[0].total} have deidentified_text.`);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

function getArg(flag: string): string | undefined {
  const idx = process.argv.indexOf(flag);
  return idx >= 0 ? process.argv[idx + 1] : undefined;
}

function hasFlag(flag: string): boolean {
  return process.argv.includes(flag);
}

async function main(): Promise<void> {
  const cmd = process.argv[2];
  switch (cmd) {
    case 'scan': {
      const out = getArg('--out') ?? 'deidentify-review.md';
      await cmdScan(out);
      return;
    }
    case 'draft': {
      const inPath = getArg('--in');
      if (!inPath) throw new Error('draft requires --in <file>');
      const outPath = getArg('--out');
      await cmdDraft(inPath, outPath);
      return;
    }
    case 'apply': {
      const inPath = getArg('--in');
      if (!inPath) throw new Error('apply requires --in <file>');
      await cmdApply(inPath, hasFlag('--confirm'));
      return;
    }
    default:
      console.log(`Usage:
  tsx backend/scripts/deidentifyQuotes.ts scan [--out review.md]
  tsx backend/scripts/deidentifyQuotes.ts draft --in review.md [--out review.md]
  tsx backend/scripts/deidentifyQuotes.ts apply --in review.md [--confirm]
`);
      process.exit(cmd ? 1 : 0);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
