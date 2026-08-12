/**
 * Bill-title nets per compass topic, for building Maryland co-sponsor indexes.
 *
 * 🔴 THE NET IS THE EXTRACTOR. A bill never fetched cannot be found, and "no on-topic bill" then
 * reports the net's blind spot as a fact about the member. The civil-rights net originally omitted
 * "religio" and "immigra" entirely — 59 religion bills and 102 immigration bills were never fetched,
 * and three rows scored "no on-topic bill" purely because nobody had looked. Whenever a topic is
 * added to a row set, its vocabulary MUST be added here FIRST.
 *
 * 🔑 Deliberately broad. Precision comes from READING the matched title afterwards, not from this net
 * — a tight net silently loses rows, while a loose one only costs fetches.
 *
 * ⚠ A title match is topical, never directional. "Rent Stabilization - Preemption of Local Authority"
 * matches the rent net and points the opposite way. Direction is decided by reading, never here.
 *
 * 🔴🔴 EVERY TERM IS \b-BOUNDED, AND THE REASON IS EMBARRASSING. The first cut of these nets used bare
 * substrings and produced, as the TOP-RANKED evidence for real rows:
 *   · `rent`    → "App-RENT-iceships in Licensed Occupations Act" ranked as Rosapepe's best housing bill
 *   · `tenant`  → "2nd Lieu-TENANT Richard Collins Hate Crimes Act" ranked as Benson's best housing bill
 *   · `premium` → "PREMIUM Cigar Lounge Alcoholic Beverages License" ranked as Harris's best healthcare bill
 *   · `rental`  → "Rental Vehicles - Spare Tires" was Kagan's top THREE housing bills
 * This is the same defect as the Socrata surname pass, where "Tran" matched "Transportation" and
 * pulled in 11,821 contributions. A substring is not a word.
 *
 * ⚠ EXCLUDE patterns handle the collisions a word boundary cannot: "housing" is a real word in
 * "Correctional Services - RESTRICTIVE HOUSING", which is solitary confinement, not shelter.
 */
export const TOPIC_EXCLUDE = {
  'Healthcare Access': /cigar|tobacco|alcoholic beverage|rental vehicle/i,
  'Affordable Housing': /rental vehicle|spare tire|restrictive housing|correctional|apprentice/i,
  'Rent Regulation': /rental vehicle|spare tire|apprentice/i,
  'Same-Sex Marriage': /marriage and family therap/i,
};

/**
 * Tighter than the recall net: what the CHAIR is actually about. Used only to RANK a reading queue.
 * ⚠ Same \b discipline — an unbounded `premium` here would push "Premium Cigar Lounge" to the top of a
 * healthcare queue, which is exactly what it did.
 */
export const TOPIC_CORE = {
  'Healthcare Access': /\bhealth insurance\b|\bmedicaid\b|\bmedical assistance\b|\bhealth benefit|\bcoverage\b|\buninsured\b|\bpremiums?\b|\bcost.sharing\b|\bcopay|\baffordable care\b|\bprescription drug|\binsulin\b|\btelehealth\b|\bhealth equity\b|\bcommunity health\b/i,
  'Affordable Housing': /\baffordable housing\b|\bhousing trust\b|\brental assistance\b|\bhomeless|\bfirst.time\b|\bdown payment\b|\binclusionary\b|\bhousing voucher\b|\beviction\b|\btenants?\b|\bhousing development\b|\bworkforce housing\b|\bforeclosur/i,
  'Rent Regulation': /\brent stabiliz|\brent control\b|\brent increase|\brent gouging\b|\bjust cause\b|\bsecurity deposit\b|\btenant protection|\beviction\b|\bleases?\b/i,
  'Childcare Affordability & Access': /\bchild care\b|\bchildcare\b|\bprekindergarten\b|\bearly childhood\b/i,
  'Same-Sex Marriage': /\bsame.sex\b|\bmarriage\b|\bLGBTQ\b|\bsexual orientation\b|\bgender identity\b|\bconversion therapy\b|\btransgender\b/i,
  'Misinformation and the Role of Algorithms in Democracy': /\bmisinformation\b|\bdisinformation\b|\bdeepfake|\bsynthetic media\b|\bartificial intelligence\b|\balgorithm|\bsocial media\b|\bcontent moderation\b|\belections?\b/i,
  'Civil Rights and Social Justice': /\bdiscriminat|\bcivil rights?\b|\bhate crime|\bequal pay\b|\bracial\b|\bfair housing\b|\bpublic accommodation|\breparation|\bequity\b/i,
  'Climate Change and Environmental Protection': /\bclimate\b|\bgreenhouse\b|\bclean energy\b|\brenewable\b|\bsolar\b|\bemissions\b|\bcarbon\b|\bnet.zero\b|\bfossil fuel|\belectric vehicle/i,
};

