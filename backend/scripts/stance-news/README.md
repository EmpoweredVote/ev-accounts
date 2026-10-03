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
