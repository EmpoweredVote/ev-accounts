// Randorf's two remaining sponsorship leads, worked through. NEITHER MOVES A CHAIR, and the
// reasons are different in each case. Recorded so the next pass does not re-open them.
//
// 1. TIF development incentives (sponsored with Forsman and Kennedy, adopted 2025-06-16).
//    🔴 THE OPERATIVE CONTENT IS AN ATTACHMENT. The resolution's only resolving clause is that the
//    city "adopts the policy on development incentives for tax increment financing, attached hereto
//    as Exhibit A". C51 says the operative section governs, and here it governs by reference to a
//    document the legislative record does not render. Whether that policy imposes wage and local
//    hiring conditions with repayment (chair 3) or spending limits and a willingness to pass on
//    deals (chair 4) is exactly what Exhibit A would say and the resolution does not.
//    ▶ A framework resolution that adopts an attachment cannot refine a chair on its own.
//
// 2. Short-term rental moratorium (sponsored with Swenson, Nephew and Forsman, adopted 2025-11-10).
//    🔴 IT IS A STUDY MORATORIUM ON ITS FACE: "pending completion of a city study weighing the need
//    for any amendment to official controls". C47 refuses a study directive as a chair. It is also
//    not housing density — the same reason Nephew's residential-zoning blank gives.
//
// File numbers are deliberately not written into the reasonings: neither matter's Legistar web GUID
// has been resolved, so neither is citable, and this batch describes uncitable instruments rather
// than numbering them. Sponsorship is attributed to the council's own legislative record, as the
// roll calls in these blanks already are.
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Roz Randorf';
const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const ev = parse(fs.readFileSync(B + '/evidence.csv'), { columns: true, skip_empty_lines: true });
const get = (t) => { const r = csv.find((x) => x.full_name === N && x.topic_key === t); if (!r) throw new Error('no row ' + t); return r; };

const TIF = ' Her sponsorships were read from the council’s own legislative record. In May 2025 she brought forward, with Forsman and Kennedy - the three councilors who sit on the Duluth Economic Development Authority - the resolution adopting the city’s policy on development incentives for tax increment financing, which the council adopted that June and which superseded every earlier policy on the subject. That is real engagement with the terms on which incentives are given, and it cannot refine this chair, because the resolution’s only resolving clause adopts a policy attached to it as an exhibit. The resolution itself says the policy exists to ensure tax increment financing is used only when necessary and in the public interest, to ensure fiscal responsibility and to promote equitable and sustainable development. Those are the framework’s purposes, not its conditions. Whether the policy requires good wages, local hiring and repayment when a developer does not deliver, which is chair 3, or sets limits and a willingness to pass on deals that cost too much, which is chair 4, is what the exhibit would say and the record does not render it. 🔴 For the reviewer: Forsman holds chair 4 partly on his role in shaping this same policy. The two readings are not in conflict - his chair rests on his own words about large incentives for large employers, and hers on the pay-on-delivery mechanism she named herself - but a reviewer who reads the exhibit may want to revisit both. Reading that exhibit is the one thing that would settle it.';

const STR = ' Her sponsorships were read from the council’s own legislative record, and the one that touches this ladder is a study. In October 2025 she brought forward, with Swenson, Nephew and Forsman, an interim ordinance under Minn. Stat. 462.355 subd. 4 imposing a moratorium on certain short-term rental permits and related city approvals, together with the resolution adopting interim controls while it was pending; both were adopted on 10 November 2025. The ordinance says on its face that the moratorium runs pending completion of a city study weighing the need for any amendment to official controls. A direction to pause and study is a refusal rather than a position, which C47 states directly, and the record carries no statement from her about what the study should conclude. It is also not evidence on this ladder for a second and independent reason: short-term rental permitting is a question about how a dwelling may be used, not about how much housing a neighbourhood should hold, and the five rungs here separate on density - duplexes, accessory dwellings, multifamily by right, single-family-only zoning. Nephew’s blank on this ladder is recorded for the same reason.';

const rows = [
  { ...get('economic-development'), reasoning: get('economic-development').reasoning + TIF },
  { ...get('residential-zoning'), reasoning: get('residential-zoning').reasoning + STR },
];

// Controls
for (const r of rows) {
  const m = r.reasoning.match(/\b2[0-6]-\d{3,4}R\b|\b2[0-6]-\d{3}-O\b/);
  if (m) throw new Error('uncitable file number leaked into ' + r.topic_key + ': ' + m[0]);
}
if (rows[0].value !== '3') throw new Error('economic-development chair must stay 3');
if (rows[1].value !== '') throw new Error('residential-zoning must stay blank');

// Carry forward every existing snippet for the pairs being replaced.
const evRows = rows.flatMap((r) => ev.filter((e) => e.full_name === N && e.topic_key === r.topic_key));
for (const r of rows) {
  const cited = [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean);
  for (const u of cited) if (!evRows.some((e) => e.topic_key === r.topic_key && e.source_url === u))
    throw new Error('lost the snippet for ' + u + ' on ' + r.topic_key);
}

fs.writeFileSync(B + '/_rows/randorf-sponsorship-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/randorf-sponsorship-evidence.json', JSON.stringify(evRows, null, 1));
console.log('rows:', rows.map((r) => r.topic_key + '=' + JSON.stringify(r.value)).join(' '), '| evidence carried:', evRows.length);
