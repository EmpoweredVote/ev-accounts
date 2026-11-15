# Collin County TX — the six officeholders no address could reach

Six held offices in the whole database carry `district_id IS NULL`. No geofence join can ever
match them, so address search returns them for **no address at all**, and nothing errors. All six
are in three small Collin County towns.

| city | offices | holders | state |
| --- | --- | --- | --- |
| Blue Ridge | Place 5 | Keith Chitwood | ✅ fixed, `CC_0433` |
| Weston | Place 5 | Marla Johnston | ✅ fixed, `CC_0433` |
| Lowry Crossing | Places 5–8 | Madrid, Rios, Cash, Simpson | 🔴 **BLOCKED — read below** |

🔴 **ONE SYMPTOM, TWO OPPOSITE CORRECT FIXES.** Blue Ridge and Weston elect every councilmember
at large, so pointing their Place 5 at the city-wide district is right. Lowry Crossing's wards are
**electorates**, so the same move would be wrong — it would tell every voter that all eight
councilmembers represent them when they elect two. Only each city's own roster separates them.

---

## Why the "one broken generator" hypothesis is not the story

The working note that opened this piece read: *every district-less office is Place 5 or higher,
while Places 1–4 and the Mayor have districts in all three towns — one seeding generator that
stopped assigning districts past Place 4.*

⚠ **It has a counterexample in the same county.** **Josephine** is the fourth small Collin County
town carrying `official_count` 5, with the same Mayor + 5 shape, and its **Place 5 has a district**
(`dd8b9f0c`, Gary Chappell). It is clean.

So the cause is unknown, and the only surviving claim is the measured list of six above. ▶ Nothing
in `CC_0433` depends on the cause, which is why it was written against the measured rows instead.

---

## Blue Ridge and Weston — settled, applied 2026-11-15 (`CC_0433`)

Each city was read on its own sources. Neither inherited Lowry Crossing's answer.

**Blue Ridge** (`blueridgecity.com`) — *"a Type A General Law City… a Mayor and five
Councilmembers who are **elected at-large by majority vote**"*, and separately *"Seats open:
Mayor, **2 At-Large Council Seats**"*. The city's own contact list pins our place numbers to our
exact rows: `council1@` Apple, `council2@` Braly, `council3@` Sissom, `council4@` Mattingly,
**`council5@` Chitwood**. That tests identity, not just composition.

**Weston** (`westontexas.com`) — *"a Mayor and five Alderman positions, are **elected at large**"*;
*"located in Northern Collin County"* is the check that this is not one of the other Westons.

🟢 **The ballot is the independent mechanism and it is structural.** In Collin County's FINAL
OFFICIAL summary for 2026-11-03:

| city | how its contests print | means |
| --- | --- | --- |
| Weston | ONE contest, `Alderman - City of Weston`, **Vote For 3** | one electorate |
| Josephine | SEPARATE `Alderman Place 3` / `Alderman Place 5` contests | at-large by place |
| Lowry Crossing | FOUR separate **Ward** contests (May 2026: `City Council, Ward 4`) | four electorates |

---

## 🔴 Lowry Crossing is blocked, and here is exactly what on

The fix is four ward polygons plus eight retitles. The polygons need boundaries. **There is no
public, georeferenced source for them.** Three paths were tried and all three are closed:

### 1. The instrument exists and is not published

From the city's own ordinance disposition table (`ecode360.com/LO6395` — the **correct** custId;
see the trap below):

| ord. | adopted | title | in code? |
| --- | --- | --- | --- |
| 351 | 2022-07-12 | Adopts Ward System | **NIC** |
| 384 | 2025-06-24 | Increase in Wards; Change in Boundaries | **NIC** |
| 385 | 2025-06-24 | Increase in Wards; Change in Boundaries | **NIC** |

`NIC` = not in code, and ecode360 hosts no PDF for any of them. The 2025-06-24 **minutes**
confirm adoption — *"Chris Madrid made a motion to approve Ordinance 385 (384 Amended); second by
Tammy Hodges. Motion passed unanimously"* — but neither the agenda nor the minutes carries a
boundary description or an exhibit map.

🔴 **THE CURRENT BOUNDARIES DATE FROM JUNE 2025 AND THERE IS A SUPERSEDED 2022 VINTAGE.** "Increase
in Wards" means the ward COUNT changed too, so any older map is the wrong map and would be
indistinguishable from the right one by area, coverage or overlap. Anything sourced here must be
pinned to Ord. 384/385.

### 2. The only published map is a photograph of a screen

`lowrycrossingtexas.org/operations/elections.php` links "Ward Map" →
`4 wards smaller.JPG` (3504×3429, served from `webgen1files1.revize.com`).

⚠ **Look at it before using it.** It is a **photograph of a computer monitor** — the screen's pixel
grid is visible across the whole frame, there is a glare hotspot in the top-left, and the image is
keystoned. It shows the four wards clearly enough to read (1 green north, 2 blue centre/southwest,
3 pink southeast, 4 tan northeast) and the street labels are legible, but it carries no coordinate
reference and is geometrically distorted by the camera.

