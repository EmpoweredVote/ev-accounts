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
