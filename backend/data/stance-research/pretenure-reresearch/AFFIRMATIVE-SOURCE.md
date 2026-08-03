# Affirmative-evidence source added — sponsorships and co-sponsorships

Tranche 1 established that roll calls in a deregulatory Congress are almost entirely **defensive** (No
votes against repeal), which rules out the far end of a scale and nothing more — so they cannot reach
chairs whose text demands an affirmative commitment. **Putting your name on a bill is a positive act**,
which is the evidence shape those chairs require. This adds that source.

Artifact: `affirmative-candidates.json` · script `_tmp-pretenure-cosponsor.mjs` · bulk data under
`_bulk/` (**not committed** — 130 MB, re-downloadable).

## Source and scale

**govinfo BILLSTATUS bulk data** (`govinfo.gov/bulkdata/BILLSTATUS/<congress>/<type>/`) — official, free,
**no API key** (we have none), and it carries `<cosponsors>` with **bioguideId** plus CRS `<policyArea>`
and `<legislativeSubjects>`.

Downloaded 116th–119th Congress, types `hr` / `hres` / `hjres`: **41,268 bills scanned → 1,595 affirmative
candidates**, of which **712 are original co-sponsorships** (the strongest signal — signing at
introduction rather than joining later).

**Coverage went from 32 to 35 of 36 pairs.** The three pairs roll calls could not touch at all now have
evidence: Hoyle / Campaign Finance Reform, Hoyle / State Redistricting, Van Epps / Immigration. Same-Sex
Marriage went from *zero* usable roll calls to candidates for all four members.

## 🔴 Two defects handed off, not papered over

**1. My CRS mappings are too broad, and this is the same error class as the keyword pass.** I claimed CRS
terms "mean what they say". That was an overclaim — the terms are professionally assigned, but *I* chose
terms wider than the topic. Demonstrated on Same-Sex Marriage:

| bill matched | via CRS subject | actually about |
|---|---|---|
| joint resolution removing the ERA ratification deadline | `sex, gender, sexual orientation discrimination` | the Equal Rights Amendment |
| Caring for Survivors Act of 2023 | `marriage and family status` | veterans' survivor benefits |

**The mapping needs tightening before adjudication**, and the right signal for a topic like Same-Sex
Marriage is the *bill* (Respect for Marriage Act, Equality Act), not a generic subject term. Treat CRS
terms with exactly the scepticism keywords earned.

**2. `bill` is null on 952 of 1,595 candidates.** Bill identity is derived from `<legislationUrl>`, which
is absent or differently shaped on those files. Title + subjects + date still identify the bill for
adjudication, but a **citation cannot be written without a bill id**, so this must be fixed before any
stance payload.

## Fixed along the way

- ⚠ **`<billType>` and `<billNumber>` DO NOT EXIST** in BILLSTATUS. The tags are `<number>` and `<type>`,
  and `<type>` also appears for **every committee** (`<type>Standing</type>`), so the first match is not
  the bill's. Use `<legislationUrl>`.
- ⚠ **The first `<title>` in the file belongs to the `<titles>` LIST, not the bill.** The bill's own title
  is the 4-space-indented direct child sitting immediately before `<titles>`.
- 🔴 **Chamber guard added.** Cindy Hyde-Smith (Senate) surfaced as a co-sponsor on a House bill in the
  first run, which is impossible. A member can only sign legislation originating in their own chamber.
  She is now correctly the single uncovered pair.
- The `original cosponsor` column read 0 everywhere — a **reporting** bug (tallied `h.original`, the field
  is `original_cosponsor`); the stored data was always right. 712 of 1,595.

## What is owed

1. **Tighten TOPIC_CRS**, then adjudicate. Chairs are still BLANK everywhere; nothing is written.
2. **Fix bill-id extraction** (952 nulls) — required for citations.
3. 🔴 **Cindy Hyde-Smith needs Senate BILLSTATUS** (`s`, `sjres`) — the only pair with no affirmative
   candidate, and the House roll-call index cannot serve her either. Both her sources are unbuilt.
4. Still unadjudicated: **277 roll-call bills** and **1,595 affirmative candidates**. The adjudication is
   the substantive remaining work, and it is a reading task, not a scripting one.
