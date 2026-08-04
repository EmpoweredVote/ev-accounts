# Newton re-research — findings, session 1 (2026-08-04)

Second cluster from `data/stance-retirement/2026-08-03-reresearch-worklist.json`: **57 owed rows across
17 politicians**, all 57 in tier-scope (9 topics, every one local-applicable).

**Nothing written to production. No migration. Next free number is 1548.**

The roster check came first, per the Beverly Hills precedent. It came back clean — and then the topic
distribution led somewhere worse than the worklist knew about.

## ✅ FINDING 1 — Newton's roster is CURRENT, which corrects a generalisation

All 24 councilors in our database match the city's own roster ward by ward, and Laredo is **already**
correctly seated as Mayor. **No roster migration is needed.** The Beverly Hills staleness was not
universal, and this is worth stating plainly: `office_terms.term_end` being NULL corpus-wide means the
database cannot *prove* currency, but it does not follow that rosters are generally wrong.

Roster source: `newtonma.gov/government/city-clerk/city-council/council-members` **via the 2026-04-22
Wayback capture**, because the live host is behind an **Akamai edge block** — 403 to plain fetch, 403 to
a browser UA, and 403 to Playwright (`rendered=246c "Access Denied"`, ref `errors.edgesuite.net`).
⚠ Classify that as a bot block, not absence: the page renders fine for a voter. Cross-checked against
`beverlypress`-equivalent local press (Fig City News, Newton Beacon) and lwvnewton.org.

⚠ Minor data-quality items, NOT fixed here: our `full_name` values are informal or misspelled against the
city's roster — **"Allison Leary" vs the city's "Alison M. Leary"** (a real misspelling), plus
"Becky Grossman" / "Rebecca Walker Grossman", "Josh Krintzman" / "Joshua Krintzman", "Maria S. Greenberg" /
"Maria Scibelli Greenberg". Worth a separate name-correction pass; not mixed into stance work.

## 🔴 FINDING 2 — 48 of Newton's 55 stances rest on TWO citations that never existed

The 57 owed rows concentrate on Environmental Protection (14) and Climate Change (12) — 26 of 57, the
single-source clustering shape that flagged the TCJA cluster. Following it found a much larger live
defect **outside the worklist**:

**48 rows across 18 Newton politicians** cite `newtonobserver.com`. **Zero are sole-sourced** — and
that is exactly why every prior sweep missed this host: **45 of the 48 pair it with
`newtonma.gov/government/city-council/agendas-minutes`**, so the row always had a second source that
looked resolvable. Same row-level blind spot recorded for the 08-01 host sweep, which required *every*
source on a row to be a bare host.

Both citations fail, each verified with a **verified control in the same run** (the lesson from the
`clark.house.gov` control that was assumed and nearly buried a real finding):

| citation | verdict | control, same run, identical conditions |
|---|---|---|
| `newtonobserver.com` (48 citations) | **does not resolve**; Wayback holds **5 URLs ever**, from 2011-02-08, and the samples are the root plus `?epl=…` **parking-page** query strings | `figcitynews.com` and `newtonbeacon.org` both live (HTTP 200, ~200KB) and archived within days; CDX hit my 400-row cap |
| both cited article paths | **ABSENT, reproduced across 3 successful probes each** | the two control hosts returned ARCHIVED on all 3 rounds |
| `newtonma.gov/government/city-council/agendas-minutes` (45 rows) | **ABSENT, 3 rounds.** Sibling coverage `government/city-council/*` = **3** archived URLs, and they are a different slug (`city-council-and-friday-packet`) | the real family `government/city-clerk/city-council/*` = **300** archived URLs (my limit), including the capture this roster was read from |

So the composed-citation test fires on the city path and the invented-outlet test fires on the host.
**None of the 48 rows has a citation a reader can check.** `newtonobserver.com` is a **sixth invented
outlet**, beyond the five already found (medfordmirror.com, newtonvillearea.com, alhambraource.com,
walthamtribunenews.com, walthamatch.com).

⚠ The earlier "EXACTLY ONE invented hostname exists" bound was **congressional-surface only**. It was
never a corpus-wide claim, and this does not contradict it.

## 🔴 FINDING 3 — the pre-tenure defect exists in LOCAL government, and 1537 never looked

Seven of those rows assert a specific dated action by councilors who were not in office:

> "voted in favor of Newton's MBTA Communities zoning compliance plan in **October 2023**"

asserted for **Sean Roche (3 rows), Julie Irish (2), Jacob Silber (2)** — all three **elected 2025-11-04
and sworn in 2026-01-01**, verified verbatim in Fig City News' newcomers piece
(<https://www.figcitynews.com/2025/11/meet-the-newcomers/>): *"Ward 5: At-Large: Brittany Hume Charm.
Ward Councilor: Julie Irish. Ward 6: At-Large: Lisa Gordon and Sean Roche. Ward 7: At-Large: Brian
Golden. Ward 8: At-Large: Jacob Silber."* Seven councilors are new this term.

Migration 1537 retired 36 pre-tenure rows but was scoped to **federal legislators via congressional roll
calls**. Nothing has ever checked local officeholders for it, and the detector could not have been
tenure-shaped anyway because `office_terms.term_start` is NULL for essentially every local official.
These rows were caught by *reading*, exactly like the rest.

⚠ Also wrong on the merits: the Newton MBTA-Communities/VCOD council vote was **2023-12-04, 21-2-1**
(Leary and Noel opposed, Ryan absent) — the October 2023 action was the **ZAP committee** vote, 5-1-1.
So the surviving rows misdate a vote they attribute to people who could not have cast it.

## Coverage impact of retiring the 48

| measure | value |
|---|---|
| Newton people with an office term | 25 (24 councilors + Mayor) |
| people holding ≥1 answer today | 19 |
| Newton answers today | 55 |
| rows resting on the invented pair | **48** |
| people who would drop to **zero** | **17 of 19** |
| people who would keep something | 1 |

Newton would go from 55 answers to 7, and — as with Beverly Hills — the city's purple
"compass stances seeded" chip would be making a promise the database no longer backs.

**12 of the 18 affected people are not in the re-research worklist at all**, because they kept these rows
and "researched = has ≥1 answer" reads them as done. The worklist's own warning about invisible per-topic
gaps applies to whole people here.

## ⏳ Operator decision owed

Retirement is the one irreversible step, and the standing rule is **verified absent → retire, never
unsure → retire**. Both citations are verified absent, reproduced, with controls. But the scope is a
judgment call: it turns Newton from "re-research 57 rows" into "re-research ~105 across 20+ people",
and it switches a city's coverage chip off. Nothing has been retired pending that call.

## What the next session has to work with

Fig City News publishes **per-meeting attendance rosters** — *"Present: Councilors Kelley (Chair), Leary,
Irish, Block, Farrell, Lucas, Golden, and Roche. Absent: Councilor Golden."* — which is the per-member
evidence Beverly Hills lacked, and it covers the **current** term, so it cannot recreate a pre-tenure
claim. Committee-level votes there are the most promising basis for the newcomers, who have no record
before 2026-01-01. The electrification ordinance (20-1, Gentile the lone no, **three absences**) is NOT
usable per-member without a roll call, and Gentile is no longer on the council.
