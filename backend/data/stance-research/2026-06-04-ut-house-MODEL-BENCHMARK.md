# A/B Model Benchmark — Sonnet vs Haiku stance research

**Task:** identical `politician-stance-researcher` run on Utah's 4 U.S. House reps, once with `model: sonnet`, once with `model: haiku`. Byte-identical task prompts; only the model (and the output subdir) differ. **Benchmark only — nothing pushed to the database** (verifier run dry, never `--apply`).

- **Date:** 2026-06-04
- **Reps (all R):** Blake Moore (UT-1, `e365a1d4…`), Celeste Maloy (UT-2, `a7983eb6…`), Mike Kennedy (UT-3, `9e3164d5…`), Burgess Owens (UT-4, `cb87ddbb…`)
- **Scope:** all 24 NATIONAL topics each (federal officials; no judicial topics). STEP 0.5 removed nothing — the only UT skip rule (`rent-regulation`, Utah Code §57-20-1) is a LOCAL topic.
- **Batches:** `data/stance-research/2026-06-04-ut-house-sonnet/` and `…-haiku/` (per-rep subdirs merged to batch-root `stances.csv`/`evidence.csv`).
- **Verifier:** `scripts/verify-stance-research.ts --threshold 1` (dry-run). Objective grounding = snippet found verbatim on the fetched page with the rep's name within ~500 chars, via the same HTTP→Chromium→Wayback ladder for both models.

---

## 1. Cost & speed

Per-agent figures are from the Agent tool's `subagent_tokens` / `duration_ms`. The 4 agents in each wave ran **concurrently**, so wall-clock ≈ the slowest agent (`max`), while the summed duration is total compute.

### Sonnet wave
| Rep | tokens | tool_uses | duration_ms | min |
|-----|-------:|----------:|------------:|----:|
| Moore | 141,370 | 100 | 745,280 | 12.4 |
| Maloy | 141,362 | 106 | 721,988 | 12.0 |
| Kennedy | 102,882 | 84 | 596,521 | 9.9 |
| Owens | 131,410 | 120 | 788,699 | 13.1 |
| **Total** | **517,024** | **410** | **2,852,488** (sum) | **wall ≈ 13.1** |

### Haiku wave
| Rep | tokens | tool_uses | duration_ms | min |
|-----|-------:|----------:|------------:|----:|
| Moore ⚠️ *(gave up — 0 rows)* | 91,185 | 30 | 249,442 | 4.2 |
| Maloy | 92,737 | 49 | 206,367 | 3.4 |
| Kennedy | 104,756 | 60 | 275,339 | 4.6 |
| Owens | 83,143 | 42 | 179,618 | 3.0 |
| **Total** | **371,821** | **181** | **910,766** (sum) | **wall ≈ 4.6** |

### Ratios (Haiku ÷ Sonnet)
| Metric | Sonnet | Haiku | Haiku/Sonnet |
|--------|-------:|------:|-------------:|
| Total tokens | 517,024 | 371,821 | **71.9%** |
| Tokens, 3 reps excl. Moore | 375,654 | 280,636 | **74.7%** |
| Wall-clock (max agent) | ~13.1 min | ~4.6 min | **34.9%** |
| Summed duration | 2,852,488 ms | 910,766 ms | 31.9% |
| **Tokens per *scored* row** | 517,024 / 87 = **5,943** | 371,821 / 59 = **6,301** | **106%** |
| Tokens per scored row, excl. Moore | 375,654 / 66 = 5,692 | 280,636 / 59 = 4,757 | **83.6%** |

> **The headline cost number cuts against Haiku.** Haiku used 72% of the tokens overall and ran ~3× faster — but because the Haiku-Moore agent burned 91k tokens and produced **zero** usable rows, Haiku's cost *per useful stance* (6,301 tok) was actually **higher** than Sonnet's (5,943). Only when you exclude the failed rep does Haiku's per-row cost advantage (≈16% cheaper) appear. Speed is unambiguous: Haiku is ~3× faster wall-clock.

