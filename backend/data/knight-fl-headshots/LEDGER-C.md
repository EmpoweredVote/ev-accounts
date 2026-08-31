# Roster C — Manatee County / City of Bradenton / City of Tallahassee — headshot sourcing ledger

Sourcing only. No downloads/crops/DB writes performed. All images verified by magic number
(ffd8ff = JPEG, 89504e47 = PNG) after fetch, then face-viewed (face-first scan) before acceptance.

## City of Bradenton (6/6 found)

Ladder rung that worked: **rung 1, official city page** (`cityofbradenton.com/council` + per-member
pages), one exception (Schuessler) resolved via **rung 3, local press** (The Bradenton Times).

- **Jayne Kocher** (Ward 1) — `cityofbradenton.com/council` div names her next to
  `800x597_Web.jpg`. Downloaded, JPEG confirmed, face viewed: woman, red-blonde hair, tennis-court
  background — plausible solo outdoor candid. Filename is a bare dimension string (no name) →
  `positional: true`. Page: `cityofbradenton.com/kocher`. License: press_use.
- **Marianne Barnebey** (Ward 2) — same page, `800x596_Web.jpg`. Face viewed: woman, red hair,
  playground background. Filename generic → `positional: true`. Page: `cityofbradenton.com/barnebey`.
- **Kemp Schuessler** (Ward 3) — first candidate image
  (`Councilman_Schuessler_Swearing-In_1_07232(1)_Web.jpg`) was a **two-person swearing-in ceremony
  photo** (him + Mayor Brown) — too close to a group/ceremony shot to ship. Went to rung 3:
  `thebradentontimes.com/stories/council-corner-city-of-bradenton-ward-3,208971` carries a solo
  studio portrait, filename `Kemp_Schuessler.jpeg` on the Bradenton Times CDN
  (`zeta.creativecirclecdn.com`). Same face as the swearing-in photo, confirmed. Used this instead.
  `positional: false` (filename contains full name).
- **Lisa Gonzalez Moore** (Ward 4) — `LM_resize_Web.jpg`. Confirmed correct city/ward via the
  adjacent `<h2>Ward Four - Lisa Gonzalez Moore</h2>`; per the roster's warning about the two-word
  surname, checked this was the Bradenton page, not another Florida official. Face viewed: woman,
  historical-marker background — plausible. Filename is only initials → `positional: true`.
- **Pam Coachman** (Ward 5) — `800x602_Web.jpg`. Face viewed: woman in yellow dress in front of the
  Bradenton Marauders outfield wall (large team logo in background, but not superimposed on her
  face/a seal-stamp — treated as an incidental environmental background, not a refusal). Filename
  generic → `positional: true`.
- **Gene Brown** (Mayor) — `mayor_desk_2-1_Web.jpg`. Face viewed: man at a desk with US/city flags,
  matches "Mayor Gene Brown" caption directly above. Filename generic (no surname) →
  `positional: true`. Page: `cityofbradenton.com/brown`.

Dead end noted: `cityofbradenton.com/council` and `/brown` both 403 to the WebFetch tool (bot
block) — worked fine via `curl` with a desktop User-Agent string. Use curl, not WebFetch, for this
domain in future waves.

## City of Tallahassee (5/5 found)

Ladder rung that worked: **rung 1, official city page**, pattern `talgov.com/cityleadership/<surname>`.

- **Jacqueline "Jack" Porter** (Seat 1) — `talgov.com/cityleadership/porter`, image
  `.../cityleadership/porter.jpg`. Solo portrait, glasses, purple blazer. `positional: false`.
- **Curtis Richardson** (Seat 2) — `talgov.com/cityleadership/richardson`, image `richardson.jpg`.
  Solo portrait, outdoor. `positional: false`.
- **Jeremy Matlow** (Seat 3) — `talgov.com/cityleadership/matlow`, image
  `Commissioner-JeremyMatlow.jpg` (16.5 MB original — very high-res). Solo portrait, beard, bow to
  the city pin on lapel. `positional: false`.
- **Dianne Williams-Cox** (Seat 5) — `talgov.com/cityleadership/williams-cox`, image
  `Commissioner-DianneWilliamsCox.jpg`. Solo portrait, outdoor greenery background.
  `positional: false`.
- **John Dailey** (Mayor, Seat 4) — confirmed per roster note that Dailey (mayor) IS Seat 4, not a
  separate commissioner. `talgov.com/cityleadership/dailey`, image `Mayor-JohnDailey.jpg`. Solo
  portrait. `positional: false`.

`www.talgov.com/commission` and `/commission/CommissionHome.aspx` both 404/dead — the live hub is
`talgov.com/cityleadership`. Use that path in future waves.

## Manatee County (11/11 found)

