# WI state-legislature stance wave — plan

Prepared 2026-07-28 (overnight). **Nothing in this wave has been written to prod.** Every number
below was measured, not assumed; the commands that produced them are named so they can be re-run.

## 1. Baseline (measured against prod `kxsdzaojfaibhuzmclfq`)

| | Assembly | Senate | total |
|---|---|---|---|
| seats | 99 | 33 | 132 |
| seats with a current holder | 99 | 33 | **132 — no missing `office_terms`** |
| sitting members with ≥1 stance answer | 9 | 2 | 11 |
| total stance answers | 17 | 5 | **22** |
| sitting members with a headshot | 1 | 0 | **1** |

2026 field (election `WI 2026 Partisan Primary`, **2026-08-11**):

| | Assembly | Senate | total |
|---|---|---|---|
| primary races | 190 | 30 | 220 |
| candidates | 216 | 40 | **256** (all with a resolved `politician_id`) |
| at zero stances | 208 | 39 | **247** |
| without a headshot | 214 | 40 | **254** |

Distinct people across *2026 field ∪ sitting members*: **291**. At zero stances: **280**. Without a
headshot: **289**.

Regenerate with `node scripts/gen-wi-2026-stateleg-roster.mjs` →
`roster_full.csv`, `roster_contested.csv`, `roster_incumbents.csv`.

## 2. Four assumptions that were wrong

1. **WI 2026 candidates are already seeded.** 256 of them, all with `politician_id` resolved, status
   `active`. The "seed candidates first" step is largely already done — the work is stances and
   headshots, not candidate creation. (WI's nomination-paper deadline was the first Tuesday in June,
   so the field is also final, not moving.)
2. **The state-leg topic set is 26 topics, not 44.** `_TOPIC_SCALE_FULL.txt` is the full *live*
   topic list. Prod scopes topics per role in `inform.compass_topic_roles`, and
   `role_scope='state'` is **26** topics. The other 18 are 8 `judicial-*` topics and city-only
   topics (`city-sanitation`, `local-environment`, `residential-zoning`, `housing`, …) plus
   federal-only ones (`social-security`, `tariffs`, `ukraine-support`). Asking a WI Assembly member
   about city sanitation or judicial interpretation is a category error. **Use the 26.**
   All 44 topic UUIDs in the file do match prod exactly, and `inform.topic_rewrites` is empty — so
   the ids are safe to reuse, it's the *scope* that was wrong.
3. **Senate: only 17 of 33 seats are up** — all odd-numbered districts (1, 3, … 33), verified from
   the seeded field rather than from recollection. 10 have their incumbent running; 7 are open.
4. **The WI Legislature does publish a per-member voting record.** It is not a feed or an API, but
   each member's page renders their complete floor record with their own position already resolved.
   132 page fetches, no API spend.

## 3. Evidence layer (all verified fetchable, all free)

| artifact | rows | what it is |
|---|---|---|
| `wi_legis_members.csv` | 132 | roster: district, party, home city, member site, **official headshot URL** |
| `wi_legis_votes.csv` | 38,478 | one row per (member, floor vote) with that member's own position |
| `wi_legis_authored.csv` | 60,148 | authored / co-authored / cosponsored / amendments per member |
| `wi_rollcalls.csv` | 562 | per roll call: bill, **subject heading**, motion, full tally |
| `wi_rollcall_topic_triage.csv` | 408 | divided roll calls shortlisted to candidate topics — **un-adjudicated** |

Producers: `scripts/scrape-wi-legis-members.mjs`, `scripts/scrape-wi-rollcalls.mjs`,
`scripts/triage-wi-rollcalls-to-topics.mjs`.

**Cross-checks that passed.** Prod's `office_current_holder` agrees with the WI Legislature roster
on **132/132 seats** (keyed on chamber+district, never on name) — an independent bill of health for
WI occupancy, which is the one failure mode CI cannot catch. Every member has a substantive record
(min 226, median 297 votes). All 132 official headshots download as distinct valid JPEGs
(28–41 KB, 132 distinct SHA-256s — no shared placeholder).

**Traps found in the data, encoded in the scripts:**

- The member-vote vocabulary is `Yes` / `No` / **`No Vote`** / `Paired For` / `Paired Against`.
  `No Vote` means **absent**, not opposition. Folding it into `No` would fabricate opposition for
  688 rows.
- Bill number is **not** a roll-call key — the same bill is voted in both chambers. Key on the
  `av####`/`sv####` id.
- The two chambers render differently (Assembly: all-caps banner + one combined tally line; Senate:
  mixed-case + separate tally lines, no `PAIRED`). A parser written against one silently produced
  260 empty rows for the other.
- 45 roll calls are **Extraordinary Session** votes; anchoring on "Regular Session" dropped them all.
- `districts.district_id` is NULL for WI state leg — the district number lives in `ocd_id`
  (`sldl:N`/`sldu:N`) and `label`. `geo_id` is not unique across `district_type`.

## 4. The honest evidence ceiling — read this before sizing anything

The 38,478-row vote corpus is large, and almost all of it cannot pin a chair:

```
562  roll calls
408  divided (losing side >= 10)      <- a 97-0 vote cannot separate members
170  of those are PROCEDURAL          <- tabling/rejecting amendments, "shall the decision
                                         of the chair stand". These express floor management,
                                         not a policy position.
238  substantive AND divided
 48  also shortlist to a state-scope topic   <-- THE USABLE POOL
```

