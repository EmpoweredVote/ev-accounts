# Bend candidate forums — the single highest-leverage unlock left in the Bend queue

**Created:** 2026-07-26
**Date-gated:** start *watching* on **2026-08-25**; act when a forum is actually scheduled.
**Priority:** high — one event closes four separate gaps that nothing else can.

## 🔴 First, correct the record

Earlier notes state "the city-hosted candidate forum is mid-September 2026 — that is the unlock."
**That date is an extrapolation from a prior cycle, not a confirmed 2026 event.** Checked
2026-07-26: the Bend Chamber's "Bend City Council and Mayor Forum — Sept. 19" page now redirects to
`bendchamber.org/event-category/candidate-forum`, which reports **"No events to display"** for 2026.

So the correct posture is *watch for it to be scheduled*, not *wait for a known date*. Do not let a
session in September conclude "the forum didn't happen" without checking the venues below — and do
not let one conclude it *will* happen on Sept 19.

## What a forum unlocks that nothing else does

Four gaps, all blocked on the same thing: **both candidates on the record, on the same questions.**

| Gap | Current state | What the forum gives |
|---|---|---|
| **Dan Sorrells** (Council P6) `-4105834` | **0 stances, 0 headshot** — the only completely empty compass on the Bend ballot | His only campaign presence is Instagram `@citycouncildan` — no site, no news profile, no questionnaire. A forum is the only place he speaks on the record. Also the only realistic headshot source outside the pamphlet. |
| **Ron "Rondo" Boozell** (Mayor) `-4105831` | 2 stances vs Kebler's 10 | The mayoral compass renders lopsided. His thinness is evidence-driven, not neglect — a third row (`climate-change`=2) was *dropped* in validation because it rested on a 2020 bullet with no timeline where chairs 2 and 3 could not be discriminated. A forum answer is dateable, current, and chair-specific. |
| **Sheriff race** Rupert `-4101714` / McLaughlin `-4101726` | **0 stances each** after exhaustive research 2026-07-26 (see the post-filing todo §4.2) | Neither man's written material names a chair on `public-safety-approach`, `jail-capacity` or `local-immigration`. A moderated forum asks the budget-direction question directly. |
| **Late ballot changes** | Field is provisional until 2026-08-29 | Forums surface withdrawals and no-shows early. |

## Where to watch (checked 2026-07-26 unless noted)

- **Bend Chamber** — `bendchamber.org/event-category/candidate-forum`. Ran the equivalent forum in a
  prior cycle on Sept 19. **Empty for 2026 as of 2026-07-26.** Most likely host; check first.
- **City of Bend elections page** — `bendoregon.gov/city-council/elections/`. ⚠️ 403s every
  non-browser request (HTML *and* images) — use Playwright, not curl/WebFetch.
- **City Club of Central Oregon** — runs candidate forums in Bend; check its events calendar.
- **Indivisible Sisters** — **already ran a Sheriff Candidate Forum**; the recording is linked from
  `votemacforsheriff.com` ("Watch Mac at the Indivisible Sisters Sheriff Candidate Forum"). See the
  standing item below — this one exists *now*.
- **Local press listings** — KTVZ, Central Oregon Daily, Bend Source events. `bendbulletin.com` is
  now **registration-walled** for article bodies; `redmondspokesman.com` mirrors much of it.

Timing to expect: after the **2026-08-28** withdrawal deadline (so the field is final) and before
Oregon ballots mail in **mid-October**. Late September is the natural window.

## ⚠️ Standing item, actionable NOW — the sheriff forum recording already exists

The **Indivisible Sisters Sheriff Candidate Forum** has already happened and is linked from
McLaughlin's site. It is **video**, which is why the 2026-07-26 stance pass could not use it. It is
the single richest unmined source for the sheriff race and needs one of:
- a published transcript or a written recap in local press, or
- someone willing to watch it and transcribe the relevant answers verbatim.

Do not paraphrase from video into `quote_text`. If no verbatim text can be obtained, the honest
outcome is the same as 2026-07-26: skip.

## Method reminders for whoever runs this

- **A forum is spoken, so the transcript problem is the whole problem.** Auto-captions are not
  verbatim — Deschutes County Planning Commission minutes carry a printed auto-transcription
  disclaimer for exactly this reason, and stances were refused from them. If the host posts an
  official recording with captions, treat captions as a *lead*, then confirm wording against a
  written recap before quoting.
- **Indirect speech is not a quote**, and it has hidden in the `reasoning` field in three
  consecutive waves. A reporter's "he said he would…" is not `quote_text`.
- **Chairs, not polarity.** If two adjacent chairs both fit, skip. "Public safety is my priority" is
  not a chair on `public-safety-approach`; the chair needs the budget-direction content.
- **`local-immigration` is structurally empty for Oregon sheriffs** — ORS 181A.820 / HB 3265 forbid
  honoring ICE detainers statewide, so compliance is legally compelled, not a chosen position. Only
  a statement going *beyond* the law can be scored.
- Validate the moment each payload exists: `py backend/scripts/validate-stance-quotes.py <payload>`,
  then hand-check attribution and the `reasoning` field, which the validator cannot read.

## Do this first

The **≥ 2026-08-29 ballot re-check** (`.planning/todos/2026-07-24-bend-or-postfiling-recheck.md` §1)
comes before any forum work — the field can still change through 2026-08-28, and there is no point
researching a candidate who withdrew. That re-check must also bump `last_verified_at` past
2026-08-29 or clear `provisional_until`, or the site keeps showing the "candidate field not final"
note.

## Related

- `.planning/todos/2026-07-24-bend-or-postfiling-recheck.md` — §1 ballot re-check, §3 the 6
  remaining headshot pins, §4.2 the full sheriff-race stance trail and why it yielded zero.
- The **November Deschutes County voters' pamphlet** is the other unlock in this window, and covers
  a different set: Kuhn, Tintle, Curtis and Boozell headshots, plus first written statements for the
  Sheriff/Clerk/Treasurer races. Grayscale ~219px, below the normal headshot bar — decide then
  whether the bar bends for sitting officials with no alternative.
