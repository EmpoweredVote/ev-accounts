# Outlet profile — Saint Paul and Duluth

## 🔴🔴 A QUARTER OF THE SAINT PAUL CORPUS WAS NEVER WRITTEN TO DISK (measured 2026-10-05)

Saint Paul was swept **before** the corpus-key fix, so its files were named
`base64url(url).slice(0, 60)` — about 45 bytes of URL, which on these outlets is not past a shared
path prefix. Articles overwrote each other. Nothing warned, and the corpus looked complete.

| Member | Named by the sweep | On disk | Lost |
|---|---|---|---|
| Noecker | 77 | 51 | **26 (34%)** |
| Her | 96 | 72 | **24** |
| Yang | 50 | 39 | **11** |
| Kim | 27 | 19 | 8 |
| Cheniqua Johnson | 27 | 20 | 7 |
| Jost | 21 | 16 | 5 |
| Bowie | 32 | 28 | 4 |
| Coleman | 12 | 11 | 1 |
| **TOTAL** | **342** | **256** | **86 (25%)** |

🔴 **A CHAIR SURVIVES A DAMAGED CORPUS. A SEARCHED BLANK DOES NOT.** A chair is a positive finding
from evidence that was present. A searched blank asserts *nothing was found*, and that assertion is
exactly as strong as the corpus behind it. Of Saint Paul's 280 rows: 4 chairs and 120 scope blanks
(facts about Minnesota law) are unaffected; **156 searched blanks were not.**

⚠ **The defect was provable from the row text, not just from the file count.** Yang's reasoning says
*"50 articles naming Nelsie Yang … every passage in the remaining 47 that quotes her beside a speech
verb was read."* Thirty-nine were on disk. The sentence asserted work that had not happened.

▶ **The measurement that catches this is `named.json` length vs `ls <corpus> | wc -l`.** It is one
line, it is cheap, and no run had ever made it. `sweep_stpaul.mjs` now asserts it at the end of every
sweep and prints `🔴 N LOST` if the key is still colliding.
▶ All eight members were **re-swept 2026-10-05** with `sweep_stpaul.mjs`: whole-URL sha1 key, the
verifier's UA, and the Pioneer Press added.

## 🔴🔴 MINNESOTA REFORMER SUPPLIED ZERO ARTICLES TO **EVERY** CORPUS IN THIS SLICE

Not the Saint Paul sweep — **all of them**, both cities, for the whole programme:

| randorf | durrwachter | forsman | nephew | kennedy | reinert | every Saint Paul member |
|---|---|---|---|---|---|---|
| 0 of 50 | 0 of 38 | 0 of 79 | 0 of 42 | 0 of 359 | 0 of 146 | 0 |

**490 rows of reasoning name Minnesota Reformer as an outlet that was searched. It never was.**

⚠ **The first diagnosis here was the user-agent, and it was wrong.** Reformer does 403 a Chrome UA,
which is true and documented below — but switching to the verifier's UA does **not** fix it. The
cause is one layer lower.

### The cause: Cloudflare fingerprints the TLS handshake, not the user-agent

Same URL, same user-agent, same machine, same minute:

| Client | Result |
|---|---|
| node `fetch()` | **HTTP 403**, 5,795 bytes, 0 article links |
| `curl` | **HTTP 200**, 150,559 bytes, 6 article links |

The 403 was swallowed by the sweep's `r.ok` test and a bare `catch {}`, so an outlet recorded as
**"✅ passed"** contributed nothing and raised no error, in every run, for weeks.

🔴 **THE RULE: PROFILE WITH THE CLIENT THAT WILL DO THE WORK. A USER-AGENT IS NOT A CLIENT.** curl,
node `fetch` and a real browser present three different TLS fingerprints, and a WAF can accept one
and refuse another carrying identical headers. Reformer was profiled with curl and swept with node
fetch, and the profile simply did not transfer.
▶ **Count what each outlet CONTRIBUTED, every run.** An outlet listed as working that returns
nothing is the signature, and it is the only thing that would have caught this.

🟢 **Fixed: `sweep_reformer.mjs`** sweeps Reformer over curl and merges into an existing corpus. It
runs its own differential control first and **exits 2 rather than record a zero**. Reformer is now
removed from `sweep_stpaul.mjs`'s fetch list so the silent zero cannot come back. First run, Yang:
141 candidates, **21 articles added** that no sweep in this programme had ever seen.
⚠ **The six Duluth corpora still lack their Reformer articles** — `sweep_reformer.mjs` works for
them too, but it has not been run and their rows still carry the false coverage sentence.