And those 48 are a *shortlist*, not evidence: each still needs the bill read to decide whether it is
chair-shaped. Expect meaningfully fewer to survive.

Roll-call coverage by topic — **10 of 26 topics have no roll-call route at all**:

- has candidates: taxes (16), voting-rights (9), transportation-priorities (5), civil-rights (4),
  abortion (3), healthcare (3), data-centers (2), homelessness (2), immigration (2),
  trans-athletes (2), childcare (1), economic-development (1), growth-and-development (1),
  jail-capacity (1), religious-freedom (1)
- **zero**: ai-regulation, campaign-finance, climate-change, deportation, fossil-fuels,
  medicare/aid, misinformation, redistricting, rent-regulation, same-sex-marriage, school-vouchers

So the realistic shape is: votes carry a *handful* of topics for incumbents; everything else needs
candidate-stated sources, and **159 challengers have no voting record at all**. An empty compass is
the honest outcome for many of these people.

A caution about the triage file itself: keyword matching on short bill titles is crude. The first
pass was full of mid-word garbage (`RENT` inside "PA**RENT**S" and "APP**RENT**ICES", `TRANSIT`
inside "TRAN**SIT**ION", `ROAD` inside "B**ROAD**BAND"), and anchoring both ends then silently
dropped plurals ("ABORTION**S**", "DATA CENTER**S**"). It now anchors the word start and allows a
trailing stem, with regression cases. It is still only a shortlist.

## 5. Wave order

Ordered by *when a voter needs it*, which is the primary date.

**Wave 0 — headshots for the 132 sitting members (no research judgment required).**
Official roster JPEGs, verified present and distinct. This is the single largest coverage win
available and it involves no stance judgment. Import into `essentials.politician_images`; the
correct-person guard still applies, and the crop rule is ~one ear-length between hair top and frame
top, never vertically centred.

**Wave 1 — the 24 contested primaries (60 candidates), before Aug 11.**
These are the only races where a WI voter has a decision on primary day; the other 196 primary races
are uncontested and matter for Nov 3. Biggest fields: AD76-D (5 — Hong's open seat), AD57-R (4),
SD1-R (4). 6 contested races have an incumbent, 18 are open.

**Wave 2 — remaining incumbents (72 not in wave 1), Aug–Sep.**
These have the vote corpus behind them, so they are the highest-yield-per-hour group. Includes the
**35 sitting members not on the 2026 ballot** (16 even-numbered Senate seats not up this cycle, plus
19 members not seeking re-election) — they still hold office and still surface in Essentials, so
they still need coverage.

**Wave 3 — remaining challengers, Sep–Oct**, ahead of the Nov 3 general.

## 6. Method

**Bill-first, not person-first.** Adjudicate each shortlisted bill ONCE — is it chair-shaped, and
which chair does a Yes vs a No support — then reuse that judgment across every member who voted on
it. One adjudication of a divided Assembly vote yields evidence for up to 99 people. This is the
opposite of the per-person research loop and it is why the wave dir is bill-keyed.

The adjudication columns in `wi_rollcall_topic_triage.csv` (`chair_shaped`, `topic_final`,
`chair_if_yes`, `chair_if_no`, `reviewer_note`) are **blank by design**. A keyword hit is not a
finding and must never become a stance value.

Standing guardrails that apply unchanged:

- **The bar: a chair the evidence names AND a source that supports it, independently.** If two
  adjacent chairs both fit, skip. A URL existing is not a source check.
- **A vote pins a chair only when the bill IS chair-shaped.** An oppositional No rules out the far
  end only. Compound chairs need every clause evidenced.
- Group rows by cited source and look for chair disagreement — one source supporting two chairs pins
  neither.
- Max **3 concurrent** research agents. Validate **each payload the moment it returns**, never
  batched: `py backend/scripts/validate-stance-quotes.py <payload>` plus a `_WAVE_GUARDS.json`
  sidecar. Structural pass is **not** sufficient — hand-check quote attribution and `reasoning`.
- Never party inference. Never build `quote_text` from WebFetch or r.jina.ai output — those return a
  paraphrase; fetch the PDF and `Read` the binary.
- Push as a tracked `push_*.sql` in this directory, **not** a numbered migration →
  `inform.politician_answers` + `inform.politician_context`.
- Resolve `politician_id` by office/district join, never bare `full_name`. State districts store
  `state` **lowercase**.

## 7. Decisions needed before anything is written

1. **Wave 0 headshots — go?** 132 official roster JPEGs, ready to import. Needs a prod write.
2. **Confirm the 26-topic state scope** replaces the 44-topic file for this wave.
3. **Wave 1 scope call.** 60 candidates × up to 26 topics in 14 days, where 44 of the 60 are
   challengers with no voting record. Full pre-primary coverage of the contested field is the
   standing preference, but the evidence ceiling above is the binding constraint — worth deciding
   explicitly whether wave 1 is "all 60 candidates, thin" or "the 6 contested incumbent races, deep".
4. **Adjudication ownership.** The 48-row shortlist needs a human pass on chair shape before any
   agent work starts. That is the gate for the whole wave.
