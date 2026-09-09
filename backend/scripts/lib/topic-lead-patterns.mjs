/**
 * topic-lead-patterns.mjs — which of the open season's topics a bill TITLE hints at.
 *
 * Pure, so it can be tested without an API key or a database. The fetching half
 * lives in congress-sponsorship-leads.mjs; this is the half that decides what a
 * title is about, and it is the half worth pinning with tests.
 *
 * 🔴 A TITLE MATCH IS A LEAD, NEVER A CHAIR. This says a bill's NAME mentions a
 * subject. It does not say what the bill does, which direction it pushes, or
 * which of five chairs its cosponsor sits in. Bill titles are written to
 * persuade — "Protect American Values Act" is a real cosponsored bill whose name
 * carries no policy content at all. Everything these patterns produce is a
 * pointer for a human to open and read.
 *
 * Deliberately BROAD, and deliberately DUMB about direction:
 *   · broad, because a false lead costs one read while a missed one costs a chair
 *   · dumb, because inferring a stance from a title is the exact error the chair
 *     discipline exists to prevent — a gun-safety bill and a carry-expansion bill
 *     both match /firearm/, and that is correct behaviour here
 */

/** topic_key → title pattern, for the nine topics Season 2 added federally. */
export const TOPIC_PATTERNS = {
  'gun-policy':            /assault weapon|firearm|\bgun\b|ghost gun|high-capacity|magazine capacity|background check|red flag|concealed carry/i,
  'minimum-wage':          /minimum wage|raise the wage|living wage|tipped wage/i,
  'cannabis-policy':       /cannabis|marijuana|hemp|descheduling/i,
  'border-security':       /border security|asylum|\bborder\b|port of entry|migrant|immigration enforcement|title 42/i,
  'defense-spending':      /defense authorization|defense appropriation|\bndaa\b|military construction|pentagon budget|defense budget/i,
  'military-intervention': /war powers|authorization for use of military force|\baumf\b|hostilities|troop withdrawal/i,
  'israel-military-aid':   /israel|foreign military financing|arms sale|arms transfer/i,
  '2020-election':         /electoral count|election certification|january 6|presidential election|electoral college/i,
  'ranked-choice-voting':  /ranked[- ]choice|instant runoff|proportional representation|voting method|single transferable/i,
};

/** Every topic whose pattern the title hints at. One bill may raise several. */
export function matchTopics(title) {
  if (!title) return [];
  return Object.entries(TOPIC_PATTERNS)
    .filter(([, re]) => re.test(title))
    .map(([topic]) => topic);
}

/**
 * topic_key → title pattern for the LOCAL ladders a county or city legislates on.
 *
 * ── WHY THIS IS A SEPARATE MAP, NOT MORE ENTRIES ABOVE ───────────────────────
 *
 * A federal bill carries a persuasive short title ("Raise the Wage Act"). A
 * county resolution carries a 300-word operative sentence in block capitals
 * ("RESOLUTION APPROVING TERMS OF A DECLARATION OF RESTRICTIVE COVENANT ON THE
 * ADRIENNE ARSHT CENTER..."). The words that identify the subject are different
 * words, so the patterns are different patterns. Matching local text against the
 * federal map finds almost nothing.
 *
 * 🔴 THE SEASON'S LOCAL SET IS 35 TOPICS AND THIS MAP IS SMALLER ON PURPOSE.
 * Only ladders a county or city actually holds a lever on are here. The eight
 * `education-*` ladders are absent from this map: in Florida the schools are run
 * by a separately elected School Board, so a county commissioner has no rung to
 * stand on — and CLAUDE.md's ruling is that scope is a per-rung question, not a
 * per-topic one. A jurisdiction whose council DOES run its schools needs those
 * patterns added deliberately, not inherited.
 *
 * ⚠ `abortion`, `trans-athletes`, `religious-freedom` and `2020-election` carry a
 * local role in the season but are omitted here too. They surface in local
 * legislation as resolutions of position rather than by subject vocabulary, and
 * a pattern broad enough to catch them matches most of the ceremonial calendar.
 * Find those by reading, not by grep.
 */
