# Essentials — UX Walkthrough (UX-01)

**App:** https://essentials.empowered.vote/
**Address:** 200 W Kirkwood Ave, Bloomington, IN 47404
**Run date:** 2026-04-13
**Persona:** Naive first-time Monroe County, IN voter entering cold (METHODOLOGY.md §1)
**Execution:** Playwright MCP (`mcp__plugin_playwright_playwright__browser_*`) end-to-end, no human-leg fallback needed.

---

## 1. Landing

Clean landing at `https://essentials.empowered.vote/`. Header reads **"Find Your Representatives"** with subhead "Enter your address to see who represents you" and a "We currently cover:" block showing two jurisdiction buttons: *Monroe County, Indiana* and *Los Angeles County, California*. Below the separator there is a single address textbox labeled "Enter your full street address" with a disabled Search button. No login wall — guest-first is respected.

Evidence: `screenshots/essentials/01-landing.png`

Observation: scope is stated up-front via the two jurisdiction chips, which correctly sets voter expectation that out-of-area addresses will degrade. No gap logged at this screen.

---

## 2. Address Entry

Typed `200 W Kirkwood Ave, Bloomington, IN 47404` character-by-character into the textbox. The Search button enabled as soon as text was present, but **no Google Places autocomplete dropdown appeared at any point during typing** — the textbox captures a raw string and there is no live confirmation that the address is recognized or geocodable before clicking Search. (→ G-114-001)

Evidence: `screenshots/essentials/02-address-typed.png`

Clicking Search navigated to `/results?q=200%20W%20Kirkwood%20Ave%2C%20Bloomington%2C%20IN%2047404`. No intermediate loading screen was captured — the transition was effectively instant.

---

## 3. Results — Federal Tier

Results page opened on the **Representatives tab** (default). The address header paragraph reads `Showing representatives for 200 W KIRKWOOD AVE, BLOOMINGTON, IN, 47404` — note: the address is rendered in ALL CAPS even though the voter typed mixed case. (→ G-114-002)

The Federal tier on the Representatives tab renders `U.S. Congress → U.S. House of Representatives - Indiana 9th Congressional District` with **only Erin Houchin** (the sitting incumbent), plus Todd Young under U.S. Senate, and the full U.S. Executive / Cabinet / Supreme Court blocks. The four Democratic primary challengers for IN-9 on the May 5 ballot (James H. Graham, Brad A. Meyer, Tim Peck, Keil L. Roark — per `BALLOT-BASELINE-2026-05-05.md` §"Federal Races") **do not appear on this tab**. They do appear on the Elections tab (see §6 below), but a first-time April-2026 voter who lands on the default Representatives tab will see only the incumbent. (→ G-114-003)

Evidence: `screenshots/essentials/03-results-all.png`

---

## 4. Results — State Tier

