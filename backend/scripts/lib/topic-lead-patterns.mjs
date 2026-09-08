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
  'rent-regulation':          /rent control|rent stabiliz|rent increase|tenant.{0,20}(right|protection)|eviction|just cause|landlord/i,
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
  'growth-and-development':   /urban development boundary|\bUDB\b|impact fee|concurrency|infrastructure capacity|moratorium|development order|planned (area )?development|growth management|community redevelopment (agency|area)|\bCRA\b|tax increment|\bTIF\b|finding of necessity/i,
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
  'climate-change':           /climate|greenhouse gas|carbon|renewable energy|solar|energy efficiency|electric vehicle|\bEV charging\b|net zero/i,
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
  'homelessness':             /public camping|encampment|sleeping in public|panhandl|loitering|vagrancy/i,
  'homelessness-response':    /homeless(ness)? (trust|services|assistance|program|shelter)|continuum of care|emergency shelter|permanent supportive housing|\bhomeless\b/i,
  'public-safety-approach':   /police (budget|staffing|department|funding)|law enforcement (budget|staffing)|crisis intervention|co-responder|mental health response|community policing|body[- ]worn camera/i,
  'jail-capacity':            /corrections (facility|department)|jail|pretrial|bail|bond schedule|diversion program|incarcerat|detention facility/i,
  'local-immigration':        /\bICE\b|immigration detainer|287\(g\)|sanctuary|immigration enforcement|undocumented|federal immigration/i,
  'city-sanitation':          /solid waste|garbage|refuse collection|litter|illegal dumping|recycling|sanitation|street sweeping/i,
  'data-centers':             /data cent(er|re)|hyperscale|server farm|utility rate|ratepayer/i,
  'childcare':                /child care|childcare|early (childhood|learning)|pre[- ]?k\b|head start/i,
  'cannabis-policy':          /cannabis|marijuana|hemp|civil citation.{0,30}possession/i,
  'gun-policy':               /firearm|\bgun\b|ghost gun|shooting range|weapons? (ban|ordinance)/i,
  'minimum-wage':             /minimum wage|living wage|wage (floor|theft)|responsible wage/i,
  'civil-rights':             /civil rights|discrimination|human rights ordinance|equity|disparit|minority[- ]owned|\bMBE\b|\bDBE\b/i,
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
