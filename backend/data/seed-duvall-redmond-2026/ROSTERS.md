# Duvall + Redmond, WA — verified roster, 16 city seats

Deep-seed wave 1. Compiled **2026-10-06**.

Spec: [`.planning/todos/2026-10-06-duvall-redmond-wa-deep-seed.md`](../../../.planning/todos/2026-10-06-duvall-redmond-wa-deep-seed.md)
Plan: [`docs/superpowers/plans/2026-10-06-duvall-redmond-wa-deep-seed.md`](../../../docs/superpowers/plans/2026-10-06-duvall-redmond-wa-deep-seed.md)

**16 seats:** each city has a separately elected Mayor and seven Councilmembers elected **at large**
by numbered position. Neither city has wards. Neither city elects a municipal court judge.

**No party affiliation is recorded here or in the migrations.** Both cities are non-partisan by
statute, and the certified results carry `NP` for every candidate. Party lives on
`races.primary_party`, never on an officeholder.

---

## Sources

| # | Source | Retrieved | What it establishes |
|---|---|---|---|
| S1 | King County Elections certified results, 2025-11-25 final — `sources/kc-2025-11-final.csv` | 2026-10-06 | Winners of the Nov 2025 contests in both cities. |
| S2 | King County Elections certified results, 2023-11-27 final — `sources/kc-2023-11-final.csv` | 2026-10-06 | Winners of the Nov 2023 contests. |
| S3 | King County Elections certified results, Nov 2021 — `sources/kc-2021-11-final.csv` | 2026-10-06 | Nov 2021 winners; the continuity test for the 2025 cohort. |
| S4 | King County Elections certified results, Nov 2019 — `sources/kc-2019-11-final.csv` | 2026-10-06 | Nov 2019 winners; the continuity test for the 2023 cohort. |
| S5 | King County Elections certified results, Nov 2017 — `sources/kc-2017-11-final.csv` | 2026-10-06 | Nov 2017 winners; proves Stuart's occupancy of Redmond Pos 4 does not reach past 2021. |
| S6 | King County Elections certified results, Nov 2015 — `sources/kc-2015-11-final.csv` | 2026-10-06 | Nov 2015 winners; proves Forsythe's and Kritzer's occupancy does not reach past 2019. |
| S7 | City of Duvall council roster, `duvallwa.gov/166/City-Council` — `sources/duvall-council-roster.html` | 2026-10-06 | The seven sitting Duvall councilmembers by position, and term expiry years. |
| S8 | City of Duvall mayor page, `duvallwa.gov/165/Mayor` — `sources/duvall-mayor.html` | 2026-10-06 | Amy McHenry, and her term stated in words as 2026-01-01 to 2029-12-31. |
| S9 | City of Redmond council directory, `redmond.gov/Directory.aspx?did=33` — `sources/redmond-council-directory.html` | 2026-10-06 | The seven sitting Redmond councilmembers and the two leadership roles. **Publishes no position numbers.** |
| S10 | City of Redmond, "Learn About Redmond's City Council" — `sources/redmond-council-about.html` | 2026-10-06 | Seven councilmembers and the Mayor, all at large; strong-mayor form. |
| S11 | City of Redmond news release, "Redmond Announces City Council Updates", posted 2026-01-21 — `sources/redmond-news-council-complete.html` | 2026-10-06 | Salahuddin's November resignation; Parsi selected 6-0 and sworn in "last night"; Stuart President, Nuevacamina Vice President. |
| S12 | Redmond Legistar matter **SPC 26-007** (MatterId 10587), "Council Vacancy Nominations, Selection of Appointment, and Swearing in of New Member", approved **2026-01-20** | 2026-10-06 | Independently dates the Parsi appointment meeting. Client `redmond` on `webapi.legistar.com`. |
| S13 | Duvall City Council minutes, 2026-01-20 — `sources/minutes/duvall-2026-01-20.pdf` | 2026-10-06 | Hernandez elected to Position 7 (12 v 0) and sworn in that night. |
| S14 | Duvall City Council minutes, 2026-08-18 — `sources/minutes/duvall-2026-08-18.pdf` | 2026-10-06 | Taylor elected to Position 3 (7 v 3) and sworn in that night. |
| S15 | Duvall City Council minutes, 2026-09-01 — `sources/minutes/duvall-2026-09-01.pdf` | 2026-10-06 | Conway elected to Position 2 (10 v 8 v 0) and sworn in that night. |
| S16 | Redmond City Council Rules of Procedure — `sources/redmond-council-rules.pdf` | 2026-10-06 | "The City of Redmond is a non-charter code City governed by RCW 35A.12." President and Vice-President elected from the members. |
| S17 | Duvall Council Procedures, Resolution 26-02 — `sources/duvall-council-procedures.pdf` | 2026-10-06 | "The City of Duvall is classified as a 'code city' by the RCW"; Mayor's tie-only vote; Mayor Pro Tempore elected by the members. |
| S18 | **RCW 35A.12.100** — `sources/rcw-35A.12.100.html` | 2026-10-06 | The code-city mayor presides and votes **only** to break a tie, and not at all on ordinances, franchises, licences or money resolutions. |
| S19 | **RCW 29A.60.280** — `sources/rcw-29A.60.280.html` | 2026-10-06 | A city term "commences immediately after December 31st following the election" — the January 1 start every regular term below uses. |

