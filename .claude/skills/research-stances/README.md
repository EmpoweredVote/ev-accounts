# /research-stances — Architecture Notes

Durable, code-adjacent description of how the stance-research pipeline works and why. The point-in-time design spec lives at `ev-accounts/backend/docs/superpowers/specs/2026-04-30-stance-research-verification-design.md`; this document supersedes it for ongoing maintenance. `SKILL.md` is the operator-facing runbook; this README is the "why".

## Pipeline overview

Three stages between operator intent and production data:

1. **Research with evidence capture** — the `politician-stance-researcher` agent emits two CSVs into a batch directory (`data/stance-research/<BATCH_ID>/`): `stances.csv` (one row per politician+topic) and `evidence.csv` (one row per snippet). The agent must capture at least one verbatim snippet (25–300 words) for every source URL it cites. **No snippet → no source.**
2. **Deterministic verification** — `scripts/verify-stance-research.ts` parses both CSVs, fetches each cited URL through a tiered ladder (`verificationFetch.ts`: plain HTTP → headless Chromium → Wayback snapshot), normalizes whitespace/quotes/dashes/case, string-matches the snippet against the page, and confirms the politician's name appears within 500 characters of the match. **No LLM in the loop.**
3. **Gated DB push + review queue** — rows with at least N verified sources (default **N=1**) push to `inform.politician_answers`, `inform.politician_context`, and `inform.politician_context_evidence`. Rows below threshold get one bounded re-research attempt; if still short, they go to `inform.stance_research_review`.

## The two CSVs

```
stances.csv:   full_name,politician_id,topic_key,value,reasoning
evidence.csv:  full_name,topic_key,source_url,snippet,snippet_index
```

Joined on `(full_name, topic_key)`. `politician_id` is threaded from the skill's STEP 0 resolution so the push never re-matches by name (and `UNMATCHED` politicians are visible up front). `value` blank = the agent couldn't ground a stance; such rows are dropped in normal mode, auto-rejected in rewrite mode.

## The snippet rule

The single most load-bearing invariant: **every cited URL has at least one verbatim snippet attached, and the verifier mechanically checks the snippet appears on the page.** This catches the two observed hallucination modes:

- *Fake quotes* — the snippet won't be on the page, period.
- *Real-but-irrelevant articles* — the snippet may be on the page but the politician's name won't be within 500 characters of it.

Verified snippets persist to `inform.politician_context_evidence` so (a) a future admin UI can show "here's the exact passage that justified this stance," and (b) the post-hoc `/verify-sources` audit can string-match the stored snippet instead of re-judging the page with an LLM (this upgrade is **live** — see below).

## Verification rules (constants in `researchVerifier.ts`)

- **Verbatim string match** after normalization (whitespace collapsed, quotes/dashes normalized, lowercased, common HTML entities decoded).
- **Minimum snippet length 25 words** (`MIN_SNIPPET_WORDS`). Shorter snippets match irrelevant pages by chance.
- **Name proximity 500 characters** (`NAME_PROXIMITY_CHARS`). Last name within 500 chars of the snippet match, OR full name in the snippet, counts.
- **Common last names require a title qualifier.** A bare "Smith" within 500 chars isn't enough; "Sen. Smith", "Mayor Smith", etc. is. (`COMMON_LAST_NAMES` / `TITLE_PATTERN`.)
- **Paywalled / 4xx / 5xx / timeout pages** → `url_broken`. Conservative: we can't verify, so we don't credit the source.

## Failure handling

- **Per-source dropping:** a source counts as verified if any one of its snippets verifies; an unverified source is dropped silently as long as the row still clears the threshold.
- **Below-threshold re-research:** the orchestrator dispatches ONE additional agent for that single (politician, topic) in RE-RESEARCH MODE, with the failed URLs as `--exclude-urls`. One attempt only — never two.
- **Still below threshold after re-research:** the row goes to `inform.stance_research_review` with status `pending` and the full per-snippet audit trail in the `evidence` jsonb column.
- **Politician name doesn't resolve in `essentials.politicians`:** review queue with status `unresolved_politician`; the CSV name is preserved in `full_name_raw`.
- **Idempotency:** all writes are upserts / replace-by-key; re-running the same `batch_id` is safe.

## How to run

The verifier script is the gate and the pusher:

```bash
cd ev-accounts/backend
# dry-run: prints PUSH / RE-RESEARCH / UNRESOLVED partition (threshold defaults to 1)
npx tsx scripts/verify-stance-research.ts --dir data/stance-research/<BATCH_ID>
# after re-research pass + review: push verified rows, queue the rest
npx tsx scripts/verify-stance-research.ts --dir data/stance-research/<BATCH_ID> --apply --re-researched
```

`SKILL.md` STEP 2.5 → STEP 5 drive this. Rewrite mode (`--rewrite-id`) runs the same verifier inside `scripts/apply-rewrite-<TOPIC_KEY>.ts`, upserting+approving verified proposals and rejecting unverified/null ones (it does **not** persist evidence — that table FKs to live `politician_context`, which the new topic lacks until publish).

## Tables and ownership