---

🔴 **The ordinary `?s=` HTML search is BLIND on four of six outlets, and a naive sweep would have
reported "no coverage" for all four.** Each row below was tested with a **positive control** — the
query `Saint Paul`, which must return results on a Minnesota news site. Four outlets returned
nothing for the control, which means the method was broken, not the corpus empty.

| Outlet | `?s=` HTML search | Control | Working method |
|---|---|---|---|
| **MinnPost** | says "no results" | ❌ **failed** | 🟢 `GET /wp-json/wp/v2/search?search=<q>&per_page=10` |
| **Sahan Journal** | says "no results" | ❌ **failed** | 🟢 `GET /wp-json/wp/v2/search?search=<q>&per_page=10` |
| **Minnesota Reformer** | returns results | ✅ passed | 🟢 `?s=<q>` — WP REST API **403s**, use the HTML search |
| **Saint Paul Pioneer Press** | returns results | ✅ passed | 🟡 `?s=<q>` — results list, but articles are paywalled |
| **MPR News** | 15.5 KB shell, 0 links | ❌ **failed** | 🔴 **UNSOLVED** — JS-rendered |
| **Racket** | 366 KB, 1 link | ❌ **failed** | 🔴 **UNSOLVED** — JS-rendered |

▶ **Run the control on every outlet before trusting a yield.** This is the Charlotte rule — *a low
yield was my extractor, not the world* — and it fired again here, on four outlets at once.
▶ **No single method works everywhere.** WP REST fixes MinnPost and Sahan and is refused by Reformer;
Reformer's HTML search works where theirs does not. Profile each outlet, record the method, reuse it.
▶ **MPR News and Racket are still blind.** Do **not** record a searched blank that claims to have
covered them until a method is found. Either solve them or name them as uncovered in the reasoning.

### 🔴 RESOLVED 2026-10-05 — MPR News is READABLE and NOT CITABLE. Racket is simply blind.

**MPR News search works in Playwright**, and the differential control is clean: `Nelsie Yang`
returns 11 article links, gibberish returns **exactly the 2** "latest stories" furniture links that
appear in both, so the real yield is **9** — including a May 2025 profile of her and her response to
the Yia Xiong shooting. Plain `curl` gets an identical 15.5 KB shell for any query, so the earlier
"JS-rendered" finding was right about the search.

🔴 **But its ARTICLE pages are hydrated client-side too, and that is what disqualifies it.** The
verifier's own UA fetches 132 KB of HTML from which the stripped text is **99 characters**, and the
string `Yang` appears **once** in the entire raw response. The body is not in the bytes — not in
`__NEXT_DATA__`, not in the `ld+json`. So a passage found on MPR could be read by a researcher and
**could never be verified or published**, because a snippet must be cut verbatim from what
`verificationFetch` receives.

▶ **PROFILE THE ARTICLE PAGE, NOT ONLY THE SEARCH.** An outlet can pass the search control and still
be unusable. "Can I read it?" and "can the verifier read it?" are different questions, and only the
second one decides whether an outlet can carry a row.
▶ MPR News therefore stays **named as uncovered** in Saint Paul reasoning — but the reason is now
"not citable", which is stronger and final, rather than "we could not search it", which invited
another attempt. ⚠ Do not spend time solving it again.

**Racket is blind, confirmed by differential control**: `Nelsie Yang`, `Saint Paul` and `qzxwvplmdk`
each return the **same 12 links**, and they are boilerplate — `about-us-racket-mn`,
`commenting-policy`, `cookies-policy`. The response sizes differ by six bytes, which is the query
echoed back. A bare link count of 82 looks like a working outlet and is not one.

## Verified working — MinnPost, by WP REST

A `Noecker` search returns ten results including the May 2025 rent-stabilization story used as
evidence below, the January 2025 council-president story, an October 2025 piece on whether Saint Paul
and Minneapolis can regulate guns locally, and a January 2026 piece on Twin Cities officials and ICE.
The last two bear directly on `gun-policy` and `local-immigration`.

