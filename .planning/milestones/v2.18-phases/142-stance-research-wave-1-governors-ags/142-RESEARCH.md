# Phase 142: Stance Research Wave 1 — Governors + AGs - Research

**Researched:** 2026-06-21
**Domain:** Politician compass-stance data research + push pipeline (v2.16/v2.17 reuse), researcher-prompt extension
**Confidence:** HIGH (pipeline, schema, in-scope set all verified against prod 2026-06-21)

## Summary

Phase 142 is a **pure data + prompt-update phase** with two deliverables. **SEXS-01** extends the stance-researcher prompt with office-type evidence guidance (this is a one-time edit to a prompt file, gating everything that follows). **SEXS-02 (partial)** researches and pushes sourced compass stances for the **80 in-scope execs** — **43 Governors + 37 Attorneys General** — that currently lack any `inform.politician_answers` rows. The work **reuses the established v2.16/v2.17 stance pipeline verbatim**: per-exec CSV produced by the `politician-stance-researcher` agent at **3-concurrency**, merged + validated by a per-batch `_merge.ts`, pushed external_id→UUID by a per-batch `_push.ts`. No new stack, no schema changes, no backend code.

The 80-exec set is **prod-verified** (query below). It includes 4 existing-but-unstanced execs (ME Gov Mills, TX Gov Abbott, TX AG Paxton, IN AG Rokita) plus the Gov+AG of all 41 newly-seeded states. Previously-stanced execs (CA Newsom/Bonta, MA Healey/Campbell, MD Moore/Brown, OR Kotek/Rayfield, UT Cox/Brown, VA Spanberger/Jones) are **NOT touched** — the `NOT EXISTS (politician_answers)` filter excludes them automatically.

**Primary recommendation:** First land the SEXS-01 prompt edit (extend `politician-stance-researcher.md` Evidence Hierarchy with office-type guidance for all 5 exec types). Then run the standard pipeline in balanced ~5-exec-per-plan batches at 3-concurrency, grouping Govs and AGs together, largest-population states first. Use the **exact external_ids from the verified query** (they are irregular — IN Rokita is POSITIVE, TX/AZ/ME/WV use ad-hoc ids) — never derive ids from the FIPS formula. Verify per-scope via labeled assertions keyed on `district_type='STATE_EXEC' AND role_canonical`, never on external_id ranges (STATE_EXEC ids are non-contiguous).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stance research (find evidence, assign 1–5) | Agent (`politician-stance-researcher`) | — | WebFetch-only research agent; orchestrated at 3-concurrency |
| Office-type evidence guidance (SEXS-01) | Prompt file (agent def + dispatch template) | — | Edit before first dispatch; shapes how agent maps exec actions to topics |
| CSV merge + validation | Build/script tier (`_merge.ts`, tsx) | — | RFC-4180 parse, quad-quote repair, problem report; no DB writes |
| Push answers + context + quotes | Database tier (`_push.ts`, pg pool, txn) | — | external_id→UUID resolve, BEGIN/COMMIT, ON CONFLICT upsert |
| Stance data persistence | `inform.politician_answers` + `inform.politician_context` (+ `essentials.quotes`) | — | answer + paired source-bearing context; zero-unsourced invariant |
| Feed surfacing (no work here) | `essentialsService.ts` (already wired) | — | `STATE_EXEC` already enumerated; verified in Phase 144, not 142 |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEXS-01 | Stance researcher prompt extended with office-type evidence guidance (AG=lawsuits/amicus/multistate coalitions; Gov=bill signings/vetoes/EOs/budget; Treasurer=invest/divest; SoS=election-admin; LtGov=honest-partial) before first dispatch; distinguishes bill signings from amicus from investment decisions | §"SEXS-01: Prompt-Update Target + Proposed Guidance" — exact target file `.claude/agents/politician-stance-researcher.md` + proposed insert text covering all 5 exec types |
| SEXS-02 (partial — Gov+AG) | Every in-scope Governor + AG that lacked stances has ≥1 sourced `inform.politician_answers` row, each paired to an `inform.politician_context` row with a real fetched source URL; zero unsourced; honest-skip per topic; proxy-row review gate; never inferred from party | §"In-Scope Set" (80 execs, verified); §"End-to-End Pipeline"; §"Schema Reference"; §"Calibration & Pitfalls" |
</phase_requirements>

## In-Scope Set — 80 Execs (43 Governors + 37 AGs)

**Verified against prod `kxsdzaojfaibhuzmclfq` on 2026-06-21** [VERIFIED: prod query]. Defining query (canonical — the planner must re-run this immediately before authoring to catch any drift):

