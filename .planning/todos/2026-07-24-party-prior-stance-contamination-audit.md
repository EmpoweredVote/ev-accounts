# Party-prior / bio-page-only stance contamination — audit + remediation

**Created:** 2026-07-24 (found while scoping the Oregon state-leg stance wave for the Bend ballot)
**Priority:** HIGH — this is published stance data that violates the project's own evidence bar
**Not date-gated.**

## What was found

Scoping stances for Bend's four ballot legislators, all three sitting members
(Levy `-4120053`, Kropf `-4120054`, Broadman `-4110027`) turned out to already have exactly
**6 stances each — same six topics, one source each, zero quotes, values almost all 1s and 2s.**
That is the signature of a bulk template, and inspection confirmed it.

### The tell that proves inference rather than research
Emerson Levy's `civil-rights` reasoning reads:
> "Supported civil rights and anti-discrimination measures; consistent progressive voting record
> **from Lake Oswego district**. https://ballotpedia.org/Emerson_Levy"

**Levy represents HD 53 — Bend / Redmond / Sisters, Central Oregon.** Lake Oswego is Portland
metro, ~130 miles away and a different district entirely. The reasoning is confabulated, and the
cited source is a Ballotpedia **biography** page, which carries no stance content to support the
claim either way.

### Scope, measured
| Scope | Rows | Politicians |
|---|---|---|
| All `inform.politician_context` | 33,929 | — |
| Sourced **only** to a Ballotpedia bio URL (`ballotpedia.org/<Name>`) | **907** | **293** |

By `representing_state` (politicians with ≥1 such row): **(none) 137, OR 97, TX 23, VA 18, CA 11**,
MD 2, ME 2, MA 1, UT 1, AZ 1.

Oregon legislators + federal OR reps (`representing_state='OR'`, title Representative/Senator),
n=96 people:
- **668** context rows total
- **293 (44%)** sourced only to a Ballotpedia bio page
- **0 quotes across the entire cohort**

### The reasoning pattern — party + district geography as the evidence
Sampled verbatim:
- "consistent progressive voting record from Portland district" (Annessa Hartman, civil-rights)
- "consistent progressive voting record from Troutdale/East Metro" (Zach Hudson, civil-rights)
- "conservative Marion/Polk County district priorities" (Anna Scharf, public-safety-approach)
- "rural Klamath/Jackson district with agricultu[re]…" (Dwayne Yunker, climate-change)
- "Central Oregon Democrat focused on outdoor recreation" (Broadman, climate-change)
- "Voted YES on tax measures supporting public investment in services and infrastructure"
  (Broadman, taxes) — **no bill named**, sourced to the bio page

This is precisely what `feedback_stance_no_assumption.md` ("never party inference") and
`feedback_chairs_not_polarity.md` forbid.

## ⚠️ CORRECTION (2026-07-25): the bill-cited rows are ALSO fabricated
An earlier draft of this file said the rows citing real OLIS/clerk.house.gov roll calls "should
survive re-verification." **That was wrong.** Verified against Wikipedia `term_start` for the three
Bend legislators:

| Legislator | Seated | Bill cited | Session | Verdict |
|---|---|---|---|---|
| Emerson Levy (HD 53) | **2023-01-09** | HB 2020 | 2019-20 | **impossible** |
| Emerson Levy | | HB 2001 | 2019R1 | **impossible** |
| Emerson Levy | | HB 3427 | 2019R1 | **impossible** |
| Jason Kropf (HD 54) | **2021-01-11** | HB 2020 | 2019-20 | **impossible** |
| Jason Kropf | | HB 2001 | 2019R1 | **impossible** |
| Jason Kropf | | HB 3427 | 2019R1 | **impossible** |
| Anthony Broadman (SD 27) | **2025-01-13** | HB 2002 | 2023R1 | **impossible** |
| Anthony Broadman | | SB 1537 | 2024R1 | **impossible** |

**7 of 8 bill-cited rows attribute a vote cast before the member was seated.** (Broadman's
Jan-2021 date is his **Bend City Council** term, not the Senate — an easy trap when reading an
infobox.) Only Levy's and Kropf's HB 2002 (2023) rows are chronologically possible, and their vote
attribution is still unverified.

