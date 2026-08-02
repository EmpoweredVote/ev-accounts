# Damaged `sources` arrays — classification and repair

279 rows scanned · **257 repaired** · 22 held for hand review.

A comma-splitting ingestion step damaged these arrays. The damage takes several shapes that
need OPPOSITE repairs, so each entry is classified before anything is written.


## 🔴 SPLIT URL — 11 row(s): a broken link a voter clicks today

A URL containing a comma was torn in half. The surviving half still *parses* as a URL, so
the gate cannot see it — but it 404s. Each repair below was proven by fetching both halves:
the rejoined URL returns 200 and the truncated one does not.

- **Ricardo Lara / Housing**
  - was: `https://ballotpedia.org/California_Proposition_21` , `_Local_Rent_Control_Initiative_(2020)` , `https://www.insurance.ca.gov/0400-news/0100-press-releases/2023/`
  - now: `https://ballotpedia.org/California_Proposition_21,_Local_Rent_Control_Initiative_(2020)` · `https://www.insurance.ca.gov/0400-news/0100-press-releases/2023/`
- **Mikel Wein / Healthcare**
  - was: `https://ballotpedia.org/Mikel_Wein` , `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election` , `_2026`
  - now: `https://ballotpedia.org/Mikel_Wein` · `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election,_2026`
- **Mikel Wein / Deportation**
  - was: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election` , `_2026` , `https://ballotpedia.org/Mikel_Wein`
  - now: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election,_2026` · `https://ballotpedia.org/Mikel_Wein`
- **Mikel Wein / Ukraine Support**
  - was: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election` , `_2026` , `https://ballotpedia.org/Mikel_Wein`
  - now: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election,_2026` · `https://ballotpedia.org/Mikel_Wein`
- **Mikel Wein / AI Oversight**
  - was: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election` , `_2026` , `https://ballotpedia.org/Mikel_Wein`
  - now: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election,_2026` · `https://ballotpedia.org/Mikel_Wein`
- **Mikel Wein / Taxes**
  - was: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election` , `_2026` , `https://ballotpedia.org/Mikel_Wein`
  - now: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election,_2026` · `https://ballotpedia.org/Mikel_Wein`
- **Mikel Wein / Climate Change**
  - was: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election` , `_2026` , `https://ballotpedia.org/Mikel_Wein`
  - now: `https://ballotpedia.org/Kentucky%27s_5th_Congressional_District_election,_2026` · `https://ballotpedia.org/Mikel_Wein`
- **Matt Levine / Healthcare**
  - was: `https://www.levine4congress.com/key-issues` , `https://www.mycameronnews.com/stories/levine-emphasizes-message-offers-few-specifics-in-6th-district-interview` , `46874`
  - now: `https://www.levine4congress.com/key-issues` · `https://www.mycameronnews.com/stories/levine-emphasizes-message-offers-few-specifics-in-6th-district-interview,46874`
- **Josh Smead / Healthcare**
  - was: `https://votesmead.com/issues/` , `https://www.mycameronnews.com/stories/smead-emphasizes-rural-outreach-healthcare-access-in-6th-district-interview` , `46873`
  - now: `https://votesmead.com/issues/` · `https://www.mycameronnews.com/stories/smead-emphasizes-rural-outreach-healthcare-access-in-6th-district-interview,46873`
- **Josh Smead / Medicare/aid**
  - was: `https://www.mycameronnews.com/stories/smead-emphasizes-rural-outreach-healthcare-access-in-6th-district-interview` , `46873` , `https://votesmead.com/issues/`
  - now: `https://www.mycameronnews.com/stories/smead-emphasizes-rural-outreach-healthcare-access-in-6th-district-interview,46873` · `https://votesmead.com/issues/`
- **Josh Smead / Climate Change**
  - was: `https://www.mycameronnews.com/stories/smead-emphasizes-rural-outreach-healthcare-access-in-6th-district-interview` , `46873` , `https://votesmead.com/issues/`
  - now: `https://www.mycameronnews.com/stories/smead-emphasizes-rural-outreach-healthcare-access-in-6th-district-interview,46873` · `https://votesmead.com/issues/`

## REASONING SPLIT — 83 row(s): truncated voter-facing text restored

- **Benjamin Brooks / Abortion**
  - was: Brooks voted NO on SB 798 in 2023
  - now: Brooks voted NO on SB 798 in 2023, joining all 13 Republicans and only one other Democrat in opposing Maryland's reproductive freedom constitutional amendment — a significant departure from most Maryland Democrats.
- **Benjamin Brooks / Immigration**
  - was: Brooks signed a 2015 letter urging Governor Hogan to welcome Syrian refugees into Maryland
  - now: Brooks signed a 2015 letter urging Governor Hogan to welcome Syrian refugees into Maryland, opposing Hogan's restrictionist position. He voted for the Community Trust Act in 2026 limiting ICE cooperation.
- **Benjamin Brooks / Housing**
  - was: Brooks introduced the Building Affordably in My Backyard Act in 2026
  - now: Brooks introduced the Building Affordably in My Backyard Act in 2026, creating expedited approval processes for residential development in jurisdictions with documented affordable housing shortages.