---

## 2. Coverage (rows scored vs not, of 4 reps × 24 topics = 96)

| | Sonnet | Haiku |
|--|------:|------:|
| Scored (non-blank value) | **87 / 96 (90.6%)** | **59 / 96 (61.5%)** |
| Not scored (blank/omitted) | 9 | 37 |
| Reps fully attempted | 4 / 4 | 3 / 4 (Moore failed entirely) |
| Scored excl. Moore (×3 reps, /72) | 66 / 72 (91.7%) | 59 / 72 (81.9%) |

**Sonnet didn't score (9):** Moore — campaign-finance, misinformation, homelessness · Maloy — campaign-finance, homelessness, childcare · Kennedy — homelessness, data-centers · Owens — homelessness.

**Haiku didn't score (37):** **Moore — all 24** (agent hit Cloudflare on house.gov/congress.gov/news and quit, writing headers only) · Maloy — campaign-finance, misinformation, school-vouchers, ai-regulation · Kennedy — same-sex-marriage, ukraine-support, voting-rights, social-security, civil-rights, redistricting · Owens — campaign-finance, misinformation, homelessness.

Both models legitimately struggle with `campaign-finance`, `misinformation`, and `homelessness` for these reps (little direct evidence). The decisive coverage gap is the **Haiku-Moore total failure**: facing the same Cloudflare-blocked sources that Sonnet pushed through (Sonnet scored Moore 21/24), Haiku declared the task impossible and stopped after 30 tool calls.

---

## 3. Grounding quality (objective — from the deterministic verifier)

Denominator = scored rows. Source = verifier PUSH (`verified_sources=N`) vs RE-RESEARCH (0).

| Metric | Sonnet | Haiku |
|--------|-------:|------:|
| Scored rows verified | 87 | 59 |
| Rows with ≥1 verified source | **19 (21.8%)** | **10 (16.9%)** |
| Rows with ≥2 verified sources | 1 (1.1%) | 2 (3.4%) |
| Avg verified sources / row | **0.230** | 0.203 |
| Total verified sources | 20 | 12 |

**Read this carefully — two things are true at once:**

1. **Sonnet grounds modestly better on the primary measure** (21.8% vs 16.9% of rows with ≥1 verifiable source; 0.23 vs 0.20 avg). Haiku's edge on "≥2 sources" is 2 rows vs 1 — noise at this sample size.
2. **Both models are *low* in absolute terms**, and that is mostly an artifact of **source accessibility, not fabrication.** The bulk of failed URLs are real pages the headless fetcher can't read: Cloudflare-gated `*.house.gov` / `congress.gov`, and paywalled `deseret.com` / `sltrib.com` / `ksl.com`. The verifier scores those as unverified regardless of whether the quote is real. The bar is identical for both models, so the *comparison* is fair — but "78% unverified" must **not** be read as "78% made up."

---

## 4. Value agreement (Sonnet = reference)

Join on (rep, topic) where **both** models produced a non-null value.

| Metric | Value |
|--------|------:|
| Comparable pairs (overlap) | **54** |
| Exact match | **33 (61.1%)** |
| Within ±1 | **52 (96.3%)** |
| Mean absolute difference | **0.43** |
| Disagreements | 21 (+1 hidden by a bad key — see below) |

**Directionality:** in **18 of 21** disagreements Haiku scored *lower / less-conservative* than Sonnet (Sonnet 5 → Haiku 4, or Sonnet 4 → Haiku 3). For a uniformly-Republican cohort, Sonnet more often commits to the strongest stance the record supports while Haiku rounds one notch toward the middle. Only 2 disagreements are Δ=2; both are Haiku errors (see §5).

