# Compass Topic Audit — 2026-04-11

Evaluates all 26 live compass topics against the criteria from the
`2026-04-10-local-officials-topic-scoping-design.md` spec, section
"Audit of existing topics."

## Criteria

For each topic, answer:

1. **Framing level** — `principle` (works at any jurisdictional level),
   `federal-leaning` (technically principle-level but stance language
   names federal programs/roles), or `program` (assumes a specific
   level's policy levers, won't work at other levels).
2. **Tier flags** — which of Federal / State / Local this topic is
   actually meaningful for once correctly framed. Used by
   `inform.compass_topic_roles` for role-aware completeness filtering.
3. **`office_scope` restriction** — whether this topic is primarily
   relevant to a specific office type (judge, sheriff, school board,
   etc.). Optional metadata; default NULL = cross-cutting.
4. **Rewrite verdict** — `keep`, `tweak` (minor stance-scale edits in
   place, no re-evaluation gate needed), or `rewrite` (full rewrite
   workflow through the Plan D machinery).

## Quick summary

| Bucket | Count | Topics |
|---|---|---|
| Keep as-is | 16 | abortion, campaign-finance, childcare, civil-rights, climate-change, data-centers, fossil-fuels, homelessness, jail-capacity, misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers, voting-rights, trans-athletes |
| Federal-only, keep | 3 | social-security, tariffs, ukraine-support |
| Federal + state, keep | 1 | medicare/aid |
| Tweak (stance-text only) | 1 | deportation |
| **Rewrite queue** | **5** | **ai-regulation, housing, taxes, immigration, healthcare** |

Housing was originally classified "keep" but on stance-text review it
has federal-scale language in 3/5 stances plus scope bleed with the
dedicated homelessness topic — promoted to rewrite. See details below.

---

## Full table