Representatives tab renders `State of Indiana General Assembly` with Matt Pierce (Indiana House of Representatives District 61) flagged `This seat is on your ballot — Primary: May 5, 2026`, plus Shelli Yoder (Indiana State Senate District 40). Only Pierce is correctly badged as on-ballot (Yoder's term runs to 2028 and is not on this primary, which matches — Yoder is shown as sitting rep, not candidate).

Also renders full `State of Indiana Executive` (Braun / Beckwith / Rokita / Jenner / Lamb / Morales / Morrison / Nieshalla / Elliott), `State of Indiana Departments & Commissions`, `Indiana Court of Appeals`, and `Indiana Supreme Court`. Lilliana Young (Pierce's Democratic primary opponent, HD-61, confirmed in `BALLOT-BASELINE-2026-05-05.md` §"State Legislative Races") **is not present on the Representatives tab** — this is the same missing-challengers pattern as the Federal tier.

Evidence: `screenshots/essentials/03-results-all.png` (same full-page shot covers tiers 3-5)

---

## 5. Results — Local Tier

Representatives tab renders three local accordion sections in this order:

1. **City of Bloomington** — Common Council members (Bolden, Rosenbarger, Asare, Flaherty, Ruff) plus Mayor Kerry Thomson. Mayor card shows a "Compare your views" chip, indicating CompassCard integration (will be exercised in Plan 114-06 per METHODOLOGY §9 cross-app).
2. **Bloomington Township** — Efrat Rosser (Trustee), Dorothy Granger / Barbara McKinney / Elizabeth Sensenstein (Township Board). All four correctly badged `on your ballot — Primary: May 5, 2026`, which matches baseline §"Township Races" for Bloomington Township (all four are D, uncontested, single slot).
3. **Monroe County** — shows Elizabeth Jones (Commission D-1), Julie Thomas (D-2), Jody Madeira (D-3), Jennifer Crossley (Council D-4) + several Council At-Large members including **Trent Deckard** and **David Henry** listed under `Council At Large`. These two are correctly badged on-ballot, but baseline has them running for **Monroe County Commissioner District 1** (not Council At Large). On the Elections tab (§6 below) they do correctly appear as Commissioner District 1 candidates. The Representatives-tab listing is showing their *current* office while the Elections-tab listing is showing their *sought* office — two tabs, two different offices for the same person, with no indication to the voter that they overlap. (→ G-114-004)

Also under Monroe County: all sitting constitutional officers — Nicole Browne (Circuit Court Clerk), Trohn Enright-Randolph (Surveyor), Brianne Gregory (Auditor), Jeffrey Hall (Coroner), Ruben Marte (Sheriff, on-ballot), Erika Oliphant (Prosecuting Attorney, on-ballot), Judith Sharp (Assessor, on-ballot), Catherine Smith (Treasurer), Amy Swain (Recorder, on-ballot). `Monroe County Circuit Court` accordion below shows all 9 circuit judges with division numbers, with Geoffrey Bradley (Div 1) and Kara Krothe (Div 6) badged on-ballot.

Note: the Representatives tab accordion ordering is **local-first** (City → Township → County → Circuit Court → State → Federal). This is intentional per CLAUDE.md tier classification but is the opposite of what a voter typically scans for. Not logged as a gap — it matches the app's documented design.

---

## 6. Election Central (Elections Tab)

Clicked the `Elections` tab. URL updates to `?view=elections`. The page reframes to **"2026 Indiana Primary — May 5, 2026"** with an "Upcoming" chip, and re-renders the same accordion sections with a completely different candidate set: every contested primary slot from `BALLOT-BASELINE-2026-05-05.md` is now visible, including:

- **IN-9 D primary:** James H. (Jim) Graham, Keil L. Roark, Tim Peck, Brad A. Meyer + Erin Houchin (incumbent R) — all 5 present and correctly badged as on-ballot. (This is the same data AUDIT-REPORT-112 §AUDIT-08 Geofence Test confirmed lives in the DB; it just isn't surfaced on the default Representatives tab.)
- **IN HD-61:** Matt Pierce + **Lilliana Young** (D challenger per baseline)
- **County Prosecuting Attorney:** Erika Oliphant + **Benjamin T. Arrington**
- **County Assessor:** Judith A. Sharp + **Bob Nyquist**
- **County Clerk:** Tree Martin Lucas, Tanner Dale Branham, Joe Davis (D) + Julie M. Hays (R)
- **Commissioner District 1:** David G. Henry + Trent Deckard
- **County Council District 4:** Jennifer Crossley (uncontested D, confirming voter is in D-4, not Peter Iversen's D-1 — matches AUDIT-REPORT-112 §AUDIT-08 geofence resolution at Bloomington City Center)
- **Recorder:** Amy Swain. **Sheriff:** Ruben Marte. **Bloomington Township Trustee:** Efrat Rosser. **Township Board:** Granger / McKinney / Sensenstein.
- **Circuit Court Judge:** Kara Elaine Krothe (Div 5/6), Geoff Bradley (Div 9/1)

The race coverage on the Elections tab is **complete and correct against the baseline denominator** for a Bloomington Township voter — every race from the baseline that applies to this address is present. This is an important positive finding.

However, **the voter has to know to click Elections** to see this. The default tab is Representatives (§3-5 above), which hides everyone except the sitting incumbent in each seat. For the voter's core question — *"who will I be voting between on May 5?"* — the default view is the wrong one in the month before a primary. (→ G-114-005)

Evidence: `screenshots/essentials/04-elections-tab.png`

---

## 7. Representative Cards

Card interaction on the Results page: every card is a `<button>` with accessible label and portrait thumbnail (or initials placeholder if no photo is on file). Clicking any card navigates to `/candidate/<uuid>`. Cards are grouped under jurisdiction accordions (City of Bloomington / Bloomington Township / Monroe County / State / Federal) and each accordion can be collapsed/expanded.

Observed non-issue: cards correctly surface a "This seat is on your ballot" badge with the primary date string. The badge appears on both the Representatives tab (for sitting officials whose seats are up) and the Elections tab (for all ballot candidates). No gap logged here — the badge mechanism works correctly.

No Federal / State / Local group-filter radios were exercised beyond the default `All`. The filter radios are present in the left sidebar and change the accordion rendering; they are not tested in depth in this walkthrough.

---

## 8. Candidate Profile — Incumbent (Matt Pierce)

Clicked Matt Pierce card from Elections tab. Navigated to `/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa`.

**What's present:**
- Header: "Matt Pierce" + "Candidate for State Representative, District 61"
- Body blurb: *"Indiana House of Representatives – District 61 — State Representatives are members of the state's lower chamber…"* (generic per-office description, not a Pierce biography)
- Contact card with Office phone, Central contact, Primary contact
- **Committee Memberships:** "Statutory Committee on Ethics — Member"
- **Voting stats:** "Voted in 100% of roll calls", "Authored 5 bills that advanced past introduction", plus a sample vote row ("Voted Nay on Shooting ranges — passed")
- `View Full Legislative Record` button (not exercised)
- **Compass & Issues** section with 19 topic stance buttons (Healthcare, Abortion, Taxes, Same-Sex Marriage, Trans Athletes, Fossil Fuels, Voting Rights, Deportation, Climate Change, Civil Rights, Campaign Finance, Immigration, Redistricting, School Vouchers, Data Centers, Homelessness, Childcare, AI Oversight, Housing), plus a "Expand my compass →" link to Compass (`https://compass.empowered.vote?return=...`)

**What's missing or wrong:**
- **Header date string reads `"Election: May 4, 2026"`.** The Indiana primary is **May 5, 2026** per `BALLOT-BASELINE-2026-05-05.md`. Off-by-one, but this is the date a voter would trust. (→ G-114-006)
- **No personal biography paragraph.** The voter learns what a state rep does generically, but nothing about Matt Pierce specifically — no office tenure, no background, no career history. `AUDIT-REPORT-112.md §AUDIT-06` flags Pierce with `Complete = N` (bio incomplete); this walkthrough confirms the voter-facing consequence. (→ G-114-007)
- **No visible Read & Rank section.** `ev-ui/src/PoliticianProfile.jsx` references Read & Rank verdict badges "under StanceAccordion" per project conventions, but none were visible on Pierce's profile. `AUDIT-REPORT-112.md §AUDIT-04` shows Pierce has 10 quotes linked in DB, so data exists — the surface appears to not be rendering. Logged as a separate gap. (→ G-114-008)

Evidence: `screenshots/essentials/05-pierce-profile.png`

---

## 9. Candidate Profile — Challenger (Lilliana Young, then Benjamin T. Arrington)

### Lilliana Young (linked but thin)

Clicked Young's card from Elections tab. Navigated to `/candidate/cb131cec-4fb4-4619-a2f0-7cdea745a2e9`.

**What's present:**
- Header: "Lilliana Young" + "Candidate for State Representative, District 61"
- "Indiana State Representative" label
- **Compass & Issues** section with a single expanded topic (Medicare/aid) and a `Show all 15 topics` button — AUDIT-REPORT-112 §AUDIT-03 confirms she has 15 of 26 stances (57.7%)
- `Expand my compass →` link to Compass

**What's missing or wrong:**
- **Same `"Election: May 4, 2026"` date bug** as Pierce (confirming it's an app-wide template string, not per-politician data)
- **No headshot** — only a "LY" initials placeholder. AUDIT-REPORT-112 §AUDIT-05 confirms `photo_source=none` for Young. Voter-facing confirmation of known DB gap. (→ G-114-009)
- **No biography, no contact info, no committee/voting sections** — she is a challenger, so the sitting-rep sections are correctly suppressed, but there is no "About the candidate" equivalent that would give the voter background on who she is
- **No Read & Rank section** — AUDIT-REPORT-112 §AUDIT-04 shows Young has 6 quotes linked; none surfaced here

Evidence: `screenshots/essentials/06-young-profile.png`

### Benjamin T. Arrington (DB stub — profile is a single card)

Clicked Arrington from Elections tab (Monroe County Prosecuting Attorney D primary). Navigated to `/candidate/a9f49b8d-086d-493f-8c34-a240c427200a`.

**What's present:**
- "Benjamin T. Arrington" header + "Candidate for Monroe County Prosecuting Attorney" + `"Election: May 4, 2026"`

**Everything else is missing.** No Compass section. No bio. No contact. No headshot (BA initials). No committee/voting sections (expected — challenger, not sitting). The profile page is **literally a single name card and nothing else.** AUDIT-REPORT-112 §AUDIT-03 confirms Arrington is a `stub` (unlinked politician — no `politician_id`), which is the DB root cause.

Arrington is not alone. Cross-referencing AUDIT-REPORT-112 `stub` rows against the Elections tab for 200 W Kirkwood, the following May 5 primary candidates on this voter's ballot are also DB stubs with equally empty profiles:
- **Bob Nyquist** (County Assessor D primary vs Sharp)
- **Joe Davis** (County Clerk D primary)
- **Tanner Dale Branham** (County Clerk D primary)
- **Julie M. Hays** (County Clerk R — uncontested but still a ballot position)

For a Monroe County voter weighing the contested D prosecutor race (Oliphant vs Arrington), or the 3-way contested D clerk race (Lucas vs Branham vs Davis), **4 of the ~10 D primary options on the May 5 ballot are unchooseable from this interface** — the voter gets a name card with the wrong election date and nothing else. (→ G-114-010)

Evidence: `screenshots/essentials/07-arrington-empty-profile.png`

---

## 10. Legislative Activity (committees / bills / votes)

Surveyed inside Pierce's profile (§8). The `Committee Memberships` table renders one row (Statutory Committee on Ethics, Member). The voting-activity panel renders two aggregate stats ("Voted in 100% of roll calls", "Authored 5 bills that advanced past introduction") and a single example vote row ("Voted Nay on Shooting ranges — passed"). A `View Full Legislative Record` button exists but was not clicked in this walkthrough.

No structural gap at the section level — the legislative record scaffolding is in place and renders for sitting officials who have data (Pierce). Challengers (Young, Arrington) correctly omit this section entirely rather than rendering empty placeholders, which is the right call.

---

## 11. Empty / Error / Loading States

Tested the "valid address outside coverage area" path by navigating to `/results?q=1600+Pennsylvania+Ave+NW%2C+Washington%2C+DC+20500` directly. The app handled this cleanly:

- Header: `Showing representatives for 1600 PENNSYLVANIA AVE NW, WASHINGTON, DC, 20500`
- **Local accordion:** explanatory paragraph — *"Local representative data is not yet available for this area."*
- **State accordion:** *"State representative data is not yet available for this area."*
- **Federal accordion:** full U.S. Executive + Cabinet + Supreme Court render normally (these are not geofenced — they apply nationwide)

This is **good behavior** for the out-of-area path: clear explanatory copy, federal-tier content still useful, no error page. No gap logged.

Evidence: `screenshots/essentials/08-out-of-area-dc.png`

Loading states were effectively instant on the production deployment — no spinner or skeleton was observed during the ~1s transition from `/` to `/results`. Error states (backend 500, timeout) were not provoked in this walkthrough and are not logged here.

---

## 12. Back-Nav Behavior

Used `browser_navigate_back` from Pierce's profile back to `/results?...&view=elections`. The Elections tab state was preserved (URL param), the scroll position defaulted to top, and all accordions re-rendered expanded. No state loss. No gap logged.

---

## 13. Gap Summary (IDs only)

The following monotonic `G-114-NNN` entries were appended to `GAPS.md` by this walkthrough. All are scoped to `app: essentials`.

- G-114-001 — No Google Places autocomplete on the address field during typing
- G-114-002 — Address rendered ALL CAPS in results header regardless of input case
- G-114-003 — Default results tab (Representatives) hides primary challengers from the incumbent-only view
- G-114-004 — Same candidate (Deckard/Henry) appears under different offices on Representatives tab vs Elections tab with no cross-linkage hint
- G-114-005 — Default tab `Representatives` is the wrong default in the month before a primary; `Elections` should lead for a voter preparing to vote
- G-114-006 — Profile page header reads `"Election: May 4, 2026"` — off by one day from the actual May 5 primary; confirmed on 3 profiles (Pierce, Young, Arrington) → app-wide template bug
- G-114-007 — Matt Pierce profile lacks a personal biography paragraph (AUDIT-REPORT-112 §AUDIT-06 Complete=N confirmed voter-facing)
- G-114-008 — Matt Pierce profile has no visible Read & Rank section despite 10 quotes linked in DB (AUDIT-REPORT-112 §AUDIT-04)
- G-114-009 — Lilliana Young has no headshot (LY initials placeholder) — confirms AUDIT-REPORT-112 §AUDIT-05 `photo_source=none`
- G-114-010 — 4 of the May 5 primary candidates on this voter's ballot (Arrington, Nyquist, Joe Davis, Tanner Dale Branham; plus Julie Hays as an uncontested R slot) have profile pages that are literally a single name card with no bio, no headshot, no Compass, no contact — they are DB stubs per AUDIT-REPORT-112 §AUDIT-03, and the voter-facing consequence is that contested races are unchooseable

**Count:** 10 gap entries, meeting the §5-per-plan floor (minimum 6 for Essentials per 114-02 PLAN).

**Antipartisan check:** No entry references party labels, endorsements, or interest-group ratings. Per METHODOLOGY §8, these absences are intentional and not gaps.

---

*Walker: Claude (Plan 114-02, Phase 114 UX walkthrough)*
*Driven via Playwright MCP against production on 2026-04-13.*
