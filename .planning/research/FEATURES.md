# Features Research — Empowered Vote Platform

**Research date:** 2026-02-17
**Milestone:** Platform quality & consolidation — demo-ready improvements
**Question:** What features do civic engagement platforms have for quiz UX, candidate display, and multi-level government navigation? What's table stakes vs differentiating?

---

## 1. Guest-First Quiz Experiences with Optional Account Creation

### What the market does

iSideWith (the largest political quiz platform by traffic) allows full quiz completion without login. Results appear immediately. Account creation is surfaced post-completion as an optional "save your results" CTA. Vote Compass (used by national broadcasters for major elections) follows the same pattern: no login gate, results always visible, sharing is the viral loop. Pew Research Political Typology quiz is fully anonymous with no account option at all.

The pattern across all high-traffic political quizzes: **friction-free entry, optional persistence**.

### Table stakes

- Quiz runs fully in-browser without requiring an account
- Results are visible before any save/login prompt
- localStorage is used to persist responses across sessions for returning guests
- "Save your results" CTA appears after quiz completion, not before
- Returning guests see their previous answers without logging in

### Differentiators

- Seamless account merge: guest localStorage state is promoted to server-side on login without data loss
- Shareable result links that work for non-registered users
- "Continue where you left off" messaging when a returning guest lands on the quiz

### Anti-features (deliberately avoid)

- Login walls before any quiz interaction — this is the primary conversion killer for political quiz tools
- Mandatory email collection to see results
- Showing a "register to unlock" gate in the middle of the quiz

### Complexity: Low-Medium
The core change is unwrapping `ProtectedRoute` from quiz routes and routing localStorage answers through the existing `CompassContext`. The tricky part is the merge flow when a guest logs in mid-session: the client must POST buffered localStorage answers to the server and then clear local state. This is a known pattern (Shopify cart merge, etc.) but needs careful sequencing.

### Dependencies
- Requires `CompassContext` to work without a user ID (use `null` or a guest UUID)
- "Clear compass" must be admin-only before guest mode ships — otherwise any user can clear their own results without login and the feature becomes pointless
- Server-side answer persistence stays as-is; guest answers stay in localStorage only

---

## 2. Political Compass/Quiz UX Patterns — Stance Presentation and Bias Mitigation

### What the market does

Positional bias (primacy/recency effects) is well-documented in survey research and explicitly addressed in political quiz design. The Prism Political Quiz uses a fixed seed for randomization so users can share a "same quiz" experience. Research on LLM political bias testing explicitly randomizes answer option order per administration to control for selection bias.

The Political Compass test uses agree/disagree on fixed statements — no ordering — which sidesteps the problem by design. iSideWith shows stances as radio buttons with fixed ordering (strongly agree → strongly disagree) because their scale is unidimensional. EV's quiz is multi-dimensional with custom stances per issue, which makes random ordering both necessary and more complex.

The current EV implementation already randomizes which spokes are inverted (via `initRandomInversions`). The gap is that stance buttons within each issue are displayed in their database insertion order — a subtle but real bias vector.

### Table stakes

- Stances presented in an order that does not systematically advantage any position
- If stances have a natural spectrum (most supportive → least supportive), the full spectrum is preserved but the direction is randomized (not the internal ordering of a spectrum)
- The per-user ordering is permanent once set — changing it on each visit would confuse returning users

### Differentiators

- Showing a question/prompt above each issue rather than just a category title — users understand what they are being asked, not just the topic area
- "Importance" weighting per issue (iSideWith does this; it significantly improves match quality)
- Neutral "skip" option separate from a midpoint answer

### Anti-features

- Randomizing stance ordering differently on every page visit — users who return and remember their previous answer will get confused
- Hiding the stance labels until a user scrolls — all options must be immediately visible for informed choice
- Showing stances with a visual scale that implies ordinal ranking when the stances are categorical