- **Benjamin Brooks / Residential Zoning**
  - was: The Building Affordably in My Backyard Act that Brooks introduced in 2026 targets zoning barriers by expediting approvals in housing-shortage areas
  - now: The Building Affordably in My Backyard Act that Brooks introduced in 2026 targets zoning barriers by expediting approvals in housing-shortage areas, indicating support for zoning reform to increase supply.
- **Benjamin Brooks / Redistricting**
  - was: Brooks opposed Maryland's 2026 mid-decade congressional redistricting
  - now: Brooks opposed Maryland's 2026 mid-decade congressional redistricting, arguing it would be unrepresentative to eliminate Maryland's sole Republican congressional district. He avoided a definitive stance on whether it should receive a Senate vote.
- **Paul Corderman / Healthcare**
  - was: Corderman opposed a 24-hour addiction crisis center downtown and voted against drug violation decriminalization bills
  - now: Corderman opposed a 24-hour addiction crisis center downtown and voted against drug violation decriminalization bills, while sponsoring legislation increasing Medicaid reimbursements for EMS.
- **Paul Corderman / Criminal Justice**
  - was: Corderman introduced the Suzanne Jones Act requiring prisoners to be released to their home communities
  - now: Corderman introduced the Suzanne Jones Act requiring prisoners to be released to their home communities, and signed a letter opposing early COVID prisoner releases.
- **Brian Feldman / Abortion**
  - was: Feldman passed a 2023 bill requiring four-year public universities to provide students access to emergency contraception and abortion services
  - now: Feldman passed a 2023 bill requiring four-year public universities to provide students access to emergency contraception and abortion services, and supported birth control access legislation (SB527 2024). He consistently supports reproductive rights access legislation.
- **Brian Feldman / Medicare/aid**
  - was: Feldman's healthcare work has focused on private insurance affordability and drug pricing rather than direct Medicaid expansion
  - now: Feldman's healthcare work has focused on private insurance affordability and drug pricing rather than direct Medicaid expansion, though his 2019 Prescription Drug Affordability Board legislation affects Medicaid drug costs as well.
- **Brian Feldman / Environmental Protection vs. Development**
  - was: As Chair of the Education Energy and Environment Committee since 2023
  - now: As Chair of the Education Energy and Environment Committee since 2023, Feldman has jurisdiction over state environmental legislation and sponsored the Renewable Energy Certainty Act (SB0931 2025) streamlining siting for clean energy generating stations.
- **Brian Feldman / Campaign Finance**
  - was: Feldman sponsored the Public Ethics - Conflicts of Interest and Blind Trust - Governor bill (SB0723 2025) and Maryland Public Ethics Law compliance bill (SB0109 2025)
  - now: Feldman sponsored the Public Ethics - Conflicts of Interest and Blind Trust - Governor bill (SB0723 2025) and Maryland Public Ethics Law compliance bill (SB0109 2025), showing interest in government transparency and ethics enforcement.
- **Brian Feldman / Public Safety Approach**
  - was: Feldman's legislative record does not show primary criminal justice focus
  - now: Feldman's legislative record does not show primary criminal justice focus, though he supported gun buyback destruction requirements (voted for SB444 2025) and has addressed public safety through broader ethics and governance reforms.
- **Brian Feldman / Housing**
  - was: Feldman's medical debt legislation (2021) prevented home liens for medical debt
  - now: Feldman's medical debt legislation (2021) prevented home liens for medical debt, protecting homeowners from losing housing due to medical bills. His direct housing legislation record is limited beyond this protective measure.
- **Brian Feldman / Voting Rights**
  - was: Feldman chaired the Education Energy and Environment Committee that heard the Maryland Voting Rights Act of 2026 (SB255)
  - now: Feldman chaired the Education Energy and Environment Committee that heard the Maryland Voting Rights Act of 2026 (SB255), which passed April 28 2026 banning vote dilution in local elections. His committee role and consistent Democratic caucus alignment reflect strong support for voting rights protections.
- **Guy Guzzone / Healthcare**
  - was: Guzzone supported a single-payer healthcare system in Maryland (2011)
  - now: Guzzone supported a single-payer healthcare system in Maryland (2011), championed the Keep the Door Open Act increasing funding for behavioral health clinics, and chairs the Health and Human Services budget subcommittee.
- **Guy Guzzone / Climate Change**
  - was: Guzzone was named Maryland League of Conservation Voters Legislator of the Year in 2025. He established the Forest Conservation Task Force (2019) and Clean Water Commerce Fund (2021)
  - now: Guzzone was named Maryland League of Conservation Voters Legislator of the Year in 2025. He established the Forest Conservation Task Force (2019) and Clean Water Commerce Fund (2021), and has a long record with the Sierra Club.
- **Guy Guzzone / Environmental Protection vs. Development**
  - was: As a former State Director of the Sierra Club and former Chesapeake Bay Trust board member
  - now: As a former State Director of the Sierra Club and former Chesapeake Bay Trust board member, Guzzone introduced forest conservation legislation (2019) and the Clean Water Commerce Fund (2021). He preferred a plastic bag ban over mere taxation.
