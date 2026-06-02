---
name: verify-sources
description: "Verify source URLs attached to compass stances and read-rank quotes. Fetches each URL, checks whether the page supports the blurb/quote, and flags ambiguous or broken sources for human review. Triggers on: 'verify sources', 'check source urls', 'audit sources', 'source verification'."
argument-hint: "[--limit N] [--type compass|readrank|all] [--dry-run]"
---

# /verify-sources — Source URL Verification

You are running the **verify-sources** skill. You will process a batch of source URLs that have not yet been verified, classify each one, and write results back to Supabase.

---

## STEP 0 — Parse `$ARGUMENTS`

Defaults:
- `--limit 20`
- `--type all` (compass + readrank)
- `--dry-run` false

Accept these flags in any order. Ignore unknown flags with a warning.

## STEP 1 — Pull unverified rows

Run this inside `ev-accounts/backend` (env needs to be loaded):

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const LIMIT = <LIMIT>;
const TYPE = '<TYPE>'; // 'compass_stance' | 'readrank_quote' | null
const { rows } = await pool.query(\`
  SELECT sv.id, sv.entity_type, sv.politician_id, sv.topic_id, sv.quote_id,
         sv.url_index, sv.url,
         p.full_name AS politician_name,
         ct.short_title AS topic_title,
         pc.reasoning AS compass_reasoning,
         q.quote_text AS quote_text,
         (SELECT array_agg(pce.snippet ORDER BY pce.snippet_index)
            FROM inform.politician_context_evidence pce
            WHERE pce.politician_id = sv.politician_id
              AND pce.topic_id = sv.topic_id
              AND pce.source_url = sv.url) AS stored_snippets
  FROM public.source_verifications sv
  LEFT JOIN essentials.politicians p ON p.id = sv.politician_id
  LEFT JOIN inform.compass_topics ct ON ct.id = sv.topic_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = sv.politician_id AND pc.topic_id = sv.topic_id
  LEFT JOIN essentials.quotes q ON q.id = sv.quote_id
  WHERE sv.status = 'unverified'
    AND (\$1::text IS NULL OR sv.entity_type = \$1)
  ORDER BY sv.created_at ASC
  LIMIT \$2
\`, [TYPE === 'all' ? null : TYPE, LIMIT]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

Replace `<LIMIT>` and `<TYPE>` with parsed values. If the query returns zero rows, print "Nothing to verify." and exit.

## STEP 2 — For each row, classify

Process sequentially. For each row:

### 2a. Fetch the URL

Use `WebFetch` with the row's `url` and a prompt like:
> "Return (1) the page's HTTP status (if inferable), (2) the main title, (3) a summary of what the page says, and (4) whether the page contains any verbatim quote from [politician_name] or any clear statement of their position on [topic_title / quote_text]."

If `WebFetch` returns an error (DNS failure, 4xx, 5xx, timeout, blocked): treat as **broken**. Go to 2c.

### 2b-0. Prefer a stored evidence snippet (deterministic — compass only)

If the row has `stored_snippets` (non-empty — populated by `/research-stances`'s pre-push verifier), **skip the LLM content judgment** and verify deterministically instead. The stored snippet was already string-matched against the page once; re-confirm it still appears, using the same matcher:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { matchSnippet } from './src/lib/researchVerifier.js';
import { fetchPageContent } from './src/lib/fetchPageContent.js';
const [url, ...snips] = process.argv.slice(2);
let page; try { page = await fetchPageContent(url); } catch (e) { console.log('FETCH_FAILED\t' + (e?.message ?? e)); process.exit(0); }
const anyVerified = snips.some(s => matchSnippet(s, page).verdict === 'verified');
console.log(anyVerified ? 'SNIPPET_VERIFIED' : 'SNIPPET_NOT_FOUND');
" -- "<URL>" "<STORED_SNIPPET_1>" "<STORED_SNIPPET_2>" ...
```

- `SNIPPET_VERIFIED` → the page still contains the exact evidence passage. The **content-supports check is satisfied deterministically** — do NOT ask an LLM. Proceed to the reputable + trusted checks below (auto-verify only if all three hold).
- `SNIPPET_NOT_FOUND` → the page no longer contains the stored passage (page changed, or the snippet was wrong). Mark `needs_review` with note "stored evidence snippet no longer found on page".
- `FETCH_FAILED` → treat as **broken**; go to 2c.

Only fall through to the LLM page-judgment in 2b when the row has **no** `stored_snippets` (e.g. readrank quotes, or compass rows researched before the evidence pipeline).

### 2b. URL loaded — check content (LLM fallback, no stored snippet)

Judge whether the page content clearly supports the blurb:
- **For compass**: Does the page contain a direct statement that supports `compass_reasoning`? The blurb must be traceable to the page, not paraphrased to the point of being speculative.
- **For readrank**: Does the page contain the verbatim `quote_text` (or near-verbatim with trivial whitespace/punctuation differences)?

Then check:
- **Is the domain reputable?** News orgs (nytimes.com, apnews.com, local newspapers), .gov, official campaign sites, verified social profiles (Twitter/X verified, Instagram verified), C-SPAN, Congress.gov. Blogs, Reddit, unverified social, aggregators, Wikipedia quoting other sources → NOT reputable.
- **Is the domain trusted** (has at least one other URL from the same host already `verified`)? Query:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { isDomainTrusted } from './src/lib/sourceVerificationService.js';
console.log(await isDomainTrusted('<URL>'));
process.exit(0);
"
```

**Auto-verify ONLY IF all three hold:**
1. Content clearly supports blurb
2. Domain is reputable
3. Domain is trusted (seen verified before)

Otherwise → `needs_review` with a one-line reason in `notes`.

### 2c. URL broken — try Wayback Machine first

Before searching for a replacement, check if the Internet Archive has a snapshot:

```bash
curl -s "https://archive.org/wayback/available?url=<URL_WITHOUT_PROTOCOL>" | python3 -c "
import sys, json
d = json.load(sys.stdin)
snap = d.get('archived_snapshots', {}).get('closest', {})
print(snap.get('url', 'NONE'), snap.get('timestamp', ''), snap.get('status', ''))
"
```

Strip `https://` or `http://` from the URL before passing to the CDX API.

If a snapshot exists (status 200), fetch its content via Bash (WebFetch blocks web.archive.org):

```bash
curl -sL --max-time 15 "<WAYBACK_URL>" | python3 -c "
import sys, re
html = sys.stdin.read()
html = re.sub(r'<(script|style)[^>]+>.*?</(script|style)>', '', html, flags=re.DOTALL|re.IGNORECASE)
text = re.sub(r'<[^>]+>', ' ', html)
text = re.sub(r'[ \t]+', ' ', text)
text = '\n'.join(l.strip() for l in text.split('\n') if l.strip())
print(text[:6000])
"
```

Assess the extracted text against the blurb using the same criteria as 2b. If it clearly supports the blurb:
- Set `replacement_url` to the timestamped Wayback URL (e.g. `https://web.archive.org/web/20221209120805/https://...`)
- Set status to `needs_review` with note: "broken; Wayback snapshot found at <timestamp>, content confirmed"

If the snapshot doesn't exist or doesn't support the blurb, proceed to web search:

Use `WebSearch` with a query like:
> `<politician_name> "<short phrase from blurb>" site:*.gov OR site:*.org`

Then a second, less-restrictive query if nothing good:
> `<politician_name> <blurb keywords>`

For the top 3-5 results, read each briefly with `WebFetch` and check: does any result contain verbatim support + come from a reputable domain?

**Never auto-apply a replacement.** If you find a strong candidate, record it in `replacement_url` with status `needs_review` and a note like "broken; replacement candidate found at <domain>". If nothing good is found, status `needs_review` with note "broken; no replacement found".

### 2d. Write back

If `--dry-run`, print the decision and continue. Otherwise:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { applySkillResult } from './src/lib/sourceVerificationService.js';
await applySkillResult('<ID>', {
  status: '<STATUS>',
  notes: '<NOTES>',
  http_status: <HTTP_STATUS_OR_null>,
  replacement_url: <REPLACEMENT_OR_null>,
});
process.exit(0);
"
```

Escape single quotes in notes. On exception, catch it, log the error, and continue to the next row (don't crash the run).

## STEP 3 — Summary

At the end, print a table:

```
verified:     N
needs_review: N  (of which M have a replacement candidate)
errors:       N
```

Followed by a list of `needs_review` rows with format:
`- <entity_type> / <politician_name> / <topic_title or quote_text>: <one-line reason>`

## Rules — do not violate

1. Never auto-apply a replacement URL. Replacements always require human approval.
2. Never mark a first-seen domain as `verified` — route to `needs_review` with note "first-seen domain".
3. Never crash the run on a single row error. Log, set status to `needs_review` with note `skill error: <msg>`, continue.
4. Never process rows with status ≠ `unverified`.
5. Sequential processing only. Do not parallelize.
