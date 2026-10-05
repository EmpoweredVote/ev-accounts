# Municipal stance evidence toolchain

Built for the Knight Cities stance programme. Tracker:
[`.planning/knight-foundation/stances.md`](../../../.planning/knight-foundation/stances.md).

**Municipal stance evidence is local reporting and members' own words, not the vote record.**
Roll calls are the *state legislature* method. Every divided policy vote on Charlotte City Council
failed as chair evidence — omnibus, housekeeping, or unanimous — so these scripts build and mine a
local-news corpus instead.

Each script exists because a plausible-looking result turned out to be a bug. The comments say which.

## Run order

```bash
python sweep.py <cfg.json>                 # name x topic, for a big outlet
python small_outlet.py <out> <cfg.json>    # name only, for a small one — run BOTH
python funnel.py <corpus> <cfg.json>       # blocks -> named -> quoted -> attributed
python all_attributed.py <corpora> <cfgs>  # the whole judgement set, usually one screen
python passages.py <corpus> "<Member>" [topic]
# then write rows (see build_rows.example.py) and:
python emit_csv.py <batch-dir> <rows.json>
npx tsx scripts/stance-gate.ts --dir <batch-dir>
npx tsx scripts/verify-stance-research.ts --dir <batch-dir>
```

`legistar_matters.py` + `legistar_votes.py` pull per-member roll calls where a city runs Legistar
(`webapi.legistar.com/v1/<client>`, public, no key). Useful for ruling instruments **out** — see the
traps below before treating a vote as evidence.

## Config

```json
{"out": "<corpus-dir>",
 "outlets": [{"name": "WFAE", "search": "https://www.wfae.org/search?q={q}"}],
 "members": {"Jane Roe": ["Jane Roe", "Councilmember Roe"]},
 "topics":  {"housing": "affordable housing"}}
```

`members` maps the **exact** `full_name` from `politicians.json` to its search aliases.

## The rules these encode — each one cost a wrong answer

1. 🔴 **Query breadth must match outlet size, in BOTH directions.** On WFAE, name-only returns the
   top ~25 results for a person — election and process coverage — and adding the topic surfaced
   9–15 new articles per query. On The Bradenton Times the reverse: `Kocher` returns 20 results
   including her own column, while `Jayne Kocher economic development incentives` returns none and
   falls back to the default listing. **Run both and merge; they are complementary.** Barnebey
   scored 19 under one and 4 under the other.

2. 🔴 **Do not tie link extraction to one publisher's URL shape.** A pattern requiring an absolute
   href with a `/2026-10-03/` date path — an NPR convention — silently excluded Queen City Nerve,
   which publishes at `/slug/` and is the outlet that covers Charlotte council meetings with direct
   member quotes. It also produced "Bradenton has no coverage" four separate ways: the live WUSF
   host is `www.wusf.org` (the old one renders results client-side), wusf.org serves **relative**
   hrefs, The Bradenton Times uses `/stories/<slug>,<id>` with `search_filter=`, and its result
   links end in `?`. `links.py` resolves against the page and strips the query.

3. 🔴 **A quote must be ATTRIBUTED to the member, adjacent to a speech verb.** A proximity test let
   through an opponent's attack — quoted, on topic, naming him — because *"Commissioner Matlow, I
   think it is unacceptable," he said* put the surname near a verb.

4. 🔴🔴 **CONFIRM IDENTITY FROM THE ARTICLE'S OWN INTRODUCTION.** Eight surname collisions across
   two cities: Kelly Lee Owens and Jessica Lea Mayfield (musicians), Michael Mayo (jazz singer),
   Baker Mayfield, Chester Higgins (photographer), a salsa musician Rosado, a death-row inmate
   Pardo, and — the dangerous one — **State Senator Julie Mayfield of Asheville**, on topic, quoted,
   correctly attributed, and not the Charlotte councilwoman. The article never said "LaWana".

5. ⚠ **A uniform answer is a broken detector.** Zero across a whole city, or an identical count for
   every query, is the signature. Every script prints per-query counts for this reason, and
   `funnel.py` exists so a steep drop can be attributed to a stage instead of guessed at.

