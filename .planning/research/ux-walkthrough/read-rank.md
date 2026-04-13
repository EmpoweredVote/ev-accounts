# Read & Rank — UX Walkthrough (UX-03)

**App:** https://readrank.empowered.vote/
**Framing question (per CONTEXT D-07):** Are there enough sourced quotes for Monroe County primary candidates for the tool to be useful, and does candidate filtering actually surface them?
**Run date:** 2026-04-13
**Persona:** First-time Monroe County voter, 200 W Kirkwood Ave, Bloomington, IN 47404
**Screenshots:** 7 PNGs in `screenshots/read-rank/`
**Gaps appended:** G-114-016 through G-114-020

---

## 1. Landing

**URL:** https://readrank.empowered.vote/ | **Screenshot:** 01-landing.png

The page title in the browser tab reads `readrank-prototype` — the app is deployed to production but still carries its prototype label, which may erode voter trust.

The landing screen presents a pizza emoji animation and two CTAs:
- **"Let's try it"** — enters a pizza-themed practice round to demonstrate the swipe/rank mechanic before real political quotes
- **"Skip practice"** — bypasses the practice and goes directly to the topic list

A first-time voter who doesn't read carefully will click "Let's try it" and spend time on practice before reaching real content. The "Skip practice" link is smaller/secondary and easy to miss. This is minor friction on first visit but not a blocker since the button exists.

Positive: The landing copy accurately describes the deidentification mechanic — "Read real politician quotes without knowing who said them. Agree or disagree, rank your favorites, and see which politicians actually match your views."

---

## 2. Candidate Filter

**URL:** https://readrank.empowered.vote/ | **Screenshots:** 02-topic-list.png, 03-address-filter-no-change.png

After skipping practice, the voter sees a topic list showing all 26 topics (Deportation, Tariffs, Abortion, Homelessness, Housing ×2, Jail Capacity, Voting Rights, Civil Rights, Climate Change, Fossil Fuels, Healthcare, Immigration, Redistricting, Same-Sex Marriage, AI Oversight, AI Regulation, Campaign Finance, Medicare/aid, Misinformation, Religious Freedom, Social Security, Trans Athletes, Ukraine Support, School Vouchers, Data Centers). All show "Not started." A progress counter at top-right reads "0/26."

**Two location filter mechanisms are available — both are non-functional:**

**Address filter (text):** Typing `200 W Kirkwood Ave, Bloomington, IN 47404` and pressing Enter produces zero change in the topic list. All 26 topics remain, none filtered or reordered. The filter field accepts input but does not geocode or filter content.

**Browse Location (dropdown):** Clicking "Browse Location" replaces the text box with a `<select>` dropdown. The dropdown contains only one option: "State" (the placeholder). No actual states are listed — it is an empty select with a placeholder that cannot be used to filter to Indiana.

**Conclusion:** Neither location filter works. A Monroe County voter has no mechanism to narrow Read & Rank to candidates on their ballot. They must evaluate all 26 topics globally to discover which of their local candidates have quotes.

---

## 3. Quote Evaluation Flow

**URL:** https://readrank.empowered.vote/ | **Screenshot:** 04-quote-eval-voting-rights.png

Clicking the "Voting Rights" topic opens the quote evaluation view. The topic shows "1 of 3" — three deidentified quotes. The format:
- Quote text in a card, attributed only as "Quote 1", "Quote 2", etc.
- "Disagree" (left) and "Agree" (right) buttons
- A "Leaderboard" panel on the right (empty until a quote is agreed)

The three Voting Rights quotes observed (pre-reveal):
1. "Every Californian deserves an equal voice in our democracy. Permanent vote-by-mail means more voices are heard..." — explicitly California
2. "That required a lot of negotiation. It required setting up a truly bipartisan committee of experts on both sides of the aisle and independent voters in the community, including with the League [of Women Voters], to help inform that plan." — no location marker but sourced from a Monroe County article (revealed later)
3. "California is now a permanent vote-by-mail state. Every registered voter will receive a ballot at home..." — explicitly California

Two of three Voting Rights quotes are California-specific. The voter has no signal that Q2 is from a Monroe County candidate — the deidentification removes not just names but also geographic context. The voter might disagree with a local candidate's quote (and thus exclude them from the ranking) without knowing it's their candidate.