```sql
SELECT p.external_id, p.full_name, d.state, o.role_canonical
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id=p.id
JOIN essentials.districts d ON d.id=o.district_id
WHERE d.district_type='STATE_EXEC'
  AND o.role_canonical IN ('governor','attorney_general')
  AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id=p.id)
ORDER BY o.role_canonical, d.state;
-- returns 80 rows: 43 governors + 37 attorneys_general
```

> **CRITICAL — external_ids are IRREGULAR. Use the exact ids below; never derive from `-(fips*100000+seq)`.** IN Rokita is POSITIVE (`499453`), TX uses `-100204`/`-100202`, AZ uses `-400091`/`-400092`, ME Gov uses `-230001`, WV AG uses `-5400002` (seq 2, not 3). The `_push.ts` resolves external_id→UUID directly, so these irregularities are harmless **as long as the CSV carries the exact id from this query**. (No NULL external_ids in scope — verified.)

### Governors (43) — `role_canonical='governor'`

| State | external_id | Governor | State | external_id | Governor |
|-------|-------------|----------|-------|-------------|----------|
| AK | -200008 | Mike Dunleavy | MT | -3000001 | Greg Gianforte |
| AL | -100001 | Kay Ivey | NC | -3700001 | Josh Stein |
| AR | -500001 | Sarah Huckabee Sanders | ND | -3800001 | Kelly Armstrong |
| AZ | -400091 | Katie Hobbs | NE | -3100001 | Jim Pillen |
| CO | -800001 | Jared Polis | NH | -3300001 | Kelly Ayotte |
| CT | -900001 | Ned Lamont | NJ | -3400001 | Mikie Sherrill |
| DE | -1000001 | Matt Meyer | NM | -3500001 | Michelle Lujan Grisham |
| FL | -1200001 | Ron DeSantis | NV | -3200001 | Joe Lombardo |
| GA | -1300001 | Brian Kemp | NY | -3600001 | Kathy Hochul |
| HI | -1500001 | Josh Green | OH | -3900001 | Mike DeWine |
| IA | -1900001 | Kim Reynolds | OK | -4000001 | Kevin Stitt |
| ID | -1600001 | Brad Little | PA | -4200001 | Josh Shapiro |
| IL | -1700001 | JB Pritzker | RI | -4400001 | Dan McKee |
| KS | -2000001 | Laura Kelly | SC | -4500001 | Henry McMaster |
| KY | -2100001 | Andy Beshear | SD | -4600001 | Larry Rhoden |
| LA | -2200001 | Jeff Landry | TN | -4700001 | Bill Lee |
| ME | -230001 | Janet T. Mills | TX | -100202 | Greg Abbott |
| MI | -2600001 | Gretchen Whitmer | VT | -5000001 | Phil Scott |
| MN | -2700001 | Tim Walz | WA | -5300001 | Bob Ferguson |
| MO | -2900001 | Mike Kehoe | WI | -5500001 | Tony Evers |
| MS | -2800001 | Tate Reeves | WV | -5400001 | Patrick Morrisey |
| | | | WY | -5600001 | Mark Gordon |

*(Governors NOT in scope — already stanced, do not touch: CA Newsom, IN Braun, MA Healey, MD Moore, OR Kotek, UT Cox, VA Spanberger. 43 + 7 = 50 governors total.)*

### Attorneys General (37) — `role_canonical='attorney_general'`

| State | external_id | AG | State | external_id | AG |
|-------|-------------|-----|-------|-------------|-----|
| AL | -100003 | Steve Marshall | NC | -3700003 | Jeff Jackson |
| AR | -500003 | Tim Griffin | ND | -3800003 | Drew Wrigley |
| AZ | -400092 | Kris Mayes | NE | -3100003 | Mike Hilgers |
| CO | -800003 | Phil Weiser | NM | -3500003 | Raul Torrez |
| CT | -900003 | William Tong | NV | -3200003 | Aaron Ford |
| DE | -1000003 | Kathy Jennings | NY | -3600003 | Letitia James |
| FL | -1200003 | James Uthmeier | OH | -3900003 | Andy Wilson |
| GA | -1300003 | Chris Carr | OK | -4000003 | Gentner Drummond |
| IA | -1900003 | Brenna Bird | PA | -4200003 | Dave Sunday |
| ID | -1600003 | Raul Labrador | RI | -4400003 | Peter Neronha |
| IL | -1700003 | Kwame Raoul | SC | -4500003 | Alan Wilson |
| IN | 499453 | Todd Rokita | SD | -4600003 | Marty Jackley |
| KS | -2000003 | Kris Kobach | TX | -100204 | Ken Paxton |
| KY | -2100003 | Russell Coleman | VT | -5000003 | Charity Clark |
| LA | -2200003 | Liz Murrill | WA | -5300003 | Nick Brown |
| MI | -2600003 | Dana Nessel | WI | -5500003 | Josh Kaul |
| MN | -2700003 | Keith Ellison | WV | -5400002 | JB McCuskey |
| MO | -2900003 | Catherine Hanaway | | | |
| MS | -2800003 | Lynn Fitch | | | |
| MT | -3000003 | Austin Knudsen | | | |

