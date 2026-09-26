---
name: research-stances
description: "Research politician stances on compass topics. Use when the user wants to research, look up, or generate stance data for politicians on Empowered Vote policy topics (national, state, and local city-level). Produces a reviewable CSV and optionally pushes approved stances to the database. Triggers on: 'research stances', 'look up stances', 'politician positions', 'stance data for', 'compass research'."
argument-hint: "\"Politician Name(s)\" | \"Legislative body\""
---

# /research-stances — Politician Stance Research Orchestrator

You are running the **research-stances** skill. Your job is to research politician stances on existing Empowered Vote compass topics, produce a reviewable CSV, and optionally push approved data to the database.

> **Related:** if this work involves candidate *quotes* (for Read & Rank / Compass / Essentials),
> follow the curation principles in `../on-the-record/.claude/skills/audit-quotes/CHECKS.md` (the
> checks + the §4 judgment rules — the working rulebook) and
> `../on-the-record/.claude/skills/publish-quotes/EDITORIAL.md` (editing/de-id mechanics), and hand
> quotes off to the `audit-quotes` skill before they go live (see STEP 4). The canonical source is
> the on-the-record corpus, docs/quote-curation/PRINCIPLES.md (sibling checkout:
> ../on-the-record/docs/quote-curation/PRINCIPLES.md) — read it alongside CHECKS.md §4 as the
> rulebook.

> **Quotes are pushed as DRAFTS, then audited, then promoted.** This skill never sets a quote live
> in the same step it inserts it. The flow is: research → pre-push QA → insert as drafts
> (`readrank_selected=false`) → `audit-quotes --include-drafts` → promote the Read & Rank picks to
> live only once the audit is clean (STEP 4).

> 🔴 **ONE CANONICAL COPY.** This skill and `.claude/agents/politician-stance-researcher.md` live in
> the ev-accounts repo. Older copies at the workspace root and in `.agents/` were up to three months
> stale (2026-09-22). If you are reading this anywhere else, stop and use the ev-accounts copy.
>
> **The stance pipeline, one line:** `build-stance-topic-bundle` → research (inline, one politician
> per run — STEP 1) → `stance-gate` → `verify:quotes` → `build-and-check` (quotes) →
> `verify-stance-research` (dry-run) → `verify-stance-research --apply` (queues rows) → human review
> in the admin queue. Every step after research is a non-interactive script with exit
> codes, so those steps can later run on a schedule. Human decisions go to the review queue
> (`inform.stance_research_review`), not the chat.
>
> 🔴 **Review-all is the default (ruling 2026-09-22): nothing auto-publishes.** `--apply` writes
> every stance to the review queue — a row that passes every check is queued with reason
> `review-all-mode` — unless the operator passes `--auto-push` for that run. Until a chair-fit
> classifier exists, a person approves every stance, and those approvals are the labeled set it
> will be built from. No env var turns `--auto-push` on.

---

## STEP 0 — Parse Input

Parse `$ARGUMENTS` for:
- **Politician names**: comma-separated list (e.g., `"Brad Sherman, Maxine Waters"`)

There is **no topic filter.** Research every topic in the `TOPIC SCALE REFERENCE` block for the
politician's level (ruling 2026-09-24, Chris Andrews: the local reference keeps all 35 topics).
`build-stance-topic-bundle.ts` has no `--topics` flag. A topic in the block that this office holds no
lever on is a scope blank (spec §4.9) — record it as a blank row with the reason; do not drop it.

If `$ARGUMENTS` is empty, ask the user:
> "Which politician(s) would you like me to research? You can provide names (e.g., 'Brad Sherman, Maxine Waters') or a body (e.g., 'Bloomington City Council')."

### Jurisdiction Resolution

If the input looks like a legislative body (e.g., "Bloomington City Council", "California State Senate"), resolve it to individual politicians by querying the database:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT DISTINCT ON (p.id) p.id, p.full_name, o.title, c.name AS chamber_name
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE c.name ILIKE '%' || \$1 || '%'
   ORDER BY p.id, o.title
\`, [process.argv[2]]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "SEARCH_TERM"
```

Replace `SEARCH_TERM` with the relevant part of the user's input (e.g., "City Council" for "Bloomington City Council").

DISTINCT ON (p.id) is required — a politician-rooted join fans out for anyone holding two offices (CLAUDE.md).

If no results, tell the user and ask them to provide specific names instead.

### Topic Resolution — the open season's questions, per office level

**ALWAYS resolve the topic set and its rung texts fresh from the DB before every research run,
through the open season's pin. Never use a hardcoded list, never read `inform.compass_stances`, and
never filter on `is_live`.** The bundle builder below does this, and it is the only topic source for a
batch.

🔴🔴 **`inform.compass_stances` is FROZEN at v1 and `is_live` does not gate the season read
path.** The topic query this step used to run joined the frozen table and filtered
`WHERE t.is_live = true`. Both were wrong, and both failed silently — the frozen table returns a
complete, plausible ladder on the right subject with the wrong rungs. Measured against the open season
on 2026-09-23:

| | |
|---|---|
| Topics pinned into the open season | **60** |
| Returned by the old `is_live = true` query | **44** |
| Pinned topics it dropped | **17** |
| Topics it returned that are not in the season | **1** — `immigration`, retired in Season 2, which the write gate no longer accepts |
| Pinned topics whose rungs differ from the frozen table | **29 of 60** (41 of 61 for the Season 3 draft) |

Build the batch bundle:

```bash
cd ev-accounts/backend && set -a && source .env && set +a
npx tsx scripts/build-stance-topic-bundle.ts --dir data/stance-research/<YYYY-MM-DD-batch> \
  --race <race_id> [--race <race_id> ...]          # candidates on these races
  # or, for officeholders not on a race:  --politician <uuid>:<federal|state|local|judicial|school>
```

It reads the open season's pins (`season_questions`) and prints the **served** text of each: the latest
published/superseded revision of the pin's version (ADR 0006; `seasonService.servedRevisionLateral`, the
same resolver the voter compass uses), then its `compass_stance_revisions`.

🔴 **The served text, not the pin's own rungs.** Every open-season pin is a superseded revision, and on
13 of the 60 topics its rung text differs from what voters read (measured 2026-09-24 — abortion on all
five rungs). Evidence must match the text voters read. The bundle does this for you; never read rungs
off `season_questions.topic_revision_id` directly.

The bundle
writes `topics.json` + `politicians.json` into the batch dir, and prints one
`TOPIC SCALE REFERENCE (<level>)` block per office level — already filtered to the topics that
apply at that level (`compass_topic_roles`). Paste the block matching each politician's level
into that politician's research contract (STEP 1). A politician printed under `level unknown` needs a
person to set the level (`--politician <uuid>:<level>`, added alongside the same `--race`) before
research. The bundle keeps one entry per person, so giving someone by both `--race` and `--politician`
is fine. Each person's `full_name` in `politicians.json` is the spelling every batch file must use.

Notes on reading the result:

- **`school` is a K-12 school board** (CA_0256; rulings 2026-09-23 / 2026-09-24, Chris Andrews). Its
  reference lists only the eight Education Lens topics (`education-*`). `school-vouchers` is not asked of
  a school board. A **community-college** trustee board (district label says "Community College";
  `COMMUNITY_COLLEGE_LABEL_RE` in `backend/src/lib/topicApplicability.ts`) prints under `level unknown`.
  It is outside every level: leave it out of the batch, and do not force it to `school` or `local`.
  A state board of education stays `state`. A school board filed on a city district (district_type
  LOCAL, e.g. Portland, Augusta, Lewiston and Westbrook ME; `SCHOOL_BOARD_OFFICE_RE`) also prints under
  `level unknown`: its district must be re-typed to SCHOOL before research. Do not research it as `local`.
- **It resolves whichever season is open, by status — do not hard-code a season number.** Today that
  is Season 2 (60 topics). The Season 3 draft has 61 and a different pin; a run today writes into the
  open season, so the open season's rung text is the text your evidence must match.
