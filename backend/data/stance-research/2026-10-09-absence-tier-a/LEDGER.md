# Absence tier-A queue — per-row ledger

**Queue:** 317 voter-facing rows / 237 people. **10 blocked** (`immigration`, the only live topic
with no Season 2 ladder) → **307 actionable**.

## ⚖ THE TEST APPLIED TO EVERY ROW
**Is the absence DOING THE SEATING?** An absence is legitimate when it rules out a NEIGHBOURING
rung on top of real evidence. It is a defect when it supplies the specificity the evidence lacks —
typically beside an **affiliation**: party, caucus, committee seat, an alignment score, an
endorsement, or an ideological label.

Second test, applied throughout: **does the evidence distinguish the seated rung from its
NEIGHBOURS?** Direction alone picks a BAND, not a rung.

## 🔑 THE REMEDY IS A SEASON 2 BLANK, AND THE CARRY QUESTION DOES NOT APPLY
Every row here is a Season 1 row with **no** Season 2 answer. Verified in `compassService.ts`:
`cs` resolves the stance text from `pa.topic_revision_id` — **the answer's own revision** — so a
Season 1 answer is displayed with Season 1 rung text and Season 1 reasoning. These rows are
internally coherent; they are not mislabelled by the Season 2 ladder.

So a defect is fixed by writing a Season 2 answer of **0**, which SUPPRESSES (verified: the guard
sits outside the season collapse, `NULLIF(pa.value, 0)`), never by re-seating on the S2 ladder.
⚠ **Consequence: the 24 NO_CARRY and 4 GONE ladder findings do NOT generate blanks.** The ladder
analysis was still worth doing — it ruled out a whole class of harm — but it is not decision-making
here. Recorded in `carry_rulings.py` for the next pass that *does* repair forward.

**A sound row gets NO ACTION.** It is already serving correctly.

---

## Batch 1 — 22 rows · **17 BLANK · 5 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 1 | Bryan Hughes | healthcare | 4 | **BLANK** | "Ranked most conservative Texas senator" + "no evidence of supporting public option". A ranking is not a position. |
| 2 | Bryan Hughes | medicare/aid | 4 | **BLANK** | Same ranking + absence; "consistent with partial privatization" is the row inferring the rung. |
| 3 | Bryan Hughes | redistricting | 5 | **BLANK** | Committee chairmanship + "supported party-drawn maps" does not separate rung 5 from rung 4 (legislature control *with* court backstop). Band, not rung. |
| 4 | Bryan Hughes | ukraine-support | 3 | **BLANK** | Says **"Likely endorses"** outright. Pure inference from a conservatism ranking. |
| 5 | Charles Perry | campaign-finance | 4 | **BLANK** | "No campaign finance reform legislation" + oil/gas ties. Absence + affiliation. |
| 6 | Charles Perry | healthcare | 4 | **BLANK** | Committee vice-chairmanship + party + absence. |
| 7 | Charles Perry | redistricting | 5 | **BLANK** | "Appointed to the Committee **as a Republican**" — the affiliation is doing the work. |
| 8 | Charles Perry | ukraine-support | 3 | **BLANK** | "No evidence of strong advocacy **either way**" and then a rung is seated anyway. |
| 9 | Cynthia Lummis | homelessness | 4 | **BLANK** | "no record of…" + "fiscal conservative stance … **suggest** she favors". |
| 10 | Cynthia Lummis | jail-capacity | 4 | **BLANK** | Mandatory minimums evidence a punitive BAND; "Hard-Core Conservative" is an OTI label, not a position. |
| 11 | Cynthia Lummis | redistricting | 4 | **BLANK** | "founding Freedom Caucus member" — caucus membership, already ruled not a position. |
| 12 | Cynthia Lummis | housing | 5 | **BLANK** | Same caucus inference + "no record of". |
| 13 | Deidre M. Henderson | campaign-finance | 4 | **KEEP** | Her **iSideWith profile** states the position; the absence only rules out a louder claim. ⚠ source class worth a later look. |
| 14 | Deidre M. Henderson | healthcare | 4 | **KEEP** | Opposed Medicaid expansion in the Utah Senate **(2015)**, with her stated reason. Dated, attributed, specific. |
| 15 | Deidre M. Henderson | redistricting | 4 | **BLANK** | The evidence describes **the legislature's** maps and her implementing court orders — not her own position. Chair needs evidence for *that* chair. |
| 16 | Deidre M. Henderson | social-security | 3 | **KEEP** | FY2021 budget proposal to eliminate the state tax on SS benefits — a concrete act of the administration she is in. |
| 17 | Janice Hahn | data-centers | 3 | **BLANK** | Measure W is **stormwater**. Adjacent-topic inference plus "no direct statements found". |
| 18 | Janice Hahn | misinformation | 2 | **KEEP** | **Chaired a county task force on election and COVID misinformation** — her own act; the absence correctly rules out the takedown rung above. |
| 19 | Janice Hahn | religious-freedom | 3 | **BLANK** | "she **would** resist religious exemptions" — an explicit counterfactual. |
| 20 | Janice Hahn | trans-athletes | 2 | **BLANK** | Pride flag, a resource centre and a commission appointment are affiliations; "aligns with Democratic mainstream" is party inference. |
| 21 | Jerry McNerney | deportation | 2 | **BLANK** | DREAMer support does not separate rung 2 from 1 or 3; a **100% Biden alignment score** is not a position. |
| 22 | Jerry McNerney | healthcare | 2 | **KEEP** | Named positions — ACA expansion, opposing privatization, Medicare drug-price negotiation — plus his own statement. |

**Running total: 22 adjudicated · 17 BLANK · 5 KEEP (77% defect rate).**
⚠ Higher than the 50% sample estimate, and the reason is visible: this batch is ordered by rows-per-person,
and the 4-row people are disproportionately the inference-seated ones. Expect the rate to fall in the
1-row tail. **Do not project the final number from here.**

---

## Batch 2 — 22 rows · **19 BLANK · 3 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 23 | Jerry McNerney | religious-freedom | 3 | **BLANK** | Co-founding the Freethought Caucus is an affiliation, and it does not separate rung 3 from its neighbours. |
| 24 | Jerry McNerney | trans-athletes | 2 | **BLANK** | Real votes (DADT repeal, school non-discrimination) but on a DIFFERENT question; nothing addresses trans athletes. |
| 25 | John Sununu | ai-regulation | 3 | **BLANK** | Row says the position predates the AI era, then seats one from a **Club for Growth 100% rating**. |
| 26 | John Sununu | redistricting | 4 | **BLANK** | "84.4% Republican voting alignment" — an alignment score is not a position. |
| 27 | John Sununu | trans-athletes | 4 | **BLANK** | "the issue was not yet legislatively prominent" + a **Christian Coalition rating**. Seats a rung on an anachronism. |
| 28 | John Sununu | voting-rights | 4 | **BLANK** | Two scorecards (84.4% R, 13% ACLU) and "suggest". |
| 29 | Luis A. Ojeda | economic-development | 3 | **BLANK** | "transformative development" and "opportunities for stakeholders" do not reach the incentives-with-conditions rung. |
| 30 | Luis A. Ojeda | homelessness-response | 2 | **KEEP** | **Co-signed the Feb 3 2026 order** to secure emergency shelter for winter 2026-27. Named, dated, his own act — squarely rung 2. |
| 31 | Luis A. Ojeda | public-safety-approach | 3 | **BLANK** | An **all-council** order for hearings is not distinctive to him, and hearings on mental health do not separate rung 3 from rung 2. |
| 32 | Luis A. Ojeda | housing | 4 | **BLANK** | The absence legitimately rules out 1, 2 and 5 — but what is left is a BAND (3-4), and the positive evidence ("affordable housing initiatives") actually sits against rung 4, which is deregulation. |
| 33 | Shamann Walton | ai-regulation | 3 | **BLANK** | Row states outright that AI has not featured in his record, and that no score can be derived. |
| 34 | Shamann Walton | tariffs | 3 | **BLANK** | "outside his direct legislative purview" + "his progressive economic stance is consistent with". |
| 35 | Shamann Walton | trans-athletes | 1 | **BLANK** | Caucus memberships and the CAREN Act (racist 911 calls) — a real ordinance, on another subject. |
| 36 | Shamann Walton | ukraine-support | 2 | **BLANK** | "outside his purview" + "progressive alignment … consistent with". |
| 37 | Angus S. King, Jr. | ai-regulation | 3 | **BLANK** | The Cyberspace Solarium Commission is real and his, but it is CYBERSECURITY; it states no position on AI rules. |
| 38 | Angus S. King, Jr. | misinformation | 3 | **BLANK** | Same commission, same gap: election security is not a position on platform misinformation policy. |
| 39 | Angus S. King, Jr. | religious-freedom | 3 | **BLANK** | "no strong documented position … his general approach … positions him at the center". Seated by temperament. |
| 40 | Bernie Moreno | healthcare | 5 | **KEEP** | His own stated position — Obamacare "had zero to do with affordability", opposes government involvement — which does reach the top rung. |
| 41 | Bernie Moreno | judicial-interpretation | 5 | **BLANK** | Trump alliance, Second Amendment and pro-life positions used to infer a JUDICIAL philosophy. Positions on other topics are not this chair. |
| 42 | Bernie Moreno | social-security | 3 | **KEEP** | Named legislation (Working Families Tax Cut Bill, no tax on Social Security) in his own press release. |
| 43 | Brian Birdwell | redistricting | 5 | **BLANK** | "Appointed … **as a Republican**" — identical shape to Perry #7. |
| 44 | Brian Birdwell | tariffs | 3 | **BLANK** | "Defense/military background **suggests** nationalist trade instincts." |