🔴 Digitising boundaries from it would produce polygons that are valid, plausibly shaped, and
wrong — the `CC_0319` Holladay failure, except that there the CRS was at least recoverable. These
polygons decide which councilmember a voter is shown. Do not trace this image.

⚠ The city site sits behind a Cloudflare **JS challenge** for image and file requests while
serving its HTML pages freely. The full browser header set does **not** get through; this is the
case where Playwright is the right escalation. The CDN host (`webgen1files1.revize.com`) serves
PDFs to plain `curl` without challenge — note the page's links resolve to the **site root**, not
to `/operations/`.

### 3. 🔴 County precincts cannot stand in for wards — measured, not assumed

The tempting derivation is "a ward is the union of the precincts its contest appears in".
**It fails here**, and the 2026-11-03 precinct report says so outright:

| ward contest | appears in county precinct(s) |
| --- | --- |
| Ward 1 | 114 |
| Ward 2 | 100, 114 |
| Ward 3 | 100, 114 |
| Ward 4 | 114 |

**Precinct 114 carries all four ward contests.** A precinct that contains voters from every ward
cannot delimit any of them, so the mapping is many-to-many in both directions and no union of
precincts recovers a ward. (Precinct 100 shows Ward 2 with `Contest Totals` 4 and Ward 3 with 0 —
a handful of voters on the far side of a line.)

### ▶ What would actually unblock it

Ord. **384** and **385** of 2025-06-24 with their exhibits, or the city's GIS file, from the City
Secretary (Janis Cable). That is an outward-facing request and is **the operator's call** — it is
not made here.

🔴 **Until then the four seats stay invisible, and that is the correct state.** The available
alternative is not neutral: repointing them at the city-wide district is affirmatively wrong on
settled evidence, and it would also make the error already live for Places 1–4 twice as large.

⚠ **Places 1–4 already point at the city-wide district**, so today half this council is wrongly
shown to every voter in the city while the other half is shown to nobody. Both halves are fixed by
the same ward polygons; neither is fixed without them.

---

## Still open, and recorded so the next pass does not re-derive it

- 🔴 **Neither Blue Ridge nor Weston uses place numbers on its own ballot, and our titles do.**
  Weston prints plain `Alderman`; Blue Ridge's Certification of Unopposed Candidates prints plain
  `Council (Consejo)` three times. So `Place N` is ours, not theirs — R8 pointing the *opposite*
  way to Lowry Crossing, where the city says Ward and we say Place. A voter-facing rename of ten
  rows that changes which row a person hangs off: a decision, not a cleanup.
  ⚠ That Blue Ridge certificate is dated **2023-05-06** and is served from the city's *current*
  elections page. Cited for the office DESIGNATION only, never for who holds anything.
- 🔴 **Weston's 2026-11-03 election unseated a sitting alderman.** One `Vote For 3` contest:
  Bragg 143, McManus 140, Johnston 130, Goldstein 107, **Mike Hill 75**. Hill holds our Place 4.
  **Nothing is seated on this** — the city roster read 2026-11-15 still lists Metzger, Hill and
  Johnston. Bragg and McManus are in no `politicians` row we hold.
- **Lowry Crossing 2026-11-03** (already on file, repeated here for one place): Ward 1 Derek
  Stephens def. Bennie "B.J." Long; Ward 2 Cynthia Sandlin unopposed; Ward 3 Cindy Cash unopposed;
  Ward 4 Donna Crenshaw Outland def. sitting member **Ollie Simpson**. Not seated.
  ⚠ Sandlin and Stephens both appear in the 2025-06-24 minutes — Sandlin on the roll call as a
  sitting member, Stephens speaking as a citizen of 615 Highridge — so neither is a stranger to
  this council, and the June 2025 "increase in wards" is why the body grew to eight.

## Two traps worth carrying out of this county

- 🔴 **A code page that matches your expectation is still a page about SOME city.** Searching for
  Lowry Crossing's council composition returns ecode360 pages that read decisively and agree with
  our row count. They are **Garland** (`GA6318`) and **Joshua** (`JO6365`). Lowry Crossing is
  **`LO6395`**. Check the custId. (Inherited from `CC_0432`; it caught the same thing again here.)
- 🔴 **Weston's elections page contains the word "ward" four times** — *"must reside on election
  day in the ward from which the person may be elected"* — and that is the page quoting LGC
  §22.032(b) verbatim, the statute for Type A general-law cities generally. A text search would
  have convicted the one city that says "elected at large" one paragraph above. ▶ Read whose
  sentence it is before reading what it says.
- ⚠ **`pdftotext -layout` misreads the Collin County results**, pairing "Mike Hill" with no figure
  and shifting the rest. Use `backend/data/local-races-2026-audit/read-racine-pdf.mjs`, which
  clusters by `y`. The arithmetic then closes: 107+143+140+75+130 = 595 = Total Votes Cast;
  595+3+530 = 1,128 = Contest Totals; 9+795+324 = 1,128 down the other axis.
