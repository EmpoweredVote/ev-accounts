---
name: project_colorado_springs_state_leg_richardson
description: State-leg worked example — Chris Richardson HD56 — coloradopolitics.com per-topic search found two of his own op-eds; a group caucus letter with no personal quote still seated a chair; a bill's own operative text (not its political framing) should govern magnitude when the two conflict.
type: project
---

Chris Richardson (R), Colorado House District 56 (Adams/Arapahoe/Cheyenne/El Paso/Elbert/Kit
Carson/Lincoln — Eastern Plains/exurban Aurora, NOT a Colorado Springs-proper seat despite El Paso
County being one of the represented counties). 3/28 seated: deportation=4, housing=3,
climate-change=4.

**What worked:**
- `coloradopolitics.com/?s=%22Chris+Richardson%22+<topic>` surfaced TWO of his own Podium op-eds
  (`coloradopolitics.com` bylined opinion pieces are searchable and are the member's own words, the
  richest source type per [[project_colorado_springs_local_scale_chairs]]'s house style) — one on
  immigration/sanctuary-law cooperation (Jan 2026, co-authored with Rep. Max Brooks), one on a
  ballot-initiative dispute (July 2026, no ladder topic matched it — skipped, off-axis).
- Per-topic queries that returned zero (tax, abortion, voucher, redistricting, education, energy,
  gun, campaign-finance, healthcare) were fast, cheap "no" signals — don't treat a null query as a
  wasted call, it's what lets you stop digging on a dead topic and move to the next.
- `completecolorado.com/?s=%22name%22` returned ZERO for this legislator despite working well for
  others in this cohort ([[project_colorado_springs_state_leg_liston]],
  [[project_colorado_springs_state_leg_degraaf]]) — confirms the per-legislator variance the Liston
  memory already flagged. A guessed completecolorado article URL from a search-result title also
  404'd — don't construct URLs from a title fragment, only from a returned href.

**A caucus GROUP LETTER with no personal quote still seated a chair — but only when its OWN reasoning
is specific.** The Dec 2025 House GOP letter opposing a PUC 41%-natural-gas-emissions-cut mandate
(coloradohouserepublicans.com press release) does not quote Richardson individually — he's a
signatory only. Seated climate-change=4 anyway because the letter's stated rationale (grid can't
support mass electrification, families can't afford forced heat-pump retrofits) is specific enough
to name a chair (market-forces-driven transition, not a government mandate), unlike a bare party-line
vote which the brief says is "close to no evidence at all." The distinguishing test I used: does the
letter's OWN text argue a specific mechanism, or does it just record a position? This one argued a
mechanism. Recorded with quote_text blank (no personal quote exists) rather than inventing one.

**🔴 When a bill's political framing and its operative text point at different magnitudes, the
OPERATIVE TEXT should govern, not the framing — but check whether the STATED MOTIVE still lets you
choose between two textually-fitting chairs.** SB25-047 (2025, prime-sponsored) requires ANY peace
officer with probable cause of unlawful presence to report to ICE — no carve-out for criminal record,
family ties, or length of residence. Read cold, that bill text alone is arguably a BETTER fit for
deportation chair 5 ("regardless of...family ties") than chair 4 ("starting with criminal records"),
since the bill doesn't prioritize by criminal history at all. I seated chair 4 anyway because
Richardson's own January 2026 op-ed built around this bill exclusively frames the problem via a
criminal-offender case and calls the issue "public safety" — his STATED motivating concern, not the
bill's literal unconditional trigger, is what a voter-facing chair should reflect, provided that
motive is his own words and not just a persuasive anecdote bolted onto broader text. This is a
narrower use of "read the bill text" than the brief's blanket rule — worth a second opinion if a
similar case recurs, since it's the closest this pass came to the sponsorship-magnitude trap the
brief warns about twice.

**Confirmed skip, no ladder match:** a bipartisan letter requesting the Governor endorse a DOE
nuclear-innovation-campus RFI submission (preliminary information-gathering only, no funding/siting
commitment) does not fit economic-development's incentive-structure chairs — skip rather than force
it. Also skipped: HB26-1080 (prime-sponsored, requires bipartisan election judges — not one — for
mail-ballot signature verification) does not touch any voting-rights chair (no ID requirement, no
access expansion/restriction, no roll purge) despite being his single most substantive-looking
elections bill; SB26-054 (security-deposit exception for post-closing occupancy agreements) is too
narrow/technical a landlord-tenant carve-out to seat any rent-regulation chair.