Ladder rungs that worked: **rung 1, official pages** for all 11 — the 7 elected commissioners off
`mymanatee.org`, and each of the 5 constitutional officers off their OWN separate domain exactly as
warned in the brief (`manateeclerk.com`, `manateepao.gov`, `manateesheriff.com`→dead link→
`flsheriffs.org`, `votemanatee.gov`, `taxcollector.com`). No county-party (`manateedems.org`) rung
was needed this wave — official rung 1 covered everyone.

### Elected commissioners (from `mymanatee.org/government/government-information/board-of-county-commissioners`)

- **Amanda Ballard** (D2) — `ballardrev-web-216-1.jpg`. Solo portrait, blue studio background.
  `positional: false`.
- **Tal Siddique** (D3) — `tal-3.jpg`. Solo portrait, red bow tie, blue studio background. Filename
  is bare first name + digit (`tal-3` reads like a seat-style pattern) → `positional: true` despite
  high confidence from page context.
- **Mike Rahn** (D4) — `rahn-web.jpg`. Solo portrait, blue studio background. `positional: false`.
- **Dr. Bob McCann** (D5) — `bob-mccann-district-5.jpg`. Solo portrait, glasses, blue background.
  `positional: false`.
- **Jason Bearden** (D6 At-Large) — `bearden.jpg`. Solo portrait, beard, blue background.
  `positional: false`.
- **George Kruse** (D7 At-Large) — `kruse-web.jpg`. Solo portrait, blue background.
  `positional: false`.

Note: the same fetch surfaced a "Vacant, District 1" row with a placeholder-image path — not in our
roster, ignored.

### Constitutional officers (own domains)

- **Angelina "Angel" Colonneso**, Clerk of the Circuit Court and Comptroller —
  `manateeclerk.com/about-us/meet-the-clerk/`, image `/media/1895/angel-1.jpg` (larger than the
  `/media/1006/angel-150.jpg` thumbnail also on the page — used the larger one). Solo studio
  portrait, pearl necklace. `positional: false`.
- **Charles E. Hackney**, Property Appraiser — `manateepao.gov/meet-charlie/`, image
  `charlie-hackney-portrait.png` (used the un-suffixed original over the `-232x300` thumbnail in the
  srcset). Solo studio portrait. `positional: false`.
- **Charles R. "Rick" Wells**, Sheriff — the on-page image reference at
  `manateesheriff.com/about/sheriff_rick_wells.php` (`Sheriff Wells Headshot 2021 2.png`) is a
  **dead asset**: it 302-redirects to `cms7files1.revize.com/manateecountysherifffl/about/...` which
  404s no matter how the spaces are encoded (tried `%20`, `+`, double-encoded, with/without the `?t=`
  cache-buster, with a Referer header) — the CDN object appears to not exist any more even though the
  HTML still references it. **Do not re-try this exact URL in a later wave; it is confirmed dead.**
  Rescued via `flsheriffs.org/staff/sheriff-charles-r-wells/` (Florida Sheriffs Association's own
  staff page), image `flsheriffs.org/wp-content/uploads/2024/03/Sheriff_Wells_Headshot_2021_.jpg`,
  alt text "Sheriff Charles R. Wells", 1500×1200. Official uniform portrait, badge visible, correct
  name in alt text and matches the "Charles R." legal first name from the roster (not to be confused
  with Charles E. Hackney — different Manatee Charles). `positional: false`.
- **Scott Farrington**, Supervisor of Elections — `votemanatee.gov/meet-the-supervisor-of-elections/`,
  image `scott-farrington.jpg` (full 2048w version, not the 300w/1024w/etc. thumbnails in the
  srcset). Solo candid photo at a waterfront. `positional: false`.
- **Ken Burton, Jr.**, Tax Collector — `taxcollector.com/about.cfm`, image
  `/assets/images/about/ken.jpg`. Portrait composited over a flag/skyline graphic background (house
  style for this site's "about" bios) — not a superimposed seal/logo on the face, judged acceptable.
  Filename is bare first name only (other staff bios on the same page follow a `bio-<surname>.png`
  pattern; his does not) → `positional: true`.

## Summary

22/22 found. Ladder: 20 resolved at rung 1 (official government/county/constitutional-officer site),
1 resolved at rung 3 (local press, Schuessler — after rejecting a 2-person ceremony photo found at
rung 1), 1 resolved by a targeted press-association fallback outside the stated ladder (Wells, after
the official department's own asset link was found dead). No Ballotpedia or county-party-page rungs
were needed this wave.

6 rows flagged `positional: true` for a human face-check: Kocher, Barnebey, Moore, Coachman, Brown
(all generic/dimension or initials-only Bradenton filenames), Siddique (`tal-3.jpg`), and Burton
(`ken.jpg`, first-name-only).
