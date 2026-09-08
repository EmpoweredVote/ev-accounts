/**
 * lead-axis.mjs — is this lead about the question the LADDER asks?
 *
 * The second stage of the federal research pass. topic-lead-patterns.mjs asks
 * "does this bill's title mention the subject?" and is deliberately broad and
 * deliberately dumb about direction. This asks the next question down, and it is
 * the one that decides whether a lead is worth a researcher's hour:
 *
 *     does this measure ACT ON THE AXIS THE FIVE RUNGS MEASURE?
 *
 * 🔴 STILL NOT A CHAIR. This says a lead is worth OPENING. It does not say which
 * rung its sponsor sits in, and nothing here should ever be turned into a value.
 * cohort-worksheet.mjs refuses to write values for reasons that apply verbatim to
 * this file: every row is a claim about a named sitting senator, and the
 * verifier's gate proves a source carries the words, never that the chair is the
 * right reading of them.
 *
 * ── WHY THIS STAGE HAD TO EXIST ──────────────────────────────────────────────
 *
 * The 2026-09-05 Senate sweep found 289 (senator, topic) pairs with at least one
 * lead across gun-policy, israel-military-aid and border-security. Read as
 * coverage that number is badly wrong, and the three ladders say why:
 *
 *   israel-military-aid asks WHAT LEVEL OF MILITARY AID. Its largest lead by far
 *     is "A resolution standing with Israel against terrorism", cosponsored by 84
 *     of 100 senators. It is a solidarity resolution: it appropriates nothing,
 *     conditions nothing and blocks nothing. It cannot separate rung 1 from rung
 *     5, and 84 senators agreeing to it tells you only that it was written to be
 *     agreed to. The same holds for the October 7 condemnations, the 75th-
 *     anniversary celebration and the hostage demands.
 *
 *   border-security asks HOW PEOPLE WHO CROSS SHOULD BE HANDLED — every rung is
 *     an asylum posture. The leads are largely Border Patrol anniversaries, Coast
 *     Guard commendations, Immigrant Heritage Month, fentanyl interdiction and
 *     CBP reporting requirements. All genuinely about the border. None about
 *     asylum.
 *
 * This is CC_0074's "real evidence, wrong question" — the reason no
 * military-intervention row was written for Padilla or Schiff — except at a scale
 * where meeting it row by row would waste most of the pass. Answering it once, in
 * code, is cheaper and reviewable.
 *
 * ── THE THREE VERDICTS ───────────────────────────────────────────────────────
 *
 *   on-axis        the measure would change the thing the rungs measure
 *   off-axis       a real, operative measure — on a different axis
 *   non-operative  commemorates, condemns, celebrates or expresses. Makes no law.
 *
 * ⚠ off-axis IS NOT "WORTHLESS". A senator's fentanyl-interdiction bill is real
 * evidence about them; it just cannot seat them on an asylum ladder. The verdict
 * scopes THIS pass and says nothing about the bill.
 *
 * ⚠ THE RULES ARE A HEURISTIC OVER TITLES and carry the same false-positive risk
 * the first stage does, in both directions. They sort a queue; they do not close
 * one.
 */

/**
 * Measure type off the bill label. The Congress API's labels are "S. 1332",
 * "SJRES. 200", "HCONRES. 202" and so on.
 *
 * This matters because operativeness is partly STRUCTURAL, not rhetorical. A
 * simple or concurrent resolution is a chamber talking to itself and never
 * becomes law, while a JOINT resolution is how a Congressional Review Act
 * disapproval, an Arms Export Control Act disapproval and a war powers direction
 * are all carried. Those bind.
 */
export function measureType(billLabel) {
  const t = String(billLabel ?? '').toUpperCase().replace(/[\s.]/g, '');
  if (t.startsWith('SCONRES') || t.startsWith('HCONRES')) return 'concurrent';
  if (t.startsWith('SJRES') || t.startsWith('HJRES')) return 'joint';
  if (t.startsWith('SRES') || t.startsWith('HRES')) return 'simple';
  if (t.startsWith('HR') || t.startsWith('S')) return 'bill';
  return 'unknown';
}

/**
 * Titles whose words are opaque but whose subject is settled, per topic.
 *
 * ⚠ EVERY ENTRY HERE WAS READ BY A PERSON. A named-bill list is the one place
 * this file can assert something its patterns cannot see, so it is also the one
 * place a wrong entry is invisible: "Secure the Border Act" contains no word any
 * asylum pattern matches, and its substance is an asylum restriction.
 */