> ⚠️ **Topic-key compliance failure (Haiku):** for Kennedy's Medicare/Medicaid topic, Haiku emitted the **invalid slug `medicare-medicaid`** instead of the required canonical `medicare/aid`, despite the prompt's "topic_key MUST exactly match one of the keys listed." That row therefore *can't join* and shows up as a coverage gap on each side rather than a disagreement. Normalized, it is a **Δ=2 disagreement** (Sonnet `medicare/aid`=5, verified×2, vs Haiku `medicare-medicaid`=3, verified×0) and Sonnet is clearly right (see §5). Sonnet used the exact key on all 87 rows.

### Every disagreement (sorted by |Δ|)
| Rep | Topic | Sonnet | Haiku | Δ (H−S) |
|-----|-------|:-----:|:----:|:------:|
| Burgess Owens | ukraine-support | 4 | 2 | **−2** |
| Mike Kennedy | school-vouchers | 5 | 3 | **−2** |
| *Mike Kennedy* | *medicare/aid (key-mismatch)* | *5* | *3* | *(−2)* |
| Burgess Owens | same-sex-marriage | 4 | 3 | −1 |
| Burgess Owens | social-security | 3 | 4 | +1 |
| Burgess Owens | climate-change | 5 | 4 | −1 |
| Burgess Owens | civil-rights | 5 | 4 | −1 |
| Burgess Owens | school-vouchers | 5 | 4 | −1 |
| Burgess Owens | ai-regulation | 1 | 2 | +1 |
| Burgess Owens | healthcare | 4 | 3 | −1 |
| Celeste Maloy | medicare/aid | 4 | 3 | −1 |
| Celeste Maloy | climate-change | 4 | 5 | +1 |
| Celeste Maloy | redistricting | 5 | 4 | −1 |
| Celeste Maloy | data-centers | 4 | 3 | −1 |
| Celeste Maloy | healthcare | 4 | 3 | −1 |
| Mike Kennedy | tariffs | 4 | 3 | −1 |
| Mike Kennedy | religious-freedom | 5 | 4 | −1 |
| Mike Kennedy | fossil-fuels | 5 | 4 | −1 |
| Mike Kennedy | climate-change | 5 | 4 | −1 |
| Mike Kennedy | immigration | 5 | 4 | −1 |
| Mike Kennedy | deportation | 5 | 4 | −1 |
| Mike Kennedy | healthcare | 4 | 3 | −1 |

(Moore contributes 0 comparable pairs — Haiku produced none. The 54-pair overlap is Maloy+Kennedy+Owens only.)

---

## 5. Reasoning spot-check (which model is better grounded)

Five disagreements, reading both models' reasoning + cited evidence:

1. **Owens / ukraine-support — Sonnet 4 vs Haiku 2 (Δ−2). Sonnet right.** Both know the same facts (2022 yes on early aid, 2024 NO on the $60B package). Sonnet weights the most-recent NO vote → stance 4 (reduce aid). Haiku lands on 2 ("continue current levels") while its *own* reasoning says he "shifted from initial support to limiting aid" — internally inconsistent, and it leans on a 2022 house.gov "backs additional Ukraine aid" post as if current. For a member who voted against the major 2024 package, 4 is correct and 2 is wrong.

2. **Kennedy / school-vouchers — Sonnet 5 vs Haiku 3 (Δ−2). Sonnet clearly right.** Sonnet cites the July-2025 op-ed where Kennedy is "proud to support the first permanent pathway to **universal school choice**" plus an iVoterGuide pledge to abolish the Dept. of Education → stance 5 (universal vouchers). Haiku grounded the K-12 voucher question in Kennedy's **technical-college bill** (higher-ed, off-topic) and scored 3. Wrong source, wrong score.

3. **Kennedy / Medicaid — Sonnet `medicare/aid`=5 (verified×2) vs Haiku `medicare-medicaid`=3 (verified×0). Sonnet right, and it's Sonnet's single best-grounded row.** Sonnet cites the BBB-Medicaid-cuts op-ed (~$900B CBO), block-grant advocacy, and the iVoterGuide market-forces answer. Haiku reused the **same off-topic tech-college article** as for vouchers, used an **invalid topic_key**, and scored 3. Triple failure.

