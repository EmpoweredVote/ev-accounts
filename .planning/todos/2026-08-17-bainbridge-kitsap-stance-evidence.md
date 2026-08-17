# Bainbridge Island + Kitsap stances — evidence state as of 2026-08-17

22 people (7 BI councilmembers, 9 Kitsap officials incl. Acting Sheriff Sapp, 6 challengers).
Local scale is **22 topics** (`inform.compass_topic_roles.role_scope='local'`). All 22 people
currently hold **zero** `inform.politician_answers` rows.

Bar applied: a chair the evidence **names**, plus a source that supports **that chair**.
Two adjacent chairs fit ⇒ skip. Compound chairs need every clause evidenced.

## CLEARS THE BAR — 4 chairs, ready to seed

| Person | Topic | Chair | Evidence |
|---|---|---|---|
| Brandon L. Myers | Public Safety Approach | **4** | WA voters' pamphlet 2026 primary: "Our Sheriff's Office must be properly staffed, supported, and equipped"; "staffing shortages"; "strengthening recruitment and retention". Chair 4 = "Increase police staffing, equipment, and pay". 3 excluded (rejects current staffing as adequate); 5 excluded (never claims top priority over other services). |
| Katie Walters | Growth and Development Pace | **3** | WA voters' pamphlet: "Kitsap is growing. We must manage growth thoughtfully, protecting our rural character and natural environment while investing in infrastructure" + her record "streamlining permitting". Chair 2 excluded **by her own record** — it requires slowing approvals. |
| Mike Nelson | Growth and Development Pace | **2** | Bainbridge Conservation Coalition 2025 council candidate survey: "new development and population growth must yield to the carrying capacity we find"; plan "for reasonable growth, not massive growth". Chair 1 excluded (no growth cap / voter approval); 3 excluded (he subordinates growth to capacity rather than building capacity for growth). |
| Lara Lant | Growth and Development Pace | **2** | Same survey: "the Comprehensive Plan cannot address issues like housing before addressing groundwater limitations"; "Good planning requires good data." |

⚠ Caveat to record in the reasoning for Nelson and Lant: the ladder says "existing **infrastructure**",
and on Bainbridge the binding constraint is the **aquifer**. The substance (growth must not outrun
capacity; slow approvals until it does) is chair 2, but say aquifer, not infrastructure.

## REFUSED — and these are the interesting ones

- **Kirsten Hytopoulos / Affordable Housing — the closest near-miss, top of the queue.**
  Verbatim, verified: *"Essential to this, to endorsing this approach, is layering on the inclusionary
  zoning, the mandatory inclusionary zoning, so that if anything comes through during this period, that
  there will be that component"* (The Urbanist, on the 6-1 interim development regulations vote).
  Chair 2 is *"Use rent caps, require new developments to include affordable units, and publicly fund
  new housing."* She evidences the **middle clause exactly** and chair 3 is affirmatively excluded —
  chair 3 is incentive-based and she insists on **mandatory**. But rent caps and public funding are
  unevidenced, so the compound rule refuses it. **One targeted pass over her council record would very
  likely close this.**
- 🔴 **Do NOT seat six people off the 6-1 interim development regulations vote.** That vote was
  compliance with a state mandate under builder's-remedy pressure, not a preference. A compliance vote
  under legal duress does not evidence a zoning chair. Only Hytopoulos (her stated condition) and
  Nelson (sole NO, "market-rate upzoning") said anything attributable.
- **Mike Nelson / Residential Zoning** — "the City Council and the Planning Commission are pushing a
  plan to massively upzone Winslow… This is disingenuous" + sole NO vote. Consistently anti-upzone, but
  nothing distinguishes chair 1 (strict character protection, community votes) from chair 2 (modest
  increases with design review). Direction without magnitude.
- **Clarence Moriwaki** — explicitly declined to take a position: "I prefer to see the answers and facts
  as determined by the expert peer review." A refusal is not a chair.
- **Joe Lombardi / Local Immigration Enforcement** — "I will keep both ICE and national politics out of
  county cases" is explicit and real, but as a **prosecutor** it speaks to charging, not detainers.
  Chairs 2 and 3 both fit.
- **Lombardi & Enright / Jail Capacity** — both have strong diversion records (pre-arrest diversion,
  THRIVE Court, Girls Court, Recovery Resource Center). The ladder is about **jail capacity**; chair 2's
  distinguishing clause is "rather than building new capacity" and neither addresses capacity at all.
- **Rick Kuss / Public Safety Approach** — "proactive enforcement", "aggressively combat the fentanyl
  crisis", "professional, visible, and responsive". Never names staffing or budget. Seating him at 4 by
  analogy to his opponent would be inventing it.
- **Katie Walters / Transportation Priorities** — expanded transit and ferry service, chairs Kitsap
  Transit. Chairs 1, 2 and 3 all involve transit; nothing distinguishes them.
- **Kevin Tisdel / Growth and Development Pace** — "grow the right way, at the right pace" names no
  chair. The least-extreme-fitting option is a tiebreaker, not evidence.
- **Cook, Simonds, Andrews, Lewis, Kennedy, Boissonneau** — Assessor / Auditor / Clerk / Treasurer.
  Administrative offices; none of the 22 local topics applies. Blank here is **correct**, not a gap.
  Do not "fill them in" later.
- **Penelope Sapp** — acting sheriff, appointed not elected, no policy record found. Blank.

## The real remaining source, not yet worked

Bainbridge Island publishes council **agendas, minutes and video**
(`bainbridgewa.gov/AgendaCenter`, plus `bainbridgeisland.granicus.com`). The substantive per-member
evidence for the seven councilmembers is in **recorded roll calls on named ordinances** — the Winslow
Subarea Plan, the Comprehensive Plan periodic update, the climate action plan, tree/canopy rules.
That is a genuine research campaign, not a scrape: each roll call has to be tied to what the ordinance
actually did before it evidences a chair.

Useful per-candidate secondary sources already located:
- Bainbridge Conservation Coalition 2025 candidate survey (groundwater/carrying capacity only) — worked.
- Housing Resources Bainbridge candidate preview (housing) — worked; only Nelson of our seven appears.
- Bainbridge Island Review (`bainbridgereview.com`) covers council votes with attribution.
- The Urbanist covers BI growth-plan fights with verbatim quotes — verified reliable here.

## Note for coverage.js

`src/lib/coverage.js` carries `{ label: 'Kitsap County', browseGovernmentList: ['53035'] }` with a
comment "No hasContext: zero compass stances, verified against the live DB 2026-08-17." **If any Kitsap
stance lands, flip `hasContext: true` and update that comment.** Seeding the four above would make it
true for Walters and Myers.