export const LOCAL_TOPIC_PATTERNS = {
  // 🔴 `section 8` MUST be qualified. Bare, it matched "SECTION 8-9 OF THE CODE"
  // and pulled 18 of 123 housing matters in as junk — a same-day permitting
  // ordinance, building-official qualifications, boats and waterways, delivery
  // robots, feeding feral cats. Miami-Dade ordinances say "Section 8-N of the
  // Code" constantly. Only two of the twenty were real vouchers.
  'housing':                  /affordable housing|workforce housing|housing trust|surtax|\bSHIP\b|housing assistance|inclusionary|rental assistance|public housing|section 8 (housing|voucher|program|tenan)|housing choice voucher|housing voucher/i,
  // 🔴 RETUNED 2026-09-08. Bare `landlord` caused 23 of 23 false positives in Miami-Dade and every
  // other alternative fired ZERO times — measured per-alternative, not guessed. A county is a
  // LANDLORD constantly: airport development leases, an office lease, the Haulover restaurant, a
  // fire station, a legacy donor lease, the Seaquarium. Every one of those says "THE COUNTY, AS
  // LANDLORD", and not one is a position on regulating rents. The lease sense is removed and the
  // regulatory sense kept as `landlord-tenant`; `tenants bill of rights` is added because that is
  // what a Florida county can actually adopt.
  // Verified both ways before landing: 7 real instruments (rent stabilization, repealing rent
  // control, a tenants bill of rights, a rent-increase notice, just-cause eviction, a
  // landlord-tenant code amendment, tenant protections) still match; 3 county leases no longer do.
  // The Miami-Dade corpus drops from 30 leads to 0 — which is the true answer, see below.
  //
  // 🔴🔴 READ THIS BEFORE SEATING ANY FLORIDA OFFICIAL ON THIS LADDER. Fla. Stat. 125.0103(2):
  //   "A municipality, county, or other entity of local government may not adopt or maintain in
  //   effect any law, ordinance, rule, or other measure that would have the effect of imposing
  //   controls on rents." The housing-emergency exception that used to exist is GONE from the
  //   current text. So rungs 1 and 2 are not things a Florida county may lawfully do, and rung 5
  //   — "oppose rent control entirely; rents set by the market" — is the STATE-IMPOSED BASELINE,
  //   not a position anyone holds. **Seating a Florida official at 5 records a preemption as a
  //   personal stance.** That is the per-rung scope question CLAUDE.md rules on, and this ladder
  //   fails it at `local` scope in Florida while remaining valid where rent control is lawful.
  'rent-regulation':          /rent control|rent stabiliz|rent increase|tenant.{0,20}(right|protection)|eviction|just cause|landlord[- ]tenant|tenants? bill of rights/i,
  // 🔴 RETUNED 2026-09-08, in the same pass as `local-environment` above and for both of its
  // reasons at once — a false positive that swamped the leads, and a blind spot over the county's
  // actual instrument.
  // ⚠ THE FALSE POSITIVE: bare `land use plan` matched a STATE SUBMERGED-LANDS LEASE (matter
  //   261104, an amendment to Lease 4653 with the Board of Trustees of the Internal Improvement
  //   Trust Fund and its "associated LAND USE PLAN"). One matter, and it appeared in NINE
  //   commissioners' zoning leads. `plan` is dropped; a comprehensive-plan amendment is already
  //   caught by `comprehensive development master plan` and `CDMP`. Bare `single family` went the
  //   same way — it was matching `HFA SINGLE FAMILY MORTGAGE` and solid-waste collection studies,
  //   so it now requires the zoning sense (`single-family only|zoning|zone|district|lot`), which
  //   is what rung 5 actually argues about.
  // 🔴 THE BLIND SPOT: MIAMI-DADE'S PRINCIPAL DENSITY INSTRUMENT IS THE RAPID TRANSIT ZONE, and
  //   not one RTZ ordinance matched this ladder. They were reaching `transportation-priorities`
  //   only — including `261065`, whose title literally opens "ORDINANCE RELATING TO ZONING" and
  //   which streamlines LIVE LOCAL ACT covenants inside transit-oriented developments. Chapter 33C
  //   is how this county upzones, so a zoning ladder that cannot see it is not measuring the
  //   question. Also newly visible: `250899`, RESOLUTION ESTABLISHING COUNTY POLICY RE ZONING
  //   APPLICATIONS, and `251944`, DOWNTOWN KENDALL URBAN CENTER ZONING.
  // ⚠ A MATTER CAN AND SHOULD CARRY BOTH TOPICS. An RTZ subzone ordinance is procedural for
  //   transportation (it adds named parcels) and on-axis for zoning (it upzones them). Dual
  //   tagging is the correct answer, not a collision — matchLocalTopics returns every match.
  // Measured on the unfiltered 2,559-matter sweep (scripts/miamidade-axis-control.mjs):
  // 70 leads / 45 matters before, 58 / 49 after — FEWER leads over MORE matters, which is the
  // shape a good retune has: junk removed, real instruments added.
  // ⚠ KNOWN RESIDUAL, measured and accepted: four Housing Finance Authority bond items still match
  //   on `multifamily`. They are financings rather than zoning decisions, but `multifamily` is rung
  //   3 and 4 vocabulary and qualifying it risks losing real hits. Read past them.
  'residential-zoning':       /rezoning|rezone|zoning (change|amendment|district|code)|land use (change|amendment)|comprehensive development master plan|\bCDMP\b|density|dwelling units per|accessory dwelling|single[- ]family (only|zoning|zone|district|lot)|multifamily|upzon|by right|parking (minimum|requirement)|rapid transit zone|\bRTZ\b|transit[- ]oriented|\bTOD\b|live local|urban center|neighborhood character|duplex|triplex/i,
  // 🔴 RETUNED 2026-09-09 after the Garcia re-audit, and it was wrong in BOTH directions:
  //   CRA housekeeping IN, CDMP amendments OUT. Measured per-alternative on the unfiltered
  //   2,560-row sweep, which is the only way this was visible:
  //     community redevelopment 60/54 · CRA 41/35   <- the flood, all budgets and appointments
  //     urban development boundary 12/6 · UDB 3/1 · impact fee 3/3 · moratorium 2/2
  //     concurrency · infrastructure capacity · development order · planned development ·
  //       growth management · TIF ..................... ALL ZERO
  //   84 leads / 68 matters before, 61 / 42 after: 43 housekeeping items out, 16 real ones in.
  // 🟢 ZERO-SCORING ALTERNATIVES ARE DELIBERATELY KEPT. `concurrency` and `infrastructure
  //   capacity` are rung 2's own words. A zero costs no false positives and guards the day the
  //   county files one; deleting them would be tidying, not tuning.
  // 🔴 THE CARVE-OUT IS SCOPED TO THE CRA BRANCH, AND THAT IS NOT COSMETIC. Applied globally it
  //   suppressed 5 core matters including 252187 and 260291 — Cohen Higgins' two cited sources
  //   for her seated chair 2. A carve-out that reaches the on-axis branch takes live rows with it.
  // 🔴 TWO SUBSTRING TRAPS FOUND BY AUDITING EVERY CARVE-OUT TERM AGAINST THE CORPUS:
  //   `vice` matched "business support serVICEs" and wrongly dropped 250514 (TIF for business
  //   support — on-axis for economic-development, which rides on this pattern). `designat`
  //   matched "coDESIGNATion" street namings. Both removed; `chair` alone still excludes the
  //   chair/vice-chair designations, verified on 250386 and 250391. **Audit a carve-out term
  //   against real text before trusting it — a bare substring is not a word.**
  // 🟢 WHAT THE RETUNE ADDS: five CDMP amendment matters the old pattern could not see (251393,
  //   251903, 252447, 260879, 261141), plus 250695 PROHIBIT THE CREATION OF COMMUNITY
  //   REDEVELOPMENT and 251426 CREATING THE EAR TASK FORCE. The CDMP is how this county changes
  //   growth policy; the pattern was blind to its own subject's name.
  // ⚠ KNOWN RESIDUAL, measured and accepted: the added CDMP items include truck-parking and
  //   vertical-farming amendments that are off-axis for THIS ladder (260879's page mentions the
  //   UDB zero times). They are correct LEADS and wrong CHAIRS — read past them. Judging them is
  //   the per-rung scope question, not the pattern's job.
  // ⚠ 241888 (ordinance 25-59, the county's central growth instrument) is NOT IN THE CACHE AT
  //   ALL — the sponsor-report corpus is windowed and it falls outside. No pattern can reach it.
  //   A researcher working from leads alone would never see LU-8H.
  'growth-and-development':   /(urban development boundary|\bUDB\b|LU-8H|comprehensive development master plan|\bCDMP\b|impact fee|concurrency|infrastructure capacity|moratorium|development order|planned (area )?development|growth management|neighborhood planning|planning exercise)|^(?!.*(budget|appoint|chair|roadside|pothole|policing|cleanup|landscaping|fiscal year|bond issuance)).*(community redevelopment|\bCRA\b|tax increment|\bTIF\b|finding of necessity)/i,
  // 🔴 RETUNED 2026-09-08 after reading all 43 leads across 11 commissioners and seating NOBODY.
  // The ladder asks how to balance NEW DEVELOPMENT against ENVIRONMENTAL PRESERVATION — its five
  // rungs turn on green space, tree preservation, environmental review before approval, full
  // offsets, and fees in lieu of on-site preservation. The old pattern asked about the health of
  // the bay instead, and in a coastal Florida county that vocabulary swamps everything: of 43
  // matters it found, 32 were Biscayne Bay water quality, septic-to-sewer, flood resilience,
  // marine vessels, seawalls, mooring buoys and BOARD APPOINTMENTS. Direction was never the
  // problem; the axis was. Same failure as `economic-development` above, same fix.
  // ⚠ `resilien` was the worst of them and is gone: it matched `Resilient Aquarium LLC`, a COMPANY
  //   NAME in a Seaquarium ground-lease assignment. A stem that loose cannot be qualified usefully.
  // 🔴 AND IT WAS MISSING THE INSTRUMENTS THAT DO SIT ON THIS AXIS. Miami-Dade regulates this
  //   through Chapter 24 (environmental protection), Chapter 33 (zoning) and Chapter 15 (trees and
  //   landscaping), and the old pattern saw none of it. A control over the UNFILTERED 2,559-matter
  //   sweep — not the leads file, which only holds what a pattern already matched — surfaced
  //   `251728` (zoning AND environmental protection, amending 33-1, 24-5 and 15-17 together) and
  //   `252162` (county parks as a wetlands MITIGATION BANK, which is rung 4's fee-in-lieu
  //   mechanism by name). Both are now found; both were invisible before.
  // Measured on that sweep: 57 leads / 43 matters before, 23 leads / 13 matters after. Every one
  // of the 32 dropped matters was read and is off-axis; both gained are on-axis.
  // ⚠ COST, STATED: bay water quality, septic-to-sewer and sea-level-rise resilience now match NO
  //   topic at all. That is correct only if no ladder asks about them, and none currently does —
  //   `climate-change` below carries neither `sea level rise` nor `resilien`. Whoever next reads
  //   the climate-change ladder should decide whether they belong there; do not add them back
  //   here, because this ladder has no rung they could evidence.
  'local-environment':        /wetland|environmentally endangered|\bEEL\b|tree (canopy|removal|preservation|protection|ordinance|trust fund)|conservation (land|easement|purpose)|mangrove|preservation area|natural forest|pine rockland|mitigation (bank|credit)|fee(s)? in[- ]lieu|environmental review|environmental impact statement|green space|open space requirement|landscap\w* (requirement|ordinance|standard|code)|environmental control plan/i,
  // 🔴🔴 RETUNED 2026-09-09, AND THE PATTERN WAS AIMED AT THE WRONG LADDER. The frozen
  //   `compass_stances` text asks about climate policy in general — "declare a climate emergency",
  //   "phase out fossil fuels" — and `climate|greenhouse gas|carbon` is that question's vocabulary.
  //   The SEASON-PINNED ladder asks something much narrower: **"How much should government do to
  //   expand clean energy?"** — mandates, subsidies, permitting and the grid, neutrality, repeal.
  //   This is the `CA_0012` trap producing a plausible pattern on the wrong question. Read the pin.
  // 🔴 TWO SEMANTIC TRAPS, both found by reading what actually matched:
  //   bare `carbon` matched "CALCIUM CARBONATE lagoon and softeners" at the Alexander Orr water
  //   treatment plant (251161); bare `interconnection` matched "EMERGENCY WATER INTERCONNECTION"
  //   with North Miami Beach (250347). Both are now qualified. That is three substring/semantic
  //   traps in one day across three topics — `bail`/BAILEY, `vice`/serVICEs, `carbon`/CARBONATE.
  // 🟢 THE PINNED LADDER'S OWN VOCABULARY SCORES ZERO, AND THAT IS THE ANSWER, NOT A BUG:
  //   `clean energy` · `solar` · `photovoltaic` · `net metering` · `renewable energy` ·
  //   `energy efficiency` · `charging station` · `electrif` · `emissions` · `microgrid` ·
  //   `battery storage` · `net zero` · `property assessed clean energy` — ALL ZERO across 2,560
  //   rows. Kept anyway: they are the rungs' words and cost no false positives.
  // 🔴 `\benergy\b` AND `\bFPL\b` WERE MEASURED AND REJECTED. `energy` returns 16/11 and is almost
  //   entirely WASTE-TO-ENERGY incinerator siting (solid waste, not clean energy). `FPL` returns
  //   18/18 and is almost entirely UTILITY EASEMENTS across county property. Both would be pure
  //   noise, the `rent-regulation`/`landlord` shape.
  // 🔴🔴 SCOPE — READ THIS BEFORE SEATING ANYONE IN FLORIDA. Fla. Stat. s. 366.032(1) forbids a
  //   county from enacting or enforcing any resolution, ordinance, rule, code or policy that
  //   restricts or prohibits "the types or fuel sources of energy production" a utility may supply;
  //   (2) extends that to appliances; (3)'s carve-out reaches only a government that OWNS AND
  //   DIRECTLY CONTROLS its own electric utility, which Miami-Dade does not (FPL serves it); and
  //   (5) VOIDS any such county policy that existed on or before 1 July 2021. So **rung 1 is
  //   largely unavailable** community-wide, and **rung 4 — "stay neutral and let the market choose"
  //   — is the posture STATE LAW IMPOSES**, so seating anyone there from inaction records a
  //   preemption as a personal belief. That is the `rent-regulation` failure in a new topic.
  //   Rungs 2 (public investment) and 3 (permitting) remain genuine county levers.
  'climate-change':           /climate|greenhouse gas|carbon (emission|neutral|footprint|reduction|tax)|decarboniz|renewable energy|clean energy|solar|photovoltaic|net metering|property assessed clean energy|energy efficiency|electric vehicle|\bEV charging\b|charging station|electrif|emissions|microgrid|battery storage|net zero|(generator|grid|solar|distributed) interconnection/i,
  'fossil-fuels':             /natural gas|petroleum|fossil fuel|pipeline|drilling|fuel terminal/i,
  'transportation-priorities':/transit|bus rapid|metrorail|metromover|bicycle|pedestrian|sidewalk|complete streets|road capacity|traffic|parking requirement|\bSMART plan\b|rail corridor/i,
  // 🔴 NARROWED 2026-09-07 after reading all 24 of Bastien's leads and seating
  // none. It carried bare `incentive` and `community redevelopment`, and in a
  // Florida county the CRA vocabulary swamps everything: 24 leads, 0 chairs, and
  // two outright wrong subjects — "INCENTIVE-BASED PROGRAMS" turned out to be
  // recycling rebates. The ladder asks how to ATTRACT BUSINESSES, so the pattern
  // now asks for that vocabulary. Redevelopment-area financing is a different
  // question and rides on growth-and-development below.
  // ⚠ AND THEN WIDENED BACK, ONCE, IN THE SAME PASS. The first narrowing dropped
  // R-345-26 — directing enforcement of the JOB REQUIREMENT in the restrictions
  // on a county land conveyance to Amazon "for economic development purposes",
  // with legal action if unmet. That is the single most on-axis instrument in the
  // corpus, and it is rung 3's conditionality almost verbatim. It was lost
  // because the pattern asked for "job creation" and the county wrote "job
  // requirement". Narrowing a detector needs its own positive control: re-match
  // the stored corpus and read what stopped matching.
  'economic-development':     /economic development (incentive|agreement|grant|purpose)|business incentive|tax abatement|ad valorem tax exemption|targeted jobs|job creation|jobs? requirement|hiring requirement|wage requirement|community benefits? agreement|enterprise zone|opportunity zone|beacon council|attract (business|employer|industr)|major employer|corporate headquarters|clawback/i,
  // 🔴🔴 SCOPE, 2026-09-09 — FLORIDA DICTATES MOST OF THIS LADDER. Fla. Stat. s. 125.0231(2): a
  //   county "may not authorize or otherwise allow any person to regularly engage in public camping
  //   or sleeping on any public property". (3) permits a designated site for up to a year ONLY with
  //   Department of Children and Families certification, which requires proving there are not
  //   sufficient shelter beds. So **rung 1 ("no penalties of any kind") and rung 2 ("decriminalizing")
  //   are legally unavailable**, and **rung 4 ("prohibiting encampments") is what state law REQUIRES** —
  //   seat anyone there from an empty record and you publish a statute as a personal belief. Rung 3
  //   is the closest thing to what the statute permits, because (3) turns on shelter-bed sufficiency.
  //   Third instance of this failure mode in one day: rent-regulation, s. 366.032, and now this.
  // 🟢 Pattern left ALONE — measured 2026-09-09 and it is sound. `encampment` 5/2; `public camping`,
  //   `sleeping in public`, `panhandl`, `loitering`, `vagrancy`, `public sleeping`, `trespass` all
  //   ZERO. Bare `camping` adds 1 and would risk recreational camping; not worth it.
  // ⚠ The whole corpus is ONE item, filed twice (261371 / 261121, both Amended, never adopted):
  //   Bastien's "ILLEGAL DUMPING AND ENCAMPMENT PLAN FOR DISTRICT 2; AND REQUIRING A REPORT".
  //   A plan-and-report directive, and paired with illegal dumping rather than with shelter.
  'homelessness':             /public camping|encampment|sleeping in public|panhandl|loitering|vagrancy/i,
  // 🔴 RETUNED 2026-09-09: 9 leads / 9 matters -> 23 / 15. The old pattern required `homeless` to be
  //   followed by trust/services/assistance/program/shelter, or to stand alone as a whole word, so it
  //   missed `homelessness` in running prose and every provider-named item. Six real matters were
  //   outside it: 251708, 260313, 251336, 250072 (a $5M Bezos Day 1 Families Fund grant), 252155
  //   (Chapman Partnership rapid re-housing) and 261104.
  // 🟢 261104 (the Mental Health Center) now tags BOTH this topic and jail-capacity. That is correct
  //   multi-tagging, not a collision — matchLocalTopics returns every match.
  // ⚠ WHAT THE LEADS CANNOT TELL YOU, and it decided the whole pass: **Bastien is prime on 11 of the
  //   14 matters, and that is her Homeless Trust role, not a position.** Nine carry
  //   `requester = Miami-Dade Homeless Trust`. `requester` is the discriminator, not volume.
  'homelessness-response':    /homeless|continuum of care|\bCoC\b|emergency shelter|permanent supportive housing|transitional housing|rapid re-?housing|housing first|shelter bed|unsheltered|chapman partnership|food and beverage tax/i,
  'public-safety-approach':   /police (budget|staffing|department|funding)|law enforcement (budget|staffing)|crisis intervention|co-responder|mental health response|community policing|body[- ]worn camera/i,
  // 🔴 RETUNED 2026-09-09. The old pattern returned 13 leads / 8 matters and was quoted as
  //   evidence this topic was THIN. It was not: the count was a broken detector. 44 / 20 now.
  // 🔴🔴 TWO OF THE OLD PATTERN'S EIGHT MATTERS WERE SUBSTRING ARTEFACTS. Bare `bail` matched
  //   "BAILES COMMONS" and "JUDGE MELVIA BAILEY-GREEN TERRACE" — a property conveyance and a
  //   street co-designation. `\bbail\b` returns the one real matter. This is the same trap as
  //   `vice` in "serVICEs" over in growth-and-development; audit a term against real text.
  // 🔴 `corrections (facility|department)` SCORED ZERO while bare `corrections` scored 5/4 — the
  //   qualifier killed it. The county writes "Corrections and Rehabilitation". Now
  //   `corrections\b|correctional`; bare singular `correction` is left out (scrivener's corrections).
  // 🟢 WHAT THE OLD PATTERN COULD NOT SEE, and it is the heart of the topic: the MENTAL HEALTH
  //   CENTER cluster — 261104, 261093, 261088, 260425, 260201, 250513, plus 261006 — and the
  //   MISDEMEANOR DIVERSION items 250837, 250794, 252312, and 250119 SECOND CHANCE ACT
  //   COMMUNITY-BASED REENTRY. Rung 1 is "redirecting incarceration funding into community-based
  //   mental health … to shrink the jail system". The pattern was blind to rung 1's own subject.
  // 🔴🔴 `consent decree` WAS MEASURED AND REJECTED: 40 leads / 39 matters, EVERY ONE a water and
  //   sewer construction contract under the WASD decree, and `(?=.*consent decree)(?=.*(jail|
  //   correction))` returns ZERO. Miami-Dade's jail consent decree is real, but this corpus does
  //   not name it. Adding the term would have been `rent-regulation`'s `landlord` again.
  // 🔴 BARE `diversion` IS ALSO REJECTED — 34/13, and the extras are WASTE diversion (252009,
  //   251068, 251585). The term is qualified instead: jail/misdemeanor/pretrial/criminal/court
  //   diversion, or diversion program/service/project. A word can be on-axis in one policy
  //   vocabulary and noise in another.
  // 🟢 ZERO-SCORING LADDER VOCABULARY KEPT: `overcrowd`, `restorative justice`,
  //   `detention (facility|center)`, `nonmonetary`. These are the rungs' own words; a zero costs
  //   no false positives.
  // ⚠ RESIDUAL, measured and accepted: 252422 AXON (TASERS), 251876 INMATE MEAL SERVICE, 250330
  //   COMMUNITY PARTNERS and 261512 GOVERNMENT FACILITIES HEARING are corrections-department
  //   operations rather than capacity policy. Correct leads, wrong chairs — read past them.
  'jail-capacity':            /\bjails?\b|corrections\b|correctional|\bMDCR\b|turner guilford|\bTGK\b|inmate|incarcerat|detention (facility|center)|pretrial|\bbail\b|bond schedule|nonmonetary|non-monetary|(jail|misdemeanor|pretrial|criminal|court) diversion|diversion (program|service|project)|misdemeanor|competency restoration|re-?entry|second chance|mental health center|\bMHC\b|overcrowd|restorative justice/i,
  'local-immigration':        /\bICE\b|immigration detainer|287\(g\)|sanctuary|immigration enforcement|undocumented|federal immigration/i,
  'city-sanitation':          /solid waste|garbage|refuse collection|litter|illegal dumping|recycling|sanitation|street sweeping/i,
  'data-centers':             /data cent(er|re)|hyperscale|server farm|utility rate|ratepayer/i,
  'childcare':                /child care|childcare|early (childhood|learning)|pre[- ]?k\b|head start/i,
  'cannabis-policy':          /cannabis|marijuana|hemp|civil citation.{0,30}possession/i,
  'gun-policy':               /firearm|\bgun\b|ghost gun|shooting range|weapons? (ban|ordinance)/i,
  'minimum-wage':             /minimum wage|living wage|wage (floor|theft)|responsible wage/i,
  // 🔴🔴 RETUNED 2026-09-09 — 5 leads / 4 matters -> 2 / 1, and THREE OF THE FOUR WERE COMPANY NAMES.
  //   Bare `equity` matched "ELITE EQUITY Habitat for Humanity" (260962) and "ELITE EQUITY DEV. INC."
  //   (251893) — an infill-housing developer. Bare `\bDBE\b` matched "DBE MISS USA, LLC" (261139), a
  //   tourist-tax grant to a beauty pageant. A word-boundary does not save you from a PROPER NOUN.
  // 🔴 EVERY OTHER ALTERNATIVE SCORED ZERO across 2,560 rows: `civil rights`, `discrimination`,
  //   `human rights ordinance`, `disparit`, `minority-owned`, `\bMBE\b`,
  //   `disadvantaged business enterprise`. The real corpus is ONE matter.
  // ⚠ That one is 260492 / R-246-26, Garcia, adopted: URGING the Governor to veto SB 1134, which would
  //   bar local governments from funding or promoting diversity, equity and inclusion. It is the most
  //   on-axis civil-rights item on the Board and it is still a REFUSAL — an urging resolution binds
  //   nobody, and opposing a preemption bill gives direction without magnitude: it cannot separate
  //   rung 1 ("mandate racial equity requirements in all institutions") from rung 2.
  // ⚠ PER-RUNG SCOPE: rung 4 says "limit FEDERAL civil rights enforcement", which no county officer
  //   can do. Read the scope ruling before seating anyone here at any level.
  'civil-rights':             /civil rights|discrimination|human rights ordinance|racial equity|equity (plan|office|program|initiative|act)|diversity, equity|\bDEI\b|disparit|minority[- ]owned|\bMBE\b|disadvantaged business enterprise|affirmative action|equal opportunity/i,
  'campaign-finance':         /campaign (finance|contribution)|lobbyist|ethics (ordinance|commission)|public financing/i,
  'ranked-choice-voting':     /ranked[- ]choice|instant runoff|election method|runoff election/i,
};

/**
 * Every LOCAL topic whose pattern the text hints at.
 *
 * Pass the operative title, not the short subject line — a county subject line
 * is an abbreviation ("SOLID WASTE COLLECTION") while the title carries the verbs.
 * Passing both concatenated is fine and is what the extractor does.
 */
export function matchLocalTopics(text) {
  if (!text) return [];
  return Object.entries(LOCAL_TOPIC_PATTERNS)
    .filter(([, re]) => re.test(text))
    .map(([topic]) => topic);
}