const NAMED_ON_AXIS = {
  'gun-policy': [
    /^assault weapons ban\b/i,
    /^background check expansion act/i,
    /^constitutional concealed carry reciprocity act/i,
  ],
  'israel-military-aid': [
    /^stand with israel act/i,
    /^israel security assistance support act/i,
    /^maintaining our ironclad commitment to israel/i,
    /^weapons resupply, stockpile, and alliance/i,
    /^fortify israel act/i,
    /^ensuring peace through strength in israel act/i,
    /^expediting israeli aerial refueling act/i,
  ],
  'border-security': [
    /^secure the border act/i,
    /^stopping border surges act/i,
    /^asylum abuse reduction act/i,
    /^protect vulnerable immigrant youth act/i,
    /^dignity for detained immigrants act/i,
  ],
};

/** What each ladder's rungs actually turn on. */
const ON_AXIS = {
  // "How should the government regulate firearms?" — which arms are legal, who
  // may buy one, who may carry one.
  'gun-policy':
    /assault weapon|semi-?automatic|high-?capacity|large-?capacity|magazine|background check|concealed carry|carry reciprocity|permitless|ghost gun|untraceable firearm|undetectable firearm|red flag|extreme risk|bump stock|stabilizing brace|forced reset|frame or receiver|engaged in the business|gun show|waiting period|firearm.{0,40}(ban|prohibit|restrict)|(ban|prohibit|restrict).{0,40}firearm/i,

  // "What level of military aid should the U.S. provide to Israel?" — the flow of
  // money and weapons, and any condition placed on it.
  'israel-military-aid':
    /arms sale|arms transfer|foreign military sale|foreign military financing|defense articles|defense services|major defense equipment|munitions|ammunition|security assistance|security supplemental|supplemental appropriations|military aid|502B|human rights practices|halt the shipment|resupply/i,

  // "How should the government handle people who cross the border?" — every rung
  // is an asylum posture.
  'border-security':
    /asylum|refugee|credible fear|expedited removal|\bparole\b|detention|detained|unaccompanied|immigrant youth|deportation|removal proceedings|remain in mexico|migrant protection protocols|inadmissib|withholding of removal/i,
};

/**
 * Classify one lead.
 *
 * @param {{topic_key: string, bill: string, title: string}} lead
 * @returns {'on-axis'|'off-axis'|'non-operative'}
 */
export function classifyLead(lead) {
  const topic = lead?.topic_key;
  const title = String(lead?.title ?? '');
  const axis = ON_AXIS[topic];
  if (!axis) return 'off-axis';

  const named = (NAMED_ON_AXIS[topic] ?? []).some((re) => re.test(title.trim()));

  // ⚠ THE AXIS TEST RUNS FIRST, AND THE INSTRUMENT ONLY SORTS WHAT IS LEFT. An
  // earlier draft had this the other way round — any simple or concurrent
  // resolution was non-operative before its subject was ever looked at, on the
  // reasoning that a measure which never becomes law cannot move a rung. That is
  // true about LAW and false about EVIDENCE, and this ladder asks what a senator
  // HOLDS, not what they enacted. Two cases show the cost:
  //
  //   · S.Res. condemning the decision to halt the shipment of United States made
  //     ammunition and weapons to Israel — 42 cosponsors. It enacts nothing and it
  //     is a signed, public objection to withholding arms, which is exactly the
  //     distinction rung 1 draws against rungs 3 and 4.
  //   · S.Res. requesting information on Israel's human rights practices pursuant
  //     to section 502B(c). Privileged under the Foreign Assistance Act, and the
  //     recognised way of forcing a vote on conditioning arms to an ally — rung
  //     2's instrument, and this topic's single most on-point lead.
  //
  // The structural rule survives where it was always doing the real work, which
  // is the leftovers: a resolution with NO axis content is a commemoration, and
  // "standing with Israel against terrorism" — 84 of 100 senators — separates no
  // rung from any other. That is caught by the axis test finding nothing, not by
  // the measure type, so the type is now only used to say WHY nothing was found.
  if (named || axis.test(title)) return 'on-axis';

  const type = measureType(lead?.bill);
  if (type === 'simple' || type === 'concurrent') return 'non-operative';
  return 'off-axis';
}

/**
 * Roll one pair's leads up to a single verdict.
 *
 * `settleable` means only that SOMETHING here is worth opening. The pass still
 * has to open it, and may still write no row: CC_0057's absent row for
 * "not researched to a conclusion" stays the honest outcome for a lead that turns
 * out not to say what the researcher hoped.
 */
export function classifyPair(leads) {
  const counts = { 'on-axis': 0, 'off-axis': 0, 'non-operative': 0 };
  for (const l of leads) counts[classifyLead(l)]++;
  const verdict = counts['on-axis'] > 0 ? 'settleable'
    : counts['off-axis'] > 0 ? 'off-axis-only'
      : 'non-operative-only';
  return { verdict, counts };
}