export const TOPIC_NETS = {
  'Healthcare Access': /\bhealth insurance\b|\bhealth care\b|\bhealthcare\b|\bmedicaid\b|\bmedical assistance\b|\bhealth benefit|\bprescription drug|\binsulin\b|\buninsured\b|\bhealth equity\b|\bpublic health\b|\bhospitals?\b|\btelehealth\b|\bhealth coverage\b|\baffordable care\b|\bcopay|\bcost.sharing\b|\bmental health\b|\bbehavioral health\b|\bmaternal health\b|\bdental care\b|\bvision care\b|\blong.term care\b|\bnursing homes?\b|\bhealth occupations\b|\bcommunity health\b|\bhealth maintenance organization/i,

  'Affordable Housing': /\baffordable housing\b|\bhousing\b|\bhomeless|\beviction\b|\bforeclosur|\brental assistance\b|\bhousing trust\b|\bfirst.time (home)?buyer\b|\bdown payment\b|\binclusionary\b|\bzoning\b|\bland use\b|\baccessory dwelling\b|\bmanufactured home|\bmobile home|\btenants?\b|\blandlords?\b|\bhabitability\b|\bhousing voucher\b|\brents?\b/i,

  // ⚠ separate from housing on purpose: a rent-regulation chair is about rent CONTROL, and the housing
  // net would drown it in 900 unrelated housing bills.
  'Rent Regulation': /\brent stabiliz|\brent control\b|\brent increase|\brent gouging\b|\brental housing\b|\btenant protection|\bjust cause\b|\beviction\b|\bleases?\b|\blandlords?\b|\bsecurity deposit\b|\brents?\b/i,

  'Childcare Affordability & Access': /\bchild care\b|\bchildcare\b|\bprekindergarten\b|\bpre.kindergarten\b|\bearly childhood\b|\bday care\b|\bdaycare\b|\bhead start\b|\bnursery\b|\binfants?\b|\btoddlers?\b/i,

  'Same-Sex Marriage': /\bLGBTQ\b|\bsexual orientation\b|\bgender identity\b|\bconversion therapy\b|\bsame.sex\b|\bmarriage\b|\bdomestic partner|\btransgender\b|\bcivil union\b/i,

  'Civil Rights and Social Justice': /discriminat|civil right|human relations|hate crime|equal pay|equity|racial|race|LGBTQ|sexual orientation|gender identity|conversion therapy|marriage|fair housing|public accommodation|reparation|lynching|hate|bias|religio|conscience|faith-based|clergy|immigra|sanctuary|undocumented|transgender/i,

  'Misinformation and the Role of Algorithms in Democracy': /misinformation|disinformation|deepfake|synthetic media|artificial intelligence|algorithm|social media|online platform|content moderation|election (integrity|disinformation)|digital literacy|data privacy|personal information|consumer data/i,

  'Climate Change and Environmental Protection': /climate|greenhouse|clean energy|renewable|solar|wind energy|emissions|carbon|energy efficien|electric vehicle|zero-emission|environment|pollution|chesapeake|conservation|net-?zero|fossil fuel/i,
};