**Running total: 44 adjudicated · 36 BLANK · 8 KEEP (82%).**
🔴 **My prediction in batch 1 was wrong so far — the rate went UP, not down.** But it is not yet
tested: the queue is ordered by rows-per-person and batches 1-2 are entirely 4-row and 3-row
people. The 1-row tail (185 people) starts later. **Still do not project the final number.**

---

## Batch 3 — 22 rows · **14 BLANK · 8 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 45 | Brian Birdwell | ukraine-support | 3 | **BLANK** | Purple Heart and Bronze Star are biography; "military background **suggests** support". |
| 46 | Dan Osborn | fossil-fuels | 3 | **BLANK** | "No specific stance on new drilling permits found" + an inference from being a Nebraska union worker. |
| 47 | Dan Osborn | redistricting | 3 | **BLANK** | The row says it outright: "**no recorded position exists**. Scored as no clear evidence" — and then carries a rung. |
| 48 | Dan Osborn | voting-rights | 3 | **BLANK** | "has not taken a clear public stance on voter ID, mail-in voting, or voting access". |
| 49 | James Lankford | fossil-fuels | 4 | **KEEP** | States his position directly — supports expanding oil and gas exploration, opposes EPA emission rules. ⚠ The "$1.5 million in career contributions" clause should go: donors are not a position. |
| 50 | James Lankford | public-safety-approach | 4 | **BLANK** | An **NRA A-rating** and gun-control votes are a different question; mandatory minimums give a band, not rung 4. |
| 51 | James Lankford | school-vouchers | 4 | **BLANK** | "OTI records … strongly supporting school choice" is a BAND covering rungs 3-5; rung 4 is a specific eligibility claim. |
| 52 | Kurt Alme | climate-change | 5 | **BLANK** | "No public statements" + alignment with Trump + **endorsements from energy and agricultural interests**. |
| 53 | Kurt Alme | deportation | 5 | **BLANK** | Says plainly that **no public statements distinguish him** from the administration, then seats the administration’s rung. |
| 54 | Kurt Alme | healthcare | 5 | **BLANK** | Endorsement + a Taxpayer Protection Pledge + "suggest". |
| 55 | Kwame Raoul | abortion | 2 | **KEEP** | Campaigned on safe, legal and accessible abortion; as AG made reproductive rights an office priority. The absence correctly rules out rung 1 (public funding at all stages) ON TOP of that. |
| 56 | Kwame Raoul | healthcare | 3 | **BLANK** | Antitrust monitoring and Medicaid-fraud investigation are the **duties of the office**, not a policy position. |
| 57 | Kwame Raoul | medicare/aid | 3 | **BLANK** | Same: enforcing Medicaid compliance is his job, not a stance on expanding it. |
| 58 | Lois Frankel | fossil-fuels | 2 | **KEEP** | Supports banning offshore drilling in the Gulf — a specific position that reaches the stop-new-permits rung. |
| 59 | Lois Frankel | healthcare | 2 | **KEEP** | Opposed ACA repeal, supports expansion through mixed public/regulated-private coverage. Named and specific. |
| 60 | Lois Frankel | medicare/aid | 3 | **KEEP** | Opposes privatization and any benefit cuts, defended the ACA’s Medicare provisions — a defensive position, which IS rung 3. |
| 61 | Terry Taplin | abortion | 2 | **BLANK** | Being "shocked and saddened" by Dobbs is documented but does not separate rung 2 from 1 or 3; the rest is "as a progressive Democrat". |
| 62 | Terry Taplin | economic-development | 3 | **BLANK** | A list of priorities (waterfront, marina, Vision 2050) is not a position on incentives and conditions. |
| 63 | Terry Taplin | fossil-fuels | 2 | **BLANK** | A committee chairmanship and **Berkeley’s** record; neither states his position on permits. |
| 64 | Tommy Tuberville | homelessness-response | 5 | **KEEP** | Dated June 2025 remarks advocating defunding cities and opposing social-service spending — reaches the withdraw-funding rung. |
| 65 | Tommy Tuberville | public-safety-approach | 5 | **KEEP** | "police need more money", expanding police budgets as top priority, mandatory minimums. Attributed and specific. |
| 66 | Tommy Tuberville | housing | 5 | **KEEP** | States opposition to federal housing programs and reliance on private markets. |

**Running total: 66 adjudicated · 50 BLANK · 16 KEEP (76%).**
Rate easing as predicted, but still multi-row people. 🔑 A new sub-shape appears here and is worth naming:
**the duties of an office are not a position** (Raoul x2 — an AG investigating Medicaid fraud is doing his job,
not advocating a Medicaid policy), and **a city’s record is not its councillor’s position** (Taplin).

---

## Batch 4 — 22 rows · **18 BLANK · 4 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 67 | Alan Wong | fossil-fuels | 2 | **BLANK** | Divesting from fossil fuels is a FINANCIAL position; rung 2 is about stopping new drilling PERMITS. Different mechanism — and it rests on a 2020 City College platform carried forward by "no documented reversal". |
| 68 | Alan Wong | rent-regulation | 2 | **KEEP** | He "explicitly backed expanding rent control", which is exactly this rung. ⚠ Flag for a later pass: the source is a **2020 City College** platform held over into a 2025 supervisorial role. |
| 69 | Amir Omar | public-safety-approach | 3 | **BLANK** | Opens "**Inferred from city policy**". Richardson PD’s Crisis Intervention Team is the CITY’s program, not his stated position. |
| 70 | Amir Omar | housing | 4 | **BLANK** | "Inferred from council record", and the record is **unanimous** votes taken "under both pre-Omar and Omar leadership" — nothing distinctive to him. |
| 71 | Brad Raffensperger | social-security | 3 | **BLANK** | The row says his retirement tax plan "**does not address federal Social Security**" and seats a federal rung anyway. |
| 72 | Brad Raffensperger | ukraine-support | 4 | **BLANK** | The row explains its own evidence away: Russia sanctioned him for **certifying the 2020 election**, not over Ukraine policy. |
| 73 | Courtney Daily | homelessness | 2 | **KEEP** | Despite the "Inferred from" opener, the content is an **explicit endorsement of housing-first at a dated candidate forum (Feb 2024)**. That is a position, stated by her. |
| 74 | Courtney Daily | transportation-priorities | 2 | **BLANK** | Council budget priorities are the body’s, not hers; "No direct statement" does the rest. |
| 75 | Cynthia S. Creem | school-vouchers | 1 | **BLANK** | S.683 is real but concerns special-education healthcare costs. Adjacent topic plus an absence. |
| 76 | Cynthia S. Creem | trans-athletes | 1 | **BLANK** | S.197 protects LGBTQ data from location surveillance — a real bill on a different question. |
| 77 | David Robertson | deportation | 3 | **BLANK** | "**Moderate default for a Democrat** without a clear deportation policy record." States the method and the absence in one line. |
| 78 | David Robertson | medicare/aid | 3 | **BLANK** | "Moderate Democrat with no evidence of either expansion or cuts." |
| 79 | David Toland | medicare/aid | 2 | **KEEP** | A **documented advocate for Medicaid expansion**, repeatedly calling it a top priority for the Governor’s second term. |
| 80 | David Toland | housing | 4 | **BLANK** | Administering LIHTC and CDBG is the department’s job — and targeted housing assistance sits AGAINST rung 4, which is deregulation. |
| 81 | Dianne Primavera | fossil-fuels | 3 | **BLANK** | The row states it: "no evidence was found of her **personally** calling for a ban on new drilling permits". |
| 82 | Dianne Primavera | housing | 4 | **BLANK** | Converting a corrections facility to homeless housing is targeted intervention, which contradicts rung 4 rather than evidencing it. |
| 83 | Donald H. Wong | abortion | 4 | **BLANK** | "Zero co-sponsorships" + "as a Republican who declines all progressive legislation" + "consistent with GOP caucus". |
| 84 | Donald H. Wong | medicare/aid | 3 | **BLANK** | "**Moderate Republican default** maintaining current programs." |
| 85 | Donna Howard | climate-change | 2 | **BLANK** | "Progressive Democrat representing Austin" and "**Austin Democrats** consistently support" — party and geography. |
| 86 | Donna Howard | taxes | 2 | **BLANK** | Repealing the sales tax on menstrual products and diapers is a real vote, but it does not evidence raising taxes on high earners. |
| 87 | Henry L. Foster III | homelessness | 3 | **KEEP** | His **platform** calls for permanent supportive housing and wraparound services; the absence is an honest limit about one specific camping-ban vote, not the basis of the seat. |
| 88 | Henry L. Foster III | taxes | 3 | **BLANK** | District demographics plus "has not been identified as either" — budget votes maintaining services do not pick this rung. |

