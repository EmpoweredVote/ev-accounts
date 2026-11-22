# Sourced start dates — the ledger

One block per state. **Read [`REGISTER.md`](./REGISTER.md) for the recipe and the two rulings, and
[`SOURCING.md`](./SOURCING.md) for the queue.** This file is step 2's output and nothing else: it
carries the six things `office_swearing_in` needs, per body, with the clause quoted and the URL
that was opened. A state's date migration is written from its block here, not from memory.

🔴 **Every date below was read off the provision, in a page opened and read.** A search result or a
`WebFetch` summary located some of these documents; none of them is the source of a date.

🔴 **Nothing here is a swearing-in date unless its block says so.** The column is named
`swearing_in_date` and the register's step 2 asks the question explicitly, because states differ:
some fix the term to a calendar date and hold the oath afterwards, some begin the term **on
qualification**, which IS the oath.

---

## MA — Massachusetts · 204 offices · ✅ sourced 2026-11-22

🔴🔴 **ONE CLAUSE, THREE DATES. MASSACHUSETTS DOES NOT DATE ITS STATE TIER TOGETHER.** The queue
in `SOURCING.md` is built on "one constitutional clause usually dates a state's House, Senate and
executives together". For Massachusetts the first half is true and the second is false: a single
sentence-group — Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII — names **three
different days** for the three groups, and the gap between the earliest and the latest is a
fortnight. A state whose House date was copied onto its Attorney General would put her in office
**14 days early**.

| body | offices | start date | group in the clause |
|---|---|---|---|
| House of Representatives | 159 | **2027-01-06** | senators and representatives |
| Senate | 40 | **2027-01-06** | senators and representatives |
| Governor · Lieutenant Governor | 2 | **2027-01-07** (noon) | governor and lieutenant-governor |
| Attorney General · Treasurer and Receiver-General · Auditor of the Commonwealth | 3 | **2027-01-20** | secretary, treasurer, attorney general, auditor |

### The authority

**Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII** (1966). Quoted from the
page, in the clause's own order:

> The terms of the governor and lieutenant-governor shall begin at noon on the Thursday next
> following the first Wednesday in January succeeding their election …
>
> The terms of the secretary, treasurer and receiver-general, attorney general, and auditor shall
> begin with the third Wednesday in January succeeding their election …
>
> The terms of senators and representatives shall begin with the first Wednesday in January
> succeeding their election and shall extend to the first Wednesday in January in the third year
> following their election and until their successors are chosen and qualified.

⚠ **The two superseded versions of this article are still printed on the same page and both read
plausibly.** Amend. Art. LXIV § 1 as originally adopted (1918) is marked *"Superseded by
Amendments, Art. LXXX"*; Art. LXXX's replacement is marked *"Annulled and superseded by
Amendments, Art. LXXXII"*. All three carry the same three-way split, so a reader who stopped at
the first would get the right days for the wrong reason — but Art. LXXX still has the governor on
a **two-year** term and Art. LXIV as adopted has the whole slate biennial, which is why the
quadrennial clause matters: **2026 is a Massachusetts gubernatorial year only under Art. LXXXII.**

### The source

`https://malegislature.gov/Laws/Constitution` — the General Court's own publication of the
Constitution of the Commonwealth. Fetched and read in full 2026-11-22 (458,545 bytes, HTTP 200,
`text/html`); the article texts above are at "Article LXXXII" in the Articles of Amendment.

### Basis

`statute` for all four rows — a constitutional provision, not a convening notice.

### Term start or oath? — **term start, and the oath is a separate, later event**

