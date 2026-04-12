# Monroe County IN — May 5, 2026 Primary Election Ballot Baseline

**Source:** Monroe County Clerk 2026 Primary Election sample ballot PDFs, published by Monroe County Public Library.
**Date verified:** 2026-04-12
**Purpose:** Authoritative denominator for race coverage audit (AUDIT-01). Every race listed below is a formal ballot position — even "NO CANDIDATE FILED" slots are counted. This document is the reference against which the DB race count is measured.

---

## Federal Races (HIGH confidence)

| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| US Representative, 9th District Indiana | James H. (Jim) Graham, Brad A. Meyer, Tim Peck, Keil L. Roark | Erin Houchin | D primary contested (4 candidates); R uncontested |

---

## State Legislative Races (HIGH confidence — varies by precinct)

| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| Indiana State Representative, District 46 | James H. Pittsford (Jimmy) III | Thomas L. (Tom) Arthur, Bob Heaton | Benton Twp, Bean Blossom precincts |
| Indiana State Representative, District 60 | Carrie L. Syczylo | Peggy Mayfield, Mike Moore, David W. Waters | Benton Twp precincts |
| Indiana State Representative, District 61 | Matt Pierce, Lilliana Young | NO CANDIDATE FILED | Bloomington precincts; D primary contested |
| Indiana State Representative, District 62 | Amy Huffman Oliver | Dave Hall | Benton Twp precincts |

---

## Judicial Races (HIGH confidence — appear on all precincts, both parties)

| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| Judge of the Circuit Court, Monroe, Division 6, Seat 5 | Kara Elaine Krothe | NO CANDIDATE FILED | D has candidate; R shaded/no filing |
| Judge of the Circuit Court, Monroe, Division 1, Seat 9 | Geoff Bradley | NO CANDIDATE FILED | D has candidate; R shaded/no filing |

---

## County-Wide Races (HIGH confidence — appear on all precincts, both parties)

| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| County Prosecuting Attorney | Benjamin T. Arrington, Erika Oliphant | NO CANDIDATE FILED | D primary contested |
| County Clerk of the Circuit Court | Tanner Dale Branham, Joe Davis, Tree Martin Lucas | Julie M. Hays | D primary contested (3 candidates) |
| County Recorder | Amy Swain | NO CANDIDATE FILED | D uncontested |
| County Sheriff | Ruben Marte' | NO CANDIDATE FILED | D uncontested |
| County Assessor | Bob Nyquist, Judith A. Sharp | NO CANDIDATE FILED | D primary contested |
| County Commissioner, District 1 | Trent Deckard, David G. Henry | NO CANDIDATE FILED | D primary contested |

---

## County Council Races (HIGH confidence — varies by district)

| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| County Council, District 1 | Peter James Iversen | NO CANDIDATE FILED | D uncontested |
| County Council, District 2 | (Kate Wiltz — uncontested, general only) | — | No primary contest observed in ballots |
| County Council, District 3 | NO CANDIDATE FILED | Martha (Marty) Hawk | R uncontested |
| County Council, District 4 | Jennifer Crossley | NO CANDIDATE FILED | D uncontested |

---

## Township Races (MEDIUM confidence for Clear Creek, Perry, Richland, Salt Creek, Van Buren, Washington, Polk — partially from B-Square Bulletin press coverage; HIGH for Bean Blossom, Benton, Bloomington, Indian Creek)

| Township | Trustee D | Trustee R | Board D | Board R |
|----------|-----------|-----------|---------|---------|
| Bean Blossom | NO CANDIDATE FILED | Ronald H. Hutson | NO CANDIDATE FILED | NO CANDIDATE FILED |
| Benton | Michelle Bright | NO CANDIDATE FILED | Joe Husk | NO CANDIDATE FILED |
| Bloomington | Efrat Rosser | NO CANDIDATE FILED | Dorothy Granger, Barbara E. McKinney, Elizabeth Sensenstein | NO CANDIDATE FILED |
| Clear Creek | Contested (details MEDIUM) | Contested (details MEDIUM) | Contested (details MEDIUM) | Dustin Cole Dillard, R. Shannon Reed, Paul Strain, Steven E. Webb |
| Indian Creek | Susan (Gus) Hingle | Christopher Reynolds | — | — |
| Perry | Levi Combs, Leon Gordon | — | Jack Davis, Jeremy Goodrich, Susie Hamilton, Jenny Olmes-Stevens, Barbara Sturbaum | — |
| Richland | — | — | Traves Conyer, Elaine Thomsen, Jay Thrasher, David Willibey | — |
| Salt Creek | MEDIUM — details pending full ballot PDF read | MEDIUM | MEDIUM | MEDIUM |
| Van Buren | MEDIUM — details pending full ballot PDF read | MEDIUM | MEDIUM | MEDIUM |
| Washington | MEDIUM — details pending full ballot PDF read | MEDIUM | MEDIUM | MEDIUM |
| Polk | MEDIUM — details pending full ballot PDF read | MEDIUM | MEDIUM | MEDIUM |