**Running total: 88 adjudicated · 68 BLANK · 20 KEEP (77%).**

### 🔑 Four sub-shapes now named, all distinct from "affiliation + absence"
1. **The BODY’s act is not the MEMBER’s position** — a city programme, a unanimous council vote, a
   council budget priority (Omar x2, Daily 74, Taplin 63). Watch for the opener "Inferred from council…".
2. **The duties of an office are not a position** — an AG investigating Medicaid fraud, a department
   administering LIHTC (Raoul x2, Toland 80).
3. **Evidence on an ADJACENT topic** — a real, named bill about something else (Creem x2, Raffensperger x2,
   Howard 86). The row is checkable and still does not carry the claim.
4. **"Zero co-sponsorships" + a party default** stated outright (D. Wong x2, Robertson x2).

⚠ Counter-note: "Inferred from…" is NOT by itself a tell. Daily 73 opens with it and then gives an
explicit endorsement at a dated forum. Read past the opener — this is why the earlier corpus-wide
"inferred" probe was measured and set aside rather than shipped as a queue.

---

## Batch 5 — 22 rows · **13 BLANK · 9 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 89 | Jay Northcut | residential-zoning | 3 | **BLANK** | Approvals made by the CITY under his mayoralty; and approving multifamily does not pick rung 3 over its neighbours. |
| 90 | Jay Northcut | transportation-priorities | 4 | **KEEP** | 🔑 The absence is INSIDE HIS OWN DOCUMENT: his campaign site’s transportation section is "exclusively road-focused" with no mention of transit. That characterises his platform — it is evidence, not a gap in the world. |
| 91 | Jim Jordan | school-vouchers | 4 | **KEEP** | Quoted and dated — "Vouchers break link of low-income and low-quality schools" (Oct 2015), plus DC opportunity scholarships. |
| 92 | Jim Jordan | tariffs | 3 | **KEEP** | Supported USMCA (Dec 2019) — real evidence — and the absence then rules out BOTH extremes to seat the middle. The legitimate shape. ⚠ The "50% USAE rating" clause adds nothing and should go. |
| 93 | Jimmy Patronis | climate-change | 4 | **KEEP** | His own anti-ESG campaign against climate criteria in state pension management, plus opposing land conservation deals. |
| 94 | Jimmy Patronis | deportation | 4 | **KEEP** | States support for specific policies — completing the border wall, strict enforcement. |
| 95 | John McKinney | local-immigration | 2 | **BLANK** | "has not publicly stated a position on sanctuary city policy" and his campaign "does not address Special Order 40 or ICE cooperation". |
| 96 | Jon Ossoff | abortion | 2 | **KEEP** | Condemned Dobbs, pledged to confirm only judges upholding Roe, defends Planned Parenthood funding. The absence rules out rung 1 on top of that. |
| 97 | Jon Ossoff | fossil-fuels | 3 | **KEEP** | YEA on the IRA and **blocked the Okefenokee titanium mine (2022)**; the absence rules out the stop-all-permits rung above. |
| 98 | Judith Zaffirini | redistricting | 2 | **BLANK** | "a Democrat from a safe majority-Latino district" + "Texas Democrats have generally opposed". |
| 99 | Judith Zaffirini | tariffs | 3 | **BLANK** | "Her district context **suggests**" — Laredo’s trade economy is not her stated position. |
| 100 | Karen E. Spilka | religious-freedom | 3 | **BLANK** | Seated at the centre by "no evidence of extremes in either direction"; the LGBTQ evidence is on an adjacent question. |
| 101 | Karen E. Spilka | school-vouchers | 1 | **BLANK** | MassReconnect is free community college — it evidences public-education funding, not eliminating vouchers, which is the limb the absence covers. |
| 102 | Katy Hall | misinformation | 4 | **BLANK** | "**97% Republican caucus loyalty**" — a loyalty score is not a position. |
| 103 | Katy Hall | rent-regulation | 4 | **BLANK** | Same 97% caucus loyalty plus "no rent control legislation". |
| 104 | Katy Yaroslavsky | economic-development | 3 | **BLANK** | "No direct statement or vote found specifically on business incentive policy"; the rest is background and campaign tone. |
| 105 | Katy Yaroslavsky | fossil-fuels | 2 | **BLANK** | Former employment at Climate Action Reserve offered as "**a signal of**" her position. An employer’s mission is not her stance. |
| 106 | Keith B. Goodenough | civil-rights | 2 | **KEEP** | A real recorded position (OnTheIssues, 2008) directly on the question. ⚠ VINTAGE FLAG: 2008, carried by "no 2026 statement". |
| 107 | Keith B. Goodenough | school-vouchers | 1 | **KEEP** | Records him opposing vouchers (Jun 2008) — squarely rung 1. ⚠ Same vintage flag. |
| 108 | Kevin Sparks | redistricting | 5 | **BLANK** | Committee membership + "Republican-controlled Texas". No stance found, stated. |
| 109 | Kevin Sparks | ukraine-support | 3 | **BLANK** | Trump endorsement + "Trump’s Republican Party has been skeptical". |
| 110 | LaNae Millett | homelessness-response | 4 | **BLANK** | "No direct Orem-specific homelessness policy statements found"; seated from "framing" and fiscal temperament. |

**Running total: 110 adjudicated · 81 BLANK · 29 KEEP (74%).** Rate easing.

### 🔑🔑 THE SHARPEST DISTINCTION THIS QUEUE HAS PRODUCED
**An absence INSIDE the person’s own document is EVIDENCE. An absence in the world is not.**
Northcut (90) is seated because his own campaign site’s transportation section is road-only — what it
omits characterises what he is proposing. Millett (110) is seated because nobody could find a statement.
Same words ("no mention of"), opposite evidential status. ▶ **A future detector must separate these or it
will fire on the best rows**, which is exactly how `rungquote` died.

⚠ NEW FLAG, not a blank: **VINTAGE**. Goodenough (106, 107) rests on OnTheIssues records from **2008**
and Alan Wong (68) on a **2020 City College** platform, each carried forward by "no reversal documented".
The positions are real and on point, so they are KEEPs — but staleness is a separate defect class from
absence-seating, and these three should be re-checked against anything more recent. 3 rows so far.

---