### Complexity: Low
The per-user permanent randomization is low complexity: generate a boolean per (user_id OR guest_uuid, topic_id) on first encounter, store in localStorage (guest) or server (authenticated), and use it to determine whether to reverse the stances array before render. The spectrum is preserved — only the direction flips. The existing `initRandomInversions` pattern in `CompassContext` is the right template; apply the same approach to stances.

### Dependencies
- Requires a question/prompt field on the `Topic` model (currently only `title` and `short_title` exist — `start_phrase` is close but used differently)
- Guest randomization state lives in localStorage alongside guest answers

---

## 3. Candidate vs. Incumbent Display Patterns in Voter Guides

### What the market does

Ballotpedia distinguishes incumbents with a badge and sorts them first within their race. Guides.vote (7M+ distribution in 2024) shows candidates grouped by race with clear "Incumbent" labels. Vote.gov links to official state voter guides which universally label incumbents.

The Center for Civic Design's voter guide field guide recommends presenting candidates with equal visual weight per position — not emphasizing incumbents over challengers — but does recommend clearly labeling status. The practical consensus: label the distinction, do not re-rank by it.

For EV's use case (politician lookup by ZIP, not a ballot context), the incumbent/candidate split is more about data freshness and relevance than ballot context. A candidate is someone running for an office they do not currently hold; showing them alongside current officeholders is genuinely useful for voters doing pre-election research.

### Table stakes

- Clear visual distinction between current officeholders and candidates (badge, border style, or section header)
- Candidate cards do not appear unless the user has explicitly opted in (toggle or filter) — candidates are noisier data and the primary use case is "who represents me now"
- Election date shown on candidate cards so users know when the race is
- Party affiliation on both incumbent and candidate cards

### Differentiators

- Grouping candidates with the incumbent they are challenging (e.g., "Senate — Illinois" shows the incumbent plus any declared challengers in the same cluster)
- "Upcoming election" banner on a section when candidates exist for that race
- Linking candidate and incumbent profiles for direct comparison

### Anti-features

- Mixing candidates and incumbents in the same undifferentiated list — this is the worst UX pattern from a user trust perspective; users think they are seeing current officeholders
- Showing candidate data without a clear "running for" or "candidate" label
- Displaying candidates by default when users expect to see current representation

### Complexity: Medium
The data model already has `ElectionRecord` and the BallotReady candidacy fetch. The work is: (1) a backend flag or separate endpoint for candidates vs. incumbents, (2) frontend toggle UI, (3) card visual variant for candidates. The BallotReady candidacy data already distinguishes these via the `is_appointed`/`is_vacant` fields and race data.

### Dependencies
- BallotReady candidacy fetch (lazy-loaded on profile view) must run proactively for ZIP results, not just profiles, to populate candidates in the ZIP view
- ElectionRecord must reliably distinguish current term vs. upcoming race

---

## 4. Multi-Level Government Navigation (Federal/State/Local)

### What the market does

The existing three-tier tab UI (Federal / State / Local) matches what Ballotpedia, Google's "Who represents me" feature, and most congressional contact tools use. The tab pattern is standard. The differentiation opportunity is in the sub-grouping and ordering within each tier.

Ballotpedia orders federal content as: Executive → Senate → House → Independent Agencies. This matches importance/familiarity. EV currently shows local before state before federal in the "All" view — the reverse of how most voters think about salience.

The U.S. Web Design System (used by federal agencies) recommends leading with the most immediately actionable content for users' current context. For a ZIP-based lookup, local officials are often most actionable (council members, school board). But for name recognition and initial orientation, federal is usually the user's starting mental model.

### Table stakes

- Three-tier navigation (Federal / State / Local) is expected and must be present
- Federal section always shows president/VP plus the user's senators and representative
- State section always shows governor plus the user's state legislators
- Within-tier grouping by category (e.g., U.S. Senate, U.S. House) with clear category headers
- Category ordering matches political salience: for federal — President/VP, Senate, House, then Cabinet/agencies

### Differentiators

