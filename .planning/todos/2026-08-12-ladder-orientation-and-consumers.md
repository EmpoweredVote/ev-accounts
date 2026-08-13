# Ladder orientation across all 44 topics, and who consumes a chair (2026-08-12)

Follows mig 1729, whose finding was that the right question is not "which topics have inversions"
but **which ladders run the other way**. Two parts: the data audit (done, mig 1730) and the
consumer audit (findings only — no code changed).

## Part 1 — the ladder audit. 44 topics, 2 reversed, 3 off-axis

**The corpus convention is: chair 1 = maximum government action, chair 5 = minimum.** 42 of 44 follow it.

### 🔴 Reversed — chair 1 is the MINIMUM-intervention end
| topic | chair 1 | chair 5 | status |
|---|---|---|---|
| **AI Oversight** | "allow AI companies to develop and deploy technology freely" | "ban AI systems that could cause serious harm" | fixed, mig 1729 (9 rows) |
| **Tariffs** | "eliminate all tariffs … completely free trade" | "impose high tariffs on all imports" | **3,315 rows, never scanned until now** |

### ⚠ Off-axis — not reversed, but no political lexicon maps cleanly
- **Residential Zoning** — chair 5 (eliminate single-family-only zoning) is deregulatory **and**
  progressive. A pro-government lexicon and a progressive lexicon point in *opposite* directions.
  This already bit mig 1727, where six rows at chair 4-5 were correct.
- **Growth and Development Pace** — same shape.
- **Government Deference** (judicial, 110 rows) — chair 1 is "side with the citizen against
  government". Not an intervention axis at all; no lexicon applies. Not scanned.
- **Affordable Housing** — mid-ladder divergence only: chair 4 is "cut regulations so private
  developers can build", right for YIMBYs and wrong for tenant-protection rows (mig 1727).
- **Misinformation** — conventional on intervention, but chair 5 "ban any government involvement in
  content moderation" is a free-speech position held across the spectrum. Flagged, not scanned.

### ✅ Scanned symmetrically → mig 1730, 10 corrections
Both directions tested, since on an off-axis ladder neither can be assumed.

| topic | candidates | inversions |
|---|---|---|
| Tariffs | 5 pro@1-2 + 25 free@4-5 | **1** |
| Residential Zoning | 3 nimby@4-5 + 24 yimby@1-2 | **7** |
| Growth Pace | 4 slow@4-5 + 2 pro@1-2 | **2** |

🔑 **Tariffs is almost entirely clean, for the now-familiar reason** — 24 of 25 candidates are real
tariff supporters whose rows contain "free trade" only as the OBJECT of what they oppose. The one
real inversion is **Laura Richardson**, who voted YES on SJR 7 (California's resolution against
Trump's broad tariffs) while stored at chair 4, "increase tariffs on countries that don't trade
fairly" → 3.

🔑 **Residential Zoning is where the off-axis ladder actually cost us — in BOTH directions**, which
a single-direction scan cannot find. Maura Healey ("the most aggressive governor in Massachusetts
history on upzoning") sat at chair 1, *protect neighborhood character strictly*. Jake Auchincloss
("explicitly advocated for ending single-family-only zoning" — chair 5's own text) sat at 2. And
the other way: Drew Boyles, who "advocated regionally and statewide to protect single-family
housing neighborhoods", sat at chair 4, the upzoning option.

⚠ **Only midpoint-crossing rows were changed.** Cloutier, Deffibaugh, Flaherty and Gordo keep
Residential Zoning chair 2 — their rows are restrictive and chair 2 is already on the restrictive
half, so they are understated at worst, not inverted.

## Part 2 — who consumes a chair. **Nothing derives spoke orientation from the ladder.**

Traced the chair value from the API through to the pixel:

1. `inform.politician_answers.value` → `compassHelpers.js` builds `{ short_title: value }`
   (`out[st] = a.value ?? 0`) — no transform.
2. `RadarChartCore.jsx` plots it as **radius**: `pct = (value / max) * 10`, `r = (adjusted / 10) * radius`.
3. The one orientation hook is `invertedSpokes`: `adjusted = invertedSpokes[shortTitle] ? 11 - pct : pct`.

🔴 **`invertedSpokes` is a per-viewer UI toggle, not a property of the topic.** `CompassContext.jsx`
initialises it to `{}` and persists whatever the user flips (`authedSlice.compass.i`);
`CompassCard.jsx` mutates it from the spoke-flip handlers. ev-ui defaults the prop to `{}`.

**So by default every spoke plots "higher chair number = further from centre", which assumes all 44
ladders share an orientation — the assumption this audit just disproved for AI Oversight and
Tariffs.** On those two spokes a dot far from centre means the *opposite politics* it means on
Healthcare or Climate, and two politicians with identical radar shapes can hold opposite positions.
Nothing is wrong with the stored data; the picture is what misreads it.

⚠ Consistent with [[feedback_compass_chairs_not_polarity]] — chairs are 1-5 discrete options, not a
left-right axis — but the radar renders them as magnitude on a shared axis anyway.

▶ **Recommendation (a product decision, so NOT actioned):** give `compass_topics` a stored
orientation column (or a canonical `invertedSpokes` default derived from it) so AI Oversight and
Tariffs render flipped for everyone, and keep the user toggle as an override on top. The audit
table above is the seed data for it. Scanning code is clean otherwise — no hardcoded `5 - value`
arithmetic anywhere in `essentials/src` or `ev-ui`.