*(AGs NOT in scope — already stanced, do not touch: CA Bonta, MA Campbell, MD Brown, OR Rayfield, UT Brown, VA Jones. 37 + 6 = 43 elected AGs total.)*
*(States absent from AG list = AG is appointed/legislature-selected, hence not seeded: AK, HI, NH, NJ, TN, WY — out of scope per REQUIREMENTS.)*

**Confidence: HIGH** — direct prod query, counts cross-checked (43 Gov + 37 AG = 80; 43+7=50 Govs, 37+6=43 AGs match the 50/43 roster denominator).

## Standard Stack

Pure data phase — no packages installed. Tooling already present in `backend/`:

| Tool | Purpose | Why Standard |
|------|---------|--------------|
| `politician-stance-researcher` agent (`.claude/agents/`) | Research one exec → CSV | Established v2.16/v2.17 researcher; WebFetch-only |
| `csv-parse/sync` (already a dep) | RFC-4180 parse in `_merge.ts`/`_push.ts` | Quote columns contain commas/embedded quotes — never split on commas |
| `node --import tsx` | Run `_merge.ts` / `_push.ts` | Project standard for ad-hoc TS scripts |
| `pool` from `backend/src/lib/db.js` | DB writes in `_push.ts`, verification | Raw `pg` pool; transactional BEGIN/COMMIT |
| `psql` (with `set -a && source .env && set +a`) | Phase-144 gate | Read-only labeled-assertion SQL |

**No `npm install`. No migrations.** Stances are written via `_push.ts` (transactional upsert), not migration files. **Package Legitimacy Audit: N/A — no external packages installed this phase.**

## End-to-End Pipeline (v2.16/v2.17 — reuse verbatim)

A **per-batch directory** under `backend/data/stance-research/{batch-name}/` is the unit of work. Recent example: `backend/data/stance-research/atlarge-house/` containing `_TOPIC_SCALE.txt`, `_merge.ts`, `_push.ts`, and one `{name}.csv` per exec.

### Step 0 — Set up a batch dir (per plan/batch)

1. Pick a batch name (e.g., `gov-ag-batch-a`). `mkdir backend/data/stance-research/gov-ag-batch-a`.
2. Copy `_TOPIC_SCALE.txt` from a recent batch (e.g., `atlarge-house/`) — it is the **25 federal compass topics with full 1–5 stance texts**, fetched live 2026-06-19, and is **unchanged for state execs**. [VERIFIED: file + live DB query both yield the same 25 keys, 2026-06-21]
3. Copy `_merge.ts` and `_push.ts`; edit two things in `_merge.ts`:
   - `OUT` → the batch's dated output CSV path (e.g., `.../2026-06-21-gov-ag-batch-a.csv`)
   - `IN_SCOPE` → the `Set<number>` of **exact external_ids** for this batch's execs (from the verified query above — copy literally, do NOT compute).
   - `DIR` derivation, `FEDERAL` set, `repair()`, and `esc()` are reused untouched.

> **`_merge.ts` clone trap (v2.17 lesson):** when sed-cloning a prior `_merge.ts`, only the `OUT` path and `IN_SCOPE` set change. Watch the substring-clobber sed trap (e.g. a name like `oh-house-b` getting clipped by an `oh-house-batch-b` replace). Hand-edit the two values to be safe.

### Step 1 — Dispatch researcher agents (3-concurrency)

For each exec, dispatch one `politician-stance-researcher` agent (Agent tool, `subagent_type: "politician-stance-researcher"`).

- **Concurrency cap = 3** on premium tier per [[feedback_stance_research_one_at_a_time]]. **NEVER mass-launch 8–13** — burns the rate-limit quota and yields empty CSVs that can be committed as if complete. Validate the first triple of the milestone; if old 429 empty-output reappears, drop to 1–2. (Distinguish clock-based *session-limit* pauses — re-dispatch cleanly — from Pro-tier 429.)
- Wait for each agent to write its CSV before launching the next batch of ≤3.