6. ⚠ **Read the agenda item text before trusting a vote title.** Charlotte's "Tree Ordinance" text
   amendment is, by its own explanation, numbering fixes and two deleted words. The UDO consolidates
   **eight** ordinances in one vote. The 2040 Plan spans nine policy areas and calls itself
   aspirational. The data-centre moratorium passed **11–0 twice**, which C46 refuses.

7. ⚠ **Motion sponsorship is not a position here.** Charlotte's distribution is procedural — Driggs
   moved 31 substantive items, mostly procurement.

8. ⚠ **Some civic WAFs refuse a browser UA.** `charlottenc.gov` 403s a Chrome UA on curl's TLS
   fingerprint (449 bytes) and serves bare curl (286 KB) *and* the verifier's own `EmpoweredVoteBot`.
   Python `urllib` is refused whatever UA it sends. Everything here shells out to curl with no UA.
   Its planning pages return **HTTP 200 carrying an Akamai challenge**.

9. ⚠ **Write the script to a file.** Building regexes through nested shell→python quoting corrupted
   a pattern three times in one session, once turning `\b` into a literal backspace byte.

## Scope is a per-rung, per-STATE question

Before researching a city, verify its state's preemptions and record which rungs survive. North
Carolina and Florida differ, and copying one to the other would have been wrong twice.

🔴 **The worst failure mode is not a blank — it is a confident wrong row.** Where a statute removes
an option, the rung describing that removal is an accurate description of **state law and of
nobody's position**: Florida's rent-regulation rung 5 and ranked-choice rung 5 both read this way,
and working backwards from the outcome would seat every member there.

---

## Minnesota additions (2026-10-04) — three Node scripts

The Python scripts above build a corpus by crawling an outlet's HTML search. Minnesota needed a
different shape, because **four of six outlets were blind to HTML search** (see the slice's
`outlets.md`). These three are the working method, and each encodes a failure that cost real time.

```bash
node sweep_member.mjs <slug> "Primary Name" ["Alt Spelling" ...]   # corpus, WP REST + site search
node attribute_quotes.mjs <slug> "First Last" ["AltFirst|AltFirst2"]  # quotes safely attributed
node divided_votes.mjs <legistar-client> <YYYY-MM-DD> [bodyId]     # every C46-eligible vote
```

### `divided_votes.mjs` — run this FIRST for a new city

It scans a whole year of roll calls and reports only the votes with 10% or more against, which is
C46's threshold. Saint Paul 2026: **1,059 items, 918 with a roll call, 8 divided, none seating a
chair.** One number prices a city's record evidence before any topic searching begins.

### `sweep_member.mjs` — pass every spelling of the name

🔴 **A member's own name can be spelled more than one way, and the database spelling is not always
the newsroom's.** `HwaJeong Kim` found 8 articles; `Hwa Jeong Kim` found 27. Searching `HwaJeong`
alone returned the same 8, which is what made the thin result look settled. Pass the joined, spaced
and hyphenated forms; the row still uses the database `full_name`.

### `attribute_quotes.mjs` — two rules, both paid for

1. 🔴 **The speech verb is required.** With it optional, a school principal's quote was attributed to
   a councilmember because the *next sentence* began with her name.
2. 🔴 **An article naming a second person with the same surname is dropped**, because bare-surname
   attribution cannot be trusted in it. A stoplist keeps sentence starters (*In Yang's response*,
   *When Yang*) from counting as first names — without it the filter excluded nearly everything and
   produced a false zero of its own.

⚠ **Known false negative**: requiring the verb immediately after the quote misses a real attribution
when an appositive intervenes — *"…" Council Member Rebecca Noecker, who represents downtown St.
Paul, said last year.* **Re-read what the strict rule drops**; it is for finding candidates safely,
not for settling attribution.

⚠ **A surname that is an ordinary English word** (Her) cannot use bare-surname matching at all.