---

## Statutory rulings

**1. Both cities are non-charter code cities under RCW 35A.12.** Redmond states it in S16; Duvall
states it in S17. So RCW 35A.12.100 (S18) governs both mayors.

**2. Neither Mayor has a general vote.** S18:

> The mayor shall preside over all meetings of the city council, when present, but shall have a vote
> only in the case of a tie in the votes of the councilmembers with respect to matters other than
> the passage of any ordinance, grant, or revocation of franchise or license, or any resolution for
> the payment of money.

So the mayor has **no vote at all** on ordinances, franchise or licence grants and revocations, and
money resolutions, and only a tie-break on everything else, plus a veto overridable by a majority
plus one.

🔴 **`offices.voting_powers` for both Mayor offices is therefore `non_voting`, not `full`**, and
`offices.representation_note` is **required** by the CHECK. This is the Nashville Vice Mayor
precedent. The note must carry the tie-break and its four carve-outs; the read path must not render
either Mayor without it.

**3. Term starts are January 1.** S19, RCW 29A.60.280(2): the term "commences immediately after
December 31st following the election". Every regularly elected holder below starts on the January 1
after the election that seated them.

**4. Appointees start on the day they take the oath.** All four were sworn in at the meeting that
selected them and began serving immediately (S11, S13, S14, S15).

**5. Leadership roles are NOT offices.** Redmond's Council President and Vice President are elected
biennially "from its members" (S16); Duvall's Mayor Pro Tempore is nominated and elected by the
councilmembers "from their peers" (S17) and retains their councilmember vote. None of the three
gets an `offices` row. Record them in the office or chamber description only.

**6. Neither city elects a municipal court judge.** 52 distinct city contests across six certified
cycles (2015–2025), zero judicial. **Positive control:** the same regex finds "Municipal Court
Judge" contests in the same 2025 file for Federal Way, Kent, Kirkland and Renton, so the detector
works. Seat count stays **16**.

---

## 🔴 Four of the sixteen are appointees, and the roster pages do not say so

The certified winner is **not** the sitting member for four seats. A name match against certified
results would seat the wrong person in all four.

| Seat | Certified winner | Sitting member | Appointed, sworn in |
|---|---|---|---|
| Redmond Pos 1 | Osman Salahuddin (2023) | **Sayna Parsi** | 2026-01-20, 6-0 (S11, S12) |
| Duvall Pos 2 | Rick Shaffer (2023) | **Linda Conway** | 2026-09-01, 10 v 8 v 0 (S15) |
| Duvall Pos 3 | Loren Kosloske (2025) | **Sara Taylor** | 2026-08-18, 7 v 3 (S14) |
| Duvall Pos 7 | Carol Kufeldt (2023) | **Jennifer Hernandez** | 2026-01-20, 12 v 0 (S13) |

## 🔴 Two traps a name match gets backwards

**1. Two sitting members LOST a different seat in the same election.**

- **Sara Taylor** lost Duvall **Position 1** to Adam Olen in Nov 2025 (34.91%) and now sits in
  **Position 3** by appointment.
- **Jennifer Hernandez** lost Duvall **Position 6** to Paul Wiggins in Nov 2025 (34.53%) and sits in
  **Position 7** by appointment.

Joining certified results on name alone seats each of them in the seat they lost.

**2. Duvall Position 5 appears in both 2023 and 2025, with Mike Supple winning both.** Position 5's
regular cycle is 2021 / 2025 (Michelle Hogg won it in 2021), so the 2023 contest was an **unexpired
short term**. Supple's occupancy is **one continuous term from 2024-01-01**, not two terms. Duvall
Position 2 has the same shape one cycle earlier (Shaffer won 2021 unexpired and 2023 full).

---

## City of Redmond — `geo_id 5357535`, `mtfcc G4110`

Non-charter code city, RCW 35A.12, strong mayor. Mayor plus seven at-large councilmembers.