- `inform.politician_answers` — existing. (Politician, topic) → numeric value. Verifier `--apply` writes here.
- `inform.politician_context` — existing. (Politician, topic) → reasoning + verified source URL list. Verifier `--apply` writes here.
- `inform.politician_context_evidence` — (Politician, topic, source_url, snippet) one row per verified snippet. Wholesale-replaced on re-research. (migration 231)
- `inform.stance_research_review` — review queue for rows that didn't clear the threshold. `evidence` jsonb captures every snippet's verdict. (migration 231)

## Configuration

- **Threshold:** how many independent verified sources a stance needs to publish. **Default 1** (cheap mode — one deterministically-verified source is enough, which avoids the expensive re-research wave). Raise with `--threshold N` on the runner or the `RESEARCH_STANCES_THRESHOLD` env var (e.g. 2 for corroboration on hot-button topics).
- **Research model:** see "Choosing the model" below.
- **Topic scope:** always the full in-scope set for the politician's role (no subsetting). Judicial topics only go to judicial officials; everyone else gets their level's national/local set.
- **Skip recently-researched:** politicians researched within 30 days are skipped by default; pass `--force` to re-research them.
- **Name proximity window:** 500 chars — `NAME_PROXIMITY_CHARS` in `researchVerifier.ts`.
- **Min snippet words:** 25 default (`MIN_SNIPPET_WORDS`), configurable per call via `matchSnippet(.., { minWords })` / `verifyEvidence({ match: { minWords } })` — lower it for concise read-rank quotes; stances keep 25 for context.
- **Snippet match:** `matchSnippet` verifies a contiguous ≥ `minWords` run OR ≥ `MIN_SHINGLE_COVERAGE` (0.6) of the snippet's 6-word shingles clustered in one bounded passage — tolerates dropped words / light framing, rejects paraphrase and far-apart stitching.
- **Page fetch:** `verificationFetch.ts` — a token-free ladder (plain HTTP → headless Chromium via `fetchPageContent.ts` → Wayback snapshot), reusing one browser across the batch. Escalates only when a page looks like a stub/bot-challenge (`looksLikeRealPage`), so legit sources behind Cloudflare/paywalls are still checked against their archive snapshot. Render build needs `npx playwright install chromium --with-deps`.

## Choosing the model

The research is done by sub-agents the skill spawns (one per politician). Each spawn is an `Agent` tool call that takes a `model`. To change which model those agents use, pick one (easiest first):

1. **Say it in the prompt** (per-run, zero setup): `/research-stances Utah State Senate — use haiku for the research agents`. The orchestrator passes `model: haiku` on each dispatch.
2. **Set `RESEARCH_STANCES_MODEL` once** in `ev-accounts/backend/.env` (set-and-forget; what an unattended/bulk run uses):
   ```
   RESEARCH_STANCES_MODEL=haiku
   ```
   STEP 1 reads it and applies it to every dispatch. Unset = the agent's frontmatter default (`sonnet`).
3. **Edit the agent default** in `.claude/agents/politician-stance-researcher.md` frontmatter (`model: sonnet`). Most bulletproof, but a manual file edit.

**Valid values in Claude Code: `sonnet`, `opus`, `haiku`** — the sub-agent dispatch only understands those three tiers, not arbitrary provider model ids.

**Running outside Claude Code (e.g. Kilo Code):** this skill is Claude-Code-format (a `SKILL.md` + agent dispatch) and won't execute as-is elsewhere. `RESEARCH_STANCES_MODEL` is a *convention* to wire up when you reimplement the orchestration in another runtime. The model-agnostic, portable core is the verifier scripts (plain TypeScript: `researchVerifier.ts`, `verificationFetch.ts`, `stanceResearchCsv.ts`, `researchEvidenceService.ts`) plus the prompt text — those carry over to any provider.

**Cost note:** the LLM research agents are ~95% of token cost; everything deterministic (verify, fetch, push) is ~free. The two biggest cost levers are the model (haiku vs sonnet) and the threshold (1 vs 2, since threshold 2 triggers re-research agents).

## `/verify-sources` integration (live)

`/verify-sources` (post-hoc source audit) now **prefers the stored `politician_context_evidence.snippet`**: when a snippet exists for a (politician, topic, url), it deterministically string-matches the snippet against the fetched page instead of asking an LLM whether the page "supports" the blurb. Falls back to LLM page-judgment only when no stored snippet exists. Cheaper and more accurate as evidence accumulates.

## Why no LLM in the verifier

Cost and determinism. The verifier runs over every (URL, snippet) pair on every batch, so any per-call LLM cost compounds. More importantly, "does this exact passage appear on this page" has a deterministic, human-auditable answer; "does this page support this stance" is a fuzzier spec. A future LLM-based snippet→reasoning relevance check is reserved as a follow-up, to be added only if review-queue patterns show snippets verifying but reasoning still off-target.

## Follow-ups (not implemented)

- Admin UI for the review queue. Schema is built for it.
- LLM-based snippet→reasoning relevance check (does the captured snippet actually support the stated reasoning?). Add only if review-queue patterns show it's needed.
- Domain reputation as a pre-push gate (currently post-hoc only, via `/verify-sources`).
- Read-rank quote verification using the same machinery (different table shape; future work).
- Evidence persistence for rewrite-mode proposals at publish time (currently only the verified source URLs ride along on the proposal).
