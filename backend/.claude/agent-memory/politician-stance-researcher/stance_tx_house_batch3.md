---
name: stance_tx_house_batch3
description: TX House 5 members 2026-05-18 batch3: Martinez(D-39), Walle(D-140), Gervin-Hawkins(D-120), Bumgarner(R-63), Buckley(R-54)
metadata:
  type: reference
---

# TX House Batch 3 — Researched 2026-05-18

## Politicians

### Armando Martinez (D-39, Weslaco/South Texas)
- ID: d9486e4a-490a-4d87-a495-655cce9700e2
- Capitol code: A3780
- Committees: Appropriations, Appropriations S/C Article III (VC), Natural Resources (VC), Disaster Preparedness (VC), House Administration, Secretary MALC
- Scored: abortion=2, school-vouchers=1, redistricting=1, deportation=2, immigration=2, trans-athletes=2, taxes=2, civil-rights=2
- Key: Rio Grande Valley border district, 20-year veteran Democrat; Secretary of Mexican American Legislative Caucus; participated in Aug 2025 redistricting walkout

### Armando Walle (D-140, Houston)
- ID: c456d802-e836-4208-8d18-33402c807429
- Capitol code: A4930
- Committees: Appropriations, S/C Articles VI/VII/VIII (Chair), Governmental Oversight (VC), Licensing & Admin Procedures; Deputy Floor Leader TX House Democrats
- Scored: abortion=2, school-vouchers=1, redistricting=1 (CONFIRMED walkout participant), deportation=2, immigration=2, trans-athletes=2, taxes=2, civil-rights=2
- Key: Wikipedia explicitly confirms 2025 redistricting walkout participation; supported fast food worker wages 2013

### Barbara Gervin-Hawkins (D-120, San Antonio)
- ID: 1a94bee0-7418-4b75-ba17-f3cf97d888aa
- Capitol code: A3445
- Committees: Appropriations, S/C Articles I/IV/V, Congressional Redistricting Select, Redistricting, Ways & Means
- Scored: abortion=2, school-vouchers=1, redistricting=1, deportation=2, immigration=2, trans-athletes=2, taxes=2, civil-rights=2
- Key: Serves on BOTH Redistricting AND Congressional Redistricting committees; co-founded George Gervin Youth Center 1991; focus: education + criminal justice

### Ben Bumgarner (R-63, Flower Mound/Roanoke, Denton County)
- ID: 586b4b4d-26f1-449c-90ba-55d4aec48066
- Capitol code: A4125
- Committees: Environmental Regulation, Pensions/Investments & Financial Services
- Scored: abortion=5 (HB1806 coauthor, NOT on SB31 exceptions), school-vouchers=5 (HB3 coauthor + SB2 cosponsor), deportation=4 (SB8 cosponsor), immigration=4, voting-rights=4 (HB5337 coauthor - proof of citizenship to vote), redistricting=4, trans-athletes=4, taxes=4
- Key: Voted to impeach Paxton and expel Slaton (shows some independence); supports banning Dems from committee chairmanships; Evolve Weapon Systems business owner

### Brad Buckley (R-54, Salado/Bell County)
- ID: d701afd5-c15c-48c4-8f16-54aa142a6769
- Capitol code: A3585
- Committees: Public Education (Chair), Natural Resources, Civil Discourse in Higher Ed (Select, Chair)
- Scored: abortion=4 (HB1806 coauthor + SB31 cosponsor=narrow exceptions), school-vouchers=5 (primary author HB3 + primary House sponsor SB2), deportation=4, immigration=4, redistricting=5, trans-athletes=4, taxes=4, fossil-fuels=4, climate-change=4
- Key: Veterinarian; authored HB4 (school accountability/assessment reform); authored meat-labeling bill (2021); authored school instructional materials (2023); SB31 cosponsor distinguishes him from Bumgarner on abortion (he supports narrow exceptions)

## Key TX 89th Session Bills Referenced
- SB2: School ESA/vouchers, signed May 3 2025; Buckley=primary House sponsor, Bumgarner=cosponsor
- HB3: ESA bill (stalled in committee); Buckley=primary author, Bumgarner=coauthor (signed 02/26/2025)
- HB1806: Bans govt support for abortion travel; Buckley and Bumgarner coauthored; signed into law
- SB31: Life of Mother Act (narrow abortion exceptions - life threat, ectopic, fetal death only); Buckley cosponsor, Bumgarner NOT on it
- SB8: Requires TX sheriffs to enter ICE cooperation agreements; Bumgarner cosponsor; signed June 20 2025
- HB5337: Proof of citizenship to register to vote; Bumgarner coauthor
- SB12: Bans gender identity instruction K-12, social transitioning; passed 89th session
- 2025 redistricting: TX House voted 88-52 Aug 20 2025 for GOP congressional maps; Dems walked out Aug 3 to deny quorum

## Source Patterns That Worked
- `capitol.texas.gov/Members/MemberInfo.aspx?Leg=89&Chamber=H&Code=[CODE]` — member info and committee list
- `capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=[BILL]` — who authored/coauthored
- `capitol.texas.gov/BillLookup/Sponsors.aspx?LegSess=89R&Bill=[BILL]` — House sponsors list
- `capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=[BILL]` — bill history incl. who sponsored
- `capitol.texas.gov/BillLookup/BillSummary.aspx?LegSess=89R&Bill=[BILL]` — bill summary
- Wikipedia for member backgrounds (en.wikipedia.org/wiki/[Name])
- en.wikipedia.org/wiki/2025_Texas_redistricting — redistricting walkout confirmation

## Source Patterns That FAILED
- Ballotpedia: empty pages for all 5 members
- ontheissues.org: 404 for all TX House members
- votesmart.org / justfacts.votesmart.org: 403 blocked
- legiscan.com: 403 blocked
- texastribune.org/people/[name]: most 404; /brad-buckley/ works but minimal content
- capitol.texas.gov author/coauthor reports: 404/500
- capitol.texas.gov vote records (journal HTML): 404