- **If no season is open, the bundle exits 1 and writes nothing. STOP.** (It also exits 1 when a
  pinned ladder does not have exactly five rungs.) Do not fall back to the frozen table. The write path
  sources its insert from a join on the open season, so with none open nothing is written and nothing
  raises.
- Each topic prints `pin: …` and `served: …`, and `topics.json` keeps both (`topic_revision_id` = the
  pin, which an answer write records; `served_revision_id` = the revision whose text you are shown).
  `verify-stance-research` refuses the batch if either one has moved since the bundle was built — a
  clarifying publish changes the served text without moving the pin. Carry them through.
- Scope is already applied: each level's block lists only the topics `compass_topic_roles` offers at
  that level, and `stance-gate` refuses a row outside it (`topic-out-of-scope`). A topic offered at a
  level can still have rungs this officeholder may not lawfully do — read §4.9 of the program design
  (`docs/superpowers/specs/2026-09-23-stance-program-design.md`) before starting the topic. A scope
  blank recorded there is closed research, not a gap to re-queue.

Work from the **full bundle output** — including the rung texts for every value. Never hardcode, and
never restate a ladder from memory: given only a `topic_key`, a model defaults to 1 = oppose /
5 = support and systematically inverts topics like `ai-regulation` and `tariffs`, which run the other
way.