The clause fixes each term to a **calendar date** ("shall begin at noon on the Thursday next
following…", "shall begin with the first Wednesday in January…"). It nowhere conditions the start
on qualification.

The oath is **Mass. Const. Part 2, Ch. VI, Art. I**, read on the same page: every person chosen
"shall, **before he enters on the discharge of the business** of his place or office, take and
subscribe the following declaration, and oaths or affirmations". That gates the *discharge of the
duties*, not the beginning of the term. 🔴 **So Massachusetts' date is a term start and must not
be written as a swearing-in.**

⚠ **"…and until their successors are chosen and qualified" is about the PREVIOUS term's END, not
this one's start.** It extends a sitting member's tenure if no successor has qualified; it does
not move the successor's term start, and it does not create an overlap in the normal case.
`seat_officeholder` closes each predecessor at `term_start - 1` = **2027-01-05** for the
legislature, which is exactly the day before the successors' terms begin. Nothing to reconcile.

### Controls — the clause read against three facts it did not produce

🔴 A reading of a provision is a reading until something independent agrees with it.

1. **The legislature's own journal, in its own words.** `JOURNAL OF THE HOUSE`,
   `https://malegislature.gov/Journal/House/193/hj01042023.pdf` (HTTP 200, 473,373 bytes, opened
   and read 2026-11-22), page 1: *"The one hundred and ninety-third General Court of the
   Commonwealth of Massachusetts convened at the State House in Boston on the **first Wednesday of
   January**, being the fourth day of the year two thousand twenty-three"* — and the members-elect
   "assembled and were called to order" that day. First Wednesday of January 2023 **was** the 4th.
2. **Our own data, written by a pass that never read this clause.** `essentials.office_terms` holds
   Maura Healey's term starting **2023-01-05**, backfilled by migration 1459 from
   `offices.politician_id`. The Thursday next following the first Wednesday of January 2023 **was**
   the 5th.
3. **The third-Wednesday group, which is the least intuitive of the three and the one most worth
   checking.** Andrea Campbell was sworn in as Attorney General, and William Galvin and Deborah
   Goldberg for their own offices, on **2023-01-18** — the third Wednesday of January 2023 — widely
   datelined (Boston Globe, WGBH, Boston.com, all 2023-01-18). ⚠ **This one is a news dateline, not
   a document**, and it is recorded as the weaker control it is. It is corroboration that the
   clause is applied as written; the clause is the authority.

All three dates reproduce from the arithmetic, checked in code rather than counted by hand:
Wednesdays in January 2023 are 4, 11, **18**; in January 2027 they are **6**, 13, **20**, and the
Thursday next following the first is **the 7th**.

### Carried into the row

| field | House + Senate | Governor + Lt. Governor | AG + Treasurer + Auditor |
|---|---|---|---|
| `election_date` | 2026-11-03 | 2026-11-03 | 2026-11-03 |
| `swearing_in_date` | 2027-01-06 | 2027-01-07 | 2027-01-20 |
| `window_end_date` | NULL | NULL | NULL |
| `basis` | `statute` | `statute` | `statute` |
| `rule_id` | `ma-const-amend-64-s1-legislators` | `ma-const-amend-64-s1-gov-ltgov` | `ma-const-amend-64-s1-constitutional-officers` |

`authority` carries the quoted sentence for that group plus the citation
*"Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII"*; `source` carries the
malegislature.gov URL and the date read; `notes` records that the date is a **term start** and
that Ch. VI Art. I's oath is a separate event.

### Two things the next step inherits

- ⚠ **The Secretary of the Commonwealth is NOT in the pending set.** Massachusetts has six
  statewide executives and `essentials.office_pending_winner` holds five: Governor, Lieutenant
  Governor, Attorney General, Auditor and Treasurer. The Secretary's office exists and
  William Francis Galvin holds it, but no 2026 winner is recorded against it. That is a result or
  seeding gap, not a dating one — the third-Wednesday row above covers the office whenever it is
  filled. **Do not read "5 executives" as Massachusetts' whole slate.**
- ⚠ **159 of the House's 160 offices are pending, and 2 House seats are flagged vacant.** The
  register's `no record` column puts 18 House winners and 3 Senate winners with no `politicians`
  row — step 4 work, against the chamber's own roster.
