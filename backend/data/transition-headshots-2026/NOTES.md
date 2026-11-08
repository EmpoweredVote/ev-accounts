# Headshots for the 2026 transition — the sourcing queue

`build-list.mjs` produces `headshot-queue-2026-11-08.{csv,json}`: every winner of the
2026-11-03 election who has **no headshot in any of the three places a photo can live**.

**Measured 2026-11-08, against production:**

| | |
| --- | --- |
| winners recorded | **1,134** |
| a photo somewhere (the positive control) | 901 |
| **no photo anywhere — the queue** | **233** |
| of those, NEW to the seat | **169** |
| already carrying a recorded licence refusal | 1 |

**By tier:** STATE_EXEC 77 · SCHOOL 59 · STATE_LOWER 38 · STATE_BOARD_EDUCATION 22 ·
STATE_BOARD 14 · LOCAL 11 · STATE_UPPER 11 · NATIONAL_LOWER 1.

**By state:** CA 82 · WI 26 · AL 11 · TX 10 · NE 10 · NM 9 · WA 9 · CO 8 · GA 8 · HI 6 ·
NH 5 · AZ 5 · MI 5 · OK 5 · SD 5, then a long tail across 31 states in all.

🟢 **The federal tier is effectively done — 1 missing of 414** — because earlier headshot
programmes worked it. **The gaps are exactly the tiers this programme has just created or just
recorded**, which is what you would expect and is worth saying out loud: a new winner arrives
with no face.

---

## 🔴 A PERSON IS ONLY "MISSING" IF ALL THREE PLACES ARE EMPTY

- **`politicians.photo_custom_url`** — the scalar the backend reads.
- **a `politician_images` row of `type = 'default'`** — what the grid reads out of `images[]`.
- **`race_candidates.photo_url`** — the one nothing sweeps, and it **beats** the fixed image on
  ballot pages.

A query against any one of them alone under- or over-counts. The builder checks all three and
asserts the opposite class is populated first: *901 winners read as HAVING a photo* is the
positive control, without which "233 are missing" is indistinguishable from a query that cannot
see photos at all.

### 🔴 TWO ROWS ALREADY DISAGREE WITH THEMSELVES, AND NOTHING CATCHES IT

**Mark Teixeira** and **Vanessa Kritzer** each carry `photo_custom_url` **and no `default`
image row**. They render on one surface and blank on the other, and no gate in this repo sees
it. Writing the scalar without the image row is a known defect — ▶ **write both, always.**
These two are not in the queue above (they have *a* photo) and want a repair, not sourcing.

---

## 🔴 BEFORE SOURCING ANYTHING, READ THE LICENCE RULES — THEY ARE NOT IN THIS FILE

This list says **who has no face**. It says nothing about where a face may come from, and that
is the part this repo has paid for repeatedly. The rules live in the memory files and must be
read before a photo run:

- `feedback_no_facebook_photos_press_only` — **press, official or public-domain only.**
  🔴 **The credit line is the licence test.**
- `feedback_headshot_must_contain_a_face` — 🔴🔴 **nothing we run asks whether an image contains
  a face.** A seal, a map, a blank frame and a torso all pass. The only gate is the CI job
  `headshot faces`, and it is **schedule-only**, so it will not fire on a PR.
- `feedback_measure_dont_eyeball_crop_geometry` and `feedback_headshot_crop_composition` —
  crop geometry is measured, never eyeballed.
- `feedback_look_at_the_proof_sheet_you_publish` and `feedback_headshot_contact_sheet_approval`
  — **look at the proof sheet**; a correct API response is not evidence the image landed.
- `project_photo_custom_url_is_what_renders` — 🔴 **write BOTH the scalar and the image row**,
  and **read the rendered `<img>`**, not the API.
- 🔴 **Mirror at native size.** A bare CDN URL is not the original: both the resize and the
  quality loss can hide in the query string.
- ⚠ **A namesake reaches production and nothing errors.** This repo has shipped the late
  President of Yemen as a Bell CA councilman and a New York talk-show host as a Manhattan Beach
  official. **Check the person against the body's own roster and OPEN THE IMAGE.**

⚠ **One of the 233 already carries a `photo_restriction_code`** — a licence refusal somebody
recorded. Do not re-source it without reading why.

---

## ▶ Where to start

**California is 82 of 233** and most of it is the December wave — school boards (59 across the
whole queue) seat on **2026-12-11** and the special districts on **2026-12-04**. Those are the
faces a voter will look for first, and they have the nearest deadline.

⚠ **A seat is not a person.** 64 of the 233 are **re-elected incumbents** who have held the seat
and still have no photo; the other 169 are new. The second group is the transition's own gap,
the first is older debt that this list happens to surface.