| topic_key | framing level | rewrite? | F | S | L | office_scope | notes |
|---|---|---|---|---|---|---|---|
| abortion | principle | keep | ✓ | ✓ | ✓ |   | Federal constitutional + state law; local DAs have prosecutorial discretion post-Dobbs → Local flag added |
| ai-regulation | federal-leaning | **rewrite** | ✓ | ✓ |   |   | Stance 4 ("require govt approval before releasing AI") is federal-only. Reframe around oversight principle. F+S only; local AI policy is too rare to earn a Local flag |
| campaign-finance | principle | keep | ✓ | ✓ | ✓ |   | FEC / state boards / local PACs |
| childcare | principle | keep | ✓ | ✓ | ✓ |   | Programs at all three levels |
| civil-rights | principle | keep | ✓ | ✓ | ✓ |   | |
| climate-change | principle | keep | ✓ | ✓ | ✓ |   | "Nation's" language in one stance, but survivable |
| data-centers | principle | keep | ✓ | ✓ | ✓ |   | Local zoning is the biggest lever — correctly tier-flagged for local |
| deportation | federal-leaning | tweak | ✓ | ✓ | ✓ |   | Stance 1 says "citizenship pathways" (federal). Tweak text to "stop all cooperation with federal deportation enforcement" so it works for sheriffs/city councils. No re-evaluation gate needed — principle is unchanged. |
| fossil-fuels | principle | keep | ✓ | ✓ | ✓ |   | "Nation's energy future" in question_text is soft-federal but survivable |
| healthcare | **program** | **rewrite** | ✓ | ✓ | ✓ |   | Stance 1 = single-payer, stance 2 = public option. These are federal-only levers. Reframe around principle of government's role in guaranteeing access. |
| homelessness | principle | keep | ✓ | ✓ | ✓ |   | Grants Pass decision makes this cross-tier |
| housing | **program** | **rewrite** | ✓ | ✓ | ✓ |   | (1) Title conflates housing affordability with homelessness (duplicative with dedicated homelessness topic). (2) Stance 5 names "federal housing programs"; stance 2 "build millions" is federal scale; stance 1 is federally aspirational. Rewrite to pure housing-supply topic, strip homelessness overlap. |
| immigration | **program** | **rewrite** | ✓ | ✓ | ✓ |   | Stances are about "borders" and "immigration levels" — federal-only concepts. Reframe around principle of welcoming-vs-restrictive posture so local officials (sanctuary, driver's licenses, enforcement cooperation) fit. |
| jail-capacity | principle | keep |   | ✓ | ✓ |   | County + state. Federal prison policy rarely discussed at this level. |
| medicare/aid | federal | keep | ✓ | ✓ |   |   | Medicaid expansion is a real state-level vote (10 states still haven't expanded as of 2025). F-only loses half the meaning. |
| misinformation | principle | keep | ✓ | ✓ |   |   | Section 230 (F), state laws (TX/FL). Not really a local lever. |
| redistricting | principle | keep | ✓ | ✓ |   |   | State process, federal VRA oversight. Not local. |
| religious-freedom | principle | keep | ✓ | ✓ | ✓ |   | |
| same-sex-marriage | principle | keep | ✓ | ✓ |   |   | Federal constitutional + state. Obergefell binds clerks; Kim Davis was an outlier, not a real local lever. F+S only. |
| school-vouchers | principle | keep | ✓ | ✓ |   |   | Primarily state; some federal. Local school boards administer public schools but can't fund vouchers (vouchers redirect state funding). F+S only. |
| social-security | federal | keep | ✓ |   |   |   | F-only. |
| tariffs | federal | keep | ✓ |   |   |   | F-only. |
| taxes | **program** | **rewrite** | ✓ | ✓ | ✓ |   | Stance 1 = "raise taxes on wealthy individuals and corporations" — that's federal/state income tax. Local tax is property/sales/permits — different instrument. Reframe around progressive-vs-regressive burden or service-funding willingness. |
| trans-athletes | principle | keep | ✓ | ✓ | ✓ |   | State athletic associations are the biggest lever; local school boards play a role; federal via Title IX. |
| ukraine-support | federal | keep | ✓ |   |   |   | F-only. |
| voting-rights | principle | keep | ✓ | ✓ | ✓ |   | Federal VRA, state laws, local election administration. |

---

## The rewrite queue (priority order)

These 5 topics need to run through the Plan D workflow. Ordered by
**political sensitivity** (lowest first, so the workflow gets shaken out
on low-stakes rewrites before high-stakes ones):

### 1. ai-regulation (lowest stakes, small number of stances to re-evaluate)

**Problem:** Stance 4 ("require government approval before releasing advanced
AI systems") is a federal-only lever. A city council can't gate AI releases.

**Rewrite direction:** Keep the oversight-intensity spectrum but make it
jurisdictionally agnostic. Each level has real AI levers (federal: NIST
standards, federal procurement, export controls; state: consumer protection,
transparency laws, employment regulation; local: facial recognition bans,
procurement restrictions, school use policies). The question becomes "how
much government oversight should there be over AI, at whatever level you
sit in?"

### 2. housing (scope cleanup + federal-scale language)

**Problem:** Two distinct issues.
(a) Title and question conflate housing affordability with homelessness,
but there's already a dedicated `homelessness` topic. Scope bleed.
(b) Stance 5 names "federal housing programs" (federal-only), stance 2
says "build millions of affordable housing units" (federal scale — a city
builds hundreds, a state maybe tens of thousands), and stance 1 "free
homes as a human right" is federally aspirational. Only stances 3 and 4
work cleanly at any level.

**Rewrite direction:** Retitle to `Affordable Housing` (drop "and
Homelessness"). Tighten the question to housing supply and affordability
only. Rewrite stances 1, 2, 5 to use jurisdictionally neutral language:
a strong supply-side position ("government should directly build and own
housing at scale"), a middle ground ("incentivize private development
and subsidize rent"), and a hands-off position ("reduce regulations and
let markets allocate housing"). Leaves stances 3 and 4 mostly intact.

### 3. taxes (principle-level, but mechanistic stance language)

**Problem:** Current stances name "income tax" instruments (raising taxes on
"wealthy individuals and large corporations", "flat tax"). Local officials
debate property tax rates, sales tax increases, fee structures, service
levies — not income tax brackets.

**Rewrite direction:** Reframe around willingness to tax for public services
("government should collect more / the same / less to fund public services"),
or around progressive-vs-regressive burden distribution. Both work at every
level.

### 4. immigration (high political salience, but local hook is clear)

**Problem:** Current stances are federal border/quota language. No local or
state lever fits.

**Rewrite direction:** Reframe around welcoming-vs-restrictive posture toward
newcomers. Federal: quotas and border policy. State: driver's licenses,
in-state tuition, occupational licensing for undocumented residents. Local:
sanctuary policies, ICE cooperation, municipal ID programs, language access.
Same underlying principle ("how should this jurisdiction treat immigrants
within its authority") maps to all three.

### 5. healthcare (highest salience, most contested reframe)

**Problem:** Current stances are entirely about federal insurance
architecture (single-payer, public option, ACA). Local officials have real
healthcare levers (public hospitals, clinic funding, Medicaid expansion
advocacy, public health authority) but the current stance scale doesn't
touch any of them.

**Rewrite direction:** Reframe around government's role in guaranteeing
healthcare access, abstracted from specific insurance architecture. The
stance spectrum becomes "government should guarantee universal access / use
targeted programs for the uninsured / leave it to markets" — works for
federal single-payer debates, state Medicaid expansion votes, and local
public-hospital funding alike.

**Save for last** because getting this reframe wrong is the most visible
failure mode — healthcare is where voters form the strongest priors.

---

## Judgment calls — resolved

All 8 calls (original 7 plus housing) walked with Chris on 2026-04-11.
Decisions below; the table above has been updated to match.

1. **deportation — tweak, not rewrite.** Only stance 1 has federal-only
   language ("citizenship pathways"). The other four are already
   principle-level about enforcement aggressiveness. Edit stance 1 in place
   via the existing `TopicAdminPanel` admin UI; no re-evaluation gate
   needed because the underlying principle isn't moving.

2. **ai-regulation — F+S, drop Local.** Facial-recognition bans and
   school AI policies exist but aren't primary compass issues for a mayor
   or city council.

3. **school-vouchers — F+S, drop Local.** Local school boards administer
   public schools but can't fund vouchers (vouchers redirect *state*
   funding).

4. **medicare/aid — F+S.** Medicaid expansion is a real state-level vote
   (10 states still haven't expanded as of 2025). F-only loses half the
   topic's meaning.

5. **misinformation — F+S, no Local.** City council resolutions exist
   but aren't meaningful policy work. Section 230 (F) and state social-
   media laws (TX, FL, UT) are the real terrain.

6. **trans-athletes — keep on compass for now, flag for re-audit in 6
   months.** Politically salient enough that voters want positions; the
   stance scale is already principle-level; folding into civil-rights
   loses resolution. Revisit once usage data is in.

7. **abortion — add Local flag (F+S+L). same-sex-marriage — keep F+S.**
   Local DAs genuinely have prosecutorial discretion post-Dobbs on
   abortion cases. Kim Davis was an outlier and Obergefell still binds
   clerks, so same-sex-marriage has no meaningful local lever.

8. **housing — promote to rewrite queue.** Not a tier-flag question
   but surfaced during review. Title/question conflate housing
   affordability with homelessness (duplicative with the dedicated
   homelessness topic); stances 1/2/5 use federal-scale language.
   Slotted as rewrite #2 after ai-regulation.

---

## Next actions after this audit lands

1. **Backfill tier flags** — once you approve the table above, a one-time
   script pass writes the F/S/L flags into `inform.compass_topic_roles`
   using the values from this doc. This is the input Plan A was waiting
   for (migration 059 created the table + constraints but left it empty).

2. **Handle the deportation tweak** — not through Plan D workflow, just
   direct stance text edits via the existing admin UI (`TopicAdminPanel`).

3. **Run the 5 rewrites through the Plan D workflow, one at a time, in
   the order above** (ai-regulation → housing → taxes → immigration →
   healthcare). Each takes: draft new framing → framing gate → seed
   proposals → research + paste proposed stances per affected politician
   → approve/reject gate → publish. Healthcare goes last.

4. **Re-audit in ~6 months** — once you have real voter behavior data
   on the rewritten topics, revisit whether the new framings actually
   surface meaningful disagreement, and whether the tier flags match
   actual usage patterns.
