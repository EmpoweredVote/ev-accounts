# Durham NC — verified rosters (wave 2, task 2)

Verified 2026-08-22. **No database writes were made to produce this file** — the only database access
was the read-only cross-state homonym check in the "Homonym check" section below.

Scope: **City of Durham (7 seats) + Durham County elected executives (8 seats) = 15 offices.**
Durham County Commissioners are 5 seats; Chair/Vice-Chair are board roles decided by an annual board
vote, **not** separate offices — see "Chair/Vice-Chair" note under Durham County below.

## Sources

| # | Source | What it establishes | Retrieved |
|---|---|---|---|
| S1 | `https://www.durhamnc.gov/1396/City-Council-Members` — City Clerk's office roster page | City roster: 7 names, wards, appointed/elected notes | 2026-08-22 |
| S2 | `https://www.durhamnc.gov/1329/About-the-Mayor` — official mayor bio page | Mayor's sworn-in date (2023), prior council service | 2026-08-22 |
| S3 | Per-member `durhamnc.gov` bio subpages (`/5483/Matt-Kopac`, `/5484/Shanetta-Burris`, `/4797/Nate-Baker`, `/1661/Carl-Rist`, `/3286/Javiera-Caballero`, `/4664/Chelsea-Cook`) | Individual assumed-office dates, term windows | 2026-08-22 |
| S4 | IndyWeek — `new-durham-city-council-members-sworn-in`, `durhams-new-city-council-sworn-in-monday`, `durham-council-selects-legal-aid-attorney-chelsea-cook-to-fill-vacant-seat` | Corroborates swearing-in dates for Kopac/Burris (2025-12-01), Baker/Rist (2023-12-04), Cook's appointment | 2026-08-22 |
| S5 | WRAL — `chelsea-cook-to-be-appointed-as-newest-durham-city-council-member` | Chelsea Cook: appointed and sworn in **2024-01-16** (same evening) | 2026-08-22 |
| S6 | IndyWeek archives — `javiera-caballero-named-durham-city-council` (2018-01-16) | Javiera Caballero: appointed and sworn in **2018-01-16** (same day, ~1 hour after the vote) | 2026-08-22 |
| S7 | `https://www.dconc.gov/county-departments/departments-a-e/board-of-commissioners/commissioners` — official county commissioners roster page | Current 5 commissioners, current Chair/Vice-Chair | 2026-08-22 |
| S8 | Per-member `dconc.gov` bio subpages (`.../Nida-Allam`, `.../Stephen-Valentine`, `.../Mike-Lee`) | Individual sworn-in dates | 2026-08-22 |
| S9 | IndyWeek — `new-durham-county-board-of-commissioners-officially-sworn-into-office` + Spectacular Magazine (2024-12) | Corroborates 2024-12-02 swearing-in for Lee, Burton, Valentine; confirms Jacobs/Allam retained | 2026-08-22 |
| S10 | `dconc.gov` archived Board of County Commissioners minutes, PDF: `20121129SSMinutes.pdf` (special session, 2012-11-29) and `20121210RSMinutes.pdf` (regular session, 2012-12-10) | Primary-source bracket for Wendy Jacobs' original swearing-in: still "Commissioner-Elect" on 11-29, seated as full Commissioner by 12-10 | 2026-08-22 |
| S11 | `https://rodweb.dconc.gov/web/` (Register of Deeds' own office site) + `https://www.ncard.us/find-your-register-of-deeds/durham-county/` (NC Association of Registers of Deeds) | Current Register of Deeds: Sharon A. Davis, serving since 2016 | 2026-08-22 |
| S12 | `https://www.branch.vote/races/2024-nc-general-election-nc-state-register-of-deeds-nc-county-durham/candidates/sharon-a-davis` + Ballotpedia `Sharon_Davis` | Independent second source: Sharon A. Davis appointed **2016-06-01**, elected Nov 2016, re-elected 2024 unopposed | 2026-08-22 |
| S13 | `https://dconc.gov/Clerk-of-the-Superior-Court` (county's own site) | Current Clerk of Superior Court: Aminah M. Thompson | 2026-08-22 |
| S14 | Ballotpedia `Aminah_Thompson` (aggregates NCSBE results) + IndyWeek `durham-county-clerk-of-superior-court-aminah-thompson-2026` | Independent second source: elected 2022-11-08 (defeating incumbent Archie Smith III), assumed office **2022-12-05** | 2026-08-22 |
| S15 | `er.ncsbe.gov` (NC State Board of Elections official results lookup) | Attempted direct primary source for both county-executive races | 2026-08-22 — **see defect below** |
| S16 | Sheriff's office bio (`durhamsheriff.com/about-us/welcome/sheriff-s-bio`) + Spectrum News `new-durham-county-sheriff-takes-oath-of-office` (2018-12-03) | Clarence F. Birkhead sworn in **2018-12-03**, first African-American sheriff of Durham County | 2026-08-22 |
| S17 | `essentials.politicians` / `essentials.office_current_holder` (production, read-only) | Cross-state homonym check — see below | 2026-08-22 |

### Source defects found (do not silently re-trust)

- 🔴 **`er.ncsbe.gov` (S15) is JS-rendered and returns an empty query form to a plain fetch** — same
  defect class as `votetravis.gov` in the Austin wave (S3 there). It could not be used as a direct
  primary source for the Register of Deeds or Clerk of Superior Court races. The county's own
  department pages (S11, S13) plus Ballotpedia's aggregation of NCSBE results (S12, S14) are used
  as the two independent sources instead, per the "county's own site and/or NCSBE" instruction.
- ⚠ **`dconc.gov`'s own URL slug for Wendy Jacobs reads `.../commissioners/wendy-jacobs-vice-chair`**,
  but the current, actively-maintained commissioners roster page (S7) and multiple 2025/2026 board
  votes (both unanimous) show **Nida Allam** as Vice-Chair for both the 2025 and 2026 board years,
  with Mike Lee as Chair both years. The slug is stale housekeeping on the county's CMS, not a
  live discrepancy — recorded here so a future reader doesn't seat Jacobs as Vice-Chair from the URL
  alone. (Moot for this file in any case: Chair/Vice-Chair are not modeled as seats.)
  Independent sources disagree on Jacobs' **term count**: one earlier snippet called her incoming
  2024 term her "third term," while a campaign-adjacent article headlines it as her "fourth term."
  Not resolved here — term count is not one of this task's required fields, and her seat's
  `term_start` (see below) does not depend on which count is correct.
- 🔴 **Wendy Jacobs' original assumed-office date could not be pinned to a day.** Every secondary
  source gives only "2012." The primary-source bracket (S10) narrows it to somewhere between
  2012-11-29 (still "Commissioner-Elect" in special-session minutes) and 2012-12-10 (seated as full
  "Commissioner" in the next regular-session minutes) — almost certainly the county's habitual
  first-Monday-in-December organizational meeting (which would be 2012-12-03), but **that specific
  date was never found stated outright in any primary document**, so per the "never guess a date"
  rule this row is recorded as `2012-01-01` / `precision='year'`, not `2012-12-03`.
- No contradictions were found between S1/S2/S3 (city) or S7/S8/S9 (county) on any of the other 14
  people's identity, seat, or date — the swearing-in dates for the two 2025 city cohorts
  (2025-12-01) and the 2023 city cohort (2023-12-04) and the 2024 county cohort (2024-12-02) are each
  corroborated by at least two independently-published sources (an official government page plus a
  press account).

## 🔴 The Mike Lee collision — read before seating anyone named Lee

Production **already contains two distinct people** named some variant of "Mike Lee," neither of
whom is this Durham official:

| `full_name` in prod | `external_id` | Office | State |
|---|---|---|---|
| `Mike Lee` | `-400077` | US Senator | Utah |
| `Michael V. Lee` | `-3710007` | State Senate District 7 | NC (Wilmington/New Hanover area) |

Durham County's Board of Commissioners Chair is a **third, distinct person**: an educator/manager
(Avalara customer-success manager, adjunct professor at UNC Charlotte, former Durham Public Schools
Board of Education member 2014–2022), first elected countywide in 2024. He is not the NC state
senator (different chamber, different county, different party — Michael V. Lee is a Republican from
New Hanover; Durham's Lee ran as a Democrat) and obviously not the Utah senator.

**Decision: store Durham's chair as `full_name = 'Dr. Michael "Mike" Lee'`.**

Justification, from how Durham County itself writes his name:
- The county's per-member bio page (S8, `dconc.gov/.../Mike-Lee`) spells out the fullest form the
  county uses in running text: **"Dr. Michael 'Mike' Lee."**
- The county's current commissioners roster page (S7) uses the shorter `Dr. Mike Lee`, and Ballotpedia
  disambiguates its own page title as `Michael_Lee_(North_Carolina_county_commissioner)` — Ballotpedia
  itself needed a disambiguator against the existing NC State Senate `Michael Lee`, independent
  confirmation that this collision is a real, previously-recognized problem and not just an artifact
  of our own database.
- `Dr.` is retained: the corpus already stores courtesy/earned titles as part of `full_name` for other
  politicians (e.g. `Dr. Kathleen Lang`, `Dr. Corey A. Jackson`, `Dr. Darshana R. Patel` — confirmed by
  `SELECT full_name FROM essentials.politicians WHERE full_name ILIKE 'Dr. %'` against prod), so this
  is not an invented convention.
- The quoted nickname `"Mike"` follows the same convention already in the corpus for nicknamed
  politicians (`Abusana "Micky" Bondo`, `José "Chito" Vela`) and for Durham's own mayor in this same
  file (`Leonardo "Leo" Williams`).

**Never write `Michael Lee` or `Mike Lee` bare for Durham's chair** — either string collides with an
existing prod row under `lower(full_name)` matching, and a future dedupe pass keyed on a
first+last-only match would silently merge the wrong person's `office_current_holder` row into
Durham's board.

## Homonym check (S17) — read-only, run 2026-08-22

```sql
SELECT p.full_name, p.external_id, d.state, d.label
FROM essentials.politicians p
LEFT JOIN essentials.office_current_holder och ON och.politician_id=p.id
LEFT JOIN essentials.offices o ON o.id=och.office_id
LEFT JOIN essentials.districts d ON d.id=o.district_id
WHERE lower(p.full_name) IN ( /* all 15 names + Mike Lee variants, lowercased */ )
ORDER BY p.full_name;
```

Result — **only the two known Mike Lee rows hit**, both outside NC's Durham seat and both documented
above:

```
Michael V. Lee|-3710007|nc|State Senate District 7
Mike Lee|-400077|UT|Utah
```

None of the other 13 names (Leonardo Williams, Matt Kopac, Shanetta Burris, Chelsea Cook, Javiera
Caballero, Nate Baker, Carl Rist, Nida Allam, Michelle Burton, Stephen J. Valentine, Wendy Jacobs,
Clarence F. Birkhead, Sharon A. Davis, Aminah M. Thompson) collide with any existing prod row, in NC
or any other state. A follow-up `ILIKE '%lee%'` scoped to `state ILIKE 'nc' OR label ILIKE '%durham%'`
confirms no third, already-seeded "Lee" row exists under a Durham office — the seat is genuinely
empty today.

## Durham County pre-existing district

`essentials.districts` already has a `COUNTY`-type row for Durham: `label='Durham County'`,
`geo_id='37063'`, `state='nc'`, `id=89a1200a-4df5-44fa-a8e5-796e9a58242f`. No City of Durham district
row was found (checked `label ILIKE '%durham%'` — only the county row exists). District/office
creation is out of scope for this task; noted for whichever task consumes this roster next.

## external_id mapping

Band: `-(3730000 + n)`, `n = 1..15`.

| n | external_id | Person | Seat |
|---|---|---|---|
| 1 | -3730001 | Leonardo "Leo" Williams | Mayor |
| 2 | -3730002 | Matt Kopac | Ward 1 |
| 3 | -3730003 | Shanetta Burris | Ward 2 |
| 4 | -3730004 | Chelsea Cook | Ward 3 |
| 5 | -3730005 | Javiera Caballero | At-Large |
| 6 | -3730006 | Nate Baker | At-Large |
| 7 | -3730007 | Carl Rist | At-Large |
| 8 | -3730008 | Dr. Michael "Mike" Lee | Commissioner |
| 9 | -3730009 | Nida Allam | Commissioner |
| 10 | -3730010 | Michelle Burton | Commissioner |
| 11 | -3730011 | Stephen J. Valentine | Commissioner |
| 12 | -3730012 | Wendy Jacobs | Commissioner |
| 13 | -3730013 | Clarence F. Birkhead | Sheriff |
| 14 | -3730014 | Sharon A. Davis | Register of Deeds |
| 15 | -3730015 | Aminah M. Thompson | Clerk of Superior Court |

## City of Durham — 7 seats, all elected citywide

🔴 **`term_start` is the day this person began holding THIS seat**, not the start of their current
term. Chelsea Cook's and Javiera Caballero's rows below are their **appointment** dates, not their
subsequent election dates — getting this wrong understates real tenure.

| Office title | `full_name` | Name parts | term_start | precision | how_started | external_id | Source |
|---|---|---|---|---|---|---|---|
| Mayor | Leonardo "Leo" Williams | first: Leonardo · nickname: Leo · last: Williams | 2023-12-04 | day | elected | -3730001 | S2, S4 |
| Ward 1 | Matt Kopac | first: Matt · last: Kopac | 2025-12-01 | day | elected | -3730002 | S1, S3, S4 |
| Ward 2 | Shanetta Burris | first: Shanetta · last: Burris | 2025-12-01 | day | elected | -3730003 | S1, S3, S4 |
| Ward 3 | Chelsea Cook | first: Chelsea · last: Cook | **2024-01-16** | day | **appointed** | -3730004 | S1, S3, S4, S5 |
| At-Large | Javiera Caballero | first: Javiera · last: Caballero | **2018-01-16** | day | **appointed** | -3730005 | S1, S3, S6 |
| At-Large | Nate Baker | first: Nate · last: Baker | 2023-12-04 | day | elected | -3730006 | S1, S3, S4 |
| At-Large | Carl Rist | first: Carl · last: Rist | 2023-12-04 | day | elected | -3730007 | S1, S3, S4 |

Notes:
- No middle names, middle initials, or suffixes were found on any city council member in any source
  consulted (official bios, Ballotpedia, Wikipedia, campaign sites). Recorded as none — not guessed.
- Chelsea Cook was appointed by council vote and sworn in the same evening, 2024-01-16 (S5: "Cook is
  the newest Durham City Council member as of Jan. 16" / "will be sworn in at the 7 p.m. Tuesday city
  council meeting"). She went on to win her first full term unopposed-in-substance (defeating Diana
  Medoff) in the 2025 general — that later win is **not** her `term_start`.
- Javiera Caballero was appointed by council vote on 2018-01-16 and sworn in roughly an hour later at
  the same meeting (S6). She was elected to a full term in 2019 and has been re-elected since — those
  later wins are **not** her `term_start`.
- Mayor Williams previously served as the Ward 3 council member (2021–2023) before winning the
  mayoralty; that is a **different seat**, so his prior council service does not extend his Mayor
  `term_start` backward. His continuous occupancy of the Mayor seat begins 2023-12-04 and continues
  through his 2025 re-election (sworn in for a second term 2025-12-01, per S1/S4 — not a new
  `term_start`, since it is the same seat held continuously).

## Durham County — 8 seats, all elected countywide

🔴 **Chair and Vice-Chair are board roles, decided by an annual board vote — not separate offices.**
Durham County has exactly five Commissioner seats. For the 2025 and 2026 board years, the board
unanimously elected Dr. Michael "Mike" Lee as Chair and Nida Allam as Vice-Chair (S7, S9) — this is
recorded as context only, never as a sixth seat or as part of any `office_title`.

| Office title | `full_name` | Name parts | term_start | precision | how_started | external_id | Source |
|---|---|---|---|---|---|---|---|
| Commissioner | Dr. Michael "Mike" Lee | title: Dr. · first: Michael · nickname: Mike · last: Lee | 2024-12-02 | day | elected | -3730008 | S7, S8, S9 |
| Commissioner | Nida Allam | first: Nida · last: Allam | 2020-12-07 | day | elected | -3730009 | S8, S9 |
| Commissioner | Michelle Burton | first: Michelle · last: Burton | 2024-12-02 | day | elected | -3730010 | S7, S9 |
| Commissioner | Stephen J. Valentine | first: Stephen · middle initial: J. · last: Valentine | 2024-12-02 | day | elected | -3730011 | S8, S9 |
| Commissioner | Wendy Jacobs | first: Wendy · last: Jacobs | **2012-01-01** | **year** | elected | -3730012 | S7, S9, S10 |
| Sheriff | Clarence F. Birkhead | first: Clarence · middle initial: F. · last: Birkhead | 2018-12-03 | day | elected | -3730013 | S16 |
| Register of Deeds | Sharon A. Davis | first: Sharon · middle initial: A. · last: Davis | **2016-06-01** | day | **appointed** | -3730014 | S11, S12 |
| Clerk of Superior Court | Aminah M. Thompson | first: Aminah · middle initial: M. · last: Thompson | 2022-12-05 | day | elected | -3730015 | S13, S14 |

Notes:
- **Wendy Jacobs is the second appointment-then-continuous-service-shaped exception in this file's
  spirit, but in the other direction: she is not an appointment case, she is a "the day is
  genuinely unrecoverable" case.** She was first elected in 2012 and has served continuously since
  (through 2016, 2020, and 2024 re-elections); her `term_start` is her original 2012 seating, not any
  later re-election — but no source states that day, so it is written with `precision='year'` rather
  than the plausible-but-unconfirmed 2012-12-03. See "Source defects" above for the primary-source
  bracket that narrowed but did not pin the date.
- **Sharon A. Davis is a third appointment-then-election case**, structurally identical to Chelsea
  Cook and Javiera Caballero: she was appointed Register of Deeds on 2016-06-01 to fill a vacancy,
  then elected to a full term in November 2016, and has been re-elected since (most recently
  unopposed in 2024). Her `term_start` is the 2016-06-01 appointment, `how_started='appointed'` — not
  any of her three subsequent election wins.
- Michelle Burton and Stephen J. Valentine were newly elected in 2024 (first term); Nida Allam and
  Wendy Jacobs were incumbents retained in the 2024 election (not reflected in their `term_start`,
  which predates 2024 for both).
- Clarence F. Birkhead was first elected Sheriff in 2018 and has been re-elected since (most recently
  announcing a 2026 re-election bid per S16); his `term_start` is his original 2018-12-03 swearing-in.
- Aminah M. Thompson defeated 20-year incumbent Archie Smith III in the 2022 Democratic primary, then
  won the general election unopposed; she is currently on the 2026 ballot for re-election
  (Democratic primary 2026-03-03, general 2026-11-03) — she remains the current officeholder as of
  this file's verification date and her `term_start` is unaffected by the pending election.
- No middle names beyond what is shown were found for Lee, Allam, or Burton in any source consulted.

## Occupancy-model reminder for whichever task writes these rows

Per CLAUDE.md: seat with `essentials.seat_officeholder(office_id, politician_id, term_start, source)`,
which writes an open-ended term and closes any predecessor automatically. Do not write a `term_end`
for any of these 15 — all are current officeholders. For Chelsea Cook, Javiera Caballero, and Sharon
A. Davis, seat them with their **appointment** date and `how_started='appointed'`; do not write a
second row for their later election(s) — continuous occupancy of one seat is one `office_terms` row.
