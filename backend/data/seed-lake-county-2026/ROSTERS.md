# Lake County, Indiana — IN-6 roster

Wave **IN-6**, slice 4, **stage 4**. City half: Gary, partially seated by IN-4.

**Lake County elects 19 offices. CC_0095 seated 12; IN-9 seated the remaining 7 (below).**
The seven County Council district seats were deferred through IN-4, IN-6 and IN-8 for want of a
boundary layer; the layer was found on 2026-09-11 and they are now live.

Migration: `CC_0095` — one migration carrying offices *and* people, per spec §3.
No boundary layer was needed: everything seated here hangs on `18089`/`G4020`, already in production.

## 🔴🔴 AN AGGREGATED SEARCH GAVE ME THREE WRONG COMMISSIONERS

A roster search returned **"Barry Shullanberger, James Williams, Mark Albertson"** as Lake County's
commissioners, and a Clerk who was also *"Recorder, Auditor, Public Administrator and Surveyor"* — a
combined office **no Indiana county has**. Those belong to a **Lake County in another state**.

The correct names, from `lakecountyin.gov`'s own department pages read one office at a time, are
**Kyle W. Allen Sr., Jerry Tippy and Michael C. Repay**.

▶ **For a generically named county, an aggregated source is a JURISDICTION-collision risk, not just
a staleness risk.** There are Lake Counties in Indiana, Illinois, Ohio, Florida, California,
Colorado, Oregon, Montana, Michigan, Minnesota, Tennessee and South Dakota. This is the Georgia
name-collision failure — where 2 of 4 hits were a Colorado senator and a Utah treasurer — with the
*jurisdiction* as the thing that collided.

⚠ **My first extraction from the county's own site was ALSO wrong**, and in the classic way: a regex
matched a navigation item present on every page, so all ten offices returned the identical string
`"Superior Court Elected Officials — Assessor"`. **Ten identical answers is a broken detector**, not
a finding. Stripping the nav and keying on the page's "Our Team" block returned ten distinct names.

## 🔴 LAKE'S COUNCIL IS SEVEN SINGLE-MEMBER DISTRICTS. ALLEN'S IS FOUR PLUS THREE AT LARGE.

Two Indiana counties in one slice, two different councils. Allen's shape was not inherited.

## Sources

| | Source | What it is |
| --- | --- | --- |
| **A** | `lakecountyin.gov/departments/{assessor,auditor,clerk,…}` | The county's own department pages, read individually — **the roster** |
| **B** | `lakecountyin.gov/departments/council` | Council composition and the seven district members |
| **C** | Lake County maps & GIS index | Confirms **PDF only** |
| **D** | ArcGIS Online, owner `lakecountyod` (174 layers) | Confirms **no electoral district layer** |

## The twelve seated

| Office | Holder |
| --- | --- |
| Commissioner, District 1 | Kyle W. Allen Sr. |
| Commissioner, District 2 | Jerry Tippy |
| Commissioner, District 3 | Michael C. Repay |
| Assessor | LaTonya Spearman |
| Auditor | Peggy Holinga Katona |
| Clerk of the Circuit Court | Michael A. Brown |
| Coroner | David J. Pastrick |
| Recorder | Gina Pimentel |
| Sheriff | Oscar Martinez |
| Surveyor | Bill Emerson Jr. |
| Treasurer | John Petalas |
| Prosecuting Attorney | Bernard A. Carter |

🔴 **All three commissioners are COUNTYWIDE**, as in Allen: Indiana requires residence in a district
but elects them county-wide, so all three must reach every Lake County address.

🔴 **All twelve terms are `unknown`.** Ballotpedia returns **404 for all thirteen** Lake County
officials tried — and that is *not* a broken method: the same batch returned **14 of 19** for Allen
County and **9 of 9** for Fort Wayne minutes earlier. Ballotpedia does not cover Lake County, as it
does not cover Gary. The county publishes no tenure. GA-2's position: no date is invented.

## The seven council districts — ✅ SEATED 2026-09-11 (IN-9, `CC_0099` + `CC_0100`)

D1 David Hamm · D2 **Ronald G. Brewer Sr.** (Vice President) · D3 Charlie Brown ·
D4 Pete Lindemulder · D5 **Christine Cid** (President) · D6 Ted Bilski · D7 Randy Niemeyer

**Lake County is now 19 of 19.** The boundaries are `X0051`, loaded by
`scripts/load-lake-county-council-boundaries.ts` from the Indiana GIO's statewide WAYEO layer —
the Secretary of State's own "Who Are Your Elected Officials" service, which
`lakecountyin.gov/departments/council/find-my-council-district` names in prose as the county's
answer to "which council district am I in". 🟢🟢 **The source was never going to be a county
layer, and the county's own page said so.** Vintage-gated 339/339 precincts against the county
Board of Elections & Registration's `CC_District_Map3X5.pdf` (2022-01-26). Full record:
[`.planning/knight-foundation/in-debt.md`](../../../.planning/knight-foundation/in-debt.md).

🟢 **THE ROSTER WAS RE-READ FROM SEVEN SEPARATE PAGES, NOT THE ONE BLOCK.** IN-6 took these names
from the council landing page's aggregate "Our Team" list — and a block can be mis-ordered without
looking wrong. The county also publishes `departments/council-1stdist` … `council-7thdist`, each
naming exactly ONE member. All seven agree with the block. **Prefer the per-item page to the
aggregate list whenever a mapping is what you need**, which is the same lesson as the wrong-state
commissioners above, one notch finer.

🔴 **Ronald G. Brewer Sr. is the man who left Gary's at-large seat**, and `CC_0100`'s gate asserts
he holds **exactly one** office. Measured 2026-09-11: no Brewer person row existed at all, so he
was created here rather than reused — the assertion is kept for the day someone reuses the row.
`office_terms_no_overlap` forbids two people on one office; it cannot see one person on two.

⚠ **Charlie Brown (Council D3) and Michael A. Brown (Clerk) are different people.**
⚠ **Randy Niemeyer (Council D7) and Rick Niemeyer (Indiana Senate, `indiana_discovery`) are
different people.**

🔴 **All seven terms are `unknown`**, for the same reason as the other twelve: Ballotpedia 404s for
Lake County, and all seven district pages carry a name, a title and a phone number and nothing
else. No date was invented.

## Acceptance

`scripts/verify-lake-council-probes.sql` — seven anchors, one per district, each an interior point
of a municipal polygon from the county Surveyor's own `Cities` layer. All seven return the right
member; a Fort Wayne point returns zero, which is the negative control.
⚠ **District 2 has no wholly-contained municipality** — Gary, Highland and Griffith are all split —
so its anchor is a measured interior point of Griffith. That is a fact about the map.