**Consequences for the audit:**
1. The `sources[1] ~* 'ballotpedia\.org/[A-Z]'` filter **UNDERCOUNTS** the problem. A row citing a
   genuine OLIS bill page looks well-sourced and passes every presence check while being fabricated.
   The 907 figure is a floor, not the total.
2. **Add a mechanizable service-date check** — compare each cited bill's session year against the
   member's `term_start`. Any citation predating it is fabricated regardless of how real the URL is.
   This is cheap, deterministic and would sweep the whole 33,929-row table, not just this cohort.
3. Rows for **Gomberg / Wallan / Yunker / Bentz** (HB 2020 walkout, H.R. 1) are still plausible on
   dates — but must now be date-checked too, not assumed.
4. The remediation unit is still **the row**; but for this Bend cohort the honest disposition is to
   **retire all 18 rows** and re-research, since even the survivors carry party-prior reasoning
   ("consistent progressive voting record from Lake Oswego district") that cannot be repaired in place.

## Why the existing gate did not catch this
The Phase 149 gate is "0-unsourced + ≥1 sourced stance." These rows all **have** a source URL, so
they pass a presence check. Nothing verified that the cited page **supports the claim**. Same blind
spot the wave-6 validator was built to close — and note that `validate-stance-quotes.py` would also
have passed all 907, because they carry **no quotes to string-match**. A source-supports-claim check
is a different and harder test than a quote-match.

## The acceptance standard — every stance needs a CHAIR and a SOURCE

Both, independently. A row is only publishable when:

1. **CHAIR** — the assigned `value` is the specific 1-5 chair whose *text* the evidence names.
   Not a polarity ("they're a Democrat so 1-2"), not an average, not the direction the topic
   "usually" runs. If two adjacent chairs both fit the evidence, the row is a **skip**, not a guess.
   → [[feedback_chairs_not_polarity]]
2. **SOURCE that actually supports the claim** — a fetched page whose content carries the position.
   **The presence of a URL is not a source check.** All 907 bad rows have a URL; that is exactly why
   the Phase 149 "0-unsourced" gate passed them. A Ballotpedia *biography* page is not a source for
   a stance. A real bill page is not a source for a vote the member could not have cast.

An empty compass is honest. A confabulated one is a false statement about a real person, published
under their name — strictly worse than no data. When in doubt, retire the row.

## Mechanizable check #1: PRE-SEATING (built, regression-tested, ready to sweep)

**Implemented** in `backend/scripts/validate-stance-quotes.py` as the `[PRE-SEATING]` finding.
It parses legislative session codes (`2019R1`, `2024S1`, …) out of **both** the `sources` array and
the `reasoning` prose, and fails any row citing a session earlier than the member's verified
`term_start`. Deduped to one finding per row per session.

```python
SEATED = {  # external_id: (first_valid_session_year, why)
    -4120053: (2023, "Emerson Levy seated 2023-01-09"),
    -4120054: (2021, "Jason Kropf seated 2021-01-11"),
    -4110027: (2025, "Anthony Broadman seated in the SENATE 2025-01-13 "
                     "(his Jan-2021 term was Bend City Council)"),
}
```

**Regression fixture:** `backend/scripts/fixtures/badseed-preseating.json` holds five of the actual
fabricated rows. The check flags all five. Keep it green.

**Why this check matters more than quote-matching here:** a fabricated *vote* has a genuine URL and
no quote to string-match, so it passes every other test in the validator. This one needs no fetch at
all and is deterministic.

### Sweep scope, measured 2026-07-25
| Population | Rows | Politicians |
|---|---|---|
| All `politician_context` | 33,929 | — |
| Cites a session code (`YYYYR#`/`YYYYS#`) | **276** | **94** |
| — of which `olis.oregonlegislature.gov` | 273 | 91 (OR) |
| — remainder | 3 | 3 (UT) |
| Cites *any* legislature-ish source (legiscan/leg.state/capitol/…) | 3,074 | — |

So the OLIS form of this check is an **Oregon sweep of 273 rows / 91 legislators** — small enough to
finish in one pass.

### To run the sweep
1. **Populate `SEATED` for all 91 OR legislators.** Get `term_start` from Wikipedia
   `Special:Export/<Name>` (fast, and it is what verified the Bend three) or the OR Legislature
   member pages. **Trap: an infobox may list several `term_startN` values for different bodies** —
   Broadman's Jan-2021 entry is his Bend City Council term, not the Senate. Match the term to the
   office the stance is attributed to.
