# California 2026 swearing-in dates — rules, sources, and what is still owed

Piece 4 of the post-election transition programme, California slice. Read this before touching
`essentials.office_swearing_in` for California, and before seating any California winner.

**Measured 2026-11-04. 337 California offices carry a 2026-11-03 race at the local tiers**
(`SCHOOL`, `LOCAL`, `LOCAL_EXEC`, `COUNTY`). **215 now have a cited date** (`CC_0345`).
**122 are owed one.** Every one of the 337 is in Los Angeles County.

---

## 🔴 Read this first: the two things that were nearly got wrong

### 1. The date we already held was not a date

Wave 3 was scoped by reading the **month** of each office's existing `office_terms.term_start`,
and the design doc reported "175 of 236 dated local terms begin in December, **the earliest on
1 December** — 27 days from this document".

**118 of ~140 dated California `SCHOOL` terms read `2022-12-01`, and every one carries
`start_precision = 'month'`.** `12-01` is this repo's honest encoding of *December, day unknown*.
The deadline was a precision artifact.

Reading the month was the right move — it found the right seats. Reading the **day** read a value
the column never claimed to hold. The real statutory date is the **second Friday**, and in 2022 it
was the 9th: no California school board started a term on 1 December at all.

▶ **A month is a search tool. A day needs an authority.**

### 2. A statute that reads like a blanket rule was wrong for 14 of 25 seats

`Cal. Elec. Code § 10554` says: *"Elective officers, elected or appointed pursuant to this part,
take office at noon on the first Friday in December next following the general district
election."* For 2026 that is **4 December**. A predicate over the office title —
`title ILIKE 'Director%'` — applies it to all 25 California district offices in this wave, and an
earlier draft of this work did exactly that.

It is **wrong for 14 of them**. § 10554 is bounded by each district's **principal act**, which can
override it. Los Angeles County's own calendar for this election lists the two groups under
separate headings, a month apart:

```
DEC. 4 (F) E+31        TAKING OFFICE — HEALTH CARE, RECREATION, AND PARK DISTRICT
JAN. 4 (M) NOON E+62   TAKING OF OFFICE — MUNICIPAL WATER, WATER AGENCIES, AND
                       WATER REPLENISHMENT DISTRICTS
```

`office_terms` is self-executing. Those 14 seats would have changed hands on the live site on
4 December, by themselves, with the people they replace still in office and nothing running that
could have noticed.

▶ **`CC_0345` lists the eight affected bodies BY NAME.** A name list is checkable against a
roster; a predicate over a title is a guess about what the title means. Its post-verify gate fails
if any row lands on `2026-12-04`, and that gate was watched firing on exactly 25 rows before the
migration was applied.

---

## The rules, each read from its own source on 2026-11-04

| Rule id | Bodies | Date | Basis | Authority |
|---|---|---|---|---|
| `ca-edc-5017` | School and community college district boards | **2026-12-11** (window to 2026-12-25) | statute | [Cal. Educ. Code § 5017](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=EDC&sectionNum=5017.) |
| `ca-water-principal-act` | Municipal water districts, water agencies, water replenishment districts | **2027-01-04** | published | Cal. Water Code § 60139, Water Code App. §§ 98-51 and 103-5(b), Cal. Gov. Code § 24200, per the county handbook |
| `ca-const-vi-16c` | Judges of the superior court | **2027-01-04** | statute | [Cal. Const. art. VI § 16(c)](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=CONS&sectionNum=SEC.%2016.&article=VI) |
| `ca-elec-10554` | UDEL districts whose principal act is silent | 2026-12-04 | statute | [Cal. Elec. Code § 10554](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10554.) — ⚠ **no California body in this set uses it** |
| `ca-gov-36503` | City officers (general law cities) | — | not computable | [Cal. Gov. Code § 36503](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=GOV&sectionNum=36503.) |
| `ca-la-county-charter` | LA County Assessor, Sheriff, Supervisors | — | **conflicted** | LA County Charter, Art. II § 6 and Art. IV § 13 |

