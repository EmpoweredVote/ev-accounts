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
  'residential-zoning':       /rezoning|rezone|zoning (change|amendment|district)|land use (change|amendment|plan)|density|dwelling units per|accessory dwelling|single[- ]family|multifamily|comprehensive development master plan|\bCDMP\b/i,
  'growth-and-development':   /urban development boundary|\bUDB\b|impact fee|concurrency|infrastructure capacity|moratorium|development order|planned (area )?development|growth management|community redevelopment (agency|area)|\bCRA\b|tax increment|\bTIF\b|finding of necessity/i,
  'local-environment':        /wetland|environmentally endangered|tree canopy|conservation (land|easement)|biscayne bay|water quality|septic|sea level rise|resilien|mangrove|preservation area/i,
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
