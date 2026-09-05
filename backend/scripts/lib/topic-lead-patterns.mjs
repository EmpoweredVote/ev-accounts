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