2. Export the 273 rows (query below), run them through the validator, and treat every
   `[PRE-SEATING]` hit as fabricated — retire it.
3. Extend to the 3,074 legislature-sourced rows by generalising from "session code" to
   "evidence date vs term_start". Any dated evidence — a vote, an ordinance, a council motion, a
   news article about an action in office — must postdate the person taking **that** office.

## Mechanizable check #2 (not built): SOURCE-SUPPORTS-CLAIM
The remaining gap. `validate-stance-quotes.py` verifies a quote appears in a source, but **890+ of
the bad rows carry no quote at all**, so there is nothing to match and they pass. Options, cheapest
first:
- **Cheap heuristic:** flag any row whose only source is a Ballotpedia/Wikipedia *biography* URL, or
  whose `reasoning` contains party-prior phrasing. Regex for the phrasing that recurs verbatim in
  this seed: `progressive voting record|conservative voting record|Democrat focused|Republican focused|district priorities`.
- **Real check:** fetch the source and ask whether it contains any statement on the topic's axis.
  Needs a model in the loop, so it is a batch job, not a lint.
- Note the validator would have **passed all 907** of these rows this morning. Do not treat a clean
  validator run as evidence a cohort is sound until this check exists.

## 🔑 THE REMEDIATION TOOL: the OLIS OData API (found 2026-07-25)

`https://api.oregonlegislature.gov/odata/ODataService.svc/` — **public, no auth, no rate limit,
clean JSON.** This is what makes the 91-legislator Oregon sweep cheap. It returns **per-legislator
roll calls**, so a vote attribution is machine-checkable instead of a judgement call.

Entity sets that matter: `Legislators`, `MeasureVotes`, `MeasureSponsors`, `MeasureHistoryActions`,
`CommitteeVotes`.

```bash
B=https://api.oregonlegislature.gov/odata/ODataService.svc
# identity + every session a member served (this alone validates term_start)
curl -sS "$B/Legislators?\$filter=LastName%20eq%20'Levy'&\$format=json"
# every individual vote on a measure
curl -sS "$B/MeasureVotes?\$filter=SessionKey%20eq%20'2025R1'%20and%20MeasurePrefix%20eq%20'HB'%20and%20MeasureNumber%20eq%202138&\$format=json"
# everything a member ever sponsored
curl -sS "$B/MeasureSponsors?\$filter=LegislatoreCode%20eq%20'Rep%20Kropf'&\$format=json"
```

**Field gotchas:**
- The sponsor field is **`LegislatoreCode`** — their typo, not ours. `SponsorLevel` is `Chief` /
  `Regular`. There is no `SponsorName`/`LastName`; querying those returns `None` for every row and
  makes real sponsorships look absent (cost me a false "NOT a sponsor" on 12 claims).
- Members are keyed by **`VoteName` / `LegislatoreCode` codes**, e.g. `Rep Levy E`, `Rep Levy B`,
  `Rep Kropf`, `Sen Broadman`.
- `MeasureVotes.ActionText` is usually null — join `MeasureHistoryId` →
  **`MeasureHistoryActions`** (NOT `MeasureHistories`, which 404s) for the action text.

**Two checks it enables that nothing else did:**
1. **Session coverage = term validation.** `Legislators?$filter=LastName eq 'X'` lists every session
   served. Levy's earliest is `2023R1`; Bobby Levy's is `2021R1`; Broadman's Senate record is
   `2025R1/2025S1/2026R1` with **zero** rows before it, and Kropf's 2,927 votes contain **none**
   before 2021. The fabricated attributions were structurally impossible, confirmed from the source.
2. **Procedural-vs-content votes.** Critical, and it can invert a score. Oregon majority members
   vote **Nay as a bloc on motions to withdraw/refer/rerefer** to defend committee process — that is
   NOT a content stance. Verified examples: on HB 3054 (2025R1) and HB 2107 (2023R1), Levy and Kropf
   each voted **Nay on "Motion to refer/rerefer to Rules failed"** and **Aye on "Passed."** the same
   day. HB 2002 (2023R1) shows Levy at `{Nay: 7, Aye: 1}` — seven Nays on kill motions, one Aye on
   repassage. **Score only third-reading/passage votes**; read `ActionText` before using any vote.
   `ActionText` also exposes `Carried by <Name>` — a floor carry, the member's own act and stronger
   evidence than sponsorship.