**Confirm before proceeding.** Show the user:
- List of politicians to research
- The open season's number, and the topic count it pinned
- Topics in scope (every topic in each level's block — there is no filter)
- Estimated scope from the bundle (politicians × in-scope topics for each one's level)

---

## STEP 0.5 — On the Record Source Discovery (tier-1 sources)

**Do this BEFORE any web research.** On the Record (the sibling transcript platform) already holds
speaker-attributed transcripts for many races — debates, forums, and news interviews. These are the
**strongest** stance/quote source we have (verbatim, timestamped, attributed to the candidate) and
they are what the `audit-quotes` source check verifies against. Skipping them was a real failure: a
prior CA-Governor run used WebFetch/Ballotpedia only and missed **18 of 21** available OTR sources.

If the politicians belong to a race, resolve the `race_id` and pull the transcripts first:

```bash
# Resolve the race_id from the candidate names (skip if the user already gave you a --race id)
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT rc.race_id::text, r.position_name, count(*)::int AS n_candidates
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.politicians p ON p.id = rc.politician_id
  WHERE lower(p.full_name) = ANY(SELECT lower(n) FROM unnest(\$1::text[]) AS n)
  GROUP BY rc.race_id, r.position_name ORDER BY n_candidates DESC
\`, [process.argv.slice(2)]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "Name1" "Name2"
```

Then extract every candidate's speaker-attributed turns across the race's OTR sources:

```bash
node ev-accounts/.claude/skills/research-stances/scripts/extract-otr.mjs \
  --race <race_id> --names "Full Name 1,Full Name 2"
# writes one markdown file per candidate to
#   ev-accounts/backend/data/stance-research/otr-transcripts/<race_id>/<candidate>.md
# each source section is headed with its YouTube URL + OTR page URL (use these as source_url_1)
```

**Always pass `--names` with the candidates' DB `full_name`s.** Debate transcripts tag turns with a
`politicianSlug`, but news-interview transcripts attribute by `speakerName` only (slug is null) — and
those are often the majority of a race's sources. `--names` matches on speaker name (token-subset, so
"Karen Bass" matches the transcript's "Karen Ruth Bass"), which covers both. Without it the tool only
finds debate turns and silently misses every interview.

`extract-otr.mjs` uses the OTR public API only (no DB): `/api/people` (candidate names),
`/api/meetings` (the race's sources via `raceIds`), and paginated
`/api/meetings/{id}/transcript?page=N` (segments carry `speakerName` + `politicianSlug`). It prints
`OTR_SOURCES=<n> OTR_CANDIDATES=<n>` at the end.

- If `OTR_SOURCES=0`, the race isn't on the platform yet — fall back to web research (STEP 1 tiers).
- Put each candidate's transcript file path into that candidate's research contract (STEP 1) as the
  **tier-1 source**. Draw verbatim quotes from it first, and use WebFetch only for topics the
  transcripts don't cover.
- Not a race (e.g. a single official)? Skip this step and go straight to web research.

---

## STEP 1 — Research Each Politician Yourself, Inline

🔴🔴 **Do NOT dispatch a research sub-agent. Do this work yourself, one politician per
run.** This skill used to say to dispatch a `politician-stance-researcher` agent per politician.
That instruction was withdrawn by ruling on 2026-08-24 and reaffirmed on 2026-09-23. Following it
as written turned 38 researched rows into 8 survivors.

**Execution rules:**
- **One politician per run.** Finish a person, review them, then start the next. Do not batch
  several people into one pass, and do not work two people concurrently.
- Confirm that person's rows are written to research.csv and evidence.csv before you start the next
  person.
- Then run the gate on the batch before you start the next person:
  `cd ev-accounts/backend && npx tsx scripts/stance-gate.ts --dir data/stance-research/<YYYY-MM-DD-batch>`.
  It uses no network and no database and writes only `gate-findings.json` and `stances.csv` in the
  batch dir, so it is safe to run as often as you like. Its findings are per row, so they name this
  person's defects before the next person starts; re-research those pairs (STEP 4a(i)) first.
- Use WebFetch only. Never WebSearch or Playwright — both share a rate-limited quota pool.

**Why inline, and not an agent — three reasons, none of them stylistic:**
1. **No MCP server is bound inside a sub-agent.** A research agent has no route to the season
   pin, the ladder text, or the database. It can web-search and report, and nothing more — so it
   cannot do the one thing this skill exists to do.
2. **Sub-agents here have repeatedly reported verification they never ran.** A returned CSV that
   claims its sources were fetched is not evidence that they were.
3. **A cohort pass needs finished peers to compare against, and a batch hides which judgment went
   wrong.** When 38 rows arrive together the review cost is the whole batch; when one person
   arrives, the reviewer can point at the row and the instrument.

🔴 **Read the ladders from the bundle, and from nowhere else.** The only authority for rung text is
the `TOPIC SCALE REFERENCE` block that `build-stance-topic-bundle.ts` printed in STEP 0 from the open
season's pin — never memory, and never a ladder copied into a file. Older copies of the researcher
agent definition carried hard-coded 1–5 scale text from the **frozen** `inform.compass_stances`
table; measured 2026-09-23, **29 of the 60 topics pinned into the open season have rung text that
differs from that table** — `same-sex-marriage` chair 1, for one, reads "require all states to
recognize…" there and "Guarantee same-sex couples full legal equality — equal marriage plus
protection…" in the pin. `.claude/agents/politician-stance-researcher.md` now carries no ladders. It
is a **reference**, not a dispatch target: read it with the Read tool for its URL patterns
(`### URL Patterns — Fetch These in Order`), its evidence contract and output format, and its
per-office guidance.

**Inject the canonical curation rules (do not paraphrase them here).** Run

```bash
node .claude/skills/research-stances/scripts/extract-canonical-rules.mjs gates deid note
```

and paste its output into the research contract below at the three `INJECT:` markers (`gates`, `deid`,
`note`). These rules come from the on-the-record corpus (sibling checkout; canonical home
`on-the-record/docs/quote-curation/PRINCIPLES.md` and its mechanics files) — never restate them from
memory. If the extractor errors, the on-the-record checkout is missing: **STOP** and resolve that, do
not fall back to a remembered summary.

**Research contract — the standard you hold yourself to for the one politician you are on.**
Read it as instructions to you, not as a prompt to send anywhere. Substitute the bracketed
values for the person in front of you.

```
Research the political stances of [POLITICIAN_NAME] ([OFFICE/TITLE if known]).

NAMES AND KEYS: in both files, copy `full_name` exactly as it appears in politicians.json —
"[POLITICIAN_NAME]", same spelling, case and spacing — and copy `topic_key` exactly as listed in
the TOPIC SCALE REFERENCE below.

Research every topic in the TOPIC SCALE REFERENCE below. A topic this office holds no lever on is a
blank row with the reason (spec §4.9), not a skipped topic.

FIVE-CHAIRS FRAMING — READ BEFORE ASSIGNING ANY VALUE:

Each compass topic has five pre-written stances — one per position on the spoke. These
aren't degree-of-agreement markers. They are five distinct, substantive positions a real
person could hold, defend in a conversation, and point to a policy that reflects it.

Think of them as five named chairs in a room. A politician's public record places them in
one of those chairs. Your job is to find which chair fits the documented evidence — not to
infer a chair from party affiliation or directional assumption.

The spoke has no correct end. Value=1 is not "conservative" and value=5 is not
"progressive" — the direction varies by topic. Read the written text at each value level
for this topic. Find sources that document this politician's position. Match the
documented record to the chair whose text fits.

When a voter matches a politician on a topic, the system must be able to say exactly why:
not "they both scored a 2 on Climate," but "they both support rapidly transitioning to
renewable energy and phasing out fossil fuels by 2030." That claim requires your value
assignment to be defensible with the specific written text — not just a directional
approximation.

Do NOT pick a value based on party expectation. Do NOT assume direction. For every stance
you record, ask: "Does this politician's documented position match the EXACT TEXT at this
value?" If not, pick a different value or leave the value blank.

TOPIC SCALE REFERENCE — assign values by matching to exact stance text:
[PASTE THE TOPIC SCALE REFERENCE BLOCK FOR THIS POLITICIAN'S LEVEL, printed by build-stance-topic-bundle.ts]

The topic_key in your CSV output MUST be copied exactly as listed above.
Do NOT invent your own topic_key slugs.
Do NOT include any topic_key not in the above list — the list is fetched fresh each run.

The TOPIC SCALE REFERENCE is already filtered to the questions this season asks of this office. Research only those. When you cannot find evidence for a specific chair, write the row with a blank value — the pipeline reads a blank as "insufficient evidence".

[If this politician's level is `school` (K-12 school board), include this block:]
SCHOOL-BOARD RULES (rulings 2026-09-23 / 2026-09-24, Chris Andrews; per-rung basis in
.superpowers/sdd/2026-09-23-stance-program-reconciliation/school-scope-proposal.md §2-§3).
They add to every other rule in this contract:
- S1. Evidence is the member's own act or words. An act is a board vote: on a policy, a budget, a levy
  or referendum resolution, an SRO contract or MOU, a materials adoption, or a charter petition,
  renewal or revocation. A superintendent's administrative rule or a staff decision is NOT the member's act.
- S2. A vote that only implements a state mandate is not chair evidence. Seat a chair only on a vote or
  words that pick among the options the law leaves open, or that go against the mandate.
- S3. A RUNG THAT STATE LAW REMOVES is seated ONLY from a vote the member cast before the law took
  effect — name the vote and its date. Otherwise the value stays blank. The member's words alone never
  seat such a rung: this narrows statement evidence at the school level only. Name the state rule in
  reasoning.
- S4. The ladders do not all point the same way. Library-books chair 1 is the LEAST restrictive rung;
  AI chair 1 is the MOST restrictive. Read each ladder.
- S5. Where one member moves nearly every item, only the named tally counts (spec §5.3).
Per topic. Every state-law claim below is marked "(to verify)": it comes from the proposal and has
NOT been checked against the statute. Confirm the statute before you rely on it.
- education-ai: most districts handle AI in administrative guidelines, not board policy (S1) — expect blanks.
- education-charter-authorization: seat only where the member's district is an authorizer, or, for
  chair 5, where a conversion or partnership law applies. "Close existing" covers only charters this
  district authorized. Evidence: a vote on a petition, renewal, revocation or conversion. Not an
  authorizer: blank. IN school corporations are authorizers (to verify); CA limits the grounds on
  which a district can deny a charter (to verify).
- education-curriculum: evidence is a vote on a curriculum or materials adoption, a
  controversial-issues policy or an opt-out policy. State standards and content laws limit every rung.
  Removed rungs (S3): IN HEA 1608 (2023, to verify) limits rungs 1-2 for sexuality content in pre-K-3;
  CA inclusivity law (to verify) removes rung 5; a "divisive concepts" law, e.g. TX (to verify),
  removes rung 1.
- education-equity-programs: rungs 1-2 are removed where state law bans K-12 DEI offices or mandatory
  training (S3). IN's 2025 anti-DEI law (to verify): whether it covers school corporations is unknown.
  Subgroup reporting is federally required, so reporting alone is not chair-3 evidence.
- education-gender-identity: record the state rule first. CA AB 1955 (2024, to verify) removes rungs
  3-5. IN HEA 1608 (2023, to verify) requires parental notification, so it removes rungs 1-2; if that
  statute has NO danger exception (to verify), it removes rung 3 as well, rung 4 is IN's floor, and
  only rung 5 is a board choice. A vote to implement the state rule is not evidence (S2). Expect mostly
  blanks in CA and IN.
- education-library-books: evidence is a vote on the terms of the reconsideration policy, or on one
  challenge or appeal. A vote to adopt a state-required procedure is not evidence (S2). IN HEA 1447
  (2023, to verify) requires a removal procedure, so rung 1 cannot be absolute for harmful-to-minors
  material; UT and TX (to verify) may do the same.
- education-school-budget: a vote to put a referendum on the ballot is rung-1 evidence; a routine
  maximum-levy advertisement is not (IN practice, to verify). In a fiscally dependent district (VA, MA,
  to verify), rungs 1 and 5 are positions on the budget request — seat them on the member's vote on
  the request.
- education-school-police: evidence is a vote on an SRO contract or MOU, a district police budget, or
  creating or ending one. Where a state mandates campus officers, e.g. TX (to verify), rungs 1-2 are
  removed (S3).
- school-vouchers is not asked of a school board (no board holds a lever on any rung). It is not in
  this reference; do not add it.

--output-dir [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/YYYY-MM-DD-[BATCH_NAME]

TIER-1 SOURCE — READ THIS FIRST:
[If an OTR transcript file was produced in STEP 0.5, include:]
Your PRIMARY source is this On the Record transcript file (verbatim, timestamped, attributed to
this candidate across the race's debates/forums/interviews):
  [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/otr-transcripts/<race_id>/<candidate>.md
Read it with the Read tool and draw your quotes from it FIRST. Every quote you take from it is
already verified to the source — cite that source's YouTube URL (shown in the file's section
header) as source_url_1. Only use WebFetch for topics the transcript does not cover.

TOOL RULE:
- Prefer the OTR transcript file above (Read tool) — it is the strongest, pre-verified source.
- For anything it doesn't cover, use WebFetch ONLY. Never use WebSearch or Playwright — both share a
  rate-limited quota pool. Fetch URLs directly using the patterns under `### URL Patterns — Fetch
  These in Order` in `.claude/agents/politician-stance-researcher.md` (Ballotpedia,
  ontheissues.org, official pages, Wikipedia, CalMatters, LA Times) — read that file for them. If a
  URL 404s, try the next pattern. Do not fall back to WebSearch.
- vote411.org and thevoterguide.org are POINTER-ONLY: use them to find where the candidate answered,
  then cite the candidate's own page. Never put a vote411.org or thevoterguide.org URL in any
  source_url column — LWV terms bar reproducing it.

TWO OUTPUT FILES, both in --output-dir (RFC-4180; quote any field containing commas; double embedded quotes):
1) research.csv:
   full_name,topic_key,value,evidence_type,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified,editor_note
   - editor_note: REQUIRED for every row with a quote_text (see EDITOR NOTE RULE).
2) evidence.csv:
   full_name,topic_key,source_url,snippet,snippet_index

EVIDENCE CONTRACT — every stance row must be provable from the page it cites:
- evidence_type = "record" when the stance rests on something the person DID in office (a bill, act,
  ordinance, recorded vote); "statement" when it rests on their own words (questionnaire, debate,
  forum, interview, campaign platform). A challenger with no record uses "statement".
- record rows: the reasoning MUST name the instrument, e.g. "Voted YES on HB 1001 (2025)" — AND that
  instrument (bill/ordinance/resolution number, however spelled) must actually appear in one of the
  row's evidence.csv snippets. Naming it in reasoning without it being in the cited page is a one-way
  citation and the gate refuses it (`instrument-not-cited`).
- For EVERY source_url_N in research.csv, write at least one evidence.csv row whose snippet is a
  VERBATIM passage of at least 25 words, copied from that page as you fetched it, that shows the
  position and names this person (or sits within a few sentences of their name). Copy — never retype,
  trim to fit, or summarise. A source you cannot back with a verbatim snippet does not go in the row.
- Only the part of a snippet that is on the page word for word is ever published: the verifier keeps
  the longest run of your snippet that appears contiguously on the page, and that run must itself be
  25 words or more, or the snippet does not count (ruling 2026-09-24). Framing words you add are
  dropped, and a snippet with words left out mid-passage can fail. Copy one continuous passage.
- Every evidence.csv row's source_url must be one of THAT row's source_url_1..3 in research.csv. An
  evidence URL the row does not cite is refused by the gate (`evidence-url-not-cited`), and the
  verifier never verifies or publishes it. When you re-source a row, remove its old evidence rows.
- The evidence must describe THIS chair, not just a direction. If it only shows which side the person
  is on and two or three chairs sit on that side, leave the value blank. "The least extreme chair the
  evidence allows" is a tiebreaker, not evidence.
- Never name a party, a party label, or a party-typical position in reasoning. Party is never evidence.
- No source_url in research.csv — stance or quote — may be a vote411.org or thevoterguide.org URL.
- reasoning must never be blank for a scored (non-blank-value) row (`reasoning-empty`).
- Do not cite ONLY ballotpedia.org — every source_url on a row being ballotpedia.org is refused
  (`ballotpedia-only`); cite the record, filing or report the Ballotpedia bio itself draws on.
- A bare-domain source_url with no path (e.g. `https://example.gov` instead of a specific page) is
  flagged for review (`source-no-path`) — link the actual page, not the site root.
- If reasoning puts words in quotation marks, that exact text (normalized for case/whitespace) must
  appear in one of the row's evidence.csv snippets — a quoted sentence nobody said, or the wrong
  sentence in quotes, is refused (`quote-not-in-snippet`). Only quote-attribute what the source shows.

HARD RULES (Compass Stance Program; do not violate):
- A cited vote needs 10% or more of the votes against, or it is not a position (C46, spec §4.12).
- A vote cast before the member took the seat is not evidence (C44, spec §4.10).
- An excused absence is not a position. Check tenure before reading a non-vote as one. Verify any
  vote-count parse against the journal's own totals (C28, spec §3.2).
- Sponsorship evidences the bill as filed — not as later amended or enrolled (C37, spec §4.4).
- A short title is not evidence (C38, spec §4.5).
- The operative section of an instrument governs, not its recital (C51, spec §5.2).
- A study directive is a refusal, not a chair (C47, spec §4.13). Inference from silence is a
  refusal, not a chair (C48, spec §4.14).
- A failed basis is not a failed chair: re-research it before you blank it. A blank on a bare
  detector flag is wrong; a blank that follows honest re-research stands (C64, spec §6.4).
- Run a positive control on every search before trusting a "nothing found" result (C60, spec §6.1).
- In source order, On the Record transcripts come first (C50, spec §5.1).
- The MCP server named `supabase-local` is production. There is no local database — the name is
  misleading, which is why this is a rule (C14, spec §2).

Before researching, read spec §3 (finding a chair), §4 (refusal rules), §5 (sourcing), §6
(verification), §10 (calibration set), §11 (first-wave protocol and its exit criterion: two
consecutive batches where the reviewer changes no chair) —
`docs/superpowers/specs/2026-09-23-stance-program-design.md`.

QUOTE-SELECTION GATES + RANKING QUESTION + DIFFERENTIATION:
[INJECT: gates]

DE-IDENTIFICATION CONTRACT:
[INJECT: deid]

EDITOR NOTE RULE:
[INJECT: note]

Other rules:
- Where you cannot find sufficient evidence for a specific chair, write the row with a blank value and say in reasoning why the evidence falls short — never guess
- One row per (full_name, topic_key) in research.csv. If you are re-researching a pair, REPLACE its existing rows in research.csv and evidence.csv — never append a second row for it.
- Every source URL must be one you fetched successfully and backed in evidence.csv (OTR YouTube URLs from the transcript file count; their snippet is the transcript passage).
- Use the full 1-5 range; match to stance text, not political alignment
```

> **Note:** `build-stance-topic-bundle.ts` already prints each topic entry in this shape — paste its
> block for the politician's level as printed:
>
>     [topic_key] (id: [uuid], pin: [topic_revision_id], served: [served_revision_id])
>     Question: "[question_text]"
>       1 = "[stance text for value 1]"
>       2 = "[stance text for value 2]"
>       3 = "[stance text for value 3]"
>       4 = "[stance text for value 4]"
>       5 = "[stance text for value 5]"

🔴 **Do not call the Agent tool here.** `politician-stance-researcher` is retained for its URL
patterns and per-office guidance, which you read; it is not to be dispatched.

---

## STEP 2 — Collect and Merge Results

After the last politician in the batch is finished:

1. Read research.csv and evidence.csv — the files you wrote — from the batch dir
2. Verify no duplicate headers where runs appended to the same file
3. Confirm every person you researched is represented — a person with no evidenced chair is a
   documented zero and must be recorded as one (blank-value rows that say why), not silently dropped
4. **One row per (full_name, topic_key).** A re-research or retry pass REPLACES that pair's rows in
   research.csv and evidence.csv — delete the old rows for the pair, then write the new ones. Never
   append a second row for a pair: two rows cross-verify each other's snippets, so `stance-gate`
   flags both `duplicate-row` (high) and `verify-stance-research` exits 2.
5. Count total stances collected vs. expected (politicians × in-scope topics from the bundle)
6. research.csv includes `quote_text`, `quote_deidentified`, and `editor_note` columns. Parse the CSV with a real RFC-4180 parser (`csv-parse/sync`), never by splitting on commas — these columns contain commas and embedded quotes. Verify every row that has a `quote_text` also has a non-blank `editor_note` (the DB requires it and the audit hard-fails without it); if any are missing, draft them before STEP 4 or send the row back.

---

## STEP 3 — Present Approval Summary

Show the user a formatted summary table:

```
## Research Results: [BATCH_NAME]

| Politician | Topics Found | Topics Skipped |
|-----------|-------------|---------------|
| Name 1    | [found]/[in-scope] | ai-regulation, redistricting |
| Name 2    | [found]/[in-scope] | none |

### Stance Overview

| Politician | Topic | Value | Reasoning (preview) |
|-----------|-------|-------|-------------------|
| Name 1 | healthcare | 2 | "Cosponsored the Public Option..." |
| Name 1 | abortion | 1 | "Voted against every restrict..." |
| ...    | ...        | ... | ... |

Batch directory: `ev-accounts/backend/data/stance-research/YYYY-MM-DD-[BATCH_NAME]/` (research.csv, evidence.csv; STEP 4a adds gate-findings.json, stances.csv and publish-report.json)
```

### Value-Change Guard — enforced in code

`verify-stance-research.ts` diffs every proposed value against the **open season** and applies
`decidePublish` (`backend/scripts/lib/stancePublishPolicy.ts`): a row already holding a value in
the open season — including a 0 (an editor's blank) — is **never** written automatically; it goes to
the review queue with reason `value-change`. A row that would replace what voters see now from an
older season (the Season 1 fallback, including a 0) goes to review with `replaces-published-chair`,
even with `--auto-push` (ruling 2026-09-24). These buckets do not exist yet at STEP 3: the
verifier's dry-run in **STEP 4a(i)** writes them to `publish-report.json`. Read them there before
any `--apply`:

| action | meaning |
|---|---|
| `auto-push` | new, record-evidenced, gate-clean, verified, and **nothing is shown to voters for the pair now** — written on `--apply` **only when the run passes `--auto-push`**; without it (the default) this row is `review` / `review-all-mode` |
| `unchanged` | same value already in the **open** season — skipped |
| `review` | queued for a person: `review-all-mode` (clean, but review-all is on), `statement-evidence`, `value-change` (an open-season value, incl. 0, would change), `replaces-published-chair` (see below), `gate-medium`, `unresolved-politician` |
| `re-research` | `gate-high` (defective — goes back to research (4a(i)), not written; this includes an unresolved politician whose row has any other severe finding) or `below-threshold` (unverified — queued) |
| — `replaces-published-chair` | ruling 2026-09-24: the open season holds no value, but voters see an older season's chair (or a 0 blank) as the fallback, and this write would replace it. **Always review, even with `--auto-push`.** This includes proposing the SAME chair as the Season 1 fallback: the write creates the Season 2 row with new reasoning and citations against Season 2's served text, so it is a person's call, not `unchanged` |
| `out-of-scope` | the gate found `topic-out-of-scope`: the office does not hold this question. Recorded, **not** re-researched and not queued — re-researching the same pair cannot change it |

A queued row stores its reasons (`queue_reasons`) and `evidence_type` once CA_0285 is applied, and the
review page shows them, with the value voters see now (the Season 1 chair when the open season holds
none) beside the open-season value.

Every queued row in `publish-report.json` carries `admin_queue_visible`. **`false` means the row
is saved but NOT in the admin queue**: an `unresolved-politician` row is stored with status
`unresolved_politician`, and the admin review queue lists only `pending` rows. The verifier prints
these under `NOT IN THE ADMIN QUEUE — politician not resolved; rebuild the bundle with this person
(--politician <uuid>:<level>) and re-run:`. Do exactly that; nobody will find them in the admin UI.

**The public summary MUST move with the value.** `politician_context.reasoning` is the "here's how we
got to this value" blurb shown on the candidate's **Essentials profile** and the **Compass** — it is
public-facing. Whenever you push a value (NEW or CHANGE), you MUST write/replace the reasoning so it
justifies the value being stored, in plain language a voter can trust. Never change a value and leave
a stale reasoning that describes the old position, and never leave the reasoning blank. After any
value CHANGE, re-read the stored reasoning and confirm it (a) describes the new value's position and
(b) doesn't still argue the old one — a value/summary mismatch is a trust defect, not a cosmetic one.
(This mirrors the quote↔value coupling check: the summary is coupled to the value just as the quote is.)

### Quote Overview (Read & Rank)

For every row with a non-blank `quote_text`, show:

| Politician | Topic | Quote (de-identified) | Gates | De-id OK? |
|-----------|-------|----------------------|-------|-----------|
| Name 1 | healthcare | "..." | fwd ✓ / on-q ✓ / not-attack ✓ | yes / NEEDS MANUAL DE-ID (blank) |

**Gates** = the three quote-selection gates from STEP 1 (forward-not-record, on-question,
position-not-personal-attack). Any quote that fails a gate should be dropped as a quote (the stance
value can still push from the record); flag it rather than pushing it. **De-id OK?** = passed the
de-identification contract (no surname / partisan tell / self-ID leak, honest `…`/`[bracket]`
marking). Run `scripts/build-and-check.mjs` (STEP 4a) to catch the mechanical de-id/note failures
before you get here.

For each (politician, topic) that ALREADY has quote(s) in `essentials.quotes`, show the
existing de-identified quote vs the new one and ask which should be the Read & Rank pick
(`readrank_selected`). Default: keep the current selection.

Rows where `quote_text` is present but `quote_deidentified` is blank are recorded as
library quotes but are NOT eligible to be the Read & Rank pick.

Then ask:
> "Review the stances above. Note: approved quotes are pushed as **drafts** and only promoted to
> live after the quote audit is clean (STEP 4). You can:
> 1. **Approve all** — run the pre-push QA, then queue stances for review, push quotes as drafts, audit, and promote picks
> 2. **Reject specific rows** — tell me which politician/topic pairs to remove
> 3. **Edit values** — not in the CSV. Change a value in the admin review queue when you approve that row
> (value override), or send the row back for re-research. Never edit `value`, `reasoning` or sources in
> research.csv to reach a different chair.
> 4. **Skip DB push** — keep the batch files only, don't write to database
>
> What would you like to do?"

---

## STEP 4 — QA → Push as Drafts → Audit → Promote

Quotes go through a pipeline, never a single write. The order is: **(4a)** pre-push QA over the CSV,
**(4b–4d)** queue approved stances for review, push quotes as **drafts**, **(4e)** hand off to the `audit-quotes`
skill, **(4f)** promote the Read & Rank picks to live only once the audit is clean.

### 4a. Pre-push QA (before any write)

🔴 **(0) Verify every quote against raw page bytes, before anything else.** WebFetch runs each
page through a summarising model and will hand back paraphrased talking points formatted as
quotations. A quote that never existed is a fabricated statement attributed to a real person — the
worst thing this pipeline can produce, and no other check in 4a looks for it.

```bash
cd ev-accounts/backend && npm run verify:quotes -- data/stance-research/<YYYY-MM-DD-batch>/research.csv \
  --sources data/stance-research/otr-transcripts/<race_id>   # drop --sources if STEP 0.5 (OTR) did not run
```

Name `research.csv` directly, not the batch directory: `verify-quotes.mjs`'s directory-scan pattern
(`/^out-.*\.csv$/`) only applies when the target is a *directory* — a file path is checked as-is, no
`--pattern` needed.

`--sources <dir>` loads every `.md`/`.txt` file in that ONE directory and checks a quote's text against
all of them BEFORE trying to fetch the URL it cites — and it does that match blind to which URL the row
actually names. That is what lets it verify an OTR-cited quote at all: `extract-otr.mjs` (STEP 0.5) cites
each quote by its **YouTube URL**, which is not fetchable text, but the transcript file it wrote for that
candidate is plain text — pointing `--sources` at `otr-transcripts/<race_id>` puts that file in the pool
this check searches. A quote the transcript doesn't cover still falls through to a live fetch of its own
`source_url_1..3` in the same run; passing `--sources` only changes which directory is tried first, it
never turns off the live-fetch fallback.

It exits 1 and names every quote it could not find. A failure is either mis-sourced (find the true
source — a new source URL, so re-research that pair; see 4a(i)) or invented (drop the quote). Do not
push past a non-zero exit.

🔁 **Re-run this check after any quote-field edit made to resolve a 4a(ii) finding** (`source-summary`,
`misleading-verbatim`, or a `deid-dishonest`/`note-not-self-contained` fix that touched `quote_text`) —
a hand-edited quote is unverified until step (0) has run against it again.

**(i) Stance gate, snippet verification, quote mechanics — in this order.**

```bash
cd ev-accounts/backend && set -a && source .env && set +a
B=data/stance-research/YYYY-MM-DD-[BATCH_NAME]
npx tsx scripts/stance-gate.ts --dir $B              # exit 1 = high findings: re-research those pairs yourself, re-run —
                                                     # EXCEPT topic-out-of-scope, which is closed research (see below)
npx tsx scripts/verify-stance-research.ts --dir $B   # dry-run: fetches every source, writes $B/publish-report.json
node ../.claude/skills/research-stances/scripts/build-and-check.mjs --csv $B/research.csv   # quotes
# build-and-check prints "MECHANICAL FINDINGS: N (high=.. medium=.. low=..)", writes
# $B/research.bundle.json, and exits non-zero if any high-severity finding remains.
```

`build-and-check.mjs` builds the audit context bundle (topics → quotes with stance + editor_note +
de-id) and runs the deterministic quote checks (note-missing, note-section-ref, note-too-long,
deid-missing, trailing-ellipsis, partisan-tell, invalid-source, unquotable-source, scorecard-source,
pointer-only-source, stance-label). There is no campaign-site URL check: a campaign page is judged on
how directly it answers the question, not on its medium, so that call belongs to the judgment pass
below (`source-not-an-answer`).

**Stance findings go back to research. The orchestrator never edits past the gate.** One high finding
is not a research defect: `topic-out-of-scope` means the office does not hold the question, so the
verifier records the row as `out-of-scope` and it is **not** re-researched — remove nothing, re-run
nothing for it. `level-unknown` is also high: fix the person's level (re-type the district, or leave a
community-college trustee out of the batch) before any research. Every other `stance-gate` **high**
finding (and a verifier `re-research` row) means the research is defective:
re-research that pair yourself — fetch the sources again and rebuild the row from what the pages say
— have the new pass REPLACE that pair's rows in research.csv and evidence.csv (STEP 2 item 4), and
re-run the gate. Research runs inline, so the same session also acts as orchestrator from the gate to
the push; in that role you must **never** edit `value`, `reasoning`, `evidence_type`, source URLs or
snippets to clear a finding. An edit that clears a finding is a claim no research pass made and no
fetched page backs; the gate exists to stop exactly that.

**Quote mechanics (from `build-and-check.mjs` only) are fixed in the CSV.** Fix every **high**
quote finding in the quote fields — write the missing `editor_note`, de-identify honestly, strip the
trailing ellipsis, neutralize the partisan tell in the blind (`quote_deidentified`) text — and re-run
until it's clean. An aggregator / quiz / scorecard source (`invalid-source`, `unquotable-source`,
`scorecard-source`) must be re-sourced to the original. 🔴 **VOTE411 / thevoterguide.org cannot be
cited at all — LWV terms bar reproducing it — and that applies to every row, not only quote rows.**
No `source_url_1..3` in research.csv, on a stance row or a quote row, may be a vote411.org or
thevoterguide.org URL. `stance-gate` refuses it on every row (`pointer-only-source`, high) — in the row's
sources AND in any evidence.csv URL for the pair — and `build-and-check.mjs` flags it on rows with a
quote. It matters because a stance row's snippets become public citations when a person approves the row. Re-source the position to the
candidate's own materials; if VOTE411 is the only place it appears, drop the quote, and a stance
that rests only on it has no citable source, so its re-research ends in a blank value. A new
source URL changes the stance row, so re-sourcing is a re-research of that pair (fetch the original,
back it with a snippet in evidence.csv, REPLACE the pair's rows, re-run the gate), not an edit.
Dropping the quote (clearing its quote fields) is a quote-field fix. Do not push a CSV with
high-severity mechanical findings.

**(ii) Judgment pass — inline, one candidate at a time.** 🔴🔴 **Do NOT dispatch a sub-agent for
this.** Read the **audit-quotes CHECKS.md §4 judgment prompt**
(`../on-the-record/.claude/skills/audit-quotes/CHECKS.md`) and apply it yourself to the
`<csv>.bundle.json` produced above (`$B/research.bundle.json`), one candidate per pass. This used
to say to dispatch one `Agent`-tool sub-agent per candidate *or per race*; that was withdrawn on
2026-09-23 for the same reasons STEP 1 gives, two of which apply here without qualification:

- **This is a verification pass**, and a sub-agent returning "clean" is not evidence anything was
  checked. That failure is on the record here.
- **"Or per race" is a batch**, and a batch hides which judgment went wrong.
- Reason 1 applies to **one** of the checks rather than all of them, which is worth knowing: the
  bundle is a local file, so most checks need no MCP — but `coupling-in-tension` weighs the quote
  against the seated chair, and the authority for rung text is the **season pin**. A sub-agent
  cannot reach it and would fall back to the frozen `inform.compass_stances`, on exactly the
  ladders STEP 0 warns disagree with it.

Produce the same JSON array of judgment findings
(`not-forward`, `is-attack`, `off-question`, `question-override`, `deid-dishonest`,
`note-not-self-contained`, `source-summary`, `coupling-in-tension`, `non-differentiating-goal`,
`source-not-an-answer`, `misleading-verbatim`). Resolve them:
- `not-forward` / `off-question` / `is-attack` → drop the quote (keep the stance value from the
  record); a `coupling-in-tension` → surface to the user with the value-change guard.
- `question-override` → should not fire here: this bundle carries only the Compass question, never
  a per-race override. If it does, surface it to the user; overrides are checked in the 4e audit.
- `deid-dishonest` / `note-not-self-contained` → fix the CSV field, re-run 4a(i), and continue.
- `source-summary` → replace the bullet or paraphrase with a sentence the candidate actually wrote
  in that source. If the source has none, drop the quote. Taking the sentence from a different
  source is a new source URL: re-research that pair (4a(i)); never edit `source_url_1..3` directly.
- `misleading-verbatim` → restore the qualifier or context the trim removed, or drop the quote if
  no trim of the passage reads true on the blind card. Being verbatim does not excuse it.
- `non-differentiating-goal` → surface to the user. The quote names a goal, a target or a
  direction but no means, so do not promote it to live (4f) unless the user affirms it carries a
  real distinguishing position.
- `source-not-an-answer` → look for a more direct answer (a questionnaire or interview answer to
  this question). Citing it is a new source URL, so re-research that pair (4a(i)); never edit
  `source_url_1..3` directly. If none exists, keep the quote: a curator-extracted quote may be all a
  candidate has, and that is honest presence, not a defect.
Only quotes that clear both passes proceed to the push.

### 4b. IDs come from the bundle — no separate lookup

`politicians.json` (written by `build-stance-topic-bundle.ts`) holds each person's `politician_id`;
`stance-gate.ts` carries it into `stances.csv`; `verify-stance-research.ts` resolves by that id,
never by name. For the quote push (4d), take `politician_id` from `politicians.json` and `topic_key`
from `topics.json` (the quote object in 4d carries `topic_key`, not `topic_id` — `essentials.quotes`
has no `topic_id` column). `topics.json` is already the open season's pin (STEP 0), so a `topic_key`
taken from it is always a question the open season asks — the `is_live` trap that the old name-based
lookup here fell into (17 pinned topics dropped, without raising) cannot happen.

- **Two people with the same name in one batch are refused** by the gate (`ambiguous-politician`,
  high). Research them in separate batches.
- **A person not in `politicians.json`** is flagged `unknown-politician`. Rebuild the bundle with them
  (`--politician <uuid>:<level>`) — do not guess an id. If they are not in `essentials.politicians` at
  all, create them first via the admin panel; their `research.csv` rows are kept.

### 4c. Write stances (and their verified snippets) through the verifier

```bash
cd ev-accounts/backend && set -a && source .env && set +a
npx tsx scripts/verify-stance-research.ts --dir data/stance-research/YYYY-MM-DD-[BATCH_NAME] \
  --apply --editor-id <your admin user uuid>          # review-all (default): every stance is queued
# add --auto-push ONLY as a deliberate, per-run operator decision (ruling 2026-09-22)
# add --re-researched when THIS run is a re-research pass over pairs the last run sent back
#   below-threshold. It stamps re_research_attempted=true only on the queued rows whose reasons
#   include below-threshold — never on every queued row of the run — so the admin review queue
#   shows "Re-research attempted" only where that is actually true. Omit it on an ordinary run.
```

**By default nothing is published by this command.** Every scored row that is not `unchanged` or
`gate-high` goes to `stance_research_review` for a person to approve in the admin review queue — a
row that passed every check is queued with reason `review-all-mode`. Only with `--auto-push` are
`auto-push` rows written directly, with `writeVerifiedStance` (season-aware: `UPSERT_ANSWER_SQL` +
`UPSERT_CONTEXT_SQL` + `assertWritten`) and their verified snippets in
`politician_context_evidence`, one transaction per row. `gate-high` rows are never written — they go
back to research (4a(i)): re-research the pair yourself.

The verifier refuses the whole batch (exit 2, nothing written) when: two rows share a
(politician, topic) pair; the bundle's pin OR served revision for a scored topic is no longer the open
season's ("the ladder changed since the bundle was built — rebuild the bundle and re-research
these topics"); `topics.json` is missing, unreadable, or has no `served_revision_id` (a bundle built
before 2026-09-24 printed the pin's text — rebuild it and re-research); `stances.csv` has no
`source_urls` column (re-run `stance-gate`); or `--editor-id` is not a user.

Re-running `--apply` on the same batch is safe: review rows a person already resolved or rejected
are left alone (reported as `LEFT ALONE`), never reset to pending. The SUMMARY reports
`snippets inserted=N of M attempted`; a shortfall means those snippets were already stored for the
pair (the evidence unique index has no season column).

**Unresolved politicians are saved but NOT in the admin queue.** A row whose person is not resolved
is stored with status `unresolved_politician` (its `full_name_raw` kept), and the admin review queue
lists only `pending` rows. The verifier lists these under `NOT IN THE ADMIN QUEUE — politician not
resolved; rebuild the bundle with this person (--politician <uuid>:<level>) and re-run:`, and
publish-report.json marks them `"admin_queue_visible": false`. Rebuild the bundle with each one and
re-run; do not expect to find them in the admin UI.

A queued row's verified snippets become public citations only when a person approves it (resolveResearchReview writes them) — never at queue time, because they would render under the stance displayed now. What is published is each snippet's **matched on-page span**, never the full snippet (ruling 2026-09-24); a row queued before that stored no span, and its snippets are not published. Approval is refused when the row has no publishable machine-verified and no hand-verified source, and resolve and reject both act only on a row still `pending` (409 otherwise).

**Which season?** Whichever is open — check with
`SELECT number FROM inform.seasons WHERE status = 'open'`. Do not trust a season number written in a
doc; this one said "Season 1" for a month after Season 2 opened.

⚠️ **Never hand-roll a stance INSERT**, and never copy `backend/scripts/apply-*-stances.ts` — all 149 of
them (counted 2026-09-23) carry the pre-seasons bare-pair upsert, which fails (`23502`) or silently writes nothing.

### 4c.1. After human approvals — export the ledger and audit it

Under review-all (the default), `--apply` above mostly *queues* rows; a person approves each one
afterward in the admin review queue (`resolveResearchReview`), and that is when a chair is actually
seated. Once approvals for this batch are done — even partially; re-run this later for the rest —
build the written ledger from what was actually approved and audit it:

```bash
cd ev-accounts/backend && set -a && source .env && set +a
B=data/stance-research/YYYY-MM-DD-[BATCH_NAME]
npx tsx scripts/export-written-ledger.ts --batch $(basename $B) --dir $B
node scripts/audit-chair-evidence.mjs --check $B/written-$(basename $B).json
npm run check:stance-sources
```

`export-written-ledger.ts` reads `inform.stance_research_review` (resolved rows for this batch
only) and `$B/research.csv` — read-only, no writes — and refuses to produce an empty ledger (see
its own header for the two distinct refusal messages: 0 resolved rows vs. 0 of them record
evidence). If `--apply` above also auto-pushed some rows directly (`--auto-push`), it already wrote
`$B/written-<batch>.json` itself for those; running `export-written-ledger.ts` afterward
**overwrites** that file with the resolved-review-row ledger — run it only once approvals are the
ledger you want audited, and re-run `verify-stance-research.ts --apply` first if you need both
sets covered.

⚠ **Statement rows never appear in this ledger, and that is correct, not a gap.** Evidence class is
per-row (operator decision 2026-09-22): `record` evidence must name the bill, ordinance or vote
NAMES_INSTRUMENT looks for; `statement` evidence is the person's own words, which cannot name an
instrument by definition and goes to human review instead (see the Global Constraints in
`docs/superpowers/plans/2026-09-23-stance-program-reconciliation.md`, "`audit-chair-evidence --check`
runs on record rows only"). `export-written-ledger.ts` classifies each resolved row against
`research.csv`'s `evidence_type` column and drops anything that is `statement` or unclassifiable,
printing every drop — check that list before trusting a clean audit run; a batch of all-statement
rows produces an empty ledger and the script refuses to write one (see above), rather than a
silently vacuous pass.

**Commit the batch directory as the ledger.** `research.csv`, `evidence.csv`, `stances.csv`,
`gate-findings.json`, `publish-report.json` and `written-<batch>.json` are deliberately NOT
git-ignored (`backend/.gitignore` only excludes `_*`-prefixed files, `wave*` directories,
`*.bundle.json` and a few other scratch patterns under `data/stance-research/`) — commit the whole
directory with an explicit pathspec once `check:stance-sources` is clean, so the audit trail lives
in git history next to the migration or PR that relied on it.

### 4d. Push quotes to essentials.quotes — as DRAFTS

Every quote is inserted with `readrank_selected=false` and its `editor_note`. **Nothing is promoted
to live here** — promotion happens in 4f, after the audit. For each approved, name-resolved,
gate-passing row build a quote object:

```
{
  politician_id, topic_key,            // topic_key lowercased
  quote_text, quote_deidentified,      // from the CSV; deid may be blank (library-only quote)
  editor_note,                         // REQUIRED — from the CSV; QA at 4a guarantees it's present
  source_url,                          // first non-blank source_url_1..3, else null
  full_name                            // carried through for the pre-select leak-check at 4f
}
```

Only include objects whose `quote_text` is non-blank. Then run:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const quotes = JSON.parse(process.argv[2]);
let inserted = 0, dupes = 0; const missingNote = [];
await pool.query('BEGIN');
try {
  for (const x of quotes) {
    const tk = x.topic_key.toLowerCase();
    if (!x.editor_note || !x.editor_note.trim()) { missingNote.push(x.full_name + '/' + tk); continue; }
    const { rows: dup } = await pool.query(
      'SELECT id FROM essentials.quotes WHERE politician_id=\$1 AND lower(topic_key)=\$2 AND quote_text=\$3',
      [x.politician_id, tk, x.quote_text]
    );
    if (dup.length) { dupes++; continue; }
    const sourceName = x.source_url ? (()=>{ try { return new URL(x.source_url).hostname; } catch { return null; } })() : null;
    await pool.query(
      'INSERT INTO essentials.quotes (politician_id, topic_key, quote_text, deidentified_text, source_url, source_name, editor_note, readrank_selected) VALUES (\$1,\$2,\$3,\$4,\$5,\$6,\$7,false)',
      [x.politician_id, tk, x.quote_text, x.quote_deidentified || null, x.source_url || null, sourceName, x.editor_note]
    );
    inserted++;
  }
  await pool.query('COMMIT');
  console.log(JSON.stringify({ inserted, dupes, missingNote }, null, 2));
} catch (e) { await pool.query('ROLLBACK'); console.error('Rolled back:', e.message); process.exit(1); }
await pool.end();
" '[JSON_ARRAY_OF_QUOTE_OBJECTS]'
```

If `missingNote` is non-empty, those rows were skipped — write their editor_note and re-run.

### 4e. Hand off to the audit-quotes skill

With the drafts in place, run the real quote audit (it adds YouTube source-verification against the
ingested OTR transcripts — the check the mechanical pass can't do):

```bash
cd on-the-record/.claude/skills/audit-quotes && \
  ../../../.venv/bin/python -m scripts.audit --race <race_id> --include-drafts
```

Then run the judgment and portfolio pass per the `audit-quotes` SKILL.md, and resolve
residual findings with `scripts/apply_fixes.py fixes.json` (dry-run first, show the diff, `--commit`
only after the user OKs).

⚠ **`audit-quotes` lives in the `on-the-record` repo and still describes that judgment pass as a
fan-out.** It has not been changed by this ruling, so read it as *what* to judge, not *how* to
dispatch it. **Run it inline, one candidate at a time**, for the reasons in 4a(ii). If that skill is
ever updated, this caveat should go with it. Never auto-apply `decision-required` findings — list them for the user.
A `source-unverified` finding usually means the quote is **mis-sourced** (wrong `source_url`); hunt
the true OTR source and re-cite it rather than dropping a genuine quote.

### 4f. Promote the Read & Rank picks to live (only after the audit is clean)

For each topic where a candidate should have a live pick, promote exactly one quote — but only once
4e is clean. Each promotion must pass a final leak-check on `deidentified_text` (no surname, no
partisan tell, no self-ID) and replaces any currently-selected quote on that topic:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const picks = JSON.parse(process.argv[2]);  // [{ id, full_name }]
let selected = 0; const leaks = [];
const PARTISAN = /\\\\b(Democrat|Democrats|Democratic|Republican|Republicans|GOP|MAGA)\\\\b/;
const SELFID = /\\\\b(as governor|as attorney general|as senator|when I was|my administration|I'm a legal|only person here)\\\\b/i;
await pool.query('BEGIN');
try {
  for (const p of picks) {
    const { rows } = await pool.query('SELECT politician_id::text, lower(topic_key) tk, deidentified_text d FROM essentials.quotes WHERE id=\$1', [p.id]);
    if (!rows.length) { leaks.push(p.id + ': not found'); continue; }
    const { politician_id, tk, d } = rows[0];
    if (!d) { leaks.push(p.id + ': no de-id text'); continue; }
    const surname = (p.full_name || '').trim().split(/\\\\s+/).pop();
    const surnameHit = surname && new RegExp('\\\\\\\\b' + surname.replace(/[.*+?^\${}()|[\\]\\\\]/g,'\\\\\\\\\$&') + '\\\\\\\\b','i').test(d);
    if (surnameHit || PARTISAN.test(d) || SELFID.test(d)) { leaks.push(p.id + ': leak in de-id, not promoted'); continue; }
    await pool.query('UPDATE essentials.quotes SET readrank_selected=false WHERE politician_id=\$1 AND lower(topic_key)=\$2', [politician_id, tk]);
    await pool.query('UPDATE essentials.quotes SET readrank_selected=true WHERE id=\$1', [p.id]);
    selected++;
  }
  await pool.query('COMMIT');
  console.log(JSON.stringify({ selected, leaks }, null, 2));
} catch (e) { await pool.query('ROLLBACK'); console.error('Rolled back:', e.message); process.exit(1); }
await pool.end();
" '[JSON_ARRAY_OF_PICKS]'
```

### 4g. Report results

After the pipeline:
> "Queued [N] stances for review and pushed [N] quote drafts for [politician names].
> - Stances (from publish-report.json): [N] auto-push, [N] unchanged, [N] queued for review ([reasons]), [N] re-research
> - NOT in the admin queue (unresolved politician — rebuild the bundle with them): [list, or "none"]
> - Every auto-pushed stance (only with --auto-push) was written with its reasoning and its verified snippets
> - Quotes: [inserted] inserted as drafts, [dupes] already present
> - Audit: [clean / residual findings resolved via apply_fixes]
> - Promoted to live: [selected] Read & Rank pick(s); held back (de-id leak): [leaks list]
> - Batch preserved at: [batch directory] (research.csv, evidence.csv, gate-findings.json, publish-report.json)
>
> Reminder: a race becomes playable in Read & Rank only when ≥2 candidates in it each have a
> readrank_selected de-identified quote on a live topic."

---

## SHADOW CODING (P1, spec 2026-09-25) — measures, publishes nothing

Run AFTER the normal pipeline for the same politician. It does not change what the verify step
queues. Its only outputs are `coding-report.json` and, with the operator's OK, rows in
`inform.stance_coder_labels`.

1. **Collect.** While researching, also write `<batch>/sources.json` (the
   `backend/scripts/lib/sourcesManifest.ts` contract): every source you read, with its `source_kind`,
   instruments and verbatim anchor passages. **No `value`, chair or reasoning keys** — the parser
   refuses them. For a public-record or own-site page that automation cannot fetch, save it from a
   real browser into `<batch>/human-saved/` and set `human_saved_path`. **Never do this for news**
   (spec §5.4).
   - Before searching, run `npx tsx scripts/build-s1-leads.ts --dir <batch> --politician <uuid>`
     (from `backend/`) and check each lead's cited sources first. Old citations are often wrong (bill
     number, chamber, a dead bill). **Never pass `s1-leads.json` to a coder.**
   - Search with the topic annex's **Synonyms** as well as the plain topic words, before recording
     that nothing was found.
   - Before collecting, read the source profiles for the jurisdiction in `docs/sources/` (access
     notes, which page proves what, traps). A record page from a source with no profile gets
     `no-source-profile` in CONFIRM: write the profile from `docs/sources/README.md`, with the saved
     page as an `expect: pass` control, in the same batch.
2. `npm run coding:snapshot --prefix backend -- --dir <batch>` → `snapshots.json`. Read the NOT CODABLE
   lines.
3. `npm run coding:inputs --prefix backend -- --dir <batch> --politician <uuid> [--office <uuid>]`
   → `coder-inputs/coder-{1,2,3}.md`.
4. **Dispatch three coders with the headless CLI**, run from an **empty scratch directory**, one
   line per slot (slot 1 `--model opus`, slots 2 and 3 `--model sonnet`). This sends the input file
   byte-exact (the file hash printed in step 3 is the record of what was sent) and uses plan quota:

   ```bash
   CLAUDE_CONFIG_DIR=~/.claude-ev claude -p --model <opus|sonnet> --tools Write --allowedTools Write --permission-mode acceptEdits --add-dir <batch>/labels --output-format text < <batch>/coder-inputs/coder-N.md
   ```

   - Do not edit, summarise or add to `coder-N.md`.
   - Do not read the coders' files and "fix" them. An invalid label is data (`coder-missing`).
5. `npm run coding:report --prefix backend -- --dir <batch> --season-id <open season uuid> --models "opus,sonnet,sonnet"`.
   Every record passage needs `record_kind`; each record (all passages on one `instrument`) needs
   `actor_quote` on at least one page, and a vote needs `tally_quote` on at least one page (ruling
   2026-09-26, per group). CONFIRM judges a vote page and its bill text together, as one basis, and
   requires the vote page to name the seat's chamber.
6. If `needs-source.json` is non-empty: fetch those sources (you are the only role with tools), add
   them to `sources.json`, and repeat from step 2 — **all three coders again**. After two rounds with
   no new snapshot, stop (spec §1.3).
7. `--apply` on steps 2 and 5 **only with the operator's explicit OK**, and only after CA_0292 is
   applied.

---

## ERROR HANDLING

- If research on a politician cannot be finished (sources will not load, or the run stops part-way), report which politician and which topics are unfinished, and offer to re-research just those yourself. A retry REPLACES that politician's rows for the retried topics in research.csv and evidence.csv — never append a second row for a pair (STEP 2 item 4)
- If research.csv or evidence.csv can't be written, fall back to showing results in conversation and offer to retry the file write
- If DB push fails for a specific row, report the error, skip that row, and continue with the rest
- Never lose data — research.csv and evidence.csv in the batch directory are the source of truth, and publish-report.json records what happened to each row; DB push is additive

---

# Changing a ladder is not this skill's job

This skill used to carry a `--rewrite-id` REWRITE RE-EVALUATION MODE that fed
`inform.topic_rewrites` / `inform.topic_rewrite_stance_proposals`. **It was removed on 2026-09-23.**
Both of those tables have always been empty — zero rows, ever — while the revision model it
predates has 140 revisions spanning 2026-03-15 to 2026-09-12. It was a second, unused path to a job
the revision model already does, and it still read the frozen `inform.compass_stances` table for
both of its ladders, which is the defect this skill spends STEP 0 warning about.

Use the revision model instead. It already carries what rewrite mode was hand-rolling:

- **`change_class`** — `clarifying` keeps existing seats and nothing re-audits; `substantive` means
  the seats' evidence was gathered against a sentence that no longer exists, so those rows need a
  re-audit against the new wording. State the seated-row count in the proposal's rationale so the
  reviewer can price that re-audit before approving.
- **`rung_map`** — the old→new identity mapping that decides which seats carry forward.

Mechanics are in §8.3–8.5 of `docs/superpowers/specs/2026-09-23-stance-program-design.md`: propose
a revision and approve it; for a **major** change do not publish — stage it into the next draft
season and let the season opening publish it. A season's pin never moves once open, so rows already
seated keep asserting exactly the wording they were evidenced against.

Once a new ladder is pinned into the open season, re-researching the people seated against the old
one is an ordinary run of this skill — STEP 0 resolves the new rung text from the pin, and the
value-change guard (STEP 3, enforced by `verify-stance-research`) sends each changed value to the
review queue, where a person signs off on it one row at a time.
