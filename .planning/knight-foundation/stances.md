# Knight Cities — stance programme tracker

The seeding programme ([`PROGRAM.md`](./PROGRAM.md)) deliberately excluded stances: *"No stances —
those are the next program."* This is that programme. **Update this file at the end of every
session.**

Standard: `docs/superpowers/specs/2026-09-23-stance-program-design.md`. Pipeline: the
`research-stances` skill. Every row goes to the admin review queue; nothing auto-publishes.

## Measured scope, 2026-10-02

| Tranche | Governments | Seated people | Holding a Season 2 chair before this programme |
| --- | --- | --- | --- |
| Cities | 25 | **287** | 20 (Long Beach 9, San José 11) + Detroit 1 |
| State legislatures | 16 | **2,551** | 171 (CA 116, NC 53) |
| Counties | 21 | **~302** | Miami-Dade only (13 rows) |

Order is **cities → state legislators → counties** (operator, 2026-10-02). State legislators have
far better evidence per row, but many lack portraits, and the municipal tier is the one the
programme is for.

## Slice status

| # | Slice | Members | Rows | Scored | Batch |
| --- | --- | --- | --- | --- | --- |
| 1 | Charlotte NC | 12 | 420 | 5 | `2026-10-02-knight-clt-city` (PR #856) |
| 2 | Bradenton, Miami, Tallahassee FL | 17 | 595 | 2 | `2026-10-03-knight-fl-cities` (PR #857) |
| 3 | Duluth, Saint Paul MN | 18 | 630 | **30** ✅queued | `2026-10-04-knight-mn-cities` — ✅ **COMPLETE 2026-10-05.** All 18 members, 630 rows, gate `high=0`, 30 rows in the review queue (Kennedy `civil-rights` 2 added by ruling 2026-10-06) |

Eighteen chairs from 35 members. 🔴 **A low yield was the TOOLING, not the world** — re-mining with a
publisher-agnostic link extractor took Charlotte 3 → 5 and Florida 0 → 2, and attributed passages
from 22 → 122 in Florida. Price the next slice from these numbers, not from the first pass.

✅ **Slices 1 and 2 are merged** (2026-10-04): PR #855 (verifier fix), then #857, then #856. #856 had
cherry-picked only half of #855 and conflicted once #855 landed; the base was merged into it and both
verifier files were resolved to master, which is a strict superset. Charlotte’s five and Florida’s two
sit in the admin review queue awaiting human approval.

## Slice 3 — Duluth and Saint Paul, Minnesota (opened 2026-10-04)

- **18 seated people**: Duluth 9 councilors + Mayor Reinert; Saint Paul 7 councilmembers + Mayor Her.
  35 local ladders pinned into the open season (Season 2, 60 pinned, 35 at `local`). **630 rows.**
- **Baseline measured, not assumed: zero** `politician_answers` rows in the open season for all 18.
  A positive control confirmed the query shape returns rows for other politicians, so the zero is real.
- Leases: `place:2717000` (Duluth) and `place:2758000` (Saint Paul).
- Branch `knight/stances-mn`; batch `backend/data/stance-research/2026-10-04-knight-mn-cities`.

### Why Minnesota, and the claim the scope review must test FIRST

Charlotte spent 216 of its 420 rows on scope blanks, and Florida 306 of 595, because both states
preempt the whole field for firearms, municipal wages and rent regulation. Those rows prove a city
cannot act; they seat nobody.

Minnesota is expected to be the opposite case. Saint Paul is believed to have enacted **both** a rent
stabilisation ordinance and a municipal minimum wage — which, if true, makes those ladders live
levers carrying recorded votes and recorded member statements.

✅ **VERIFIED 2026-10-04 — the claim holds.** Full working:
[`scope-review.md`](../../backend/data/stance-research/2026-10-04-knight-mn-cities/scope-review.md).
**15 topics are scope blanks (270 rows), 20 are live (360).** 43% blank, against 51% for both
Charlotte and Florida. Four ladders that NC and FL could not reach are live here, each with a cited
Saint Paul instrument: `rent-regulation` (§ 471.9996 subd. 2 + Leg. Code ch. 193A), `minimum-wage`
(ch. 224, amended by Ord 26-31 four months ago), `local-immigration` (Admin. Code ch. 44; RES 25-1980,
Dec 2025) and `ranked-choice-voting` (ch. 31).

🔴 **`cannabis-policy` REVERSES THE FLORIDA FINDING — do not copy it across.** § 342.13 bars a
Minnesota city from prohibiting cannabis, and rung 4 *is* the state law, so it is blank here while it
was live in Florida.

🔴 **A LEGISTAR SEARCH FOR "ranked choice" RETURNED ZERO AND THE ZERO WAS FALSE.** Saint Paul’s
ordinances say **"ranked voting"**. Search the term the body uses, not the term the ladder uses.

🟢 **Saint Paul has the Legistar public Web API** (client `stpaul`, no key; control passed on
`charlottenc`). **Duluth does not** — `duluth` and `duluthmn` both 500, so Duluth needs HTML work and
should be priced higher per member.
⚠ `RLH RSA` rent-stabilization appeals are single-property determinations, not positions.

⚠ **Saint Paul's mayor reads as Kaohly Her, `is_incumbent` true.** Confirm the current officeholder
against the city's own page before citing the office — a roster label says how someone arrived, not
what they hold now, and a departed official's URL can serve their successor.

### ✅ SLICE 3 IS COMPLETE — 18 members, 630 rows, 28 chairs (2026-10-05)

Tomanek 2 · Jordon Johnson 1 · Desotelle 1 · Clanaugh 0. Nephew gained her first chair, Randorf went
to four — the most in the slice — and five members moved on `local-immigration` alone. Gate `high=0`, verifier clean,
nothing auto-published.

#### 🔴🔴 THE BIGGEST FINDING OF THE SLICE: SPONSORSHIP IS AN EVIDENCE CHANNEL AND NOBODY HAD USED IT

`GET /matters/{id}/sponsors` on the Legistar Web API. It seated **four members at
`local-immigration` 3** off one instrument, Duluth resolution **26-0100R**, which bars city
agencies from using city resources to assist federal civil immigration enforcement except as
required by federal law or court order. Chair 1 is excluded **by the document**: it expressly
preserves compliance with 8 U.S.C. 1373, the statute barring restrictions on immigration-status
information sharing.

▶ **C46 REFUSES A UNANIMOUS VOTE. C37 ADMITS THE SPONSORSHIP.** Nephew's blank already named this
instrument and refused it, correctly, as "adopted unanimously by voice vote". That is true of the
VOTE and it stopped one rule short. **When a measure passes without division, stop asking how
people voted and ask who wrote it.**

Three tools were blind to it at once: `divided_votes.mjs` (not a divided roll call), the member
vote lists, and **every news sweep** — no article in any of the nine corpora names the sponsors;
MinnPost says only "four of their colleagues".

🟢 **And it answers questions prose leaves open.** Forsman thanked "three other councilors" for
what he "put forward"; the sponsor list shows 24-0588R (the $500,000) is Randorf, Nephew, Forsman
and Tomanek, and that **24-030-O, the camping ordinance, has NO sponsors at all** — the
administration brought it. That disproved a sentence already sitting in Forsman's scored row.

#### 🟢 LEGISTAR DETAIL PAGES **ARE** CITABLE — `instruments.md` said they were not

The web GUID is **not** the API's `MatterGuid`. They are different identifiers.

| URL form | Result |
|---|---|
| `?ID=…` alone, or a mismatched pair, or **the API's `MatterGuid`** | 200, **19 bytes** |
| `?ID=…&GUID=<the web GUID>` | 200, **116 KB**, sponsors + full operative text, to curl AND node |

🟢 **AND ONE KNOWN PAIR BOOTSTRAPS THE REST.** `Calendar.aspx` does not expose the pairs, which is
what made this look impossible — but any single matter page does. A `LegislationDetail` page links
every `MeetingDetail` it reached, with that meeting's pair; a `MeetingDetail` page links every matter
on the agenda, with each matter's pair. Seed from any news story that links a Legistar matter and
walk meetings → agendas. That is how 26-005-O was found, and **it settled Randorf**.

🔴 **CUT THE SNIPPET WITH ITS ORIGINAL CASE.** Slicing out of `normalizeText(page)` lowercases it,
which makes a poor published citation and silently fails the gate: the instrument patterns are
**case-sensitive**, so "Chapter 2" in a reasoning never matches "chapter 2" in a snippet. Use
`scripts/stance-news/_legistar_text.mjs`, which returns a case-preserving twin and asserts the two
align before slicing.

#### Rules this slice's last four members paid for

1. 🔴 **FOR A COMMON SURNAME THE MEMBER'S OWN SWEEP IS THE WORST SOURCE.** Jordon Johnson: 700
   files kept on the surname, **9 name him** (1% signal), **0 attributed quotes**. Every passage
   used came from other members' corpora, where **26** articles name him. Read the slice first.
2. 🔴 **A NAME-PRESENCE COUNT IS NOT A COVERAGE COUNT.** 10 of those 26 name him only in the
   council roster sidebar the Duluth News Tribune appends to its local stories.
3. 🔴 **THE AMBIGUITY CHECK HAS NO STOPLIST AND INVENTS PEOPLE.** It dropped 10 of Clanaugh's 23
   usable articles for "Repair", "Represents", "While", "Local" and "Yet" Clanaugh — including the
   candidate forum, his best article. It needs a plausible-given-name test; until then read the
   excluded list by hand.
4. 🔴 **A QUESTIONNAIRE SNIPPET MUST START AT THE MEMBER'S NAME.** `checkNameProximity` windows
   ±500 characters around the SNIPPET START, and a Q&A puts the name at the head of the section —
   2,096 characters above Tomanek's answer. That is what made Mayor Her's questionnaire uncitable.
   It works when the run from name to answer is contiguous; the snippet is then long, and says so.
   ⚠ `TITLE_PATTERN` matches `councilor` and **not the plural `councilors`**, so "BY COUNCILORS
   JOHNSON" does not rescue a common surname.
5. ⚠ **Naming a second instrument in a reviewer note trips `instrument-not-cited`.** "Chapter 2"
   in an aside cost four high findings. Describe an uncitable instrument; do not number it.

#### ▶️ OPEN, IN PRIORITY ORDER

1. ✅ **Sponsorship leads — the list is EMPTY.** Randorf's TIF policy and short-term-rental
   moratorium are **done** (see below), and so are the last two: her **2021 climate emergency
   declaration** and **Kennedy's ordinance integrating the city's LGBTQ+ commission** — both worked
   through 2026-10-06, **neither moves a chair**, three blanks rewritten. See the block below.
2. ⚠ **The pre-2026 sponsor scan is INCOMPLETE.** The API caps at 1000 matters per query and three
   year-windows hit the cap. Nothing ladder-bearing was missed for the four members done here, but
   the record is not exhaustive for the longer-serving members.

#### ✅ THE LAST TWO SPONSORSHIP LEADS — WORKED THROUGH 2026-10-06, NEITHER MOVES A CHAIR

Three blanks rewritten, 630 rows, gate `high=0`, verifier `RE-RESEARCH: 0`, 29 rows in review.

**The 2021 climate emergency declaration** (Randorf, with Sipress, Anderson and **Forsman**; adopted
2021-04-12). 🔴 **ITS OPERATIVE CLAUSES ARE A DECLARATION, A TARGET AND A PLANNING DIRECTIVE.**
C47 refuses a plan directive. The one number is an emissions target for the **city's own** operations
and community — not a requirement about how energy is produced — and this ladder asks how much
government should do to **expand clean energy** (mandates / subsidies / permitting). "Support
renewable energy development" appears **once**, as one bullet among nine subjects the plan should
cover: a subject, not a level. Seeking "state, federal, philanthropic and private" money is not the
public investment of chair 2.
▶ **IT TOUCHES TWO MEMBERS.** Forsman co-sponsored it and his `climate-change` blank is rewritten
for the same reason. ⚠ **The sponsor list is the only place either name appears on it** — a grep of
all nine corpora for "climate emergency" returns three articles, none about this resolution.

**Kennedy's LGBTQ+ commission ordinance** (introduced 2025-10-07, read once, **WITHDRAWN**
2025-10-27), plus the follow-on she co-sponsored, adopted 2025-12-15.
🟢 **RULED CHAIR 2 BY CHRIS CANTRELL, 2026-10-06** — *"make it chair 2"*. The row was blank for one
commit and the blank's reason was a genuine tie: her statement of purpose puts improving equity,
increasing efficiency and strengthening the impact of the work in **one sentence**. *Strengthening*
is chair 2; consolidating advisory bodies for *efficiency* with the enforcement powers untouched is
chair 3. The ruling reads the first as controlling. ▶ **The researcher's blank and the ruling are
both recorded in the row**, so a reviewer sees the tie and who broke it.
The row rests on the ordinance repealing the old article and **rewriting the operative chapter** —
which states it is enforceable through compliance actions by the city, and whose purposes are
effectuated by information, education, mediation, conciliation and enforcement — on the ground she
**added**, and on the standing committee with a vote. Chair 1 is excluded by the instrument: it
mandates nothing of any institution outside the city's own advisory structure.
⚠ **THE GENDER-IDENTITY INSERTION LOOKS LIKE AN EXPANSION AND IS NOT.** The same ordinance adopts
the state human rights act definitions "as it may be amended from time to time", and Minnesota added
that ground in 2023 — so the insertion **conforms** the city code to state law. 🔴 **This was only
visible in the RTF amendment marks.** `MatterTextPlain` shows inserted words with no sign that they
are new, and shows nothing of what was struck.

#### 🟢🟢 `Gateway.aspx?M=L&ID=<API MatterId>` MAKES EVERY MATTER CITABLE — NO MEETING WALK

The block above says a known ID+GUID pair must bootstrap the rest by walking meetings → agendas,
because `Calendar.aspx` does not expose pairs. **It does not.** `Gateway.aspx?M=L&ID=<MatterId>`
302s straight to `LegislationDetail.aspx?ID=<webId>&GUID=<webGuid>`, and the MatterId comes from
`/matters?$filter=MatterFile eq '<file>'` for any file number you can name. Two matters resolved
this way on the first try, at 178 KB and 105 KB.
🔴 **IT TAKES ANY INTEGER AND WILL SERVE A DIFFERENT MATTER.** `_legistar_gateway.mjs` asserts the
file number appears on the page it reached, and exits non-zero when it does not. Do not skip it.
▶ This retires the remaining "readable but not citable" entries for Duluth. `instruments.md` and
the 26-0100R note both record the old limit.

🔴 **THE FILE NUMBER AND THE SPONSOR NAME ARE 545 CHARACTERS APART IN A LEGISTAR HEADER, AND THE
NAME WINDOW IS 500.** No snippet can start at `File #: …` and still carry the sponsor's name. It
does not matter: **a Duluth file number matches NO pattern in `INSTRUMENT_IDENTIFIER_PATTERNS`**, so
naming `25-026-O` in a reasoning obliges no snippet to carry it. ⚠ `Chapter 2` **does** match, and
`\bOrdinance\b` in `NAMES_INSTRUMENT` is **case-sensitive** — a record row whose reasoning says only
"ordinance" in lower case fails `record-no-instrument`. Both cost a high finding here.

🔴 **`/matters/{id}/texts` RETURNS 405 ON `duluth-mn`** — so `_matter_text.mjs` cannot read any
Duluth matter. The route that works is `/matters/{id}/versions` → `[{Key, Value}]` →
`/matters/{id}/texts/{Key}`. **`Key` is the MatterTextId; `Value` is the version number**, and
passing `Value` gives a 404 that reads exactly like a matter with no text.

#### ✅ RANDORF'S TWO EARLIER SPONSORSHIP LEADS — WORKED THROUGH, NEITHER MOVES A CHAIR

Different reasons in each case, and both are worth not re-opening.

**TIF development incentives** (with Forsman and Kennedy, adopted 2025-06-16).
🔴 **THE OPERATIVE CONTENT IS AN ATTACHMENT.** The only resolving clause is that the city "adopts
the policy on development incentives for tax increment financing, attached hereto as Exhibit A".
C51 says the operative section governs — and here it governs **by reference to a document the
legislative record does not render**. Whether that policy sets wage and local-hiring conditions with
repayment (chair 3) or spending limits and a willingness to pass on deals (chair 4) is precisely
what the exhibit would say. Randorf keeps chair 3 on the film incentive's pay-on-delivery mechanism,
which she named herself.
▶ **A framework resolution that adopts an attachment cannot refine a chair on its own.** Reading
Exhibit A is the one thing that would settle it — and would bear on Forsman's chair 4 as well, since
his rests partly on shaping this same policy.

**Short-term rental moratorium** (with Swenson, Nephew and Forsman, adopted 2025-11-10).
🔴 **IT IS A STUDY MORATORIUM ON ITS FACE** — the interim ordinance runs "pending completion of a
city study weighing the need for any amendment to official controls". C47 refuses a study directive
as a chair, and no statement from her says what the study should conclude. It fails on a second,
independent ground too: short-term rental permitting is about how a dwelling may be used, not how
much housing a neighbourhood should hold, which is what `residential-zoning` separates on. Nephew's
blank there is recorded for the same reason.

#### ✅ THE SAINT PAUL CITATIONS ARE FIXED TOO (2026-10-05)

🔴 **THE OLD CITATION WAS A PAGE WITHOUT THE PEOPLE ON IT.** Noecker, Bowie and Jost all cited the
same 47-word agenda row from `MeetingDetail.aspx?LEGID=7306…`. The page is not broken and the
snippet IS on it — but it is an agenda listing: **"Bowie" and "Jost" appear ZERO times on it**,
"Noecker" twice and both ~24,000 characters away, and it carries no roll call at all. The verifier
was right to refuse all three.
▶ **When a citation fails, ask first whether the PAGE can carry the claim.** This one never could.

The meeting-walk found the two that can, both linked from that same agenda row:

| Page | Carries |
|---|---|
| `LegislationDetail` ID 7282238 / GUID 60463898-… | File # **Ord 25-29**, the title, and **"Sponsors: Anika Bowie, Saura Jost, Rebecca Noecker"** |
| `HistoryDetail` ID 33396952 / GUID 808097B7-… | **"Votes (4:3) … Rebecca Noecker Yea … Anika Bowie Yea … Saura Jost Yea … Cheniqua Johnson Nay"**, and "Mover: Saura Jost" |

All three now verify on **3 of 3** sources with no failures. No value, evidence_type or reasoning
changed — a re-source and nothing else. A negative control in the script asserts the OLD page still
fails, so the fix is addressing the real defect.

⚠ **Cheniqua Johnson keeps one failing source, correctly.** Her MinnPost snippet reads "Kim,
Jalali, Yang and Johnson have all expressed interest…" — a bare common surname with no title. Her
reasoning describes it accurately AS a group attribution, so the citation stays and the verifier
declines to publish it. She gained the roll call, which evidences her Nay. **A group attribution is
not a statement by the member, and a verifier refusing it is the system working.**

#### ✅ The campaign-statements ruling is fully worked through

Randorf `local-environment` was the last flagged row: still blank, because the ladder was always
the constraint and not admissibility. A sweep of all 630 rows found the obsolete pre-office
sentence in **three** rows, not the two that were flagged — Randorf `childcare` carried it unnoticed.
It is now in **0 of 630**. Both childcare blanks keep their independent second reason.

---

### ✅ DONE — THE FOUR REMAINING DULUTH MEMBERS (kept: the recipe below is the one to reuse)

Work in `C:/ev-accounts-stances-mn` on branch `knight/stances-mn`. Everything below is measured,
not assumed; nothing here needs re-deriving.

🔴 **THE TOOLCHAIN CHANGED UNDER THIS SECTION ON 2026-10-05 — READ THE SAINT PAUL RE-SWEEP BLOCK
BELOW BEFORE RUNNING THE RECIPE.** Six defects were fixed in `attribute_quotes.mjs`,
`attribution.mjs` and the sweeps, and three new tools exist. The per-member recipe is now:

```bash
node scripts/stance-news/sweep_duluth.mjs <slug> "<Full Name>" ["<Alt>"]   # Reformer REMOVED from it
node scripts/stance-news/sweep_reformer.mjs <slug> "<Full Name>"          # curl; QUERY_GAP_MS=6000 FETCH_GAP_MS=2000
node scripts/stance-news/_corpus_profile.mjs <slug> "<Full Name>" ["<Alt>"]   # 🔴 BEFORE reading anything
node scripts/stance-news/attribute_quotes.mjs <slug> "<Full Name>" ["Alt|Spellings"]
node scripts/stance-news/_triage_quotes.mjs <slug> [--topic <key>]        # reading ORDER, never a finding
node scripts/stance-news/quote_context.mjs <slug> <n>                     # settle every quote by reading
SURNAME=<Surname> node scripts/stance-news/quoted_passages.mjs <slug>     # what the strict rule dropped
```

⚠ **Reformer 429s after roughly four members.** It is a budget across runs, not per run: raise the
gaps, do not retry at the same speed. `sweep_reformer.mjs` controls at BOTH ends of a run and exits
rather than record a throttled zero — **a genuine +0 and a blocked +0 are identical in a log.**
⚠ **Duluth's Reformer yield is ONE article across all six members**, so expect nothing and measure
anyway. All six are now searched; their rows say so.

| Member | Seated | Expect |
| --- | --- | --- |
| **Terese Tomanek** | 2020-06-12, Council President 2020–2026 | the real record of the four — six years, chaired the body, one of the four who prepared the 2024 public safety package |
| **Jordon Johnson** (at large) | **2026-01-05** | ~9 months. 🔴 **Johnson is a very common surname — expect the Kennedy problem** (her corpus was 94% other Kennedys). ⚠ **Cheniqua Johnson of Saint Paul is in THIS SAME BATCH** — do not cross them |
| **Diane Desotelle** | **2026-01-05** | ~9 months. Rare surname. Voted nay on the Housing Trust Fund appointments and against tabling the eviction moratorium |
| **David Clanaugh** | **2026-01-05** | ~9 months. Rare surname. **Co-authored the eviction moratorium resolution with Durrwachter** and is quoted on it — the best single lead of the three newcomers |

⚠ **Three of the four took their seats in January 2026**, so a documented zero is a likely and
correct outcome. Nephew is the precedent: 35 rows, 0 chairs, every blank reasoned.

#### The recipe, per member, in order

```bash
cd /c/ev-accounts-stances-mn/backend
set -a; . /c/EV-Accounts/backend/.env; set +a      # this worktree has no .env of its own

node scripts/stance-news/_office_record.mjs duluth-mn <Surname>          # confirm the term
node scripts/stance-news/member_votes.mjs duluth-mn 2024-01-04 138 "<Surname>"   # their 31 divided votes
node scripts/stance-news/sweep_duluth.mjs <slug> "<Full Name>" ["<Alt>"]  # ~20 min; watch <out>/_progress.log
node scripts/stance-news/scrub_corpus.mjs <slug>                          # belt and braces; the sweep also scrubs
node scripts/stance-news/attribute_quotes.mjs <slug> "<Full Name>"        # CANDIDATES, not settled
node scripts/stance-news/quote_context.mjs <slug> [n ...]                 # READ each one in context
SURNAME=<Surname> node scripts/stance-news/quoted_passages.mjs <slug>     # what the strict rule dropped

# write _<slug>_rows.mjs modelled on _kennedy_rows.mjs, then:
node scripts/stance-news/_<slug>_rows.mjs
node scripts/stance-news/merge_rows.mjs <batch> <batch>/_rows/<slug>-rows.json <batch>/_rows/<slug>-evidence.json
npx tsx scripts/stance-gate.ts --dir <batch>                   # must be high=0
npx tsx scripts/verify-stance-research.ts --dir <batch>        # dry run; want failed=0
```

🟢 **The 15 scope blanks are already generated** for all four, at
`<batch>/_rows/<slug>-blanks.json` — **on disk in this worktree only, because `_rows/` is gitignored.**
If they are missing, regenerate with
`node scripts/stance-news/duluth_scope_blanks.mjs "<Full Name>" > <batch>/_rows/<slug>-blanks.json`.
They are a fact about the office, identical for every councilor, and a control asserts the wording
still matches the rows already committed. Do not regenerate or reword them.

#### The traps, in the order they will bite

1. 🔴 **Check how each outlet spells the name before sweeping.** WDIO writes "Durwachter" with one
   `r`. Pass every variant; the sweep now sweeps and filters on all of their surnames.
2. 🔴 **Measure the noise ratio for a common surname.** Count how many corpus files actually contain
   the FULL name. For Kennedy it was 23 of 359. The sweep keeps on the surname alone and cannot see this.
3. 🔴 **`attribute_quotes` produces MISATTRIBUTIONS — never write a row from its list without opening
   the article.** Across this slice it attributed the tenants’ organiser, a former councilor and the
   US Health Secretary to the wrong people. `quote_context.mjs` is how you settle it.
4. 🔴 **A thin yield is usually the tool.** Every one of these looked like "rarely quoted": curly-only
   quote matching, straight quotes mis-pairing, a title list without "Councilor", a middle name
   parsed as the surname, a middle initial defeating the ambiguity check. `_attr_selftest.mjs` has
   14 controls — **run it after touching the matcher**.
5. 🔴 **Snippets: >= 25 words, verbatim, cut from the fetched file, and the member’s name within 500
   characters.** For a COMMON surname the verifier also needs a title qualifier within 30 characters,
   so prefer "District N Councilor <Full Name>". A signed op-ed fails this — take the passage next to
   the author bio.
6. 🔴 **Read the agenda item AND the other item on the same agenda.** Durrwachter voted against the
   council’s tenant ordinance and for the tenants’ stronger one; her nay inverts if read alone.
7. 🔴 **A 5-4 minority can hold both poles**, and a lone-dissent PATTERN can be procedural rather than
   political — Durrwachter’s five were about vetting and disclosure, and she wanted the projects built.
8. ⚠ **Duluth’s enacted ordinance text is readable via the Legistar API and NOT citable** (the detail
   page returns a 19-byte 200; Municode is a JS shell). Read it to pick the chair, cite the reporting.
9. 🟢 **CAMPAIGN STATEMENTS COUNT (ruling 2026-10-05, Chris Cantrell). USE THEM.** This reverses how
   the first six members were researched. A candidate’s own words about the office they went on to
   hold are statement evidence like any other. **Date-stamp every such row in the reasoning** so a
   reviewer can weigh staleness, and keep the ordinary bar: the statement must still name a chair.
   🔴 **AND IT NEEDS A LINK. A SOURCED STANCE.** A campaign statement is evidence on exactly the same
   terms as any other: a fetchable page carrying the words verbatim, at least 25 of them, with the
   person named within 500 characters. A remembered position, a party platform, or an aggregator is
   not a source, and vote411.org and thevoterguide.org cannot be cited on any row at all.
   🟢 In practice this slice is fine: the campaign material is in WDIO and Duluth News Tribune
   articles already sitting in the members’ corpora, so each row can carry a real citation.
   ⚠ C44 is untouched — it is about **votes** cast before the seat, and those stay excluded.

#### 🟢 RULING 2026-10-05 — campaign statements count, and what that reopens

Chris Cantrell: *"campaign statements count, use them going forward"*.

The first six Duluth members were researched under the opposite assumption, and several blanks say
so in their reasoning. The ruling is forward-looking, so nothing is rewritten automatically — but
these rows were decided ON the exclusion and should be revisited once the four are done:

| Member / pair | What was excluded | Likely effect |
| --- | --- | --- |
| **Nephew** `housing` | Nov 2023: wants more supportive housing, and *"the Duluth City Council should focus changing city ordinances, in order to build more homes"* | 🔴 **The one that matters.** Her campaign remarks were her only substantive housing material, and she is currently a documented zero across all 35 rows |
| **Nephew** `economic-development`, `residential-zoning` | the same campaign round, on revenue and on building more homes | worth re-reading; neither was clean before |
| **Randorf** `local-environment` | **2019**: livable-wage jobs *"but not at the expense of the Lake Superior watershed"* | ⚠ two terms and six years back. Admissible under the ruling, but date-stamp it and let the reviewer weigh it |
| **Durrwachter** `childcare` | 2023 meet-and-greet, reporting what residents told her | no change — that blank carries a second, independent reason: it names no rung |

#### ✅ NEPHEW RE-RESEARCHED 2026-10-05 — THE CONTROL, AND ITS ANSWER IS ZERO

She was chosen as the control precisely because she was a documented zero across all 35 rows, so
any chair gained would be attributable to the ruling alone and to nothing else.

**Result: still 0 chairs. 5 rows replaced, all still blank.** `high=0`, verifier clean, and the 15
chairs already seated in this batch all still verify.

🔴 **ADMISSIBILITY WAS NEVER THE BINDING CONSTRAINT — THE LADDER WAS.** Her campaign material is
real, in her own quoted voice, fetchable, and easily over the 25-word bar. It still seats nobody,
because it names *subjects* and not *rungs*:

- `housing` — she argues supply ("creating just more housing units in general will take pressure
  off the system"; the council "should focus changing city ordinances, in order to build more
  homes") but never names subsidies (chair 4) or market pricing (chair 5), and her in-term position
  is a binding cap on vacation-rental licences, which points at chair 3 instead. Three chairs stay open.
- `economic-development` — her remarks are a **sequencing** argument (housing must come before
  growth), made twice. Every rung of that ladder is about business incentives. **Different axis.**
- `growth-and-development` — the same sequencing argument. It states a precondition for growth, never a pace.
- `homelessness-response` — 🔴 **this row was never on the revisit list and should have been.** The
  forum put homelessness *directly* to the candidates and her answer was about nonprofit supportive
  housing. The ladder asks how much to **spend**; "more of these programs need to be encouraged" is
  not a funding level. ▶ **The exclusion operated SILENTLY — a row whose reasoning never mentioned
  campaign material had still been decided without it.** Do not trust the flagged list as complete.
- `residential-zoning` — "changing city ordinances" names no density level.

▶ **STILL OPEN: Randorf `local-environment`** (the 2019 watershed remark). Not yet revisited.
✅ The false sentence — *"Statements she made as a candidate in the 2023 campaign are not used…"* —
is now in **0 rows**, down from 3. A positive control confirmed the detector matched all 3 first.

▶ **Do the four remaining members next, applying the ruling from the start.** Replace pairs rather
   than append (`merge_rows.mjs` does this; it replaced exactly 5 and touched no other member).

---
#### 📁 THE SAINT PAUL CORPORA LIVE OUTSIDE THE REPO

`C:/ev-accounts-corpora/stance-news-mn/` — 2,137 files, about 96 MB, for all eight Saint Paul
members (bowie, cjohnson, coleman, jost, kher, kim, noecker, yang). These are the **re-swept**
articles that took the batch from 256 readable to 810.

🔴 **EVERY DULUTH CORPUS IS IN GIT AND NO SAINT PAUL ONE EVER WAS**, and nothing said so. They are
not gitignored — the 2026-10-05 re-sweep committed with explicit pathspecs (rule 3, correctly) and
the articles were simply never staged. The gap surfaced only when `check:deletable` refused to
delete the worktree over 2,137 unique files.
▶ **RULE 3 AND "COMMIT YOUR OUTPUTS" PULL AGAINST EACH OTHER.** A pathspec commit protects you from
another session's `git add -A` and silently leaves your own new files behind. After a sweep, list
what is untracked before you finish.
⚠ They were byte-compared file by file before the worktree was removed, with a positive control
confirming the comparison could see a tampered byte. Re-sweeping them is not cheap: roughly 20
minutes per member, and Reformer 429s after about four.

#### ✅ APPLIED 2026-10-06 — 30 ROWS ARE IN THE ADMIN REVIEW QUEUE, ALL PENDING

`verify-stance-research --apply --editor-id <chris@empowered.vote>`:
`pushed=0 reviewed=30 left-alone=0 not-in-admin-queue=0 stamped=18 errors=0`. Confirmed in
production: `inform.stance_research_review` holds **30 rows for `2026-10-04-knight-mn-cities`,
30 pending, 17 people**. Nothing auto-published, which is correct — the batch runs in
`review-all` mode and `AUTO-PUSH` was 0.

🔴🔴 **AND THE APPLY IS WHERE WE LEARNED SLICES 1 AND 2 WERE NEVER APPLIED.** This file said
Charlotte's five and Florida's two "sit in the admin review queue awaiting human approval".
They do not. Measured 2026-10-06, before this run: the queue held **four batches, all from
June 2026**, and no `inform.politician_answers` row had been written since **2026-09-27** —
days before either PR merged.
▶ **MERGING THE PR IS NOT PUBLISHING.** A merged branch means the research is in the repo; the
rows reach a reviewer only when somebody runs `--apply` against production. Slice 3 is the
first of the three to have had it run.
▶ **CHECK THE QUEUE, NOT THE TRACKER.** Two sentences in this file asserted a production state
nobody had queried. The query is one line:
`SELECT batch_id, count(*) FROM inform.stance_research_review GROUP BY batch_id;`
⏳ **OPEN: slices 1 and 2 still need `--apply`.** Their batch directories are
`2026-10-02-knight-clt-city` and `2026-10-03-knight-fl-cities`.

#### 🔴🔴 `reasoning` IS VOTER-FACING, AND 21 OF 30 SCORED ROWS CARRIED PIPELINE BOOKKEEPING

Found 2026-10-06, at the point of publishing. `writeVerifiedStance` writes `reasoning` straight into
`inform.politician_context`, and `Citations.jsx` renders it **verbatim** under "Why this position?".
21 of this batch's 30 scored rows would have published internal bookkeeping to voters:

| What was in the voter prose | Example |
|---|---|
| Correction logs | *"🔴 Correction, 2026-10-05: this row previously opened by saying Forsman put forward…"* |
| Internal rule codes | *"C46 governs votes; C37 governs sponsorship"* |
| Ruling notes naming the operator | *"Ruled chair 2 by Chris Cantrell on 6 October 2026"* |
| Snippet mechanics | *"a shorter cut would not carry her name close enough to be attributable"* |
| Stale claims | *"Resolving that URL is the one thing that would settle her row"* — settled the day before |

🔴 **A SENTENCE-LEVEL REGEX SPLIT WAS TRIED FIRST AND HAD TO BE THROWN AWAY.** It read the SHAPE of
a sentence and not what it said, and failed in both directions at once:
- It **orphaned continuations.** *"Two things the reviewer should weigh."* matched; the two things
  did not, and would have stayed behind as a dangling fragment.
- It **deleted evidence.** *"The re-swept corpus adds her own account of why, which states the chair
  directly: …"* matched on its bookkeeping clause and would have taken Jost's quotation with it.

▶ **THE REVIEWER TAILS IN THIS BATCH ARE MOSTLY BALANCING FACTS** — what cuts the other way, what
the record shows that does *not* support the chair. Deleting them makes a row one-sided, which is
worse for a voter than leaving the bookkeeping in. 🟢 **The rule is: strip the bookkeeping, keep the
caveat, and reword it as plain prose.** A voter benefits from "one qualification: this chair names
major employers and her instruments are housing". A voter has no use for "C46".

`_voter_prose_rows.mjs` does it with a hand-written replacement table. **Every `old` string is
asserted present and asserted unique**, because a replacement that silently no-ops is a row that
ships bookkeeping to a voter. Controls: no rule code, glyph, "reviewer", "this row", ruling note or
corpus bookkeeping may survive; the row must still name a chair; a `record` row must still name an
instrument; and the prose may not lose more than 35% of its length. Removed text is kept verbatim in
`editor_note`. 21 rows, −0% to −19%, gate `high=0`, verifier `RE-RESEARCH: 0`.

⚠ **Write the next slice this way from the start.** Put the caveat in the reasoning and the
bookkeeping in `editor_note` as you go; retrofitting 21 rows costs far more than writing them right.

#### Finishing

Commit with an explicit pathspec, then push. If push protection rejects it, a scraped page contained
someone else’s key: run `scrub_corpus.mjs`, amend, push again. **Never allowlist the secret.**
When all four are done, update the slice table, the chair count, and open the PR.

---

## 🔴🔴 SAINT PAUL WAS RE-SWEPT AND RE-RESEARCHED, 2026-10-05 — 4 CHAIRS BECAME 11

**All eight members redone.** The 15 scope blanks each are facts about Minnesota law and were
preserved untouched; the ~20 searched blanks each were rewritten. Gate 490 rows `high=0`,
`RE-RESEARCH: 0`, 22 rows in review. Nothing auto-publishes.

| Member | Chairs before → after | New |
| --- | --- | --- |
| **Noecker** | 1 → **3** | `economic-development` 4, `residential-zoning` 4 |
| **Coleman** | 0 → **2** | `homelessness` 3, `local-immigration` 3 |
| **Her** (mayor) | 0 → **1** | `local-immigration` 1 |
| **Kim** | 0 → **1** | `housing` 4 |
| **Yang** | 0 → **1** | `ranked-choice-voting` 2 |
| Cheniqua Johnson · Bowie · Jost | 1 → 1 | confirmed, better evidenced |

### Why it was redone — two silent zeros, and neither raised an error

1. 🔴 **A QUARTER OF THE CORPUS WAS NEVER ON DISK.** Saint Paul was swept before the corpus-key
   fix, so filenames were `base64url(url).slice(0,60)` and articles overwrote each other: **342
   named, 256 written, 86 lost.** Noecker lost 26 of 77. Yang's rows claimed *"every passage in the
   remaining 47 was read"* when 39 existed.
2. 🔴 **MINNESOTA REFORMER SUPPLIED ZERO TO EVERY CORPUS IN THE SLICE**, both cities, while 490 rows
   named it as searched. It refuses node's `fetch` at the **TLS layer** — 403 and 5,795 bytes where
   `curl` with the same UA gets 200 and 150,559. ▶ **A USER-AGENT IS NOT A CLIENT.** Profile with
   the client that will do the work, and count what each outlet CONTRIBUTED per run.

**Result: 256 readable articles → 810.** Reformer alone added 155 to Saint Paul (Kim +61, Coleman
+37, Her +25, Yang +21) and **one** across all six Duluth members. Coleman's `rent-regulation`
evidence and Noecker's both came from Reformer articles no sweep had ever fetched.

### Rules this cost, beyond the two above

- 🔴 **THE AMBIGUITY CHECK ASSUMED WESTERN NAME ORDER.** 18 of Yang's 34 quotes came from articles
  that never name her — Kaying Yang, the Chinese foreign minister **Yang Jiechi**, Korean officials.
  `<First> Yang` never matches a surname-first name. Fixed with an **article-level gate**: the piece
  must name the member in full or no quote in it is theirs. Saint Paul, with Yang, Her, Vang, Xiong
  and Thao, is the worst place for this.
- 🔴 **ARTICLE-LEVEL AND QUOTE-LEVEL TAKE OPPOSITE ANSWERS.** Requiring the full name *beside the
  speech verb* yields **0 quotes for Mayor Her** — newsrooms name her once then write "Her said".
  Which articles are about someone, and which quotes are theirs, are different questions.
- 🔴 **CONSECUTIVE QUOTES BELONG TO THE LAST-NAMED SPEAKER.** A rec worker's testimony about having
  been homeless was attributed to Council President Noecker because the next sentence began
  "Noecker said…". ⚠ My first fix — reject quotes ending in terminal punctuation — dropped 24 of
  Her's 88, including *"…?" Her asked.* The discriminator is a **preceding attribution to a
  different named person**, not punctuation.
- 🔴 **`nameRe` REGEX-ESCAPED THE ALTERNATION** `attribute_quotes` built, so every alternate spelling
  was inert and matches fell back to the bare surname. It takes an **array** now.
- 🔴 **THE GATE MUST ACCEPT first+surname.** `"Kaohly Vang Her"` skipped **221 of her 265 articles** —
  every one printing the ordinary "Kaohly Her". A middle name is optional in print.
- 🔴 **A POSITION THAT CAN BE READ BUT NOT CITED DOES NOT PUBLISH.** Three times: Mayor Her's
  questionnaire (name 2,788 chars from the passage), Cheniqua Johnson's housing (702 and 1,693),
  Jost's transportation (source will not verify). All three are **recorded in their blanks** with
  what would settle them, so the next pass finishes rather than rediscovers them.
- 🔴 **URLS COME FROM THE CORPUS INDEX, NEVER A CONSOLE DISPLAY.** I composed a MinnPost URL from a
  line truncated at 74 characters and it 404'd. The verifier caught it. A truncated field is not a
  short value.
- 🟢 **`_corpus_profile.mjs` BEFORE READING ANYTHING.** Collision loss, signal ratio, same-surname
  ambiguity, campaign-era count, per-outlet contribution. Yang is 16% signal, Kim and Coleman 9%:
  the raw file count is the flattering lie every time. It is also what exposed the gate bug, because
  it said 265 of 265 name her while the gate claimed 221 did not.
- ⚠ **MPR NEWS IS READABLE AND NOT CITABLE** — Playwright renders its search, but its article pages
  are hydrated client-side (132 KB of HTML, 99 characters of text). **Racket is blind**: the same 12
  boilerplate links for a real query and for gibberish. Both stay named as uncovered. Do not retry.

### Consistency checks worth keeping

🟢 **Four members seated off ONE ordinance, and the chairs track the votes.** Noecker, Bowie and
Jost co-authored Ord 25-29 (the new-construction exemption) and sit at `rent-regulation` **3**;
Cheniqua Johnson voted against it and sits at **2**.
🟢 **`minimum-wage` is blank for Coleman, Yang and Kim for the SAME reason.** All three proposed
eliminating the youth training wage. It excludes holding or removing the floor and does not choose
among the three rungs that remain. The clearest instrument Coleman has still earned no chair.

---

**SAINT PAUL (ORIGINAL PASS, SUPERSEDED ABOVE)** — seven councilmembers and the mayor, 280 rows. **4 chairs**, all on `rent-regulation`:
Noecker 3 · Bowie 3 · Jost 3 · Johnson 2. Every row is queued for human review; nothing publishes.

**✅ NEPHEW RE-RESEARCHED UNDER THE RULING — 35 rows, still 0 chairs.** 5 blanks rewritten with the
campaign material read and weighed. See the control write-up above: the bar that held her out was
never admissibility, it was that her statements name subjects rather than rungs.

**✅ RANDORF IS DONE — 35 rows, 3 chairs** (`homelessness` 3 · `rent-regulation` 3 · `economic-development` 3).
**✅ DURRWACHTER IS DONE — 35 rows, 2 chairs** (`climate-change` 1 · `economic-development` 2).
**✅ FORSMAN IS DONE — 35 rows, 2 chairs** (`homelessness` 3 · `economic-development` 4).
**✅ KENNEDY IS DONE — 35 rows, 2 chairs** (`economic-development` 4, alongside Forsman ·
`civil-rights` **2**, ruled 2026-10-06 — see the sponsorship block above). She argued
for the Sofidel package on the floor — *"I don’t want the perfect to get in the way of the good …
We need this economic development. I don’t think this is the time to stand back"* — and is one of
the three DEDA councilors who introduced the TIF policy that sets the limits.

**▶️ FOUR PEOPLE REMAIN, ALL IN DULUTH:** Jordon Johnson, Terese Tomanek, Diane Desotelle and
David Clanaugh. Desotelle, Clanaugh and Johnson took their seats in January 2026, so expect thin
records; Tomanek has served since 2020 and chaired the council in 2026.

🔴🔴 **A COMMON SURNAME MAKES THE CORPUS 94% NOISE, AND THE SWEEP CANNOT SEE IT.** The keep-filter
matches the SURNAME alone, so her sweep kept **359 articles of which only 23 name Janet Kennedy** —
the rest are RFK Jr., JFK, Justice Kennedy, the Kennedy Center, Harvard Kennedy School. The
ambiguity check then excluded 290, leaving 69 usable. ▶ **Measure that ratio before trusting a
corpus size**; for Durrwachter the same filter was harmless.

🔴 **A MIDDLE INITIAL DEFEATED THE AMBIGUITY CHECK.** *"Robert F. Kennedy Jr."* contains no
`[A-Z][a-z]+ Kennedy` pair, so those articles read as unambiguous and **three of ten attributed
quotes were the US Health Secretary**. The regex now allows one or two initials: exclusions rose
207 → 290 and attributions fell 10 → 7, with a regression control confirming Forsman stayed at 39.

⚠ **Her own sweep MISSED the paper-mill article** that another member’s sweep caught. A per-member
corpus is not exhaustive, and a citation need not come from the member’s own corpus.
🔴🔴 **THIS LINE WAS WRONG AND STOOD FOR A DAY: `kennedy` IS NOT IN `COMMON_LAST_NAMES`.** It used
to read "Kennedy is a common surname for `checkNameProximity` too, which then demands a title
qualifier within 30 characters". Measured 2026-10-06: `COMMON_LAST_NAMES.has('kennedy') === false`
(`johnson` is true). The verifier never demanded a title for her, so her two
`economic-development` snippets carrying *"5th District Councilor Janet Kennedy"* are good practice
that **nothing was enforcing**. ▶ **The guard that would have caught a 94%-noise corpus was not the
verifier, and believing it was is how a corpus problem gets left to one tool that cannot see it.**
▶ **A guard you have not watched fail is a guard you have not seen run.**

**✅ MAYOR REINERT IS DONE — 35 rows, 3 chairs** (`homelessness` 5 · `residential-zoning` 4 ·
`growth-and-development` 4). The strongest member in the slice: 146 of 398 articles name him.

🟢 **`homelessness` NOW SEPARATES THE MAYOR FROM HIS OWN COUNCIL — Reinert 5, Randorf 3, Forsman 3.**
He proposed a misdemeanor carrying up to $1,000 and 90 days; the council refused it and cut the
penalty to a $200 fine. 🔴 **His argument EXCLUDES chair 4 by name** — the civil citation is the
city's only tool and *"individuals can literally tear them up and walk away"* — and excludes chair 3
in reverse, because chair 3 routes people to services *rather than* the criminal justice system and
he argues the criminal connection is what makes services reachable.

🔴 **RHETORIC AND INSTRUMENT POINTED AT DIFFERENT CHAIRS, AND THE INSTRUMENT WON.** On zoning he says
*"We need all the kinds, in all the places"*, which reads as chair 5. The ordinance he backs allows
**fourplexes in Residential-Traditional**, cuts lot widths and setbacks and raises height maximums —
chair 4. It neither ends single-family zoning nor allows any type on any lot. ▶ **Read what the
instrument does before seating the slogan.**

🟢 **A MAYOR LEAVES ALMOST NO RECORD IN LEGISTAR, and the near-zero is a real finding.**
`mayor_actions.mjs` over **1,914 items in 76 meetings** returns exactly one match: 25-016-O *"passes
without Mayoral signature"*. He has vetoed nothing. The pattern fired once, so the zero is measured,
not a broken detector. ⚠ Not signing has two readings and no reporting says which — a lead, never a
chair. ▶ **A mayor is researched from proposals and statements.**