- **Guy Guzzone / Civil Rights**
  - was: Guzzone voted for transgender/non-binary anti-discrimination protections in 2011 and campaigned against repealing same-sex marriage in 2012
  - now: Guzzone voted for transgender/non-binary anti-discrimination protections in 2011 and campaigned against repealing same-sex marriage in 2012, demonstrating consistent support for LGBTQ+ civil rights.
- **Guy Guzzone / Same-Sex Marriage**
  - was: Guzzone actively campaigned against repealing same-sex marriage in Maryland (2012)
  - now: Guzzone actively campaigned against repealing same-sex marriage in Maryland (2012), demonstrating strong and early commitment to marriage equality.
- **Guy Guzzone / Taxes**
  - was: As Budget and Taxation Committee Chair
  - now: As Budget and Taxation Committee Chair, Guzzone has balanced fiscal responsibility with progressive priorities. He supported fuel tax indexing to inflation for infrastructure and online advertising taxes. He sponsored an Earned Income Tax Credit expansion (SB0668 2025) for lower-income workers.
- **Guy Guzzone / Childcare**
  - was: Guzzone sponsored the Community Eligibility Provision Expansion Program (SB0769 2025) expanding free school meals to more low-income children
  - now: Guzzone sponsored the Community Eligibility Provision Expansion Program (SB0769 2025) expanding free school meals to more low-income children, and sponsored Community Action Agencies funding (SB0666 2025) for anti-poverty services.
- **Guy Guzzone / Immigration**
  - was: Guzzone worked on legislation allowing sensitive locations like churches and schools to set their own immigration enforcement policies
  - now: Guzzone worked on legislation allowing sensitive locations like churches and schools to set their own immigration enforcement policies, including privacy protections for migrant data.
- **Guy Guzzone / Housing**
  - was: Guzzone co-sponsored legislation removing certain homes from tax sale when taxes consist only of unpaid water and sewer service liens
  - now: Guzzone co-sponsored legislation removing certain homes from tax sale when taxes consist only of unpaid water and sewer service liens, providing targeted tenant protection. His record is less focused on broad housing reform than other progressive Democrats.
- **Guy Guzzone / Economic Development Incentives**
  - was: Guzzone advocates responsible zoning for business growth and technology transfer
  - now: Guzzone advocates responsible zoning for business growth and technology transfer, prioritizes balanced budgets, and has focused on workforce development. His approach balances fiscal responsibility with supporting community economic growth.
- **Guy Guzzone / Homelessness**
  - was: Guzzone sponsored funding for Maryland Community Action Agencies (SB0666 2025) which provide homelessness prevention and anti-poverty services
  - now: Guzzone sponsored funding for Maryland Community Action Agencies (SB0666 2025) which provide homelessness prevention and anti-poverty services, and chairs the Health and Human Services budget subcommittee overseeing these funding streams.

_… 58 more in the rollback JSON._

## WHITESPACE — 163 row(s): a stray "\r" dropped, reasoning untouched


## ⚠ Held for hand review — 22 row(s)

- **Linda Sanchez / Housing** — split-URL candidate not proven by fetch (joined=403, truncated=403)
- **Mónica García / Immigration** — split-URL candidate not proven by fetch (joined=404, truncated=404)
- **Mónica García / Deportation** — split-URL candidate not proven by fetch (joined=404, truncated=404)
- **John Lee / Taxes** — prose in sources on a row whose reasoning is complete: "John Lee"
- **Benjamin Brooks / Public Safety Approach** — no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)
- **Brian Feldman / Healthcare** — no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)
- **Clarence Lam / Healthcare** — no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)
- **Clarence Lam / Medicare/aid** — no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)
- **Clarence Lam / Criminal Justice** — no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)
- **Steve Daines / Voting Rights** — prose in sources on a row whose reasoning is complete: "Susan Collins"
- **John Fleming / Healthcare** — prose in sources on a row whose reasoning is complete: "single-payer"
- **John Fleming / Immigration** — no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)
- **John Fleming / Religious Freedom** — no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)
- **Craig Zucker / Civil Rights** — no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)
- **Igor Tregub / Deportation** — split-URL candidate not proven by fetch (joined=200, truncated=200)
- **Igor Tregub / Immigration** — split-URL candidate not proven by fetch (joined=200, truncated=200)
- **Kris Fair / Misinformation** — prose in sources on a row whose reasoning is complete: "disinformation"
- **William Valentine / Voting Rights** — no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)
- **Gary Palmer / Campaign Finance** — prose in sources on a row whose reasoning is complete: "\"Given that individual contributions must be disclosed, I support fu
- **Garland Barr / Taxes** — prose in sources on a row whose reasoning is complete: "advocates \"single-rate tax system\""
- **Steven Horsford / School Vouchers** — prose in sources on a row whose reasoning is complete: "Don't gut education; get best teachers in classrooms"
- **Kelly Armstrong / School Vouchers** — prose in sources on a row whose reasoning is complete: "Our budget will support Education Savings Accounts"