**Dispatch prompt per exec must include:**
- Politician name + office/title + **state** (e.g., "Brian Kemp (Governor of Georgia)").
- The **`--output-file`** absolute path: `C:/EV-Accounts/backend/data/stance-research/gov-ag-batch-a/{lastname}.csv`.
- The full **`_TOPIC_SCALE.txt`** contents pasted into the TOPIC SCALE REFERENCE placeholder (per [[feedback_stance_scale_embed_texts]] — embed the actual 1–5 stance texts; never label "5=progressive").
- **The SEXS-01 office-type evidence guidance** (see next section) — for Gov + AG specifically this wave.
- The RFC-4180 escaping reminder (v2.16 lesson): wrap reasoning/quotes in double quotes, escape embedded quotes by doubling (`""`), do not append a stray trailing `"` to the empty final field.
- The CSV column order the agent already knows: `full_name,external_id,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified`. **The agent leaves `external_id` blank** by its own spec — but for the external-id-keyed merge to work, the **dispatch prompt MUST instruct the agent to put the exact external_id in the `external_id` column** (this is how v2.16/v2.17 batches keyed rows; the merge validates `IN_SCOPE.has(ext)`).

### Step 2 — Merge + validate

```bash
cd C:/EV-Accounts/backend && node --import tsx data/stance-research/gov-ag-batch-a/_merge.ts
```

`_merge.ts` (see `atlarge-house/_merge.ts`):
- Reads every `*.csv` not starting with `_`.
- **Quote-repair rule (CRITICAL):** `raw.replace(/"""""+/g, '"""').replace(/""""/g, '"""')` — collapse **quad+ quotes to triple ONLY**. **NEVER** collapse `"""`→`""`: `"""text"""` is a VALID RFC-4180 literal-quoted field and the 3→2 collapse corrupts it. `csv-parse` runs with `relax_quotes: true, relax_column_count: true, trim: true`.
- Validates each row: `IN_SCOPE.has(external_id)`, `FEDERAL.has(topic_key)`, `value` 1–5, non-empty reasoning, ≥1 `http(s)` source. Emits a `problems[]` list and `per_rep` counts (rows per external_id).
- Writes the merged dated CSV with re-escaped fields.

**Standing rule (this milestone):** auto-push batches that merge with **0 problems AND 0 unsourced**; still show the summary. Otherwise fix the offending per-exec CSV (regenerate that exec — never global quote-replace) and re-merge.

**Known CSV artifacts to fix per-file before merge (v2.17):**
- Stray lone trailing `"` on the empty final field of every row → `sed -i 's/,"$/,/'` on that file (a line ending `,"` is always the artifact; a valid empty final field ends `,`).
- Quad-quote `""""` → handled by `_merge.ts repair()` automatically.

### Step 3 — Push (external_id→UUID, transactional)

```bash
cd C:/EV-Accounts/backend && set -a && source .env && set +a \
  && node --import tsx data/stance-research/gov-ag-batch-a/_push.ts \
     data/stance-research/2026-06-21-gov-ag-batch-a.csv
```

> **`_push.ts` does NOT load dotenv** — the `set -a && source .env && set +a` prefix is mandatory (verify scripts use `import 'dotenv/config'`, push scripts do not). [VERIFIED: `_push.ts` imports only pool, no dotenv]