⚠ **The worst case is a multi-candidate questionnaire round-up**, where many candidates answer the
same question in sequence and the member's name appears elsewhere on the page. A quote was
misattributed that way and had to be corrected after it was committed. In a round-up, take
attribution from the candidate's own labelled block, never from the page.

### Reading an ordinance

🔴 **Never describe what an ordinance changed from its plain text.** Legistar's `MatterTextPlain`
renders it with the strikethrough invisible, so it reads as the text *before* the amendment — this
produced a wrong mechanism in three already-seated rows. Use `MatterTextRtf` and track `\strike` /
`\ul`; for a .docx attachment, read the Word revision marks in `word/document.xml`.

🔴 **A PDF cannot be cited.** `verificationFetch` throws `not_html`, so minutes and amendment
attachments — exactly where the per-member detail lives — are unusable as sources. Saint Paul's
amendment-level record is effectively uncitable; cite reporting instead, or record the row as a
blank for want of a citable source and say so.

---

## Duluth additions (2026-10-05) — four more failures, all of them confident wrong answers

### `divided_votes.mjs` is not optional, and a hand sample is not a measurement

Duluth was recorded as having **no per-member roll calls at all**, from a hand sample of three
meetings and two matters. Running this script over 40 meetings found **10 divided votes**, every
dissenter named by full name.

🔴 **The defect was the SAMPLE, not the detector.** Both hand probes returned a *true* empty — those
items did pass by unanimous voice vote. Generalising from them to the city was the error.
⚠ Duluth records a roll call for **12 of 905 items (1.3%)**; Saint Paul for 918 of 1,059 (87%). A
1.3% rate is exactly what "no roll calls" looks like from three meetings. ▶ **Run the whole-year
script before characterising a city's record.** It costs four minutes.

`duluth_vote_detail.mjs <matter files>` prints the full per-member tally and the action text for
named matters, which is what tells a tabling vote from a vote on the merits.

### 🔴🔴 A divided vote is only legible against the measure it COMPETED WITH

Duluth voted on two tenant ordinances the same night: the tenants' union petition (failed 2-6) and
the council's own weaker alternative (passed 6-2). **Durrwachter voted against the council's
tenant-protection ordinance and for the stronger one.** Read alone, her nay scores as anti-tenant; it
is the opposite. ▶ Rule 6 above says read the agenda item text. This is one layer deeper: **read the
other item on the same agenda.**

### 🔴🔴 A link filter learned from the first sample can exclude the whole target

Five Duluth News Tribune queries returned **0 articles** and the corpus was there. The extractor
required a 24-hex id in the path, learned from the first URLs seen — which were *paid political
letters*. DNT's **news** URLs carry no id.

Rule 2 said do not tie extraction to one publisher's URL shape. The second costume is **one SECTION
of one publisher**. ▶ A uniform zero across several different queries is the signature; check it
against an extractor you have not tuned.

### 🔴 A LONGER query can make a search worse

On WFAE, adding the topic to the name gained 9–15 articles. On DNT, `right to repair` returned
Vikings football and a weather forecast, while the single word `tenant` returned the entire
right-to-repair corpus. DNT ORs the terms and ranks badly. ▶ **Match query breadth to the search
engine, not only to the outlet's size.** Run the one discriminating word as well as the phrase.

### 🔴🔴 Profile with the UA the VERIFIER will use

Minnesota Reformer: **Chrome UA → HTTP 403** Cloudflare challenge; **bare curl → 200**;
**`EmpoweredVoteBot/1.0` → 200**. A Chrome-UA profiling pass recorded it as blocked and contradicted
a correct earlier note. A row is citable only if `verificationFetch` can read it, so a browser-UA
probe answers the wrong question — **in both directions**.

⚠ Playwright clears a Cloudflare challenge but is **not** a universal fix: Northern News Now returned
**zero** search results in a real browser.

### ⚠ The sweep scripts know only three Twin Cities outlets

