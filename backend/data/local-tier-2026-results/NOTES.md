# The local tiers against AP — a recon, not a wave (2026-11-08)

**The answer is ONE winner.** AP's per-state feed can record exactly one result we do not already
hold: **Robert Luna, Los Angeles County Sheriff**, with Alex Villanueva as the loser beside him.
Everything else AP has called in these tiers is either already recorded or sits in a city we hold
no office in.

This directory is the measurement. Nothing was written to production.

```
fetch-ap.mjs                 copied verbatim from ../state-leg-2026-results — it downloads the
                             WHOLE per-state file; its LEG_OFFICE_IDS only shapes the summary line
ap-2026-11-08/               CA IN OR TX UT WA, re-fetched (not reused from the state-leg pass)
our-rows-2026-11-08.json     1,041 candidacies across 476 races, COUNTY/LOCAL/LOCAL_EXEC/SCHOOL/JUDICIAL
```

---

## 🔴🔴 THE PREMISE THIS RECON WAS COMMISSIONED ON IS WRONG, AND IT IS THE SAME ERROR ONE TURN LATER

The queue said: *"AP's per-state files carry County Executive, County Clerk, County Treasurer,
Sheriff, District Attorney, Mayor, City Council and School Board contests."* `CC_0381`'s notes
said: *"51 City Council, 18 School Board, 10 Sheriff."*

**Both are true nationally and neither is true here.** Those counts were enumerated across all 51
state files. We hold these tiers in **six** states, and in those six files AP publishes:

| AP office | races | **called** |
| --- | --- | --- |
| City Council (`N`) | 23 | **1** |
| City Board of Supervisors (`CBS`) | 5 | 0 |
| City Representative (`CRP`) | 4 | 0 |
| School Board (`SCB`) | 3 | 0 |
| Mayor (`M`) | 2 | 2 |
| City Auditor (`CAD`) | 2 | 2 |
| Community College Board Trustee (`CCB`) | 2 | 1 |
| Sheriff · City Attorney · Public Defender · City Board of Education · City Assessor-Recorder · Municipal Court Judge | 1 each | 4 of 6 |
| **total** | **47** | **9** |

🔴 **THERE IS NO COUNTY EXECUTIVE, COUNTY CLERK, COUNTY TREASURER, DISTRICT ATTORNEY, ASSESSOR OR
CORONER RACE IN ANY OF THE SIX FILES.** Our COUNTY tier is 99 races — Tarrant TX (45), Salt
Lake/Utah/Davis UT (32), King/Kitsap WA (14), Deschutes/Washington OR (7), Indiana (10) — and
**AP covers not one of them.**

▶ **THE CATALOGUE OF A SOURCE IS A PROPERTY OF THE ENDPOINT — *AND OF THE SLICE YOU NEED*.**
`CC_0381` learned that an office list read off `results/national/` is a fact about that file.
The correction it wrote down was then read as a fact about AP, and it is not: it is a fact about
**the union of 51 files**. A national total says nothing about whether the six states you hold
are in it. ⚠ This is the second time in one week that a true enumeration pointed at a wrong
conclusion because its scope was not carried with it. **Cite the scope with the count.**

---

## The nine called races, and what each one is

🟢 **The positive control ran first.** A uniform "no AP race for any county office" is the shape
of a blind detector, so the place-name scan was watched finding what it should: `Austin` 47 hits,
`Los Angeles` 38, `Seattle` 6 — and only then trusted on `Tarrant` 0, `Salt Lake` 0, `Kitsap` 0.
⚠ `Monroe` (1), `Davis` (10) and `Bend` (1) are **candidate surnames**, not places; checked
against `officeName`/`seatName` and none is a contest.

| AP race | status here |
| --- | --- |
| **LA County Sheriff** — Luna def. Villanueva 70.2–29.8 | 🟢 **THE ONE MATCH.** Our `ca COUNTY / Los Angeles County / Sheriff` carries both names and `result IS NULL` on both |
| LA Mayor — Raman def. Bass 54.7–45.3 | ✅ **already recorded**, `CC_0379`, citing this same AP race id |
| Oakland Mayor (Barbara Lee) · Oakland City Auditor · Oakland Council D4 | ✗ we hold **no Oakland offices** |
| SF Assessor-Recorder · SF Public Defender · SF Community College unexpired term | ✗ we hold **no San Francisco offices** |
| Portland City Auditor | ✗ we hold Bend, Beaverton, Cornelius and Tualatin — **not Portland** |

🔴 **I SUSPECTED THE LA MAYOR ROW WAS A DATA FAULT AND IT IS A REAL UPSET.** "Mayor / Los Angeles
— WON: Nithya Raman" reads like a council member filed under the wrong office. Reading the raw
record settled it: AP flags **Karen Bass** as the incumbent (`incumbentID: 50853`) and Raman as
the winner on 54.66% of 1.1M votes. ▶ **A row that looks impossible is a question, not a finding
— open it.**

🔴 **SIX OF THE NINE CALLS ARE UNOPPOSED BALLOTS WITH `voteCount: 0`.** AP calls those on the
ballot, not the count — `CC_0381`'s rule. Each has exactly one candidate for one seat, so no
ordering decision exists and a top-vote-getter gate would be vacuous. **Oakland's Mayor race is
`rankedChoice: true`**, where that cross-check is invalid outright. Neither matters today: the
single writable race is a genuine two-candidate contest with real counts.

⚠ **ALL NINE READ `isCertified: false`.** Any write here is `called`, never `certified`.

---

## 🔴 AP's LOCAL COVERAGE IS A BALLOT PUBLICATION, NOT A RESULTS SERVICE

**38 of the 47 are still "Too Early to Call" five days out**, including every Austin, Fresno, San
Diego, San Jose, El Paso and Seattle contest, both Portland council races (22 and 13 candidates)
and all five San Francisco supervisor districts. AP posted these ballots and has not returned to
call them. ▶ **Do not plan a delta pass on this tier expecting AP to catch up.** Where a local
result is wanted, the county is the source — which is what `CC_0377`-`CC_0380` already do.

🟢 **The ballots themselves still match ours exactly where they overlap**, which is the one
reusable finding: AP's five Austin council districts are our five (D1, D3, D5, D8, D9), AP's
Seattle 5 is our District 5, AP's LA District 3 and District 9 are ours. **If AP ever calls them,
the join key is `seatName` → our `district_label`, and it needs no relaxation.**

---

## What this means for the headshot queue

**One winner, and he is already in the seat and already has a photo.** Robert Luna holds
`ca COUNTY / Los Angeles County / Sheriff` today — `office_current_holder` names him — so
recording the result adds **no new face**. ▶ **The headshot queue does not grow from this tier.
Sorting the 233 is safe to start.** That was the question the recon was meant to answer.

---

## ▶ What is next

1. **Write the one row.** LA County Sheriff: Luna `won`, Villanueva `lost`, `called`, cited to AP
   race `20261103CA84304`. It is one migration and it needs no new office, person or polygon.
   🟢 **Measured, not assumed: it is NOT already recorded.** The dump above is production, and
   both rows read `result IS NULL` with `result_source` empty — so `CC_0377`-`CC_0380` did not
   take this contest from the RR/CC even though they were reading the same election.
2. **Leave the other 46.** Re-reading this feed will not improve them.
3. 🔴 **Do not re-run this recon against the other 45 states expecting a different answer.** The
   question was "what does AP add to the tiers we hold", and we hold them in six states. Adding
   states is seeding, not a results pass — `CC_0381`'s rule 5, unchanged.