**Wrong-person trap:** `Rep Levy E` (Emerson, D-53, Bend) vs `Rep Levy B` (Bobby, R-58). On HB 2138
they voted opposite ways. `oregonlegislature.gov/levy` is **Bobby**. Always resolve the code first.

## ✅ STEP 1 DONE — Bend ballot four remediated 2026-07-25
Retired all **18** fabricated rows (snapshot: `backend/data/stance-research/or-bend-stateleg/retired-partyprior-snapshot.json`,
via `backend/scripts/retire-bend-stateleg-partyprior.mjs`) and replaced them with **45 evidence-only
stances / 16 quotes, 0 unsourced, 0 bio-page-only**:

| Person | Was | Now | Quotes |
|---|---|---|---|
| Emerson Levy `-4120053` | 6 fabricated | **14** | 6 |
| Jason Kropf `-4120054` | 6 fabricated | **14** | 4 |
| Anthony Broadman `-4110027` | 6 fabricated | **14** | 4 |
| Michael Summers `-4129001` | 0 | **3** | 2 |

Every vote and sponsorship claim was re-verified against the OData API by the orchestrator, not just
the agents. Two corrections applied: **Kropf's HB 2172 (2021R1) chief-sponsorship was struck** (the
API records no named sponsor for that measure and no Kropf sponsorship of anything numbered 2172 in
any session — the row survives on six verified floor carries and three verified Chief sponsorships),
and **Summers `public-safety-approach`=4 was dropped** (its chair-4 content — "increase police
staffing" — existed only in a 2024 voters' pamphlet hosted at
`digitalcollections.library.oregon.gov/nodes/view/281745`, which serves a **2 KB viewer shell**; its
`/nodes/download/` endpoint also returns HTML, so the quote is unverifiable, and the reachable
source supports chair 3 at best. It was also the prior cycle and a different office).

**Michael Summers identity note:** he is Broadman's own 2024 SD-27 opponent and chairs the Redmond
School District 2J board; **`electsummers.com` is live** — the dead domains recorded in the Bend
headshot trail (`summersfororegon.com`, `michaelsummersoregon.com`) were the wrong ones.

## Remaining remediation order
2. **Decide the disposition rule** for the other ~289 politicians / ~890 rows: re-research,
   or retire the row (delete the answer + context) pending real evidence. Retiring is defensible —
   an empty compass is honest, a confabulated one is not.
3. The **137 "(none)"** politicians (no office row / no representing_state) need identifying first;
   external_id range spans `-66000091`..`-40202`, so this is several unrelated seeds, not one.

## Query: the 273 session-citing OR rows (input to the pre-seating sweep)
```sql
SELECT p.external_id, p.full_name, o.title, o.representing_state,
       t.topic_key, pa.value, pc.sources, left(pc.reasoning,200) AS reasoning_head
FROM inform.politician_context pc
JOIN inform.politician_answers pa
  ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
JOIN inform.compass_topics t ON t.id=pc.topic_id
JOIN essentials.politicians p ON p.id=pc.politician_id
LEFT JOIN essentials.offices o ON o.politician_id=p.id
WHERE (array_to_string(pc.sources,' ') || ' ' || coalesce(pc.reasoning,''))
        ~ '\y(19|20)\d{2}\s?[RS]\d\y'
ORDER BY p.full_name, t.topic_key;
```

## Query to re-derive the bio-page-only set
```sql
SELECT p.external_id, p.full_name, o.representing_state, t.topic_key, pa.value, pc.sources,
       left(pc.reasoning,200)
FROM inform.politician_context pc
JOIN inform.politician_answers pa
  ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
JOIN inform.compass_topics t ON t.id=pc.topic_id
JOIN essentials.politicians p ON p.id=pc.politician_id
LEFT JOIN essentials.offices o ON o.politician_id=p.id
WHERE coalesce(array_length(pc.sources,1),0)=1
  AND pc.sources[1] ~* 'ballotpedia\.org/[A-Z]'
ORDER BY o.representing_state, p.full_name, t.topic_key;
```

**Do NOT add new stances to these cohorts until the disposition is decided** — piling researched
rows on top of party-prior rows makes the two indistinguishable without reading every `sources`
array.
