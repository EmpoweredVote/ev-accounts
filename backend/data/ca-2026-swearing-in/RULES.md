# California 2026 swearing-in dates — rules, sources, and what is still owed

Piece 4 of the post-election transition programme, California slice. Read this before touching
`essentials.office_swearing_in` for California, and before seating any California winner.

**Measured 2026-11-04. 337 California offices carry a 2026-11-03 race at the local tiers**
(`SCHOOL`, `LOCAL`, `LOCAL_EXEC`, `COUNTY`). **All but one now have a row**
(`CC_0345`, `CC_0346`, `CC_0347`):

- **230 are seatable** — `basis` of `statute` or `published`, each with its authority.
- **106 are city offices marked `estimated` and are NOT seatable.** The law fixes a *process*
  for them, not a day; they carry the statutory floor and the rule that bounds them, and each
  must be replaced per city when that city publishes its installation date.
- **1 — the Los Angeles County Sheriff — has no row at all**, because its source contradicts
  itself. See below.

---

## The dates

| Date | Offices | Who | Authority |
|---|---|---|---|
| **2026-12-04** | 8 | Municipal water districts | [Water Code § 71253](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=WAT&sectionNum=71253.) |
| **2026-12-04** | 3 | Walnut Valley Water District (California water district) | [Water Code § 35057](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=WAT&sectionNum=35057.) → [Elec. Code § 10554](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10554.) |
| **2026-12-04** | 3 | County water districts | Water Code § 30502 + Elec. Code § 10554 |
| **2026-12-04** | 2 | Irrigation districts | [Water Code § 21101](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=WAT&sectionNum=21101.) |
| **2026-12-04** | 2 | Library districts (Educ. Code ch. 9) | [Educ. Code § 19700(b)](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=EDC&sectionNum=19700.) |
| **2026-12-04** | 1 | Wrightwood Community Services District | [Gov. Code § 61042(a)](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=GOV&sectionNum=61042.) |
| **2026-12-11** | 197 | School and community college boards | [Educ. Code § 5017](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=EDC&sectionNum=5017.) (window to 12-25, § 35143) |
| **2027-01-04** | 6 | Water agencies, water replenishment district | Water Code § 60139, Appendix §§ 98-51 and 103-5(b) |
| **2027-01-04** | 4 | Superior court judges | [Cal. Const. art. VI § 16(c)](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=CONS&sectionNum=SEC.%2016.&article=VI) |
| **2026-12-14** | 4 | City of Los Angeles — Mayor, City Attorney, Council 3 and 9 | [LA City Charter § 205(c)](https://codelibrary.amlegal.com/codes/los_angeles/latest/laac/0-0-0-392) |
| *estimated* | 106 | All other city officers, 52 cities | [Gov. Code § 36503](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=GOV&sectionNum=36503.) + [Elec. Code § 10263(b)](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10263.) — no statewide date |
| *conflicted* | 1 | LA County Sheriff | LA County Charter, Art. II § 6 and Art. IV § 13 |

**19 California seats change hands on 4 December — 30 days out, and the earliest in the
programme.** All 19 are district seats.

**The county handbook** is
[Candidate Handbook and Resource Guide, November 3, 2026 General Election](https://content.lavote.gov/docs/rrcc/documents/candidate-handbook-general-election-complete-v-10.pdf),
Los Angeles County Registrar-Recorder/County Clerk (read 2026-11-04). It is the only source found
that answers taking-office dates for **this specific election**, and it answers several at once —
but see the next section before trusting any part of it.

⚠ **Not every body here is in Los Angeles County.** Wrightwood Community Services District draws
property tax from both San Bernardino and Los Angeles counties and its 2017 formation election was
run by San Bernardino County, so the LA handbook is not its authority. Its row is cited to the
Government Code instead. The rest of the set is Los Angeles County.

---

## 🔴 Three things that were wrong, and how each was caught

### 1. The date we already held was not a date

Wave 3 was scoped by reading the **month** of each office's existing `office_terms.term_start`.
The design doc reported "175 of 236 dated local terms begin in December, **the earliest on
1 December** — 27 days from this document".

**118 of ~140 dated California `SCHOOL` terms read `2022-12-01`, and every one carries
`start_precision = 'month'`** — this repo's honest encoding of *December, day unknown*. No
California school board ever started a term on 1 December.

Reading the month was right; it found the right seats. Reading the **day** read a value the column
never claimed to hold. ▶ **A month is a search tool. A day needs an authority.**

### 2. A statute that reads like a blanket rule was wrong for some seats — and then the fix was wrong too

`Elec. Code § 10554`: *"Elective officers, elected or appointed pursuant to this part, take office
at noon on the first Friday in December next following the general district election."* A predicate
over `title ILIKE 'Director%'` applies it to all 25 California district offices. **An earlier draft
did exactly that.**

§ 10554 is a **default**, bounded by each district's **principal act**. `CC_0345` therefore moved
14 offices off it onto 4 January, following the handbook's calendar heading.

🔴 **That over-corrected. 8 of those 14 belonged on 4 December after all, and `CC_0346` moved them
back.** The calendar heading reads:

```
JAN. 4 (M) NOON E+62
TAKING OF OFFICE — MUNICIPAL WATER, WATER AGENCIES, AND WATER REPLENISHMENT DISTRICTS
(Water Code § 60139, Water Code Appendix 98–51 and 103–5 (b) and Govt. Code § 24200)
```

**The heading names municipal water districts and its citations do not.** § 60139 is the Water
Replenishment District act; Appendix 98-51 and 103-5(b) are two *water agencies'* special acts. The
**same handbook's General Information table** gives municipal water districts their own row —
*"Friday at Noon, December 4, 2026 (Water Code §§ 71252, 71253 ...)"* — and § 71253 says it in plain
words.

▶ **READ THE CITATION, NOT THE HEADING.** This is the repo's *"a source can be authoritative for one
field and stale for another"* rule operating **inside a single document**.

⚠ **A month late is not the safe direction.** Avoiding a month early produced a month late, which
leaves the departing director resolving as the current officeholder after they have gone. Both are
live on the site; neither raises anything. `CC_0346`'s post-verify now gates **both** directions:
no municipal water row off 4 December, and nothing on 4 January under a rule that does not set it.

### 3. Two library-district chapters, a week apart, and the earlier one is in November

California has **two** library-district chapters:

| Chapter | Sections | Term begins | 2026 |
|---|---|---|---|
| 8 | 19400-19532 | last Friday in **November** (§ 19422, § 19510) | **2026-11-27** |
| 9 | 19600-19734, *"in Unincorporated Towns and Villages"* | first Friday in **December** (§ 19700(b)) | **2026-12-04** |

**2026-11-27 would be the earliest handover in the entire transition programme** — before December
entirely. Both California library districts here are **chapter 9**, in their own words, so nothing
lands there. The chapter 8 rule is kept in the catalogue anyway, because the next county's wave
will meet a district that uses it.

🔴 **The territory does not decide the chapter.** Palos Verdes Library District serves four
**incorporated** cities and is still a chapter 9 district: *"formed in April 1928 under the
provision of Sections 19600-19734"* (pvld.org). Its own trustee roster prints **"Term Expires:
11/27/2026"** — the chapter 8 date — beside **"Term Began: 12/02/2022"**, which is the first Friday
in December 2022 and therefore chapter 9. The formation statute and the start-date field agree; the
expiry field is the outlier. Judged field by field, not page by page.

### 🔴 And a name can stop saying what a body is

**Palmdale Water District** is an **irrigation district**: formed in 1918 as the Palmdale Irrigation
District *"under Division 11 of the Water Code"*, renamed in 1973. The rename did not change the act
it runs under. "Water District" on its own is not a class — Walnut Valley Water District is a
*California* water district (division 13), Crescenta Valley Water District is a *county* water
district (division 12), and Palmdale is an *irrigation* district (division 11). Three bodies, three
divisions, one suffix.

▶ **Establish the principal act from the body's own records.** All three happen to land on
4 December, so the date survives the confusion — but the citation would have been wrong, and the
next state's bodies will not be so forgiving.

---

## The school date is a commencement; the oath is a window

- **§ 5017** — the term **commences** on the second Friday in December: **2026-12-11**.
- **§ 35143** — the organizational meeting where the oath is administered falls *"on a day within a
  15-day period that commences with the second Friday in December"*, each district choosing its own
  day: **2026-12-11 … 2026-12-25**.
- **§ 5017**, second sentence — the predecessor **continues to discharge the duties** until the
  successor qualifies.

**Our existing rows record the oath, not the commencement.** Glendora `2022-12-12`, Azusa and Duarte
`2022-12-13`, others on the 14th and 15th — each sourced to that district's own minutes, while the
second Friday of December 2022 was the **9th**.

`swearing_in_date` is the commencement; `window_end_date` is the window's last day.

🟢 **RULED 2026-11-08 BY THE OPERATOR (Chris Cantrell): "Seat whichever is earliest."**
**So: seat all 197 at the § 5017 COMMENCEMENT, 2026-12-11** — not at each district's oath.
No longer an open question; do not re-derive it.

- It is the **legally correct start of the term**, and it is the only date that exists today:
  § 35143 has each board pick its meeting day at the regular meeting immediately *before*
  11 December, so the per-district dates cannot be known in advance.
- ⚠ **The cost of the ruling, stated plainly so nobody reports it as a bug:** between 11 and
  25 December a seated incoming member can be shown while the predecessor is still lawfully
  discharging the duties under § 5017's second sentence. That is accepted, not overlooked.
- `swearing_in_date` stays the commencement and `window_end_date` the window's last day, so the
  record still says what is a statutory date and what is a window.
- ▶ **The same rule decides the rest of the programme**: where a term's commencement and the
  oath are separate events, seat at the EARLIER one.

---

## The city offices — 110 across 53 cities

### Los Angeles is the exception: its charter fixes a date

**LA City Charter § 205(c)**: *"The term of an official elected to City office shall commence on the
**second Monday in December** next following his or her election."* → **2026-12-14**.

Controlled against a real past seating: the City Clerk's roster records the 2024 citywide officers as
commencing **2024-12-09**, the second Monday of that December. § 205(c) also stages the cycle — the
Mayor, City Attorney, Controller and **odd-numbered** council districts commence each fourth
anniversary of 2022. The four offices on this ballot are Mayor, City Attorney and Council Districts
**3 and 9**, both odd. Charter and ballot agree, which is the check that the right cycle was read.

### 🔴 Being a charter city does not mean having a date

**Burbank's charter fixes no commencement at all.** Read the same day: it provides only that, for a
consolidated election, the county *"shall canvass the returns and shall certify the result … to the
Council, who shall thereupon declare the result"*. No date. Burbank is therefore in exactly the same
position as the general law cities.

12 of the 53 are confirmed charter cities, from the California Department of Industrial Relations'
*List of Charter Cities that Are in Compliance with Senate Bill 7 (2013), Senate Bill 829 (2011),
and Senate Bill 922 (2012)*, current as of 2026-03-05: **Alhambra, Arcadia, Burbank, Compton, Culver
City, Downey, Inglewood, Irwindale, Los Angeles, Palmdale, Pomona, Santa Monica**.

⚠ **That list is a subset and absence proves nothing.** It names only charter cities compliant with
three particular statutes, so a charter city missing from it is not thereby a general law city.
Montebello was separately confirmed general law from its own clerk's page. The other 40 are
unclassified — and the classification only decides *which document to read*, never the date, so
nothing seeded depends on it.

### The other 106: the law fixes a process, not a day

| Section | What it says |
|---|---|
| `Gov. Code § 36503` | city officers hold office *"from the date of the **installation of officers** following adoption by the council of the official canvass"* |
| `Elec. Code § 10262(b)` | for a consolidated election the council acts *"no later than the next regularly scheduled city council meeting following presentation of the 28-day canvass … or at a special meeting called for this purpose"* |
| `Elec. Code § 10263(b)` | at that meeting the council shall *"declare the results **and install the newly elected officers**"* |

So declaration and installation are **one event**, at that council's own meeting.

**What is fixed:** the 28-day canvass is **2026-12-01** (E+28), and § 10263 requires the canvass to be
complete before the council may install. The county's canvass must finish within 30 days
(**2026-12-03**) and the RR/CC is tentatively scheduled to certify **2026-11-27**.

🔴 **Why these are `estimated` and carry 2026-12-01, not a computed meeting date.** "The next
regularly scheduled council meeting" is derivable from each city's published meeting rule — but
§ 10263(b) says **"no later than"** and expressly allows *"a special meeting called for this
purpose"*. Cities use it: Glendale's June 2026 election was certified by the RR/CC on 26 June and the
city held a **special council meeting** to administer the oath. A computed next-regular-meeting is an
upper bound that is **systematically late**, and writing 106 upper bounds as dates would repeat, in
bulk, the error `CC_0346` had to correct for the municipal water districts.

▶ **A bound you can defend beats a date you cannot.** `2026-12-01` is the statutory floor, `basis`
is `estimated` so nothing can seat from it, and the rule that sets the ceiling is in the row.

⚠ **Nothing is published yet, and that is expected, not a search failure.** This was written one day
after the election; the canvass does not complete for four weeks. **The dates will appear through
late November and early December** — replace each row with `basis = 'published'` as its city posts
one.

### 🔴 There is no jurisdiction key in the data, and it bit this migration

37 of the 110 have `districts.label` reading only `District 1` … `District 6`, with `city` **and
`ocd_id` NULL**. The city is recoverable, but from a *different column* depending on how the office
was seeded — `ocd_id` (`place:artesia`), the `geo_id` slug (`arcadia-council-district-2`), or the
label prefix. That is why piece 4 carries the date per office rather than deriving it from a
jurisdiction key.

**`CC_0347`'s first dry run wrote 69 rows instead of 106**, silently. Its Los Angeles test was
`d.ocd_id LIKE '…place:los_angeles%'`, and for a NULL `ocd_id` that is **NULL, not false** — so
`WHERE is_la_city` dropped those 37 rows *and* `WHERE NOT is_la_city` dropped them too, because
`NOT NULL` is `NULL` and not true. They fell out of both branches and the inserts just wrote fewer
rows, with no error. **The count gate is what caught it.** ▶ Three-valued logic does not raise; it
quietly returns a smaller set.

### 1 · Los Angeles County Sheriff · the source contradicts itself

```
NOV. 30 (M) NOON E+27
TAKING OF OFFICE — ASSESSOR, SHERIFF, AND COUNTY SUPERVISORS
Officers take office at noon on the first Monday in December following the election.
(Art. II, § 6, Art. IV, § 13, County Charter)
```

**30 November 2026 is a Monday and is not in December.** The first Monday in December 2026 is the
**7th**. The stated rule and the calendared date are a week apart and cannot both be right.
`Gov. Code § 24200`'s default (2027-01-04) is displaced by the charter, so the statute does not break
the tie.

▶ **Read Los Angeles County Charter Art. II § 6 and Art. IV § 13.** Until then
`swearingInDateForRule('ca-la-county-charter', …)` throws and nothing is seeded. The same rule governs
the **Assessor and the Supervisors**, so resolving it pays for itself beyond this one seat.

---

## Consequences for the wave order

| Date | Offices | What |
|---|---|---|
| **2026-12-04** | **19** | district seats — **settled, and the earliest in the programme** |
| 2026-12-07 *or* 2026-11-30 | 1 | LA County Sheriff — conflicted |
| **2026-12-11** | **197** | school and community college boards — the bulk |
| **2026-12-14** | 4 | City of Los Angeles |
| early–mid December | 106 | other city offices — bounded, undated, **not seatable** |
| 2027-01-04 | 10 | water agencies and superior court judges |

The design doc put wave 3 at 1 December and called it 27 days out. The true first handover is
**4 December** and the bulk is **11 December**. The programme is not late — but the 19 seats on
4 December are now the nearest real deadline, and they are ready to seat as soon as results exist.

**The open work in California is now a watch, not a research problem.** 106 city seats need their
installation dates, and those dates do not exist yet anywhere. They appear as each council posts its
December agenda, from late November. The Sheriff needs one charter read.
