# Outlet profile — Saint Paul and Duluth

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

## Duluth

Not yet profiled. Expect the Duluth News Tribune (Forum Communications) to be paywalled. Duluth is a
**statement-only** city — see `instruments.md` — so its outlet profile matters more there than in
Saint Paul, not less.

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