4. **Owens / same-sex-marriage — Sonnet 4 vs Haiku 3 (Δ−1). Legitimate gray area, slight edge Sonnet.** Both cite Owens' lone "present" vote and religious-liberty rationale. Sonnet → 4 (civil unions / reserve marriage); Haiku → 3 (let states decide) and adds a Fairness-for-All cosponsorship. A "present" vote genuinely sits between 3 and 4; reasonable analysts differ. Sonnet's is better-sourced (the "warning beacon" quote), but this one is roughly a tie.

5. **Kennedy / immigration — Sonnet 5 vs Haiku 4 (Δ−1). Edge Sonnet.** Sonnet cites concrete bills (Deporting Fraudsters Act, Laken Riley, PROTECT Act raising H-1B fees to $100K — which targets *legal* immigration) → 5. Haiku cites campaign-site generalities → 4. The score-5 call is aggressive but evidence-backed; Haiku's is defensible but thinner.

**Verdict: 4 of 5 favor Sonnet (one is a tie).** Twice Haiku anchored on the *same off-topic source* (a tech-college article) for two unrelated topics, once contradicted itself, and once emitted an invalid slug. Sonnet's stronger scores are backed by named votes/bills/op-eds; where it reaches for a 5 it is aggressive but cites real, on-topic evidence. None of the spot-checked Haiku reasonings were better-grounded than Sonnet's.

---

## 6. Recommendation

**For this pipeline, Sonnet earns its cost; Haiku is not yet good enough for an unsupervised first pass.**

Quantified, on Utah's 4 U.S. House reps:
- Haiku used **72% of the tokens** and ran **~3× faster** wall-clock…
- …but **failed one rep entirely** (0/24, after burning 91k tokens), dragging coverage to **61.5% of cells vs Sonnet's 90.6%**, and pushing Haiku's **cost-per-useful-stance *above* Sonnet's** (6,301 vs 5,943 tokens/scored row).
- On the **54 cells both scored**, agreement is high: **61% exact, 96% within one point, MAD 0.43** — so where Haiku produces an answer it usually lands in Sonnet's neighborhood.
- But Haiku grounds **worse on the objective gate** (16.9% vs 21.8% of rows with a verifiable source), emitted an **invalid topic_key**, and in the reasoning spot-check was **better-grounded in 0 of 5** disagreements (worse in 4, tie in 1), twice citing an off-topic source.

**Bottom line:** Haiku's value *agreement* (96% within ±1) is good enough that it's viable as a **cheap pre-fill that a stronger model or human reviews** — its scores are rarely wildly off. But its first-pass *grounding* and *robustness* are not good enough to trust unsupervised: it gives up on hard-to-source reps, mis-sources topics, and breaks the topic-key contract. Since the deterministic verifier is the real publish gate and most rows from **both** models already fall to re-research, the marginal token savings from Haiku don't offset its lower coverage and weaker grounding. **Keep Sonnet (the agent default) for first-pass research.** If cost pressure is real, the defensible use of Haiku is a *bulk pre-fill on well-documented officials* whose output is then verified/upgraded — not as the sole researcher, and never on reps with thin or access-restricted sourcing.

### Caveats
- n is small (4 reps, one ideologically uniform cohort) — this measures **agreement + grounding**, not scale spread, and one model failure (Moore) swings the aggregates.
- Absolute verified-source rates are depressed by Cloudflare/paywall blocking of `*.house.gov`, `congress.gov`, and major Utah news; identical for both models, so the comparison holds, but don't read low verification as fabrication.
- Audit trail: both batches' CSVs are retained under `data/stance-research/2026-06-04-ut-house-{sonnet,haiku}/`; verifier logs at `/tmp/verify-{sonnet,haiku}.log`; analysis JSON at `/tmp/bench-analysis.json`. Helper scripts: `scripts/_bench-merge-subdirs.ts`, `scripts/_bench-analyze.ts`.