## Batch 6 — 22 rows · **16 BLANK · 6 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 111 | LaNae Millett | local-environment | 3 | **BLANK** | Tree planting and parks inspection scores are real acts, but neither states a position on the ladder; Utah Lake Commission is a seat. |
| 112 | Laura Downs | economic-development | 3 | **BLANK** | A stated concern about state preemption, then "**suggesting** she values local control" — the inference to the incentive rung is the row’s, not hers. |
| 113 | Laura Downs | school-vouchers | 2 | **BLANK** | Her platform evidences the public-funding limb; the voucher limb comes entirely from "No evidence of voucher support found" — which, if anything, points at rung 1. Band, not rung. |
| 114 | Lisa Murkowski | ai-regulation | 3 | **BLANK** | FISA reform (2024) is a different question; the row opens "No direct evidence found". |
| 115 | Lisa Murkowski | redistricting | 3 | **BLANK** | "No direct evidence found"; Alaska having one at-large district is a structural fact, not her position. |
| 116 | Lois Kolkhorst | redistricting | 5 | **BLANK** | "has **benefited from** partisan redistricting" + alignment with the majority. Neither is a stance. |
| 117 | Lois Kolkhorst | ukraine-support | 3 | **BLANK** | "Trump-aligned Republicans have been skeptical" — a group’s tendency, not hers. |
| 118 | Matt Dorsey | trans-athletes | 2 | **BLANK** | 🔴 Seated on **being openly gay** plus unnamed "voting record and public statements". Being LGBTQ is already on the record as an affiliation, not a position. |
| 119 | Matt Dorsey | transportation-priorities | 3 | **BLANK** | Agency presidency and authority membership are ROLES; "reflecting engagement" is not a stated position. |
| 120 | Matt Mahan | local-immigration | 3 | **BLANK** | San Jose’s sanctuary policies "**predate his tenure**", and the rest is "suggests moderate". |
| 121 | Matt Mahan | transportation-priorities | 3 | **BLANK** | "No direct evidence of a distinctive transportation stance", then a rung. |
| 122 | Phil Weiser | social-security | 3 | **BLANK** | Suing to block DOGE access to SSA systems (Feb 2025) is real and his — but it is about DATA SECURITY, and the row concedes "no documented position on expanding or cutting benefits", which is what the ladder asks. |
| 123 | Phil Weiser | same-sex-marriage | 3 | **BLANK** | Named litigation, but pro-LGBTQ advocacy does not evidence rung 3’s RELIGIOUS-EXEMPTION limb — "no documented stance opposing" is what places him there. |
| 124 | Raj Salwan | city-sanitation | 3 | **KEEP** | His platform names street cleanup and maintaining facilities as priorities; the absence then rules out the significantly-expanded rung above. Legitimate shape. |
| 125 | Raj Salwan | residential-zoning | 3 | **BLANK** | "No direct vote record is accessible"; the zoning position is read off an Innovation District description. |
| 126 | Raul Torrez | climate-change | 3 | **BLANK** | PFAS contamination suits are a different question, and enforcing existing regulation is the office’s job. |
| 127 | Raul Torrez | fossil-fuels | 3 | **BLANK** | The row says it: "**no documented position on fossil fuel drilling permits or extraction policy**". |
| 128 | Ruben Gallego | abortion | 2 | **KEEP** | Supported **Arizona Proposition 139 (2024)** to enshrine abortion rights — named, dated, specific. Absence rules out rung 1 on top. |
| 129 | Ruben Gallego | childcare | 2 | **KEEP** | Backed ARPA and Build Back Better childcare funding during his House tenure. Named vehicles. |
| 130 | Tony Wied | climate-change | 5 | **KEEP** | ⚠ An LCV score, but **decomposed into the record it summarises** — 33 anti-environment votes to 0, against clean air, efficiency standards and renewables — plus his own campaign’s energy-deregulation emphasis. A score reported with its votes is a record. |
| 131 | Tony Wied | deportation | 4 | **KEEP** | Publicly defended ICE agents and supports Remain in Mexico. Stated positions. |
| 132 | Aaron Ford | same-sex-marriage | 3 | **KEEP** | Quoted (April 2022) and backed by AG litigation defending LGBTQ civil rights; the absence rules out the opposing rung. ⚠ This is one of the 4 rows whose S1 rung 3 is **invalidated** in S2 — immaterial here, since the remedy is a blank and the S1 row displays on the S1 ladder. |

**Running total: 132 adjudicated · 97 BLANK · 35 KEEP (73%).**

### 🔑 A fifth sub-shape: THE EVIDENCE IS ON A DIFFERENT AXIS THAN THE LADDER
Weiser 122 is the clearest case in the queue. The lawsuit is real, dated, named and HIS — and it is about
data security, while the ladder asks about benefit levels. The row even concedes the gap in the same
sentence. **Checkable is not the same as on-point**; this is [[enacted_vehicle_rule]] applied to litigation
rather than bills. Same shape: Torrez 126 (PFAS ≠ climate), Murkowski 114 (FISA ≠ AI).

⚠ And the counter-case that keeps it honest: Wied 130 is seated on an **LCV score**, which is normally a
disqualifier — but the row reports the votes behind it (33-0, named subjects). **A score given with its
record is a record.** Blanking it would have been the detector’s rule beating the evidence.

---

## Batch 7 — 22 rows · **12 BLANK · 10 KEEP**  *(the one-row tail begins)*

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 133 | Addison P. McDowell | fossil-fuels | 4 | **KEEP** | States support for offshore drilling and ANWR drilling in his own **iSideWith responses**, and opposition to production regulation. |
| 134 | Alek Bartrosouf | economic-development | 2 | **KEEP** | The Northcut shape: his platform is small-business permitting throughout, with **no mention of large corporate subsidies** — which is exactly what rung 2 excludes. An absence inside his own document. |
| 135 | Alyson Sullivan-Almeida | medicare/aid | 4 | **BLANK** | "Republican with no Medicare expansion advocacy found" — and then "no evidence of privatization advocacy either". Two absences and a party. |
| 136 | Amelia Powers Gardner | homelessness-response | 3 | **KEEP** | Supported and **helped fund** the county warming center through the budget — maintaining existing programmes is precisely this rung. |
| 137 | Andy Martin | medicare/aid | 3 | **KEEP** | His own **2026 Citizens Count survey** answers oppose Medicare for All on both models, ruling out the rung above; nothing points below. |
| 138 | Angelia Pelham | public-safety-approach | 4 | **BLANK** | 🔴 "Inferred from council consensus" + "**No record of Pelham dissenting**". Absence of dissent read as agreement, on a body’s budget vote. |
| 139 | Angélica María Dueñas | same-sex-marriage | 2 | **BLANK** | A general LGBTQIA+ protection commitment does not reach rung 2’s specific claim (nationwide recognition with full federal benefits); "democratic-socialist progressive" does the rest. |
| 140 | Ann Millner | taxes | 4 | **KEEP** | **Championed Utah’s 2023 rate cut, 4.85% → 4.65%**, within a $400M package. Named, dated, hers. |
| 141 | Anna Paulina Luna | medicare/aid | 4 | **BLANK** | "**98% Heritage Action score**" plus an absence. |
| 142 | Asaad Alnajjar | fossil-fuels | 3 | **BLANK** | Solar street lighting and EV charging are real platform items; the row concedes "**no stated position on oil drilling permits or extraction**". |
| 143 | Ashley Moody | campaign-finance | 4 | **BLANK** | "has not championed" + "did not pursue" + "Trump-aligned". Two absences and an alignment. |
| 144 | Bilal Mahmood | misinformation | 3 | **BLANK** | A Waymo robotaxi hearing is tech scrutiny on another subject; "No specific stance on misinformation regulation" is conceded. |
| 145 | Bob Ferguson | medicare/aid | 3 | **KEEP** | **Defended the ACA** in court and won the Providence Health charity-care settlement — preserving existing programmes is this rung, and these are his own named actions, not office routine. |
| 146 | Brady Brammer | fossil-fuels | 5 | **KEEP** | "**Explicitly stated support for coal and natural gas development**", wanting Utah to lead energy exports with all fossil options on the table. |
| 147 | Brandon Gordon | housing | 4 | **BLANK** | An administrative role plus "**No strong ideological housing position**" — the row disclaims the seat it then takes. |
| 148 | Brian L Bengs | ukraine-support | 2 | **KEEP** | Supported providing aircraft to Ukraine — directly on the question. ⚠ VINTAGE FLAG, and the strongest one yet: a **2022** campaign statement, and he has since **changed party** (Democrat → independent). |
| 149 | Bridget Brink | tariffs | 2 | **KEEP** | Direct quote — "Roll back Trump’s reckless tariffs, which have raised costs for all consumers". |
| 150 | Brooke Jenkins | local-immigration | 3 | **BLANK** | "**operates within** SF’s sanctuary framework" is a description of her jurisdiction; "no evidence she has publicly opposed" seats the rung. |
| 151 | Bryant Acosta | residential-zoning | 2 | **BLANK** | "**implying** support for zoning reforms", with detailed positions "**not publicly available**". |
| 152 | Burhan Azeem | homelessness-response | 2 | **BLANK** | **Cambridge’s** approach, then "No direct votes or statements from Azeem specifically". |
| 153 | Byron Donalds | deportation | 4 | **KEEP** | Platform positions stated: pro-ICE, anti-sanctuary, defunding non-compliant entities. |
| 154 | Caitlin Dube | school-vouchers | 1 | **BLANK** | Her platform is detailed and entirely public-school — but rung 1 is about **eliminating vouchers**, and a platform that never mentions them does not state that. Band (1-2), not rung. |

**Running total: 154 adjudicated (50%) · 109 BLANK · 45 KEEP (71%).**
✅ The batch-1 prediction is now bearing out: 77 → 82 → 76 → 77 → 74 → 73 → **71%** as the queue moves
from 4-row people into the one-row tail. The multi-row people really were the inference-seated ones.

