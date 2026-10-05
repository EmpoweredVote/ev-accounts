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