**Mid-stream champion matchup:** After agreeing with the first two quotes, the app pauses for a "Choose Your Champion" head-to-head before showing Q3. This is an interesting design that builds a ranked tournament, but it adds interaction steps mid-flow.

The same pattern was observed in a second topic (Redistricting, Q1): "Californians voted overwhelmingly to keep the independent redistricting commission. Politicians should not draw their own district lines." — California-specific.

---

## 4. Verdict Flow

**URL:** https://readrank.empowered.vote/ | **Screenshot:** 05-verdict-leaderboard.png

After evaluating all 3 Voting Rights quotes and selecting a final champion, the app shows "All quotes evaluated — 3 ranked · 0 disagreed" with the final leaderboard. A "See Who Said It" button appears.

Clicking "See Who Said It" reveals the politicians with sources:

| Rank | Quote excerpt | Politician | Source | View on Essentials? |
|------|--------------|-----------|--------|-------------------|
| 1 (CHAMPION) | "That required a lot of negotiation... bipartisan committee... League of Women Voters..." | **David G Henry** — Council At Large | B Square Bulletin (Monroe County) | Yes — link with `#compass=` fragment |
| 2 (CHALLENGER) | "Every Californian deserves an equal voice..." | Eleni Kounalakis — CA Lt. Governor | Lt. Governor's Office Press Release | Yes |
| 3 | "California is now a permanent vote-by-mail state..." | Gavin Newsom — CA Governor | Governor's Office Press Release | Yes |

**Key finding:** David G Henry (Monroe County Council At Large, running for County Commissioner D-1 in the May 5 primary) has a sourced quote in Read & Rank — but a voter had no way to know this before completing the evaluation. The California-heavy framing of Q1 and Q3 obscures that Q2 is from a local candidate. Without the location filter working, the voter cannot pre-filter to Monroe candidates.

**Screenshot:** 06-reveal-who-said-it.png

---

## 5. Verdict Flow-Back to Essentials (Guest Path)

The "See Who Said It" reveal screen includes a "View on Essentials" link for each politician. These links use deep URLs with a `#compass=` base64-encoded fragment carrying the voter's Read & Rank session state (which quotes they agreed with, their champion selection). The structure mirrors the Compass → Essentials flow-back discovered in Plan 114-03.

**Example link structure:**
`https://essentials.empowered.vote/politician/0be7d42f-...#compass=eyJ2Ijp7IjE2YzIyNDE5...`

The session data fragment is present and structurally valid. Whether Essentials correctly decodes and displays the Read & Rank verdict badges on the politician profile was not verified in this session (cross-app integration is the subject of Plan 114-06), but the data passthrough from Read & Rank is confirmed working.

On the topic list (post-completion), a paragraph at the bottom reads: **"Your verdicts appear on candidate profiles in Essentials."** — no hyperlink, no CTA button. This text mentions the flow-back but provides no navigation path for a voter who wants to act on it. Logged as G-114-019.

---

## 6. Per-Candidate Quote Coverage — Monroe May 5 Primary

The coverage audit below is based on: (a) direct Voting Rights topic completion (3 quotes observed + reveal), (b) Redistricting Q1 preview (California quote), (c) AUDIT-REPORT-112.md quote counts for linked politicians, and (d) known stub status for county-wide candidates.