⚠ VINTAGE flag now 4 rows (68, 106, 107, 148). Bengs is the sharpest: a 2022 position carried by "no
updated 2026 statement" **across a party change**. Still a KEEP — it is a real position on the exact
question — but it is the one most likely to be wrong today.

---

## Batch 8 — 22 rows · **12 BLANK · 10 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 155 | Callie Barr | abortion | 2 | **KEEP** | Her own iSideWith 2024 profile and a pro-choice platform; the absence rules out rung 1 (public funding at all stages) on top. |
| 156 | Callie Carroll | homelessness-response | 3 | **BLANK** | "**served on council when** Springfield approved…" — the city’s grant application, and then "No direct Carroll statement". |
| 157 | Candice B. Pierucci | taxes | 4 | **KEEP** | ⚠ Opens with a 96% party-loyalty score, but then names what she actually supported — the **2025 income tax rate reduction and child tax credit expansion** — plus her own platform. |
| 158 | Carleigh Beriont | taxes | 2 | **KEEP** | States the position outright: raise taxes on corporations and the wealthy, protect working people, cap large-corporate price increases. |
| 159 | Carlos A. Gimenez | tariffs | 3 | **KEEP** | A dated recorded position (Feb 2021) endorsing trade through fair agreements; the absence rules out the blanket-tariff rung. |
| 160 | Carmen Chu | climate-change | 3 | **BLANK** | The row concedes her record is "limited to local infrastructure actions" and that she has served "**without a documented record**". |
| 161 | Carol Alvarado | civil-rights | 2 | **KEEP** | **Documented opposition to anti-DEI bills** is a real position on this ladder; the absence rules out rung 1 (reparations). |
| 162 | Catherine Cortez Masto | religious-freedom | 3 | **BLANK** | Opposing the contraception exemption is real — but it points AWAY from the centre, and it is "no evidence of an explicitly strict separationist position" that places her at 3. The absence picks the rung against the evidence’s direction. |
| 163 | Chris Killpack | public-safety-approach | 4 | **BLANK** | "Supporting first responders" is a band (3-5), not rung 4; the rest is a **PAC endorsement**. |
| 164 | Chyanne Chen | city-sanitation | 3 | **KEEP** | Platform names parks and street improvements, and the absence rules out the enforcement-first rung above. Same shape as Salwan 124. |
| 165 | Cole Hefner | redistricting | 5 | **BLANK** | "party affiliation and voting pattern with Freedom Caucus members **strongly suggests**". |
| 166 | Crystal Muhlestein | homelessness-response | 3 | **BLANK** | "**No specific documented position** … found in campaign materials or public record"; advisory-board seats are not positions. |
| 167 | Cynthia F. Friedman | redistricting | 3 | **BLANK** | 🔴 The row states the method in its own words: "**Absence of activity on this topic places her at** maintaining current…". |
| 168 | Daniel Meuser | voting-rights | 4 | **KEEP** | Recorded as requiring voter ID and opposing same-day registration — directly on the S2 identification axis, which most voting-rights rows miss. |
| 169 | David Chiu | ai-regulation | 3 | **BLANK** | "No direct evidence", "No Assembly bills on AI were found", "**Assigned** a moderate" — the row describes assigning, not finding. |
| 170 | David F. Bristol | public-safety-approach | 4 | **KEEP** | Despite the "Inferred from" opener: he **chaired the 2020 $210M bond committee** funding police and fire expansion and **publicly endorsed** the PD drone programme. Both are his acts. |
| 171 | David Jacobs | local-environment | 3 | **KEEP** | **Moved the referral (Jan 20 2026) and moved the final approval (Apr 6 2026)** of the Squantum Elementary solar PPA. Moving a motion is his act even where the vote is 9-0. |
| 172 | David T. Vieira | medicare/aid | 3 | **BLANK** | "No co-sponsorship" + "no evidence of privatization push" + "**moderate default**". |
| 173 | Debbie Wasserman Schultz | housing | 4 | **BLANK** | Targeted housing assistance is evidence AGAINST rung 4, which is deregulation — so the seat rests on "No specific evidence of support for universal public housing or rent caps". |
| 174 | Derek Dooley | climate-change | 5 | **KEEP** | The Northcut shape again: his own economic priorities page says "unleash American energy" **with no mention of climate change at all** — which is precisely what rung 5 describes. |
| 175 | Derek Tran | transportation-priorities | 3 | **BLANK** | "No direct statement by Tran … was found", then a district description. |
| 176 | Diego Morales | misinformation | 4 | **BLANK** | Coalition membership, and the **group’s** emphasis offered as his position. |

**Running total: 176 adjudicated (57%) · 121 BLANK · 55 KEEP (69%).** Still easing.

🔑 Two rows this batch are the clearest statements of the defect the queue exists to find, in the
corpus’s own words: Friedman 167 — "**Absence of activity on this topic places her at**…" — and Chiu 169,
"**Assigned** a moderate value". Neither claims to have found anything.

---

## Batch 9 — 22 rows · **14 BLANK · 8 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 177 | Donna Miller | medicare/aid | 2 | **BLANK** | A dated, explicit interview — but opposing $880bn in cuts is DEFENDING the programme, which is rung 3. It does not evidence rung 2 (significantly expand). Band, not rung. |
| 178 | Elise M. Stefanik | childcare | 4 | **BLANK** | "No record of supporting…" plus "her **general governing philosophy**". |
| 179 | Erin Houchin | homelessness | 4 | **BLANK** | The **Affordable HOMES Act (H.R. 5184, passed 263-147, Jan 2026)** is real, named and hers — and it is housing deregulation, while this ladder asks about encampment enforcement. Off-axis, the Weiser shape. |
| 180 | Eugene Vindman | abortion | 2 | **KEEP** | Campaigned explicitly on restoring abortion rights nationwide; the absence rules out rung 1. |
| 181 | Eunice Lehmacher | tariffs | 2 | **KEEP** | Quotes her calling the tariffs "illegal" and costly; the absence rules out eliminating tariffs entirely. |
| 182 | Fiona Ma | religious-freedom | 3 | **BLANK** | "No direct statements … were found." Conversion-therapy co-authorship is real but on another question; the rest is endorsements. |
| 183 | Frank LaRose | deportation | 4 | **BLANK** | Referring registrations to DOJ is election administration — the duties of his office — and an "invasion" line is rhetoric "**signaling**" a deportation rung. |
| 184 | Garrett McGuire | housing | 4 | **BLANK** | "Expand housing supply" is consistent with rungs 3, 4 and 5 alike. Band, not rung. |
| 185 | George Casey | transportation-priorities | 3 | **BLANK** | Transit-oriented development points BELOW rung 3; and the row concedes "no explicit positions found on bike lanes, pedestrian infrastructure, parking requirements" — the ladder’s actual terms. |
| 186 | Glenn Thompson | fossil-fuels | 4 | **KEEP** | Called for OCS and ANWR drilling and has consistently supported expanding offshore oil and gas; opposes EPA greenhouse-gas regulation. |
| 187 | Grace Meng | healthcare | 2 | **BLANK** | Opposing ACA repeal is real but spans rungs 1-3; **Medicare for All Caucus membership** would point to rung 1, and it is "No evidence she…" that picks 2 instead. |
| 188 | Gretchen Whitmer | misinformation | 3 | **KEEP** | **Signed 2024 legislation requiring disclaimers on AI-generated political ads** — her own act — and the absence rules out the platform-wide mandate rung above. |
| 189 | Guy Reschenthaler | healthcare | 4 | **BLANK** | "OnTheIssues documents **no explicit healthcare stance**", then fiscal temperament and an ARP vote that is not a healthcare position. |
| 190 | Hampton Harris | abortion | 4 | **KEEP** | His site opposes abortion AND **does not state a no-exceptions ban** — an omission in his own document that marks the boundary with rung 5. |
| 191 | Heather Smiley | abortion | 4 | **KEEP** | Supported the Missouri abortion ban measure, plus her own iSideWith profile; the absence rules out rung 5’s criminal penalties. |
| 192 | Henry Santana | school-vouchers | 1 | **BLANK** | "A proud product of public schools" in his own questionnaire is real — but it is not a position on **eliminating vouchers**. |
| 193 | Hilda L. Solis | school-vouchers | 1 | **BLANK** | An **NEA 100% rating** and education funding votes; neither states a position on eliminating vouchers. |
| 194 | Hillary J. Scholten | abortion | 2 | **KEEP** | **Quoted scripture on the House floor defending abortion access** — a specific, attributable act; the absence rules out rung 1. |
| 195 | Isaac G. Bryan | trans-athletes | 1 | **BLANK** | An **Equality California endorsement** and the fact that **California law** already allows participation. Neither is his position. |
| 196 | J.B. Jennings | misinformation | 3 | **BLANK** | "as a Republican he **would be expected to** be skeptical". |
| 197 | Jacob Bouma-Sims | medicare/aid | 2 | **KEEP** | A specific proposal — lowering effective Medicare eligibility to **26** for qualifying categories — which is exactly "expand eligibility, stopping short of universal". |
| 198 | Jason Brown II | school-vouchers | 1 | **BLANK** | Detailed public-school platform with no mention of vouchers — but see the rule below: omission cannot evidence an affirmative commitment to eliminate them. |