⚠ **The gun story does not reopen `gun-policy`.** Minn. Stat. 471.633 preempts the field whatever a
member says they would like to do; the ladder's rungs remain unavailable. Read it for context, not
for a chair.

## Incidental confirmation — Saint Paul's mayor

The scope review flagged that `Kaohly Her` needed checking against a source outside our database.
Sahan Journal's results name her as mayor repeatedly, including a story on her 2027 budget proposal
and one on her election. **Confirmed; the open question is closed.**

## Duluth — profiled 2026-10-05, every row carries a control

Each row was tested **differentially**: the same extractor was run on a real query (`Forsman`) and on
a nonsense one (`qzxwvplmdk`), and the outlet counts as working only if the real query returns links
the nonsense query does not. **A bare link count proves nothing** — Northern News Now returned 64 links
and Duluth Reader 37, and both return the *same* links for gibberish.

| Outlet | Method that works | Control | Notes |
|---|---|---|---|
| **Duluth News Tribune** | 🟢 `GET /search?q=` + **absolute**-href extraction | ✅ 12 query-specific | **Best in the city.** City-hall reporter Peter Passi. **NOT paywalled** |
| **WDIO** (ABC) | 🟢 `?s=` HTML search | ✅ 24 query-specific | Station coverage, short pieces, direct quotes |
| **Duluth Monitor** | 🟢 `GET /wp-json/wp/v2/search` | ✅ 6 query-specific | Investigative: TIF subsidies, housing goals, encampments |
| **Minnesota Reformer** | 🟢 bare curl **or the EmpoweredVoteBot UA** | ✅ passed | 🔴 **403s a CHROME UA.** See below |
| MinnPost · Sahan Journal | 🟢 WP REST | ✅ passed | Statewide; thin on Duluth but not empty |
| **Perfect Duluth Day** | 🔴 none | ❌ Cloudflare 403 to *every* UA incl. the bot | robots.txt also disallows `/?s=` for all agents |
| **FOX 21 Online** | 🔴 none | ❌ HTTP 429 to every UA | BLOX/TownNews WAF, 65-byte body naming our IP |
| **Business North** | 🔴 none | ❌ HTTP 429 to every UA | same WAF as FOX 21 |
| **Northern News Now** | 🔴 none | ❌ **0 results in a real browser** | Gray TV; search is broken, not merely JS-rendered |
| **Duluth Reader** | 🔴 none | ❌ blind — gibberish returns the same 37 links | |

▶ **Three working local outlets, one of them the daily of record.** That is a *better* profile than
Saint Paul's, where four of six were blind. Duluth was priced as the hard city and is not.

### 🔴🔴 A HEX-ID FILTER PRODUCED A CONFIDENT ZERO ON A RICH CORPUS

Five DNT queries — `right to repair`, `tenant right to repair`, `rent`, `Duluth tenants union`,
`rental housing` — returned **0 articles each**, and the corpus was there the whole time. The
extractor required a 24-hex-character id in the path, because the first URLs seen carried one:

    /community/letters/paid-political-letter-forsman-a-community-builder-5d01…-6520…   ← has an id
    /news/local/duluth-voters-to-decide-if-tenants-should-have-right-to-repair-homes  ← has none

**Only DNT's paid-political-letter URLs carry an id. Its news URLs do not.** The filter was written
from the first sample and excluded exactly the section being searched for.
▶ **This is rule 2 of the README again** — *do not tie link extraction to one publisher's URL shape* —
and it now has a second costume: not the publisher, but **one SECTION of one publisher**.
▶ **A uniform zero across five different queries is the signature.** It was visible and nearly missed.

### 🔴 A LONGER QUERY MADE DNT'S SEARCH WORSE — this is the third costume of query breadth

| Query | What came back |
|---|---|
| `right to repair` | Vikings beat Dolphins · a weather forecast · a prep cross-country result |
| `tenant` | **the entire right-to-repair corpus** — the news piece, the pro/con column, the editorial |

DNT ORs the terms and ranks badly, so each extra word adds noise instead of precision. On WFAE adding
the topic *gained* 9–15 articles per query; here it **lost** the corpus.
▶ **Query breadth must match the outlet's search engine, not just its size.** Run the single
discriminating word as well as the phrase, and merge.

### 🔴🔴 MINNESOTA REFORMER 403s A CHROME UA AND SERVES THE VERIFIER BOT A CLEAN 200