---

## Addendum — Sonnet batch published to production (2026-06-05 UTC)

After the benchmark, the **Sonnet** batch was taken through the rest of the pipeline (the Haiku batch was **not** touched — benchmark only). Per the verification gate, only verified rows publish.

- **One bounded re-research pass** (4 Sonnet agents, one per rep, re-doing only the 68 unverified topics with the exact failed-URLs excluded) lifted verification from **19 → 56 pushable** rows. Two agents (Maloy, Kennedy) wrote snippets with unescaped quotes; both `evidence.csv` files were repaired (re-serialized with correct CSV escaping; snippet text preserved — the verifier normalizes quotes anyway).
- `verify-stance-research.ts --threshold 1 --apply --re-researched` result: **pushed=56 (69 evidence snippets) · reviewed=30 · stamped=4 · errors=0.**

| Rep | Pushed (live) | Review queue | Dropped (value=null) |
|-----|-------------:|-------------:|---------------------:|
| Blake Moore | 4 | 17 | 0 |
| Celeste Maloy | 18 | 3 | 0 |
| Mike Kennedy | 13 | 8 | 3 (campaign-finance, homelessness, data-centers) |
| Burgess Owens | 21 | 2 | 1 (homelessness) |
| **Total** | **56** | **30** | **4** |

- **Moore dominates the review queue (17/30)** — his sources are the most fetch-resistant (KSL/Deseret/Standard-Examiner/congress.gov behind Cloudflare/paywall), so even re-researched snippets couldn't be verified by the automated fetcher.
- The 30 review-queue rows are pending in `inform.stance_research_review` (batch `2026-06-04-ut-house-sonnet`), **not live**; each carries its per-snippet failure audit trail. Topics not pushed retain whatever prior value existed.
- These reps already had ~22–24 unverified answers each; this run upgraded 56 of them to **evidence-backed** values. Re-researching was clearly worth it: it ~tripled what could be published (19→56).

---

## Addendum 2 — Review-queue recovery pass (2026-06-05 UTC)

The 30 review-queue rows got one more focused recovery pass (4 Sonnet agents) — this time excluding *all* previously-failed URLs and steering hard toward fetcher-friendly sources (GovTrack, ProPublica Represent, Ballotpedia, Wikipedia, OnTheIssues, Vote Smart, Wayback snapshots) with a strict verbatim-quote + RFC-4180 CSV-escaping rule. Output written to `…-sonnet-rq2/`, applied under the original batch_id.

- Agents produced values for **22/30**; the verifier passed **16**. Result: `pushed=16 (24 snippets) · reviewed=6 · stamped=4 · errors=0`. The 16 flipped review rows were marked `status='resolved'` in `inform.stance_research_review`.

| Rep | Recovered → live (rq2) | Total live now | Still pending |
|-----|----------------------:|---------------:|--------------:|
| Blake Moore | +9 | 13 | 8 |
| Celeste Maloy | +2 | 20 | 1 |
| Mike Kennedy | +3 | 16 | 5 |
| Burgess Owens | +2 | 23 | 0 ✅ |
| **Total** | **+16** | **72** | **14** |

**Cumulative outcome for the Sonnet batch:** 72 verified stances live (93 evidence snippets) out of 86 scored — up from 19 verifiable at first dry-run. The verification gate climbed **19 → 56 → 72** across the original pass + two bounded recovery passes.

**14 rows remain in review** (all `re_research_attempted=true`, `verified=0`): Moore — civil-rights, climate-change, deportation, immigration, redistricting, same-sex-marriage, school-vouchers, trans-athletes · Kennedy — civil-rights, climate-change, religious-freedom, same-sex-marriage, social-security · Maloy — social-security. These cluster on topics whose evidence lives almost exclusively on fetch-blocked pages (LCV scorecard, congress.gov roll-calls, paywalled local news) — the automated fetcher genuinely can't reach a verbatim quote, so they correctly stay out of production pending human review.
