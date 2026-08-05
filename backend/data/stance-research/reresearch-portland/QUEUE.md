# Re-research cluster: Portland OR City Council + Mayor

**Queued 2026-08-04, operator-approved, immediately after migration 1558 retired 57 rows.**
Cluster size: **57 retired rows owed + 15 suspect survivors = 72 rows in scope** across 13 people
(12 in the retirement, all 4 survivors are inside those 12).

Rollback for the retired rows, with every value/reasoning/source verbatim:
`data/stance-retirement/2026-08-04-willametteweek-rollback.{json,md}`

---

## 🔑 The thing that makes this cluster different: they are SITTING officials

All 12 took office **January 2025** under Portland's new charter (12-member district council + mayor).
Every retired row was sourced to a **2024 campaign** questionnaire that never existed. So do **not**
re-research this cluster as a candidate cohort — there is now **18+ months of actual voting record**,
which is stronger evidence than any campaign questionnaire would have been.

**Preferred evidence, in order:**
1. **Council votes** — `portland.gov` council minutes/records for a specific item, cited per item.
2. **Named quotes** in real local coverage (WW, Portland Mercury, OPB, KGW, Oregonian).
3. **Official per-member pages** on portland.gov.

⚠ **`portland.gov/council/agenda` and `portland.gov/mayor` are LANDING PAGES.** Both are live (HTTP 200)
but neither evidences any individual's position on anything. The Beverly Hills rule applies in full: an
agenda is not minutes, and "unanimously approved" is **not per-member evidence** — it establishes
neither presence nor position. Attribute only to members named in the record.

---

## Rows owed, by person

| politician | district | rows owed | topics |
|---|---|---|---|
| Candace Avalos | D1 | 7 | Affordable Housing · Criminalization of Homelessness · Homelessness Response · Local Immigration Enforcement · Public Safety Approach · Rent Regulation · Residential Zoning |
| Steve Novick | D3 | 7 | Affordable Housing · Criminalization of Homelessness · Environmental Protection vs. Development · Homelessness Response · Local Immigration Enforcement · Rent Regulation · Residential Zoning |
| Angelita Morillo | D3 | 5 | Affordable Housing · Criminalization of Homelessness · Local Immigration Enforcement · Public Safety Approach · Rent Regulation |
| Elana Pirtle-Guiney | D2 | 5 | Affordable Housing · Criminalization of Homelessness · Local Immigration Enforcement · Public Safety Approach · School Vouchers & Public Education Funding |
| Keith Wilson | Mayor | 5 | Affordable Housing · Criminalization of Homelessness · Local Immigration Enforcement · Rent Regulation · Transportation Priorities |
| Sameer Kanal | D2 | 5 | Affordable Housing · Criminalization of Homelessness · Local Immigration Enforcement · Public Safety Approach · Rent Regulation |
| Tiffany Koyama Lane | D3 | 5 | Affordable Housing · Criminalization of Homelessness · Local Immigration Enforcement · Public Safety Approach · School Vouchers & Public Education Funding |
| Eric Zimmerman | D4 | 4 | Affordable Housing · Criminalization of Homelessness · Economic Development Incentives · Public Safety Approach |
| Jamie Dunphy | D1 | 4 | Affordable Housing · Criminalization of Homelessness · Economic Development Incentives · Public Safety Approach |
| Mitch Green | D4 | 4 | Affordable Housing · Criminalization of Homelessness · Local Immigration Enforcement · Public Safety Approach |
| Dan Ryan | D2 | 3 | Affordable Housing · Criminalization of Homelessness · Local Immigration Enforcement |
| Loretta Smith | D1 | 3 | Public Safety Approach · Rent Regulation · Residential Zoning |

**8 of the 12 now hold zero answers** (Morillo, Avalos, Pirtle-Guiney, Zimmerman, Dunphy, Green, Kanal,
Koyama Lane) and read as unresearched. The other 4 keep rows and so still read as **researched while
owing** — the PARTIAL_INVISIBLE class. Drive this cluster from **this file**, never from a coverage query.

---

## 🔴 15 suspect survivors — verify BEFORE treating them as coverage

These were not retired by 1558 (they do not cite willametteweek) but none is safe to lean on. They are
the only reason Portland's coverage chip still stands.