**Running total: 198 adjudicated (64%) · 135 BLANK · 63 KEEP (68%).**

### ⚖ REFINEMENT to the "absence in his own document" rule — it has a LIMIT
An omission characterises an **EMPHASIS or PRIORITY**; it cannot evidence an **AFFIRMATIVE COMMITMENT**.
Northcut (90) and Dooley (174) are KEEPs because their ladders ask what a person PRIORITISES, and a
road-only or energy-only page answers that. Dube (154), Santana (192) and Brown (198) are BLANKs because
school-vouchers rung 1 asks whether they would **eliminate voucher programmes** — and a platform that never
mentions vouchers does not say. 🔑 **Ask what the rung is a claim ABOUT before reading an omission as evidence.**

---

## Batch 10 — 22 rows · **16 BLANK · 6 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 199 | Jeff Cheney | public-safety-approach | 4 | **BLANK** | "**under Cheney**" is passive, the budget is the council’s, and the "public statements" are never quoted. Contrast Bristol 170, who chaired the bond committee and endorsed the programme himself. |
| 200 | Jeff Lambson | economic-development | 3 | **BLANK** | Beautification and a CARE Tax renewal are not business-incentive policy; "**votes alongside** pro-development" is not a position. |
| 201 | Jen Plumb | data-centers | 2 | **BLANK** | The **caucus** questioned the proposals; "**No individual Plumb statement identified**". |
| 202 | Jennifer Campbell | city-sanitation | 3 | **BLANK** | A committee chairmanship and a newsletter promoting a reporting app; neither states where she sits on the ladder. |
| 203 | Jerry Carl | deportation | 4 | **KEEP** | Recorded as supporting ICE enforcement and opposing sanctuary cities; the absence then rules out rung 3’s long-term-resident carve-out. |
| 204 | Jim Banks | homelessness | 4 | **BLANK** | "no record of" + general opposition to federal spending. |
| 205 | Joan Huffman | climate-change | 5 | **BLANK** | Three absences in four sentences — no legislation found, no funds allocated, no evidence of any climate policy support. |
| 206 | Joaquín Torres | homelessness-response | 2 | **KEEP** | **12 years as SF Housing Authority Commission President**, with a described record of public-housing rehabilitation and transfers to affordable programmes. A record of what he did in office, on this ladder’s axis. |
| 207 | Jocelyn Benson | abortion | 2 | **BLANK** | Announcing a campaign on the Roe anniversary is symbolism and **Reproductive Freedom for All** is an endorsement; the rung is then picked by "no evidence she". |
| 208 | Joe Mitchell | climate-change | 4 | **KEEP** | Quotes his platform — "every tool", gas, oil, nuclear, coal, hydro, solar, wind — **with no mention of emissions targets or mandates**. An all-of-the-above energy page IS the let-the-market-decide rung. |
| 209 | Joe Neguse | abortion | 2 | **KEEP** | His own **Project Vote Smart survey (Aug 2018)** answer, and the absence rules out rung 1. |
| 210 | John Barrasso | housing | 5 | **BLANK** | "no record of" plus the label "**hard-core conservative**". |
| 211 | John Boozman | homelessness-response | 4 | **BLANK** | "**91.5% Trump alignment voting record** … **suggests he would favor**". |
| 212 | John C. Velis | redistricting | 3 | **BLANK** | "No evidence of co-sponsorship" + "**Did not sign the transparency pledge**". Two absences, nothing else. |
| 213 | John F. Keenan | redistricting | 3 | **BLANK** | Chairs Elections Laws, "but no independent commission legislation visible" — a committee seat and an absence. |
| 214 | John Fleming | school-vouchers | 4 | **BLANK** | Recorded as "supporting school vouchers" — which spans rungs 3-5. Rung 4 claims eligibility for **most families**. Contrast Jordan 91, who is quoted on the specific mechanism and a named programme. |
| 215 | John Hoeven | ai-regulation | 3 | **BLANK** | "No documented specific position … was found", then general philosophy. |
| 216 | John J. Cronin | redistricting | 3 | **BLANK** | Two absences and nothing else in the row at all. |
| 217 | John Leiber | taxes | 4 | **BLANK** | His 2025 statement is about **spending restraint and safeguarding investments**, not tax rates. 🔑 Opposing increases is not proposing cuts — the documented re-seat rule. |
| 218 | John Shulli | fossil-fuels | 5 | **KEEP** | His own call to "unleash American oil, natural gas, and coal", with no environmental limits anywhere on the page. |
| 219 | Joseph D. Morelle | abortion | 2 | **BLANK** | His own PVS survey says **unrestricted** abortion rights — that is rung 1. The absence on public funding is what pulls him down to 2, against the direction of his own evidence. |
| 220 | Josh Stein | campaign-finance | 2 | **KEEP** | Supported new restrictions on independent expenditures (2010) in his legislative record; the absence rules out the public-financing-only rung. |

**Running total: 220 adjudicated (72%) · 151 BLANK · 69 KEEP (69%).**

### 🔑 A sixth sub-shape: THE ABSENCE OVERRIDES THE EVIDENCE’S OWN DIRECTION
The nastiest variant, because the row looks well-sourced. The positive evidence points at one rung and
an absence drags the seat to a different one:
- **Morelle 219** — his own survey says "unrestricted abortion rights" (rung 1); "no documented stance on
  public funding" seats him at 2.
- **Cortez Masto 162** — she opposed the contraception exemption (away from centre); "no evidence of a
  strict separationist position" seats her at the centre.
- **Miller 177** — opposing $880bn of cuts is rung 3 (defend); she is seated at 2 (expand).
🔑 **Check which way the positive evidence points BEFORE asking whether the absence is legitimate.** An
absence may only ever narrow a range the evidence already establishes — never move it.

---