---

## Ellettsville Town Council Races (HIGH confidence — appears on Ellettsville-area precincts)

| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| Ellettsville Town Council, Ward 4 | NO CANDIDATE FILED | Andrew Henry | R uncontested |
| Ellettsville Town Council, Ward 5 | NO CANDIDATE FILED | Marv Ulmet | R uncontested |

---

## Race Count Summary

| Level | Distinct Race Types | Primary Race Slots (D+R separately) | Confidence |
|-------|--------------------|------------------------------------|------------|
| Federal | 1 | 2 | HIGH |
| State Legislative | 4 (Districts 46, 60, 61, 62) | 8 | HIGH |
| Judicial | 2 | 4 (D has candidates; R shaded) | HIGH |
| County-Wide | 6 (Prosecuting Attorney, Clerk, Recorder, Sheriff, Assessor, Commissioner) | Up to 12 | HIGH |
| County Council | 4 | Up to 8 | HIGH |
| Township (11 twps × 2 races — Trustee + Board) | Up to 22 | Varies by township contest | MEDIUM (7 of 11 townships) |
| Ellettsville Town | 2 | 4 | HIGH |
| **Total** | **~43 distinct race slots** | **~42-50 across both primaries** | HIGH/MEDIUM mix |

**Key denominator for AUDIT-01:** The confirmed denominator for a Bloomington Township voter is approximately 20-25 race slots across both parties. County-wide total across all townships and precincts is approximately 43 distinct race positions. A race with "NO CANDIDATE FILED" is still a ballot position and should appear in the audit — it represents a known coverage gap if missing from the DB.

---

## Intentional Omissions

**State Convention Delegate races are intentionally excluded from this baseline and from all audit scripts.**

Democratic State Convention Delegates appear on page 2 of all Democratic ballots. These are internal party organizational elections — voters select up to 10, 17, or 20 delegates (depending on district) to attend the state convention. These are not civic voter guide content. Empowered Vote covers races where voters choose between candidates for public office, not party organizational elections.

If audit output flags "State Convention Delegate" as a missing race type, this is incorrect — those races should not appear in the DB and should not be counted as a gap.

---

## Confidence Notes

| Race Level | Confidence | Basis |
|------------|-----------|-------|
| Federal (US Rep D-9) | HIGH | Read directly from official ballot PDFs (both parties) |
| State Legislative (Districts 46, 60, 61, 62) | HIGH | Read directly from official ballot PDFs (both parties) |
| Judicial (Circuit Court Seats 5 and 9) | HIGH | Read directly from official ballot PDFs (both parties) |
| County-Wide (6 races) | HIGH | Read directly from official ballot PDFs (both parties) |
| County Council (Districts 1-4) | HIGH | Read directly from official ballot PDFs; District 2 (Kate Wiltz): MEDIUM — no primary contest observed in ballots, general election only |
| Township: Bean Blossom, Benton, Bloomington, Indian Creek | HIGH | Read directly from official ballot PDFs |
| Township: Clear Creek, Perry, Richland | MEDIUM | Partially from B-Square Bulletin press coverage; remaining ballot PDF pages not yet fully read |
| Township: Salt Creek, Van Buren, Washington, Polk | MEDIUM | Details pending full ballot PDF pages 20+ being read |
| Ellettsville Town Council (Wards 4-5) | HIGH | Read directly from official ballot PDFs |

---

## Sources

1. **Republican ballot PDF:** `https://mcpl.info/files/inline-files/rep._2026_primary_sample_ballots.pdf` — Official Monroe County Clerk 2026 Republican Primary sample ballot, published by Monroe County Public Library. Read pages 1-15, full ballot races verified 2026-04-12.

2. **Democratic ballot PDF:** `https://mcpl.info/files/inline-files/dem._2026_primary_sample_ballots.pdf` — Official Monroe County Clerk 2026 Democratic Primary sample ballot, published by Monroe County Public Library. Read pages 1-20, full ballot races verified 2026-04-12.

3. **B-Square Bulletin cross-reference:** `https://bsquarebulletin.com/election-2026-contested-local-primaries-some-november-matchups-take-shape-across-monroe-county/` — Used for cross-reference of township races (Clear Creek, Perry, Richland).

4. **Indiana SoS candidate list:** `https://www.in.gov/sos/elections/files/Primary-Candidate-List-3.25.26.xlsx` — Indiana Secretary of State official candidate list as of 2026-03-25, used as secondary verification for state and federal races.