| Office title (exact string for the migration) | Pos | Holder | Term start | Precision | Evidence |
|---|---|---|---|---|---|
| `Mayor` | — | Angela Birney | **2020-01-01** | day | Won Mayor 2019 (60.04%) and 2023 (69.92%). Held Pos 5, not Mayor, in 2015 — Marchione was Mayor. S1–S6 |
| `Councilmember, Position 1` | 1 | Sayna Parsi | **2026-01-20** | day | Appointed 6-0 and sworn in; Salahuddin resigned Nov 2025. S11, S12 |
| `Councilmember, Position 2` | 2 | Vivek Prakriya | **2026-01-01** | day | Won 2025 (64.14%); Steve Fields held it from 2021. S1, S3 |
| `Councilmember, Position 3` | 3 | Jessica Forsythe | **2020-01-01** | day | Won 2019 (54.67%) and 2023 (98.43%); Hank Margeson held it in 2015. S2, S4, S6 |
| `Councilmember, Position 4` | 4 | Melissa Stuart | **2022-01-01** | day | Won 2021 (62.62%) and 2025 (74.49%); Tanika Padhye held it from 2017. S1, S3, S5 |
| `Councilmember, Position 5` | 5 | Vanessa Kritzer | **2020-01-01** | day | Won 2019 (70.98%) and 2023 (98.56%); Angela Birney held it in 2015. S2, S4, S6 |
| `Councilmember, Position 6` | 6 | Menka Soni | **2026-01-01** | day | Won 2025 (56.90%); Jeralee Anderson held it from 2021. S1, S3 |
| `Councilmember, Position 7` | 7 | Angie Nuevacamina | **2024-01-01** | day | Won 2023 (53.68%); David Carson held it from 2019. S2, S4 |

Leadership, not offices: **Melissa Stuart** is Council President and **Angie Nuevacamina** Council
Vice President, both from January 2026, two-year terms, elected by the Council (S11, S16).

## City of Duvall — `geo_id 5319035`, `mtfcc G4110`

Non-charter code city, RCW 35A.12, strong mayor. Mayor plus seven at-large councilmembers.

| Office title (exact string for the migration) | Pos | Holder | Term start | Precision | Evidence |
|---|---|---|---|---|---|
| `Mayor` | — | Amy McHenry | **2026-01-01** | day | Won 2025 (64.54%); the city states the term runs 2026-01-01 to 2029-12-31. Held Council Pos 3 from 2018. S1, S8 |
| `Councilmember, Position 1` | 1 | Adam Olen | **2026-01-01** | day | Won 2025 (64.92%) over Sara Taylor; John Isaacson held it from 2021. S1, S3 |
| `Councilmember, Position 2` | 2 | Linda Conway | **2026-09-01** | day | Appointed and sworn in; Rick Shaffer, elected 2021 and 2023, had held it. S15 |
| `Councilmember, Position 3` | 3 | Sara Taylor | **2026-08-18** | day | Appointed and sworn in; Loren Kosloske won it in Nov 2025. S14 |
| `Councilmember, Position 4` | 4 | Ronn Mercer | **2024-01-01** | day | Won 2023 (98.93%); Michael Remington held it from 2019. S2, S4 |
| `Councilmember, Position 5` | 5 | Mike Supple | **2024-01-01** | day | Won the 2023 **unexpired** term and the 2025 full term — one continuous occupancy. Michelle Hogg won the seat in 2021. S1, S2, S3 |
| `Councilmember, Position 6` | 6 | Paul Wiggins | **2026-01-01** | day | Won 2025 (65.29%) over Jenn Hernandez; Jennifer Knaplund held it from 2021. S1, S3 |
| `Councilmember, Position 7` | 7 | Jennifer Hernandez | **2026-01-20** | day | Appointed 12-0 and sworn in; Carol Kufeldt won it in 2023. S13 |

Leadership, not an office: **Ronn Mercer** is Mayor Pro Tempore (S7, S17).

⚠ **A known error in Duvall's own Council Procedures.** S17 says the veto may be overridden by "a
majority plus one vote of the Council, which has **5 members**". The council has **seven**: S7 says
"an elected body of seven members", and the certified results carry Positions 1 through 7 in every
cycle from 2015. The "5 members" clause is stale text; it does not change any seat.

---

## Vacancy history deliberately NOT written

Four seats were vacant between a departure and an appointment — Redmond Pos 1 from Salahuddin's
resignation (S11 says only "in November", no day) to 2026-01-20, and the three Duvall seats. This
seed writes **only the sitting holder**, so each office gets exactly one `office_terms` row starting
at the date above. No predecessor row and no vacancy span is written.

That is deliberate and correct: `essentials.office_holders_as_of()` will return nobody for those
seats during the gap, which is what happened. Writing a vacancy span would require a start date that
S11 does not give, and CLAUDE.md forbids inventing one.