## Batch 11 — 22 rows · **15 BLANK · 7 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 221 | José Menéndez | same-sex-marriage | 2 | **BLANK** | "no record of opposing" + "did not co-author any anti-LGBTQ legislation" + an urban district. Three absences and a geography. |
| 222 | Juanita Lopez | local-environment | 3 | **KEEP** | A detailed, specific platform of her own — 24/7 sanitation, per-district departments, littering enforcement. The absence is not what seats it. |
| 223 | Karen McCandless | public-safety-approach | 3 | **BLANK** | "No explicit reform-oriented positions found, but **also no** strong punitive stance" — seated at the centre by two absences plus a former employer. |
| 224 | Kathy Kimberlin | public-safety-approach | 3 | **BLANK** | Co-founding a coalition and sitting on a Chamber committee are affiliations; "public safety is a top priority" is not a rung. |
| 225 | Keith Ellison | abortion | 2 | **KEEP** | As AG he **joined a 2025 multistate coalition** challenging the executive orders — a concrete act on this topic, not just the NARAL ratings. |
| 226 | Keith Grover | voting-rights | 4 | **KEEP** | "**Supports requiring photo ID for voting**" — directly on the S2 identification axis. |
| 227 | Kenneth Fredette | medicare/aid | 4 | **BLANK** | Well sourced — he led the opposition and wrote the op-ed (2013) — but **opposing an expansion is not proposing a scale-back**. Rung 4 claims active reduction. Same rule as Leiber 217. ⚠ Also VINTAGE (2013). |
| 228 | Kim Schrier | social-security | 3 | **BLANK** | A **2022 NCPSSM endorsement** plus "no documented positions" on either direction. |
| 229 | Kris Mayes | same-sex-marriage | 3 | **KEEP** | Her **303 Creative statement (June 2023)** is squarely the rung-3 question — religious objection versus equal service — plus Fair Housing enforcement. |
| 230 | Kristina Knickerbocker | voting-rights | 2 | **BLANK** | "Protecting voting rights" is generic, and the S2 rung 2 is a specific claim about accepting **non-photo ID**. The row concedes she "does not specify". |
| 231 | Kyle Blomquist | ai-regulation | 3 | **BLANK** | He does support AI regulation — framed on privacy and IP. Rung 3 is the **liability** mechanism. Band, not rung. |
| 232 | Laura Kelly | abortion | 2 | **KEEP** | Opposed the 2020 constitutional amendment ("a return to the dark ages") and campaigned against the 2022 Kansas referendum. Named, dated, quoted. |
| 233 | Lindsay Sabadosa | redistricting | 3 | **BLANK** | 🔴 In its own words: "**Insufficient evidence to assign a specific value — defaulting to** bipartisan committee standard." |
| 234 | Lindsey Dougherty | school-vouchers | 1 | **BLANK** | Public-school platform with "no mention of vouchers" — omission cannot evidence eliminating them. |
| 235 | Lindsey P. Horvath | ai-regulation | 3 | **BLANK** | "No specific public positions on AI oversight policy found"; AI "has not been a prominent part of her public platform". |
| 236 | Lucy McBath | climate-change | 3 | **BLANK** | A **97% LCV score** and "publicly favors green energy" — and unlike Wied 130, no votes are named behind the score. |
| 237 | Lydia M. Edwards | ukraine-support | 2 | **BLANK** | 🔴 "No evidence of any opposing position. **Scored based on her p[arty]**." |
| 238 | Maggie Toulouse Oliver | redistricting | 2 | **BLANK** | "has consistently supported independent redistricting" is asserted with no source, in a row headed "No documented position"; the rest is **New Mexico’s** system. |
| 239 | Marc C. McGovern | homelessness-response | 2 | **KEEP** | Named programmes he ran — Cambridge’s **first warming center**, the Winter Warmth Drive, Metro Boston Homeless Summit coordination. |
| 240 | Marie Gluesenkamp Perez | fossil-fuels | 3 | **BLANK** | A 57% LCV lifetime score with yearly percentages, and "**suggests** she votes to maintain". A score without its votes. |
| 241 | Mark C. Downey | school-vouchers | 1 | **BLANK** | A quoted but generic public-education passage; no mention of vouchers either way. |
| 242 | Mark Dorazio | civil-rights | 4 | **KEEP** | "**Explicitly opposes prosecutor discretion**" and frames equal enforcement of existing law as the fairness standard — which is what rung 4 says. |

**Running total: 242 adjudicated (79%) · 166 BLANK · 76 KEEP (69%).**

🔑 **The score rule, now settled across the queue.** Wied 130 KEEP (33-0 with the subjects named),
McBath 236 and Gluesenkamp Perez 240 BLANK (percentages only). **A score is admissible exactly when the
row reports the record behind it**; otherwise it is a third party’s summary standing in for a position.

---

## Batch 12 — 22 rows · **14 BLANK · 8 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 243 | Mark Warner | school-vouchers | 1 | **BLANK** | Public-school funding support plus "has not supported" — not a position on eliminating vouchers. |
| 244 | Martin Heinrich | religious-freedom | 3 | **BLANK** | "No evidence found of … an extreme position"; ENDA support "**suggests**" the rest. |
| 245 | Mary E. Miller | misinformation | 4 | **BLANK** | The Protecting Our Democracy Act vote is real but on another question; the rest is **Freedom Caucus** alignment. |
| 246 | Matt Gromlich | abortion | 2 | **KEEP** | His own Q&A — a decision for patients and doctors, not politicians — and the omission narrows WITHIN the range that statement establishes rather than moving it. |
| 247 | Matt Meyer | school-vouchers | 1 | **BLANK** | Being a former public-school teacher and running on school funding is not a position on vouchers. |
| 248 | Maurice Mercer | abortion | 2 | **KEEP** | A specific platform position: supports the right to decide, and supports life through adoption/foster/family support **rather than legal restrictions**. |
| 249 | Melanie Lucero | climate-change | 5 | **KEEP** | **Explicitly opposes Green New Deal regulations** as job-killing, and her energy page is fossil expansion with no climate content at all. |
| 250 | Michael D. Brady | redistricting | 3 | **BLANK** | Two absences, nothing else. |
| 251 | Michael J. Moran | religious-freedom | 3 | **BLANK** | Opens "**No documented position.**" and seats one anyway. |
| 252 | Michael Watson | redistricting | 5 | **BLANK** | "has **no documented record**", plus his party and his state’s practice. |
| 253 | Mike Ezell | deportation | 4 | **BLANK** | "a consistent advocate for stronger border enforcement" is an unsourced characterisation spanning rungs 3-5. |
| 254 | Mike Lee | ai-regulation | 2 | **BLANK** | "no documented AI-specific legislation" + libertarian philosophy. One of the original sample true positives. |
| 255 | Mike Riley | transportation-priorities | 2 | **BLANK** | Strong sourcing — he co-chaired the coalition that won Bend’s **$190M 2020 GO Bond** — but the row says the bond funded "a roughly even mix", which is rung 3, not prioritising non-car modes. ⚠ Also pre-council and "no more recent statement". |
| 256 | Mitch McConnell | ai-regulation | 2 | **BLANK** | "no direct AI legislation record", then net-neutrality and FCC votes that "**indicate**" a position on AI. |
| 257 | Nancy Mannion | childcare | 3 | **KEEP** | Supports expanding childcare **tax credits** — the rung’s own mechanism — and the omission marks the boundary with universal public funding above. |
| 258 | Nicholas A. Langworthy | healthcare | 4 | **KEEP** | His site’s healthcare section is competition, doctor choice and telemedicine throughout, with no public-coverage content. The Northcut shape, on a rung about framework. |
| 259 | Pamela Campos | local-environment | 3 | **BLANK** | The row concedes "no specific votes or statements on tree preservation, environmental review requirements" — the ladder’s actual terms. |
| 260 | Patricia D. Jehlen | religious-freedom | 3 | **BLANK** | Healthy Youth Act and S.2155 are named and hers, but on another question; "no evidence of an explicit position on religious exemptions" is conceded. |
| 261 | Peggy Flanagan | misinformation | 3 | **BLANK** | "No direct stance found"; her page "does not take a specific position". |
| 262 | Pete Lynch | climate-change | 3 | **KEEP** | Platform commits to public power and renewables investment — the rung’s content — and the omission marks it short of a phase-out. |
| 263 | Pete Ricketts | same-sex-marriage | 5 | **KEEP** | A directly quoted stated position — "marriage is the union of one woman and one man". ⚠ **VINTAGE, and the most severe in the queue: 2006**, i.e. nine years before Obergefell. The row is careful to note he missed the 2022 RFMA vote. |
| 264 | Phil Scott | campaign-finance | 3 | **KEEP** | Recorded supporting donation restrictions (Apr 2008); the absence rules out both extremes. ⚠ VINTAGE (2008). |

**Running total: 264 adjudicated (86%) · 180 BLANK · 84 KEEP (68%).**

⚠ **VINTAGE flag now 6 KEEPs: 68, 106, 107, 148, 263, 264.** Ricketts (2006) and Goodenough (2008) are
the oldest. Every one is a real, on-point, attributed position carried forward by an absence of anything
newer — so none is an absence-seating defect, and none is blanked here. But **this is a queue of its own**
and it should be worked as one: a position stated before the law changed under it is the likeliest
kind of row to be wrong today.

---