**The county handbook** is
[Candidate Handbook and Resource Guide, November 3, 2026 General Election](https://content.lavote.gov/docs/rrcc/documents/candidate-handbook-general-election-complete-v-10.pdf),
Los Angeles County Registrar-Recorder/County Clerk (read 2026-11-04). Its Calendar of Events is
the only source found that answers taking-office dates for **this specific election**, and it
answers several at once. ⚠ Judge it field by field: one of its own entries contradicts itself
(below).

### 🔴 The school date is a commencement, and the oath is a window

Two statutes, two events, a fortnight apart:

- **§ 5017** — the term **commences** on the second Friday in December: **2026-12-11**.
- **§ 35143** — the annual organizational meeting, where the oath is actually administered, is
  held *"on a day within a 15-day period that commences with the second Friday in December"*:
  somewhere in **2026-12-11 … 2026-12-25**, each district choosing its own day.
- **§ 5017, second sentence** — a member whose term has expired **continues to discharge the
  duties of the office until a successor has qualified**.

**Our existing rows record the OATH, not the commencement.** Glendora `2022-12-12`, Azusa and
Duarte `2022-12-13`, others on the 14th and 15th — each sourced to that district's
organizational-meeting minutes, while the second Friday of December 2022 was the **9th**.

`CC_0345` writes the **commencement** as `swearing_in_date` and the window's last day as
`window_end_date`, so the table says what it knows instead of flattening a window into a point.

▶ **Open decision for the operator.** Seating all 197 at `2026-12-11` means that for up to two
weeks the site shows the incoming member while the predecessor is still lawfully discharging the
duties. The alternative — each district's actual organizational-meeting date — is **not available
yet**: § 35143 says the board picks that day at its regular meeting immediately *before* 11
December. Sixty-odd districts, none of them decided. The commencement date is the only answer
that exists today, and it is the legally correct start of the term.

---

## What is still owed — 122 offices

### 110 city offices · `ca-gov-36503` · ~45 cities

`Cal. Gov. Code § 36503`: city officers *"hold office for their prescribed terms from the date of
the **installation of officers following adoption by the council of the official canvass** of
their election"*. A per-council event. **There is no statewide date**, and the county handbook
carries none either — it conducts these elections but does not set the installation.

Bounds that do exist: the official canvass must be completed within 30 days
(**2026-12-03**, Elec. Code §§ 15301/15372/15400/15401), the RR/CC is tentatively scheduled to
certify on **2026-11-27**, and the Board of Supervisors declares the election concluded on
**2026-12-01**. So installations fall in early-to-mid December. That is a bound, **not a date**,
and nothing may be seeded from it.

⚠ **Charter cities set their own rule** — Los Angeles, Burbank, Culver City, Long Beach, Santa
Monica, Compton, Inglewood and others in this set are charter cities, and § 36503 is the
*general law* city rule. Check the charter, not the Government Code, for those.

🔴 **The jurisdiction is not on the district row for 37 of them.** Their `districts.label` reads
only `District 1` … `District 6` with `city` NULL and `ocd_id` NULL. The city is recoverable, but
from a different column depending on how the office was seeded — `ocd_id` (`place:artesia`),
`geo_id` (`arcadia-council-district-2`), or the label prefix. **This is why piece 4 carries the
date per office instead of deriving it from a jurisdiction key: there is no such key today.**

### 11 district offices · principal act not yet established

| Body | Offices |
|---|---|
| Walnut Valley Water District | 3 |
| Altadena Library District | 1 |
| Crescenta Valley Water District | 1 |
| La Cañada Irrigation District | 1 |
| La Puente Valley County Water District | 1 |
| Palmdale Water District | 1 |
| Palos Verdes Library District | 1 |
| Valley County Water District | 1 |
| Wrightwood Community Services District | 1 |

The county's taking-office entries name health care, recreation-and-park, municipal water, water
agencies and water replenishment districts. **They name none of these nine bodies.**

They are *probably* `ca-elec-10554` (**2026-12-04**) — the same calendar's § 10515 entry lists
county water, community services and irrigation districts among the districts it runs elections
for under that part. 🔴 **"Probably" is exactly how the 14 above would have been got wrong.**
Read each body's principal act. If any of these is really 4 December, it is the **earliest
handover in the entire programme** and it is 30 days out.

### 1 · Los Angeles County Sheriff · the source contradicts itself

The handbook's entry reads:

```
NOV. 30 (M) NOON E+27
TAKING OF OFFICE — ASSESSOR, SHERIFF, AND COUNTY SUPERVISORS
Officers take office at noon on the first Monday in December following the election.
(Art. II, § 6, Art. IV, § 13, County Charter)
```

**30 November 2026 is a Monday and is not in December.** The first Monday in December 2026 is the
**7th**. The stated rule and the calendared date are a week apart and cannot both be right.
`Cal. Gov. Code § 24200`'s default — noon on the first Monday after 1 January, **2027-01-04** — is
displaced by the charter ("except as otherwise provided"), so the statute does not break the tie
either.

▶ **Read Los Angeles County Charter Art. II § 6 and Art. IV § 13.** Until then
`swearingInDateForRule('ca-la-county-charter', …)` throws, and nothing is seeded.

⚠ This rule also governs the **Assessor and the Supervisors**, so resolving it pays for itself
beyond the one seat in this wave.

---

## Consequences for the wave order

The design doc put wave 3 at **1 December** and called it 27 days out. Measured against cited
authority, California's 2026 handover dates are:

| Date | Offices | What |
|---|---|---|
| 2026-12-04 | 0 confirmed (≤ 11 possible) | UDEL districts — **unresolved**, and the earliest if real |
| 2026-12-07 *or* 2026-11-30 | 1 | LA County Sheriff — **conflicted** |
| **2026-12-11** | **197** | school and community college boards — the bulk, and certain |
| early–mid December | 110 | city offices — bounded, undated |
| **2027-01-04** | **18** | water districts and superior court judges |

**The real California bulk date is 11 December, not 1 December** — 37 days out, not 27. The
programme is not late, but the thing that would have made it late is the 11 unresolved district
seats, and those are the ones to settle next.