| UA sent | Result |
|---|---|
| Chrome 120 desktop | **HTTP 403**, Cloudflare *"Just a moment…"* |
| bare curl, no UA | 200 |
| `EmpoweredVoteBot/1.0` | **200**, 159 KB |

This inverts the usual direction and it **cost a false negative in this very session**: the first
profiling pass sent a Chrome UA, recorded Reformer as blocked, and contradicted yesterday's note
saying it works. Yesterday's note was right.
▶ **Profile with the UA the VERIFIER will use.** A row is only citable if `verificationFetch` can read
it, so a browser-UA probe answers the wrong question in both directions.
⚠ Playwright also clears the challenge, but it was not needed, and **Playwright is not a universal
fix** — Northern News Now rendered **zero** results in a real browser.

### 🟢 The Duluth News Tribune is NOT paywalled — the expectation was wrong

The Charlotte Observer and the Pioneer Press are paywalled, and DNT was expected to match. It does
not. Fetched with the verifier's own UA, articles return **complete body text**: 10,193 chars for the
right-to-repair ballot piece, 6,227 for the labor-support piece, 10,145 for the rent-relief piece —
full quotes, bylines and datelines, no truncation and no sign-in wall. robots.txt disallows only
`/search` and `/cms` for `*`, with `Crawl-delay: 10`.
🔴 **`/search` IS disallowed for the bot.** Searching is a research step for a human; **never cite a
DNT search URL** — cite the article.

---

## 🔴🔴 Attribution: the speech verb is REQUIRED, and a second person with the surname voids the article

Two false attributions were produced and caught while working Yang, and both would have published a
quote under the wrong person's name.

**1. The speech verb must be required, not optional.** With it optional, this passage attributed a
school principal's words to Yang, because the *next sentence* merely began with her name:

> "If a kid missed the bus, she'd be willing to take them home." **Nelsie Yang**, who is now a
> St. Paul City Council Member, got to know Marny during her sch…

**2. An article that names a second person with the same surname cannot carry bare-surname
attribution.** Saint Paul coverage contains many people surnamed Yang. The filter now drops any
article containing another `<First> <Surname>`, with a stoplist so that sentence starters — *In
Yang's response*, *When Yang*, *Like Yang* — do not count as first names. Without that stoplist the
filter excluded almost everything and produced a **false zero** of its own.

⚠ It also surfaced a **Kathy Noecker** (a 2012 campaign-finance story). Checked: no Rebecca Noecker
row cites that article.

### The rule is a trade-off, and it has a known false negative

Requiring the verb immediately after the quote misses a real attribution when an appositive sits in
between:

> "Repealing this ordinance doesn't create a better system…" **Council Member Rebecca Noecker**, who
> represents downtown St. Paul and surrounding areas, **said** last year.

That quote is genuinely hers. ▶ **Re-read any quote the strict rule drops before discarding it** —
the strict rule is for finding candidates safely, not for settling attribution.

### 🔴 A multi-candidate questionnaire round-up is the worst case

A quote was attributed to Jost that belongs to **Patty Hartmann**, from a MinnPost round-up in which
many candidates answer the same question in sequence. The member's name appears elsewhere on the
page, so proximity rules pass. **In a round-up, attribution must come from the candidate's own
labelled block, never from the page.** Two of Jost's reasonings cited that quote and have been
corrected.

## 🔴🔴 A MEMBER'S OWN NAME CAN HAVE MORE THAN ONE SPELLING — sweep every variant

| Query | MinnPost | Sahan | Corpus built |
|---|---|---|---|
| `HwaJeong Kim` (our database spelling) | 1 | 7 | **8 articles** |
| `Hwa Jeong Kim` (the newsrooms' spelling) | 10 | 17 | **27 articles** |

The database spelling found **less than a third** of her coverage, and nothing warned of it — the
thin result looked exactly like a member who is rarely covered. Searching `HwaJeong` alone returned
the same 8, which is what made it look settled.

▶ **Before accepting a thin corpus, try the spaced, hyphenated and joined forms of the name.** This
is the third costume of the same lesson in this slice: `"ranked choice"` vs `"ranked voting"` was the
body's vocabulary, the topic sweeps were query breadth, and this is the **person's own name**.
▶ The row still uses the database `full_name`, which the pipeline requires. Only the SEARCH varies.