`sweep_member.mjs` hardcodes MinnPost, Sahan Journal and Minnesota Reformer. It knows nothing about
the **Duluth News Tribune, WDIO or Duluth Monitor**, which are the three that work in Duluth. Extend
it per city, or it will report a thin corpus that is an artifact of its own outlet list.

### 🔴🔴 Two ways a sweep lies about being alive — both cost 45 minutes on 2026-10-05

**1. A fetch with no timeout stalls the whole run, silently.** `sweep_duluth.mjs` v1 used bare
`fetch`. One request hung; the process stayed alive, held memory, and reported nothing. Flat CPU over
a 15-second sample is what finally distinguished *hung* from *slow* — nothing in the output could.
▶ **Every fetch takes `AbortSignal.timeout(...)`.** A sweep makes hundreds of requests to a dozen
hosts and one of them will hang.

**2. Buffered progress is invisible.** `process.stdout.write('.')` flushes to a terminal and buffers
to a file, so a backgrounded sweep wrote **zero bytes for 45 minutes** whether it was working or not.
▶ **Append progress to a log file after every query**, with the running corpus size. `sweep_duluth.mjs`
writes `<out>/_progress.log`; watch that, not stdout.

⚠ Together these two are worse than either alone: the symptom of a hung run is *no output*, and the
symptom of a healthy backgrounded run was also *no output*. **A detector that cannot distinguish
success from failure is not a detector** — the same rule the positive-control discipline encodes,
applied to the tooling instead of to the corpus.

### 🔴 A hardcoded scratchpad path turns a dead corpus into a clean zero

`attribute_quotes.mjs` held an absolute path into **one session's** scratchpad
(`.../claude/.../e6365231-.../scratchpad/outlets/`). That directory is deleted when the session ends,
so the next run read an empty corpus and would have reported *no attributed quotes* — a finding
shaped exactly like a member nobody quotes.

It now takes `SWEEP_OUT` (default `data/stance-news`), the same root the sweeps write to, and
**exits non-zero on a missing or empty index** rather than proceeding:

```
corpus index is EMPTY — that is a broken sweep, not a finding
```

▶ **A tool that reads a corpus must refuse to run on an empty one.** Silence from an empty input is
the single most convincing false negative this toolchain can produce, and every other rule here is
about not trusting one.
▶ **Corpora belong under `data/stance-news/<slug>/`, in the repo tree**, not in a scratchpad — they
are the evidence a row was built from, and a reviewer may need to see them.

### 🔴🔴 The verifier rejects the body of a SIGNED FIRST-PERSON OP-ED — the strongest statement evidence there is

`checkNameProximity` (`backend/src/lib/researchVerifier.ts`, `NAME_PROXIMITY_CHARS = 500`) requires
the member's name within 500 characters of the snippet. **A column the member wrote never names them
beside their own argument** — it says *"we should focus on strengthening and enforcing the
protections we already have"*, and the only occurrences of the name are the byline at the top and the
bio at the bottom, thousands of characters away.

Randorf's Duluth News Tribune column failed this way. The snippet was verbatim, contiguous, 67 words,
and inside a single `<p>` in the live HTML — and the source was still recorded as failed. The rule is
working as written; the shape of the evidence defeats it.

**Workaround, until the rule learns about bylines:** take the passage that sits **immediately before
the author bio**. It states the position and the name follows within a sentence or two:

```
It is a vote for a thoughtful, legally sound approach that delivers real protection without
creating new risks. Duluth deserves a policy that delivers justice and security for tenants, not
just promises.
          ↓ about 90 characters later
Roz Randorf is the elected representative of District 3 on the Duluth City Council.
```

▶ **Check a failed source before assuming the snippet is wrong.** Re-running the verifier is the
first test: a transient block clears, and this did not. Reading the live HTML is the second — it
showed the text present and contiguous, which ruled out every explanation except the rule itself.
▶ **A first-person source needs its snippet chosen with the name-proximity rule in mind**, which is
the opposite of how a human would pick the best passage.
⚠ Worth fixing properly: the byline is structured data on every one of these pages, and a column by
the member is a *stronger* citation than a reporter's paraphrase of them, not a weaker one.