| politician | rows | sole source | status |
|---|---|---|---|
| Dan Ryan | 6 | `portland.gov/council/agenda` | 🔴 **Live landing page.** Cannot evidence 6 distinct stances. Agenda ≠ minutes, no roll call. |
| Keith Wilson | 2 | `portland.gov/mayor` | 🔴 **Live landing page.** Same problem. |
| Keith Wilson | 3 | `oregonlive.com/portland/2024/10/portland-mayoral-candidates-weigh-in-on-homelessness-housing-and-public-safety.html` | ⚠ **Likely composed.** 403 to fetch (bot block, NOT absence), but **zero Wayback captures** while the sibling directory `oregonlive.com/portland/2024/10*` is well archived — sibling coverage decides it, per 1548. |
| Loretta Smith | 2 | `oregonlive.com/portland/loretta-smith` | ⚠ **Likely composed** — index-page shape, zero captures, same control. |
| Steve Novick | 2 | `oregonlive.com/portland/steve-novick` | ⚠ Same. |

⚠ **oregonlive.com 403s every request** (bot block). A 403 is never absence — the verdict above rests on
archive sibling coverage, never on the 403. First control attempt returned nothing for BOTH the target
and the control, which is inconclusive; the deciding run used `oregonlive.com/portland/2024/10*` as the
control and it returned real captured articles.

⚠ **Portland's `hasContext: true` chip in `essentials/src/lib/coverage.js:119` was deliberately NOT
flipped** — the Newton precedent: 15 rows survive, so the claim is not yet false, and flipping on
suspicion breaches "verified absent → retire". **If these 15 fall, the chip must get the Beverly Hills
treatment** (essentials commit `ca993e74`).

⚠ **Neither landing-page class trips the CI gate.** `PRIMARY_SITE_NO_PATH` looks for a bare host, and
`/council/agenda` has a path — so 8 rows evidenced by a landing page pass the gate cleanly. Gate blind
spot worth a separate check.

---

## Sources verified to EXIST (2026-08-04) — and what they do not cover

Checked live while diagnosing the fabricated citations, so nobody repeats the work:

| source | status | covers |
|---|---|---|
| `wweek.com/news/2024/10/16/wws-fall-2024-endorsements-portland-city-council-district-{1,2,3,4}/` | ✅ live 200 | WW's endorsements + candidate profiles. 🔴 **Zero** mentions of immigration, sanctuary, ICE, rent control/regulation, zoning, vouchers, or "affordable housing" across all five. Thin per person: **Kanal 0 mentions**, Koyama Lane 1, Loretta Smith 1, Green 2, Morillo 3, Ryan 3; substantive only for Avalos 8, Dunphy 8, Pirtle-Guiney 10, Novick 10, Zimmerman 8, Wilson 4. |
| `wweek.com/news/2024/10/16/wws-fall-2024-endorsements-portland-mayor/` | ✅ live 200 | as above |
| `wweek.com/news/2024/10/08/what-district-{1,2,3,4}-wants/` | ✅ archived | district-level issues, not per-candidate positions |
| `wweek.com/news/2024/10/{02,09}/city-council-entrance-interview-<name>/` | ✅ live 200 | Per-candidate Q&A but only ~6 candidates exist, **2 of ours** (Zimmerman, Loretta Smith). Zimmerman's: rent 7, housing 4, police 4 mentions — but **immigration 0, zoning 0**. |
| `willametteweek.com` (any path) | ❌ dead | WW's **genuine former domain** (archived 1998, 301→wweek.com through 2020). Host real, cited articles never existed. |

**Untried, and the obvious next moves:** Portland Mercury, OPB, KGW, `portland.gov` per-councillor pages
and council minutes for specific items since January 2025.

---

## Standing rules for this cluster

- **Do not return to the original sources** (rule 1508) — the willametteweek URLs never existed, so there
  is nothing to return to. Needs genuinely new sources.
- **Free sources only** (operator ruling 2026-08-04). Leave a row PENDING rather than chasing a clerk.
- **A PENDING row is not a blank.** Record what was read.
- **Detect per CITATION, not per row** (the 1548 lesson) — a landing page sharing a row with a real
  article is invisible to row-level checks.
- **Yield reality check: ~1 verified row per 6 page fetches.** 72 rows is a long grind; expect PENDING.