## Batch 13 — 22 rows · **13 BLANK · 9 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 265 | Rafael Mandelman | trans-athletes | 1 | **BLANK** | Opening 28 beds at Jazzie’s Place is a real act for trans residents — and it is shelter policy, not athletics. Off-axis, plus "openly gay supervisor". |
| 266 | Rebecca Bennett | school-vouchers | 1 | **BLANK** | **NJEA and NEA endorsements**, plus an inference about whom those bodies endorse. Two steps removed from her. |
| 267 | Rick Crosson | abortion | 2 | **KEEP** | His own issues page — decisions belong to women and their doctors, opposing criminalisation — with the omission narrowing within that range. |
| 268 | Rick Scott | ai-regulation | 2 | **BLANK** | "No detailed AI regulatory position found", then the 11-Point Plan and a philosophy. |
| 269 | Riley M. Moore | climate-change | 5 | **KEEP** | His **signature action as WV Treasurer — penalising banks over ESG fossil-lending policies**. A named act of his own, not just the 0% score. |
| 270 | Robert B. Aderholt | deportation | 4 | **BLANK** | A **100% FAIR rating** plus positions (opposing pathways, backing the wall) that span rungs 3-5 without picking 4. |
| 271 | Robert Menendez | abortion | 2 | **KEEP** | The score rule satisfied: 100% from Reproductive Freedom for All, **reported with the votes behind it** — NAY on every tracked restriction 2023-25, H.R. 21 named. |
| 272 | Roby Smith | climate-change | 4 | **BLANK** | **SFOF membership** "signals", plus an endorsement of another politician. |
| 273 | Ron Estes | tariffs | 3 | **KEEP** | Supported **USMCA (Dec 2019)**; the absence then rules out both extremes. Same shape as Jordan 92. |
| 274 | Ronald Mariano | same-sex-marriage | 2 | **BLANK** | **Massachusetts’** pioneering role and what "Massachusetts Democrats" do — the state’s record offered as his position. |
| 275 | Rusty MacLachlan | transportation-priorities | 4 | **BLANK** | A 35-year home-building background and "the **county’s** road-focused mandate". |
| 276 | Ruthzee Louijeune | trans-athletes | 1 | **BLANK** | Championing Boston’s LGBTQIA+ Sanctuary City designation is hers and named — and it is not about sports participation. Off-axis, as Mandelman 265. |
| 277 | Ryan Tubbs | transportation-priorities | 4 | **KEEP** | Two dated sources (Celina Record 2026-01, Community Impact Q&A 2026-03), specific road projects named, and **no transit content** — the Northcut shape with the sources shown. |
| 278 | Sarah Chadzynski | childcare | 2 | **BLANK** | "Cutting childcare costs" names no mechanism, so it does not pick rung 2. Contrast Mannion 257, who names tax credits. |
| 279 | Scott Brown | abortion | 2 | **KEEP** | Described himself as pro-choice, called Roe settled law, protested the 2012 GOP platform change. ⚠ VINTAGE (2012-14) and "No 2026 position was found". |
| 280 | Scott Colom | same-sex-marriage | 3 | **BLANK** | Opens "**no documented explicit stance on same-sex marriage**"; the DA letter concerns gender-affirming surgery. |
| 281 | Scott DesJarlais | fossil-fuels | 4 | **KEEP** | States support for offshore drilling and gas exploration and opposition to EPA greenhouse-gas rules. |
| 282 | Sean Garballey | campaign-finance | 3 | **BLANK** | Three absences in two sentences and nothing else. |
| 283 | Seth Magaziner | abortion | 2 | **KEEP** | Dated statement (Jun 2022) that he will keep fighting for the right to choose; the absence rules out rung 1. |
| 284 | Seth Moulton | homelessness | 2 | **BLANK** | "his progressive record **suggests**" + "No explicit criminalization stance found". The row the original 100-row scan missed. |
| 285 | Shana Anderson | fossil-fuels | 2 | **BLANK** | "**implies** moving away from fossil fuel-dependent growth, though no direct statement on fossil fuels specifically". |
| 286 | Shelley Moore Capito | religious-freedom | 4 | **KEEP** | Supported faith-based exemptions and backs legislation protecting religious organisations — directly this rung. |

**Running total: 286 adjudicated (93%) · 193 BLANK · 93 KEEP (67%).**

🔑 **"Off-axis" is now the commonest reason a WELL-SOURCED row still fails.** Mandelman 265 and
Louijeune 276 both name real, attributable LGBTQ acts of their own — shelter beds, a sanctuary
designation — on a ladder about **athletics**. Nothing is wrong with the citation; it answers a
different question. Cf. Weiser 122, Houchin 179, Colom 280.

---

## Batch 14 (final) — 21 rows · **13 BLANK · 8 KEEP**

| # | person | topic | v | call | why |
|---|---|---|---|---|---|
| 287 | Stacy Garrity | deportation | 4 | **BLANK** | A dated statement (Aug 2025) — about ending **Medicaid and public benefits**, not about deportation. Off-axis. |
| 288 | Stephen Lynch | data-centers | 3 | **BLANK** | "has not taken a specific public stance"; his district is "not a major data center development zone". |
| 289 | Stephen Sherrill | rent-regulation | 4 | **BLANK** | Props C and D are named and his positions on them are real — they are **business tax measures**, not rent regulation. |
| 290 | Stephen Whitburn | same-sex-marriage | 2 | **BLANK** | A former employer and the district he represents. |
| 291 | Steve Carlson | abortion | 4 | **KEEP** | His platform frames abortion as permissible only to preserve the mother’s life, **with no rape or incest exceptions mentioned** — the omission is what places him precisely, inside his own document. |
| 292 | Steve Womack | ukraine-support | 3 | **BLANK** | "has not taken an extreme isolationist position" + "**no specific record**". Two absences. |
| 293 | Sydney Zulich | economic-development | 3 | **BLANK** | "**Inferred from general positioning.** No direct statements … were found", then Bloomington’s tools. |
| 294 | Sylvia Luke | social-security | 3 | **BLANK** | A real state record on senior programmes, and "**No direct statement or vote on Social Security**" — which is the ladder. |
| 295 | Tan Parker | fossil-fuels | 5 | **BLANK** | "as a conservative Texas Republican he aligns with Texas’s oil/gas dominant economy". |
| 296 | Tate Reeves | ai-regulation | 2 | **KEEP** | **Launched Mississippi’s statewide AI framework (May 2026)** — guidelines rather than mandates, which is rung 2 exactly; the absence rules out the approval-requirement rung. |
| 297 | Taylor Rehmet | housing | 4 | **BLANK** | 🔴 "**insufficient evidence to differentiate from baseline**" — and a value is recorded anyway. |
| 298 | Tim Cywinski | school-vouchers | 1 | **BLANK** | A detailed public-school platform (IDEA, block grants, free meals, Pre-K) that never mentions vouchers. |
| 299 | Tim Moore | climate-change | 5 | **KEEP** | Named dated votes — weakening environmental regulation (Jun 2020), supporting hydraulic fracturing (Jul 2012). |
| 300 | Tim Sheehy | abortion | 4 | **KEEP** | Stated life begins at conception and criticised **Montana Initiative 128**; supports IVF. Specific and his. |
| 301 | Tim Walz | campaign-finance | 2 | **KEEP** | Stated support for **public funding of campaigns** — directly this rung. ⚠ VINTAGE (2006). |
| 302 | Tish Hyman | local-immigration | 3 | **BLANK** | Two absences and nothing else in the row. |
| 303 | Traci Crockett | housing | 5 | **KEEP** | Her housing section is removing regulatory barriers, opposing mandates and empowering the free market — rung 5 in her own words. |
| 304 | Trent Deckard | housing | 4 | **BLANK** | **ARPA-funded housing investment is evidence AGAINST rung 4**, which is deregulation. Same inversion as Wasserman Schultz 173. |
| 305 | Troy A. Carter | abortion | 2 | **KEEP** | Opposed fetal heartbeat bills as a state senator (2019) and stated the position again in 2021. |
| 306 | Ty Pinkins | abortion | 2 | **KEEP** | His **current 2026** site states the position, and the omission narrows within it. The cleanest version of this shape in the queue. |
| 307 | Wray Wade | transportation-priorities | 3 | **BLANK** | 🔴 A committee **liaison role** and **presenting a constituent with a bus pass** for heroism. Neither is a transportation position. |

---

# ✅ READ COMPLETE — 307 of 307 actionable rows

|  | rows |
|---|---|
| **BLANK** — the absence (or an affiliation beside it) is doing the seating | **206** |
| **KEEP** — sound; no action, the Season 1 row goes on serving | **101** |
| *blocked* — `immigration`, the only live topic with no Season 2 ladder | *10* |
| **total in queue** | **317** |

**Final defect rate 67%** (206/307). The detector's measured precision from a 12-row sample was ~50%;
the true figure is **67%**, so the sample **under**-estimated it. 🔑 The per-batch trend ran
77 → 82 → 76 → 77 → 74 → 73 → 71 → 69 → 68 → 69 → 69 → 68 → 67 → 67: high among multi-row people,
settling in the one-row tail, exactly as predicted after batch 2 — but never falling near 50%.

## ⚖ What a BLANK here means
The chair is not supported by the row's own reasoning. It does **not** mean the person holds no
position — only that nobody has shown one. Each blank is written as a Season 2 answer of `0`, which
SUPPRESSES the Season 1 row rather than re-seating it, and carries an INTERNAL RECORD saying which
kind of nothing it is.

## ▶ Two queues this pass created and did not work
1. **VINTAGE — 8 KEEPs** (68, 106, 107, 148, 263, 264, 279, 301). Real, on-point, attributed
   positions held over by "no reversal documented": Ricketts **2006** (pre-Obergefell), Goodenough
   **2008**, Walz **2006**, Bengs **2022 and across a party change**. Not absence defects, so not
   blanked — but the likeliest rows in the corpus to be wrong *today*.
2. **The 10 `immigration` rows** stay blocked. No Season 2 ladder exists to write to.

