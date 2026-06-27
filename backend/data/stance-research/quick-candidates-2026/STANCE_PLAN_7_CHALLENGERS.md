# PLAN (COMPLETE ✅): Stance research for 7 challenger candidates — 2026 statewide races

Status: **COMPLETE 2026-06-27.** Executed via 3-concurrent research waves + primary-source
verification pass (UUID-keyed push). Data is live in DB; no deploy needed.

## OUTCOME (71 evidence-only stances across 5 candidates; 2 whole-record honest-skips)
| candidate | race | stances | quotes | notes |
|---|---|---|---|---|
| Hannah Pingree | ME Gov (D) | 20 | 9 | open seat; campaign site + LD 1020 marriage equality |
| Andy Ellis | MD Gov (Green) | 20 | 7 | sourced from gp.org / mdgreens.org platform he runs on |
| Bobby Charles | ME Gov (R) | 13 | 8 | Maine Wire op-eds/speeches + BDN debate coverage |
| Dan Cox | MD Gov (R) | 10 | 6 | OnTheIssues + MD legislative bill sponsorships |
| Rick Bennett | ME Gov (I) | 8 | 1 | sitting state senator; roll-call votes verified |
| James B. Rutledge III | MD AG (R) | **0** | 0 | whole-record honest-skip — no fetchable sources (ran unopposed, primary 6/23) |
| Sonya Dunn | MD Comptroller (R) | **0** | 0 | whole-record honest-skip — no fetchable sources (no campaign site, primary 6/23) |

**Verification pass deleted 16 rows** (12 post-push + 3 pre-push + 1 redistricting) that were
inference dressed up with URLs — confirming [[feedback_stance_no_assumption]]:
- pre-push drops: cox/misinformation (election-fraud≠content-moderation), ellis/trans-athletes
  (self-admitted "platform doesn't address"), bennett/housing (invalid topic_key + speculative)
- post-push drops: cox {fossil-fuels, trans-athletes, jail-capacity}, charles {data-centers,
  economic-development, civil-rights}, bennett {abortion — oppo-research framing, not a Bennett
  position}, pingree {redistricting}, ellis {homelessness, jail-capacity, misinformation, rent-regulation}
- corrections: fabricated figures stripped (pingree $25M/4,850 childcare), truncated quotes fixed
  (cox voting-rights), value remaps (cox abortion 5→4 per his bills' rape/incest exceptions;
  ellis deportation 1→2 per platform's "clear and present danger" carve-out)

Incumbent baselines for parity: Wes Moore 21, Brooke Lierman 16 (MD AG Brown not in this DB count).
ME Gov is an open seat (no incumbent baseline).

## Goal
Give the 7 challenger records (created for headshots, currently 0 stances) full
evidence-only compass coverage so their races become real head-to-heads. Same
pipeline as the Hilton/Becerra/Bass/Raman work in quick task 023.

## The 7 candidates (all STATEWIDE EXEC → state-tier = 26 topics)
| full_name | politician_id (UUID) | race | office tier |
|---|---|---|---|
| Dan Cox | 4a876d03-4e8f-4d0a-a236-4f594b59f29c | MD Governor | state-tier |
| Andy Ellis (Green) | 48593795-6e01-4da0-99b3-ef522b906652 | MD Governor | state-tier |
| James B. Rutledge III | 579020c7-482d-440e-b2f7-f7191da9b0e5 | MD Attorney General | state-tier |
| Sonya Dunn | 47977cc4-c208-41ff-8944-7afc7c9bf055 | MD Comptroller | state-tier |
| Hannah Pingree (D) | ac09c6dc-d7db-4bdb-9829-0e746c8ca665 | ME Governor | state-tier |
| Bobby Charles (R) | 8aad9681-4dc3-4803-9ff1-7c004303b4ab | ME Governor | state-tier |
| Rick Bennett (Ind.) | f64c1364-65a7-4958-a9f2-999383f0729d | ME Governor | state-tier |

Head-to-head context: MD Gov incumbent Moore(21)/AG Brown(17)/Comptroller Lierman(16)
already have stances — cover the SAME 26 state-tier topics for parity. ME Governor is an
OPEN seat — all three (Pingree/Charles/Bennett) need the full set; no incumbent baseline.

## ⚠️ KEY WRINKLE: push by UUID, not external_id
These 7 have **NULL external_id**. The standard `_push.ts` resolves external_id→UUID and
will NOT find them. Two options (pick one in step 4):
- (A) Adapt the push to key on a `politician_id` (UUID) CSV column instead of external_id —
  recommended (no external_id pollution). Copy `_push.ts`, swap the PID resolution block to
  read `r.politician_id` directly.
- (B) Assign each a negative external_id first, then use stock `_push.ts`. More steps; only
  if a UUID push is inconvenient.

## Topic set (26 state-tier)
`SELECT t.topic_key FROM inform.compass_topics t JOIN inform.compass_topic_roles r
 ON r.topic_id=t.id AND r.role_scope='state' WHERE t.is_live;`
Scale texts already on disk: `_TOPIC_SCALE_ALL.txt` (44 topics; filter to the 26 state ones)
or regenerate a state-tier scale file the way `_TOPIC_SCALE_LOCAL.txt` was built.

## Steps
1. Fetch the 26 state-tier topic_keys + their 1–5 stance texts; build a `_TOPIC_SCALE_STATE.txt`
   (embed exact texts — direction varies per topic; never write "5=conservative").
2. Dispatch `politician-stance-researcher` agents, **≤3 concurrent** (memory: rate limits),
   one per candidate, each handed its 26 topics + the embedded scale. EVIDENCE-ONLY: every row
   needs a real fetched URL; honest-skip any topic with no source (see
   [[feedback_stance_no_assumption]], [[feedback_stance_scale_embed_texts]]). Office-type
   guidance: AG (Rutledge)=lawsuits/amicus; Comptroller (Dunn)=fiscal/audit/investment;
   Governors=full state policy platform. Sources: campaign sites, Ballotpedia, state press,
   voting records (Bennett & Pingree are former/*current* ME legislators → real records exist).
3. Each agent writes a CSV per candidate (columns incl. a `politician_id` UUID column):
   `full_name,politician_id,topic_key,value,reasoning,source_url_1..3,quote_text,quote_deidentified`
4. Push via the UUID-keyed `_push.ts` variant (option A above) → writes politician_answers +
   politician_context + quotes.
5. **Primary-source verification pass** (like the Gov/Mayor work): re-check quotes are verbatim,
   figures/dates/votes real, value mapping sound; fix + re-push. (Ballotpedia/OnTheIssues can
   carry stale or misattributed entries — verify.)
6. Verify coverage: each candidate's state-tier count vs the incumbent's; honest-skips OK.
   Record an audit/migration note. Commit + push (data is live via DB; no deploy needed).

## Notes
- Pipeline dir: `backend/data/stance-research/quick-candidates-2026/` (has `_push.ts`,
  `_TOPIC_SCALE_ALL.txt`, prior CSVs as templates).
- Already-covered, no action: OR Gov (Kotek 31 / Drazan 10), OR Senate (Merkley 23 / Brock
  Smith 27) — both full head-to-heads. VA Senate = Warner only (R nominee pending Aug 4).
- All DB writes go live immediately (psql); the `electionService` deploy is already done.