- Building/landmark imagery per tier as visual anchoring (Capitol dome for federal, state capitol for state, city hall/courthouse for local)
- "Your representatives" quick-jump to show only directly elected officials (filter out appointed/cabinet)
- Position start/end dates on cards for context ("Term ends 2026")
- Level indicator on compass issues (this issue affects federal policy vs. state law vs. local ordinance)

### Anti-features

- Infinite scroll within a tier with no visual grouping — users lose context
- Hiding all three tiers behind a single long scrolling list without tier headers
- Building images that are generic stock photos rather than actual local landmarks — this erodes trust with users who recognize their local buildings

### Complexity: Low-Medium
Reordering federal categories is a frontend-only change to the `FEDERAL_ORDER` sort constant. Building images require curating a small asset library (one image per major government building type) and associating them with tier headers. The image sourcing/licensing is the hard part, not the implementation. Level indicators on compass issues require a new `level` field on the `Topic` model and a UI badge.

### Dependencies
- Federal reordering: standalone, no backend changes
- Building images: need to decide on image sourcing (Unsplash, Wikipedia Commons, or custom photography for local buildings)
- Issue level indicators: requires `Topic` model migration (add `level` enum field) and admin UI to set it

---

## 5. Building/Landmark Imagery for Government Levels

### What the market does

USA.gov uses the Capitol dome as a visual anchor for federal content. State government portals use state capitol photos. Most civic platforms that include building imagery use it as section headers or background cards — not inline with each politician card.

The pattern is: one representative image per tier/section, not one per politician or per category.

### Table stakes

- A recognizable civic building image per government tier (federal, state, local)
- Images are used as section headers or background treatments, not card thumbnails
- Alt text that identifies the building for accessibility

### Differentiators

- Actual local buildings: the Bloomington City Hall for Bloomington local section, the Los Angeles City Hall for LA local section — this makes the platform feel locally grounded
- State capitol buildings: sourced from Wikipedia Commons (public domain), one per state
- Graceful fallback: a generic civic building placeholder when a specific building image is not available

### Anti-features

- Using stock civic imagery that looks generic (a generic courthouse stock photo for every city)
- Full-bleed background images that compete with politician card readability
- Images that are not indexed/responsive, causing layout shift on mobile

### Complexity: Low (implementation) / Medium (asset curation)
The component work is straightforward — a section header with a background image. The effort is in sourcing and curating a reasonable set: U.S. Capitol (public domain), state capitols (Wikipedia Commons), and specific local buildings for cities the platform actively supports (LA, Bloomington initially).

### Dependencies
- Requires knowing which cities/localities the platform will actively support at launch — don't build image infrastructure for 50 cities if only 2 matter for the demo

---

## 6. Project Consolidation Patterns for Multi-App Platforms

### What the market does

The civic tech space has examples across the full spectrum:

- **Monorepo + separate deployments** (e.g., Vote.org, Rock the Vote): All apps in one repo with shared component libraries, each deploying independently. Works well for 2-5 person teams. The shared library approach (EV's ev-ui pattern) is consistent with this.
- **Unified single-page app with tab/section navigation**: Less common in civic tech, more common in SaaS. High integration cost but single deployment.
- **Loosely coupled microsite federation**: Each feature is its own deployment (current EV pattern). Works at small scale; becomes harder to manage as the number of apps grows.

For a 2-3 person team with existing apps, the decision criteria are: (1) how often do changes span multiple apps, (2) how much shared state needs to flow between apps, and (3) what is the deployment complexity budget.

### Table stakes

- Shared authentication across all apps (currently working via cookie-based session)
- Consistent visual design language (currently working via Tailwind tokens and ev-ui)
- Users do not need to re-login when moving between apps

### Differentiators (if consolidating)

- Single URL structure (e.g., `empowered.vote/compass`, `empowered.vote/find`) instead of subdomains/separate deployments
- Shared navigation that makes the platform feel like one product, not a collection of tools
- One build/deploy pipeline instead of one per app

### Anti-features

- Forcing a full monorepo rewrite before the platform is demo-ready — this is a distraction from the actual milestone
- Building a shared-state architecture (global Redux/Zustand across apps) before the use cases are proven
- Over-engineering the build pipeline (e.g., Nx or Turborepo) when the current multi-repo structure works and changes are infrequent across apps

### Complexity: High (if consolidating now)
A full monorepo migration during a demo-preparation milestone is high risk. The research question is right ("research and decide") — the answer should be: converge on a target architecture, do not migrate yet. The target is most likely a path-based SPA or a Vite multi-app monorepo, but migration should wait until after the demo. The current structure (separate apps, shared ev-ui library) can support the demo milestone without consolidation.

### Dependencies
- CORS and cookie domain settings in the backend must be updated if app URLs change
- ev-ui library versioning becomes more complex in a monorepo (shared symlink vs. published package)

---

## Summary: Table Stakes vs. Differentiators vs. Anti-Features

| Feature Area | Table Stakes | Differentiators | Anti-Features |
|---|---|---|---|
| Guest quiz | Full quiz without login; localStorage persistence; post-completion save prompt | Seamless guest-to-account merge; shareable result links | Login gate before quiz starts; email required to see results |
| Stance presentation | Order does not systematically bias; permanent per-user randomization | Question/prompt field above issue; importance weighting per issue | Per-visit randomization; hidden stance labels |
| Candidate display | Clear visual badge (Candidate vs. Incumbent); opt-in toggle; election date shown | Grouping challenger with incumbent; "Upcoming election" banner | Undifferentiated candidate/incumbent list; no "running for" label |
| Multi-level navigation | Three-tier tabs; expected category grouping; correct priority ordering (Senate before agencies) | Building imagery; position start/end dates; issue level indicators | Infinite scroll without grouping; generic stock building images |
| Project consolidation | Shared auth and design language (already done) | Single URL structure; unified nav; one deploy pipeline | Full monorepo migration during demo milestone; premature shared-state architecture |

---

## Key Dependencies Between Features

1. **Guest quiz → stance randomization**: Both need a guest identity (localStorage UUID). Design one guest identity scheme and use it for both.
2. **Stance randomization → question/prompt field**: The prompt gives users context when stances arrive in non-default order. Shipping randomization without the prompt degrades UX.
3. **Candidate display → BallotReady candidacy data**: Candidates only appear if the candidacy lazy-fetch is running. This currently triggers on profile view, not on ZIP results. A ZIP-level candidacy pass is needed.
4. **Building images → known city/locale list**: Do not build image infrastructure before confirming which localities the platform demonstrates. Start with U.S. Capitol + state capitols + Bloomington City Hall + LA City Hall as the minimum viable set.
5. **Federal reordering → no backend changes**: This is purely a frontend sort constant. It is a quick win with zero risk.
6. **Issue level indicators → Topic model migration**: A new `level` field on `compass.topics` requires a migration and admin UI. This is a backend + frontend change. Do not block other features on it.

---

## Sources

- [iSideWith — Political Quiz](https://www.isidewith.com/political-quiz)
- [Vote Compass — 2024 United States Election](https://votecompass.com/)
- [Guides.vote — Candidate Quiz](https://guides.vote/candidate-quiz)
- [The Political Compass](https://www.politicalcompass.org/test)
- [Pew Research Center — Political Typology Quiz](https://www.pewresearch.org/politics/quiz/political-typology/)
- [Prism Political Quiz — Randomization Pattern](https://prismquiz.github.io/)
- [Center for Civic Design — Designing a Voter Guide](https://civicdesign.org/fieldguides/designing-a-voter-guide-to-an-election/)
- [Center for Civic Design — Best Practices for Official Voter Guides (PDF)](https://civicdesign.org/wp-content/uploads/2016/02/VoterGuides-DesignGuide-16-0221.pdf)
- [Rock the Vote — Tech for Civic Engagement](https://www.rockthevote.org/programs-and-partner-resources/tech-for-civic-engagement/)
- [Civic Design Systems: Ultimate Guide to Smart UX](https://www.maxiomtech.com/accessible-ux-civic-design-systems/)
- [The political preferences of LLMs — PLOS One (response order bias research)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0306621)