`_push.ts` (see `atlarge-house/_push.ts`):
1. Resolves `external_id → politician_id` via `SELECT ... WHERE external_id = ANY($1::int[])`.
2. Resolves `topic_key → topic_id` via `SELECT ... WHERE is_live=true` (lowercased map).
3. Aborts with `UNRESOLVED:` if any external_id or topic_key fails to resolve (catches a missing record or a typo'd key before any write).
4. In a single `BEGIN/COMMIT` txn, per row: upsert `inform.politician_answers` (`ON CONFLICT (politician_id, topic_id) DO UPDATE SET value`), upsert `inform.politician_context` (`reasoning`, `sources[]`), then optionally insert into `essentials.quotes` + set the Read & Rank pick (with a surname-leak guard).
5. Prints `{answers, contexts, quotesIns, quotesDup, selected, leaks}`.

**Mid-session note:** MCP Supabase tokens expire (~1hr). For all verification queries prefer `psql` (with the `source .env` prefix) or `node --import tsx` + `pool` — not the MCP tool.

**Confidence: HIGH** — pipeline files read directly; commands match v2.17 phase memory.

## SEXS-01: Prompt-Update Target + Proposed Guidance

**Target file (PRIMARY): `C:/EV-Accounts/.claude/agents/politician-stance-researcher.md`** — the agent definition. This is where the durable evidence methodology lives (the `Evidence Hierarchy` section, lines ~348–358, and `Stance Assessment` rules, lines ~403–409). Adding office-type guidance here makes it apply to **every** future dispatch automatically. [VERIFIED: agent def read 2026-06-21]

**Secondary (optional reinforcement): the per-dispatch prompt template** the orchestrator pastes for each exec. The ROADMAP success criterion only requires the guidance be present "before the first research agent is dispatched"; editing the agent def satisfies that durably, and the dispatch prompt can additionally name the specific office type for the exec being researched.

> **Note on SKILL.md:** `.claude/skills/research-stances/SKILL.md` is the human-driven orchestrator skill. It is **stale** (says "ALWAYS dispatch ONE agent at a time" and "44 topics") vs. current practice (3-concurrency, 25 federal topics for execs). The Phase 142 work does not run through SKILL.md — it uses the per-batch dir + direct Agent dispatch. **Do NOT put SEXS-01 guidance only in SKILL.md.** Put it in the agent def (and dispatch template). Optionally, the planner may also correct SKILL.md's concurrency line, but that is not required by SEXS-01.

### Proposed guidance text (insert into the agent def, new subsection under "Evidence Hierarchy")

> **`### Office-Type Evidence Guidance (statewide executives)`**
>
> Statewide executives do not cast legislative roll-call votes. Map their *executive actions* to compass topics — and do not over-read a role description as a stance.
>
> - **Governor** — Score from **bills signed or vetoed**, **executive orders**, **budget proposals/line-item vetoes**, and **emergency declarations**. A signed abortion-restriction bill, a vetoed gun bill, an EO on immigration enforcement, or a budget that zeroes a program are documentable stances. State .gov press/bill-action pages and Ballotpedia (gubernatorial actions) are primary sources. Do NOT score a topic from a campaign slogan when a signing/veto record exists — actions over words.
> - **Attorney General** — Score from **lawsuits the office filed or joined**, **amicus briefs**, and **multistate coalition letters/actions**. An AG who sued to block (or defend) a federal abortion rule, joined an amicus on Second Amendment, or led a multistate suit on environmental regulation has a documentable stance on that topic. **Multistate-coalition membership counts ONLY when the coalition has a published position directly ON that topic** — do not infer a stance on topic X from membership in a coalition that acted on topic Y. NAAG, the state AG office press-release page, and amicus/lawsuit trackers are primary sources.
> - **Treasurer** *(Wave 2 — Phase 143)* — Score from **investment or divestment decisions** and **documented fund actions** (e.g., divesting a state pension from fossil fuels or from firms over a policy; ESG-investment policy). Do NOT score from a budget-overview page or generic "manages state funds" description.
> - **Secretary of State** *(Wave 2)* — Score from **specific election-administration actions** (voter-roll purges, mail-ballot rule changes, voter-ID implementation, certification disputes). Do NOT score voting-rights from "the SoS administers elections" role text.
> - **Lieutenant Governor** *(Wave 2)* — LtGovs often have **no independent policy record**. Produce an **honest-partial** (only the topics with independent sourcing — e.g., bills authored when previously a legislator, or their own public statements). **Never mirror the same-state Governor's stances** without independent sourcing for the LtGov personally.
>
> The distinction matters: a **bill signing** (Governor) is a different evidentiary act than an **amicus brief** (AG) or an **investment decision** (Treasurer). Cite the act that actually happened; do not generalize one office's tools onto another.

**Confidence: HIGH** for target file; **MEDIUM** for exact insertion phrasing (the planner/user may refine wording — the *content* is locked by ROADMAP SC#1 and REQUIREMENTS SEXS-01).

## Schema Reference

[VERIFIED: `information_schema` query against prod 2026-06-21]

### `inform.politician_answers` (PK: `politician_id, topic_id`)
| Column | Type | Notes |
|--------|------|-------|
| politician_id | uuid | NOT NULL |
| topic_id | uuid | NOT NULL |
| value | numeric | NOT NULL (1–5) |
| write_in_text | text | nullable; unused by push |

> **No `created_at` column.** You CANNOT date-filter writes. Verify scope via **per-scope external_id counts**, never via a global row counter (concurrent prod cron/FEC jobs drift the global count). [VERIFIED]

### `inform.politician_context` (PK: `politician_id, topic_id`)
| Column | Type | Notes |
|--------|------|-------|
| politician_id | uuid | NOT NULL |
| topic_id | uuid | NOT NULL |
| reasoning | text | NOT NULL |
| sources | ARRAY (text[]) | NOT NULL — the source URLs; `sources[1] LIKE 'http%'` is the zero-unsourced check |

**Zero-unsourced invariant:** every `politician_answers` row MUST have a paired `politician_context` row whose `sources[1]` starts with `http`. `_push.ts` writes both in the same loop iteration, and `_merge.ts` rejects any row lacking an http source, so a clean merge guarantees the invariant. The Phase-144 gate re-asserts it.

### `essentials.quotes` (Read & Rank — optional per row)
Written by `_push.ts` only when `quote_text` is non-blank. Columns used: `politician_id, topic_key, quote_text, deidentified_text, source_url, source_name, readrank_selected`. Surname-leak guard prevents selecting a de-id quote that still contains the exec's surname. Not required for SEXS-02 completion (stances + context are), but carry quotes through when the agent finds a good one.

### Topic reference
Topics are keyed by `topic_key` (lowercased) → `inform.compass_topics.id`. `_push.ts` resolves this live.

## The 25 Federal Compass Topics + Scale Source

[VERIFIED: live DB query 2026-06-21 — 44 live topics total; 25 federal after excluding 11 city + 8 judicial]

State execs are scored on the **25 federal (non-city, non-judicial) topics**, identical to the v2.17 House set:

```
abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change,
data-centers, deportation, fossil-fuels, healthcare, homelessness, housing, immigration,
medicare/aid, misinformation, redistricting, religious-freedom, same-sex-marriage,
school-vouchers, social-security, tariffs, taxes, trans-athletes, ukraine-support, voting-rights
```

- This **exactly matches** the `FEDERAL` set hardcoded in `_merge.ts` and the `_TOPIC_SCALE.txt` "25 federal compass topics" file. No edit needed — copy the file as-is.
- Note `homelessness` (statewide topic, key `homelessness`) IS federal-scope; `homelessness-response` (city) is excluded. `medicare/aid` contains a slash — keep it verbatim.
- **Scale-direction discipline** ([[feedback_stance_scale_embed_texts]]): embed the actual 1–5 stance texts in every dispatch (the `_TOPIC_SCALE.txt` does this). NEVER write "5=progressive" — direction varies per topic (e.g., abortion 1 = fully funded access; fossil-fuels 1 = ban all drilling; civil-rights 1 = mandate equity). The agent def also carries an inversion-trap table (lines ~410–445) as a backstop.

## Calibration & Pitfalls (from prior waves — CRITICAL)

### Never infer from party ([[feedback_stance_no_assumption]])
Every scored stance needs ≥1 real fetched source URL. **Strict mode:** skip a topic entirely if no direct evidence — do not assign even a "middle" value. This overrides any default researcher behavior. For execs this is especially live: it is tempting to assume a Republican governor is anti-abortion or a Democratic AG is pro-climate — **score only from the signed bill / filed lawsuit / amicus, never from the (R)/(D)**.

### Proxy-row review gate (standard since Phase 139 — expect ~several drops/wave)
After merge, review every row whose only evidence is a **proxy**:
- **Drop** rows sourced only by **caucus/coalition membership** without a published position ON that topic. For AGs specifically: multistate-coalition membership counts ONLY when the coalition has a published position directly on that topic (ROADMAP SC#4). A "Democratic AGs Association" membership is not a stance on data-centers.
- **Drop** rows where the only "evidence" is committee role, party platform, or "overall record alignment."
- **Keep** when the proxy has a published on-topic platform (e.g., a coalition amicus that explicitly took position X on topic X), a concrete org role with documented on-topic action, or a campaign-platform priority the exec personally ran on (above the caucus bar).

### isidewith.com is BELOW the evidence bar
Its "positions" are aggregator characterizations, not documented votes/statements. **Drop** rows sourced ONLY by isidewith (no ballotpedia/wikipedia/ontheissues/lcv/votesmart/.gov/state-AG-press). Thin execs become honest-partials.

### same-sex-marriage=5 requires a documented anti-recognition vote/action
`same-sex-marriage=5` ("make it illegal") needs a documented anti-recognition vote OR explicit support for a one-man-one-woman constitutional amendment. For a governor that could be **signing** such a measure or a state constitutional-amendment endorsement. **Drop** when the only evidence is Equality-Act opposition / "opposes special LGBTQ protections" / a religious-exemption service-refusal bill (those support `religious-freedom=4/5`, not SSM=5).

### Honest-skip / honest-partial
- **Honest-skip** a topic with no documentable evidence (most execs will have <25 topics; that is correct, not a failure).
- **Honest-partial** for thin records (e.g., a newly-elected governor with few signings yet). Score the topics with evidence; skip the rest. Honest-skip beats inference.

### No-scope-creep verification (per-scope external_id counts)
Because `politician_answers` has **no created_at** and concurrent prod jobs drift the global row count, **verify isolation via per-scope external_id counts**, not the global counter. The push is external_id-keyed, so writes are provably isolated to the batch's IN_SCOPE ids. Confirm each scope's covered count rose by exactly the expected number of execs.

**Confidence: HIGH** — all rules drawn directly from project memory + the v2.17 phase log.

## Batching Recommendation

Mirror the v2.17 "balanced plans, largest-first" approach. 80 execs across plans of ~5 execs each (so each plan ≈ 2 batches of ≤3 dispatched serially) → roughly **8 plans**, or fewer larger plans if the planner prefers. Suggested grouping (Govs + AGs of the same large states together so calibration carries within a state):

- Group by population tier, largest first: CA-tier is already done; start with **FL, NY, IL, PA, OH, GA, NC, MI** (Gov+AG pairs), then mid states, then small/single states.
- Each plan owns one batch dir, runs ≤3 concurrent, merges (0-problem auto-push), and asserts its per-scope external_id coverage.
- The 4 existing-but-unstanced execs (ME Gov, TX Gov, TX AG, IN AG) can fold into whichever batch their state lands in — they push identically (external_id-keyed; IN AG's positive id `499453` and TX's `-100202/-100204` resolve fine).

**Plan count: TBD by planner** — research recommends ~8 balanced plans; the exact split is a planner decision.

## Validation / Gate Approach

SEXS-03's consolidated gate lands in **Phase 144** (`backend/scripts/verify-phase-141-144.sql`), mirroring `verify-phase-132-140.sql` (read-only, `psql -v ON_ERROR_STOP=1`, labeled `RAISE EXCEPTION`/`RAISE NOTICE` assertions). Phase 142 plans should each include a lightweight per-batch coverage assertion and contribute the Wave-1 assertions the 144 gate will consolidate.

> **Gate-keying difference from v2.17 (IMPORTANT):** the House gate keys on the contiguous range `floor((-external_id)/1000)`. **STATE_EXEC external_ids are NON-contiguous and irregular** (IN positive, TX -100204, AZ -400091, ME -230001). The Phase-142/144 assertions MUST key on:
> ```sql
> ... FROM essentials.politicians p
> JOIN essentials.offices o ON o.politician_id=p.id
> JOIN essentials.districts d ON d.id=o.district_id
> WHERE d.district_type='STATE_EXEC' AND o.role_canonical IN ('governor','attorney_general')
> ```
> NOT on external_id ranges.

Two assertion families per the v2.17 pattern:
1. **Coverage:** every in-scope Gov/AG has ≥1 `politician_answers` row. Assert exact covered counts per scope (e.g., 43 Gov + 37 AG = 80 covered), with any documented honest-skip pinned to its exact external_id (belt-and-suspenders, as USHS-14a pins -37006).
2. **Zero-unsourced:** 0 answer rows for STATE_EXEC Gov/AG lack a paired `politician_context` row with `sources[1] LIKE 'http%'`.

Run a **live diagnostic to fix every assertion constant BEFORE authoring** the gate (v2.17 gate-design lesson) — the covered count must reflect any honest-skips decided during research.

## Runtime State Inventory

> Not a rename/refactor phase, but the data-write nature warrants a stored-data note.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data (written) | `inform.politician_answers` (+ `politician_context`, + optional `essentials.quotes`) keyed by politician UUID/topic UUID | Data write via `_push.ts`; idempotent upsert ON CONFLICT — re-running is safe |
| Live service config | None — `STATE_EXEC` feed surfacing already wired in `essentialsService.ts` (no change) | None |
| OS-registered state | None | None — verified, no scheduler/cron registration touched |
| Secrets/env vars | `DATABASE_URL` in `backend/.env` (read-only consumption via `set -a && source .env`) | None |
| Build artifacts | None — no migrations, no compiled output | None (per-batch dirs under `backend/data/stance-research/` are CSV data, committed as record) |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node + tsx | `_merge.ts` / `_push.ts` | ✓ (used through v2.17) | project node | — |
| `pg` pool (`backend/src/lib/db.js`) | push + verification | ✓ | — | — |
| `csv-parse/sync` | merge/push parse | ✓ (existing dep) | — | — |
| `psql` | Phase-144 gate | ✓ (used in v2.17 gate) | — | `node --import tsx` + pool |
| `politician-stance-researcher` agent | research | ✓ (`.claude/agents/`) | — | — |
| WebFetch quota | agent research | ✓ at 3-concurrency | — | drop to 1–2 if 429s |
| Prod DB `kxsdzaojfaibhuzmclfq` | reads + writes | ✓ | — | — |

No blocking gaps.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SKILL.md "ONE agent at a time" | 3-concurrency direct Agent dispatch per batch dir | 2026-06-16 (premium tier) | SKILL.md text stale; follow project memory + per-batch dir flow |
| SKILL.md "44 topics" / name-resolved push | 25 federal topics for execs; **external_id-keyed** push (`_push.ts`) | v2.16/v2.17 | Use `_push.ts` external_id resolve, not SKILL.md's name-resolve RPC path |
| Scale labels "5=progressive" | Embed actual 1–5 stance texts every dispatch | 2026-06-02 | Prevents systematic inversions |

**Deprecated/outdated:** `.claude/skills/research-stances/SKILL.md` STEP 1 dispatch rule and topic count are stale — do not treat as authoritative for this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact wording of the SEXS-01 insert text | SEXS-01 | Low — content is locked by ROADMAP SC#1; phrasing is editable by planner/user |
| A2 | ~8 balanced plans is the right split | Batching | Low — planner decides exact split; any balanced split at ≤3-concurrency works |

*(In-scope set, schema, topic set, pipeline files, and calibration rules are all VERIFIED — not assumed.)*

## Open Questions

1. **Should SEXS-01 also fix the stale SKILL.md concurrency/topic text?**
   - What we know: SEXS-01 only requires the *researcher prompt* carry office-type guidance; the agent def is the durable home.
   - What's unclear: whether the user wants SKILL.md corrected in the same pass.
   - Recommendation: put SEXS-01 guidance in the agent def (required); optionally add a one-line SKILL.md correction as a low-priority cleanup task, not a gate.

2. **Do quotes (Read & Rank) need to be populated for execs this wave?**
   - What we know: SEXS-02 requires stances + sourced context; quotes are additive (Read & Rank becomes playable only with ≥2 selected de-id quotes per race).
   - Recommendation: carry quotes through `_push.ts` when the agent finds a clean one, but do not gate the phase on quote coverage.

## Sources

### Primary (HIGH confidence)
- Prod DB `kxsdzaojfaibhuzmclfq` — in-scope query (80 execs), schema (`information_schema`), live topic set (25 federal) — all run 2026-06-21
- `C:/EV-Accounts/.claude/agents/politician-stance-researcher.md` — agent def (CSV columns, evidence hierarchy, inversion-trap table)
- `C:/EV-Accounts/backend/data/stance-research/atlarge-house/{_merge.ts,_push.ts,_TOPIC_SCALE.txt}` — exact pipeline scripts
- `C:/EV-Accounts/backend/scripts/verify-phase-132-140.sql` — gate assertion pattern
- `C:/EV-Accounts/.planning/ROADMAP.md` (Phase 142–144), `.planning/REQUIREMENTS.md` (SEXS-01..03), `141-RESEARCH.md` (§Current Stance Coverage, external_id scheme)

### Secondary (HIGH confidence — project memory)
- `feedback_stance_no_assumption`, `feedback_stance_research_one_at_a_time`, `feedback_stance_scale_embed_texts`, `project_phase141_wave2_resume` (Chris's auto-memory)

### Tertiary
- `.claude/skills/research-stances/SKILL.md` — orchestrator skill (noted STALE for concurrency/topic-count; pipeline-of-record is the per-batch dir flow)

## Metadata

**Confidence breakdown:**
- In-scope set (80 execs, ids): HIGH — direct prod query, counts cross-checked
- Pipeline (merge/push/dispatch): HIGH — files read directly, commands match v2.17
- Schema: HIGH — information_schema verified
- SEXS-01 target file: HIGH; insert wording: MEDIUM (editable)
- Calibration/pitfalls: HIGH — from memory + v2.17 log
- Gate approach: HIGH — pattern read; keying difference flagged

**Research date:** 2026-06-21
**Valid until:** 2026-07-21 (stable internal pipeline; re-run the in-scope query before authoring in case of roster drift)
