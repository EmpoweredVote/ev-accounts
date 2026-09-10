# Lake County, Indiana — IN-6 roster

Wave **IN-6**, slice 4, **stage 4**. City half: Gary, partially seated by IN-4.

**Lake County elects 19 offices. This wave seats 12.** The seven County Council district seats are
**deferred**, exactly as Gary's six city district seats were, and for the same reason.

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

## The seven deferred

D1 David Hamm · D2 **Ronald G. Brewer Sr.** · D3 Charlie Brown · D4 Pete Lindemulder ·
D5 Christine Cid (President) · D6 Ted Bilski · D7 Randy Niemeyer

🔴 **Ronald G. Brewer Sr. is the man who left Gary's at-large council seat.** IN-4's change-check
found that vacancy but not where he went; he went here. **This slice has now seen two people move
between jurisdictions mid-term** — Mark Spencer (Gary at-large → Senate District 3) and Brewer. The
probe asserts Brewer holds **no** office yet; when the council seats are written, check first
whether he already holds a Gary one.

⚠ **Charlie Brown (Council D3) and Michael A. Brown (Clerk) are different people.** Same surname,
different offices, and one of them is deferred.

▶ **Next action:** Lake County's GIS page offers *"Request GIS Map or Data"*. Request the County
Council district geometry, then add the seven seats. **Do not georeference the PDFs.**