| Candidate | Race | Quotes in Read & Rank | Notes |
|-----------|------|-----------------------|-------|
| Will Graham | US Rep IN-9 (D) | 0 | No politician record (stub) per AUDIT-112 |
| Brad A. Meyer | US Rep IN-9 (D) | 0 | No politician record (stub) |
| Tim Peck | US Rep IN-9 (D) | 0 | No politician record (stub) |
| Keil L. Roark | US Rep IN-9 (D) | 0 | No politician record (stub) |
| Erin Houchin | US Rep IN-9 (R) | Unknown | In Compass picker; likely has some quotes; not explored |
| Matt Pierce | IN HD-61 (D) | 10 (in DB, per AUDIT-112) | Confirmed linked politician; quotes exist but voter cannot filter to Pierce without completing multiple topics |
| Lilliana Young | IN HD-61 (D) | 6 (in DB, per AUDIT-112) | Same as Pierce — quotes exist but not surfaceable via location filter |
| Benjamin T. Arrington | Monroe Co Prosecutor (D) | 0 | Stub, no politician record |
| Erika Oliphant | Monroe Co Prosecutor (D) | 0 | Stub (unknown), no confirmed record |
| Bob Nyquist | Monroe Co Assessor (D) | 0 | Stub |
| Judith A. Sharp | Monroe Co Assessor (D) | 0 | Unknown |
| Tanner Dale Branham | Monroe Co Clerk (D) | 0 | Stub |
| Joe Davis | Monroe Co Clerk (D) | 0 | Stub |
| Tree Martin Lucas | Monroe Co Clerk (D) | 0 | Unknown |
| Julie M. Hays | Monroe Co Clerk (R) | 0 | Stub |
| Trent Deckard | Monroe Co Commissioner D-1 (D) | Unknown | In Compass picker; likely some quotes; current office is Council At Large |
| David G. Henry | Monroe Co Commissioner D-1 (D) | ≥1 confirmed | Voting Rights Q1 (B Square Bulletin) — champion in this session |
| Jennifer Crossley | County Council D-4 (D) | 0 | Unknown; no confirmed Compass data |
| Efrat Rosser | Bloomington Twp Trustee (D) | 0 | Unknown; no confirmed data |
| Geoff Bradley | Circuit Court Div 1 Seat 9 (D) | 0 | Unknown; no confirmed data |
| Kara Krothe | Circuit Court Div 6 Seat 5 (D) | 0 | Unknown; no confirmed data |

**Summary:** 4 of the most contested May 5 races (IN-9 D primary, County Prosecutor, County Clerk, County Assessor) have zero Read & Rank quotes for any candidate. Pierce and Young have quotes in the DB, but voter cannot surface them efficiently due to broken location filtering and topic-centric (not candidate-centric) UI structure.

---

## 7. Answering the Framing Question

**Are there enough sourced quotes for Monroe County primary candidates for the tool to be useful, and does candidate filtering actually surface them?**

**Candidate filtering: No.** Both location filter mechanisms (address text entry and Browse Location dropdown) are non-functional. The address filter accepts input but produces no change in topic list or quote content. The Browse Location dropdown has no state options — only a "State" placeholder. A Monroe County voter cannot filter to their candidates by any means in the current production build.

**Enough quotes: Partially.** Pierce has 10 quotes and Young has 6 per AUDIT-112, meaning the HD-61 D primary is theoretically evaluable in Read & Rank. David G Henry has at least 1 confirmed quote. However, those quotes are buried across 26 mixed topics alongside California politicians, with no geographic signal to tell the voter which quotes are from their local candidates. The voter who persists through all 26 topics and reads every reveal will eventually discover their Monroe candidates — but this is a 3–4 hour commitment, and the current UX provides no shortcut.

**For the contested primaries that matter most** (IN-9 D: Graham/Meyer/Peck/Roark; County Prosecutor: Arrington/Oliphant; County Clerk: Branham/Davis/Lucas; County Assessor: Nyquist/Sharp): zero quotes exist. Read & Rank is completely dark for these races.

**Bottom line:** Read & Rank has the right architecture (deidentified quotes → ranking → reveal) but needs two things to be useful for a Monroe County May 5 voter: (1) working location filtering so Pierce/Young/Henry quotes surface without completing all 26 topics, and (2) quote data entry for the contested primary challengers (IN-9 D, County Prosecutor, County Clerk) whose absence makes the tool irrelevant to the primary ballot's most contested races.

---

## 8. Gap Summary (IDs only)

| ID | Severity | Type | One-line |
|----|----------|------|----------|
| G-114-016 | blocker | feature | Both location filters non-functional (address text + Browse Location dropdown) |
| G-114-017 | confusing | ux-friction | Topic-centric structure — no candidate-level navigation to surface Monroe quotes efficiently |
| G-114-018 | blocker | data | IN-9 D primary challengers + all county-race candidates have zero Read & Rank quotes |
| G-114-019 | confusing | ux-friction | "Your verdicts appear on Essentials" has no hyperlink or CTA — dead end for voter who wants to act |
| G-114-020 | minor | content | App page title is "readrank-prototype" — prototype label visible in browser tab in production |

---

*Phase: 114-ux-walkthrough*
*Plan: 04*
*Completed: 2026-04-13*
