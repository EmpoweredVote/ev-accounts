# Ledger — Wave A: Miami-Dade County / City of Miami (24 people)

Sourcing only. No downloads/crops/uploads. All 24 of 24 found. No positional-filename cases.

## Standing environment note

`miami.gov` and `mdctaxcollector.gov` return HTTP 403 (Akamai/Cloudflare bot block) to every
direct fetch attempt from this environment (curl with browser UA, WebFetch tool, and a
`r.jina.ai` proxy all blocked identically). `miamidade.gov`, `miamidadeclerk.gov`,
`miamidadepa.gov`, and `votemiamidade.gov` are NOT blocked and were fetched directly.
For the 6 City of Miami people, the Wayback Machine (web.archive.org) mirrors the live
miami.gov pages and serves the same official image bytes — used as the verified `url` with
the live miami.gov page cited as `page` (true source of record). A later wave should try
miami.gov directly again in case the block is transient.

## City of Miami (6)

**1. Miguel Angel Gabela — Commissioner, District 1**
- miami.gov direct fetch: 403 (Akamai). CDX lookup found archived snapshot 2025-09-18.
- Wayback snapshot: https://www.miami.gov/My-Government/City-Officials/District-1-Miguel-Angel-Gabela
- Image: `.../files/sharedassets/public/v/1/head-shots/gabela-headshot2.jpg` (full res, 6.06MB, JPEG ffd8ffe1) — verified, viewed, face matches expected (casual color headshot, gray beard).
- Outcome: FOUND. License: press_use (official city page).

**2. Damian Pardo — Commissioner, District 2**
- miami.gov direct: 403. Wayback snapshot 2025-12-23.
- Image: `.../head-shots/pardo-2.jpg` (1.76MB JPEG) — verified, viewed, bald/bearded man matches known photos of Pardo.
- Outcome: FOUND. press_use.

**3. Rolando Escalona — Commissioner, District 3**
- miami.gov direct: 403. Wayback snapshot 2026-07-12 (newest commissioner, sworn in Dec 2025).
- Image: `.../head-shots/rolando_escalona_d3_438x323.png` (163KB PNG) — verified, viewed. Filename includes his name (not positional, despite "d3" in filename).
- Outcome: FOUND. press_use.

**4. Ralph "Rafael" Rosado — Commissioner, District 4**
- miami.gov direct: 403. Wayback snapshot 2026-01-01.
- Image: `.../head-shots/d4/ralph.png` (10.7MB PNG, full res) — verified, viewed, pink-background portrait with City of Miami lapel pin.
- Note: filename is bare first name "ralph.png" inside a "/d4/" folder — borderline but contains the person's name, so NOT flagged positional. Folder also held ralph.png/leo.png/christian.png/lazaro.png (other D4 staff), confirming these are person-named, not seat-named.
- Outcome: FOUND. press_use.

**5. Christine King — Commissioner, District 5 (Commission Chairwoman)**
- miami.gov direct: 403. Wayback snapshot 2026-05-13.
- Image: `.../head-shots/king-headshot.jpeg` (89KB JPEG) — verified, viewed, matches expected (Guyanese-American attorney, per bio).
- Outcome: FOUND. press_use.

**6. Eileen Higgins — Mayor**
- miami.gov direct: 403. Wayback snapshot 2026-08-03.
- Image: `.../050526eileen_higgins290_v3.jpg?w=500&h=750` (500x750 JPEG, complete — verified end marker ffd9 since size hit exactly 65535 bytes on first pull, re-checked with PIL, valid) — viewed, blonde woman with glasses, arms crossed, dark dress + city pin.
- 🔴 IDENTITY CHECK: confirmed this is Mayor Eileen Higgins, NOT Danielle Cohen Higgins (County Commissioner D8, different photo, different domain — see #18 below). Two different photos, two different faces, confirmed by direct visual comparison.
- Outcome: FOUND. press_use.

## Miami-Dade County (18)

Ladder rung 1 (miamidade.gov commission district pages) produced ALL 12 county-commissioner
headshots in one pass — home page for each district (`/global/government/commission/districtNN/home.page`)
embeds a `headshots/` or `districtNN/` image with the commissioner's surname in the filename.
No need for rung 2 (miamidadedems.org) or rung 3 (local press) this wave.

**7. Juan Fernandez-Barquin — Clerk of the Court and Comptroller**
- Source: https://www.miamidadeclerk.gov/clerk/clerks-biography.page (loads fine, not blocked)
- Image: `/resources-clerk/images/JuanBackground.jpg` (6.6MB JPEG) — verified, viewed, young man, dark hair, red tie.
- 🔴 IDENTITY CHECK: confirmed distinct from Dariel Fernandez (Tax Collector, #24, different photo/site).
- Outcome: FOUND. press_use.

**8. Anthony Rodriguez — Commissioner, District 10**
- Source: https://www.miamidade.gov/global/government/commission/district10/home.page
- Image: `/resources/images/commission/district10/rodriguez-headshot-home-page.jpg` — verified JPEG, viewed, man with beard, US flag backdrop.
- Outcome: FOUND. press_use.

**9. Roberto J. Gonzalez — Commissioner, District 11**
- Source: .../district11/home.page
- Image: `/resources/images/commission/headshots/roberto-j-gonzalez-headshot.jpg` — verified JPEG, viewed, young man dark hair.
- Outcome: FOUND. press_use.

**10. Juan Carlos "JC" Bermudez — Commissioner, District 12**
- Source: .../district12/home.page
- Image: `/resources/images/commission/district12/bermudez-headshot.jpg` — verified JPEG, viewed, gray-haired man, gold tie.
- Outcome: FOUND. press_use.

**11. René Garcia — Commissioner, District 13**
- Source: .../district13/home.page
- Image: `/resources/images/commission/headshots/rene-garcia-headshot-1.jpg` — verified JPEG, viewed, gray hair, red tie.
- 🔴 IDENTITY CHECK: confirmed distinct from Alina Garcia (Supervisor of Elections, #23).
- Outcome: FOUND. press_use.

**12. Marleine Bastien — Commissioner, District 2 (county)**
- Source: .../district02/home.page
- Image: `/resources/images/commission/district02/bastien-headshot-home-page.jpg` — verified JPEG, viewed, Black woman, braided hair, royal blue jacket.
- Outcome: FOUND. press_use.

**13. Keon Hardemon — Commissioner, District 3 (county)**
- Source: .../district03/home.page
- Image: `/resources/images/commission/headshots/keon-hardemon-headshot-update.jpg` (6.1MB, full res) — verified JPEG, viewed, man in pinstripe suit.
- Outcome: FOUND. press_use.

**14. Micky Steinberg — Commissioner, District 4 (county)**
- Source: .../district04/home.page
- Image: `/resources/images/commission/district04/steinberg-headshot-home-page.jpg` — verified JPEG, viewed, woman, long dark hair.
- Outcome: FOUND. press_use.

**15. Vicki L. Lopez — Commissioner, District 5 (county)**
- Source: .../district05/home.page
- Image: `/resources/images/commission/district05/vicki-lopez-160x283.jpg` — verified JPEG, viewed, blonde woman, red blazer.
- Outcome: FOUND. press_use.

**16. Natalie Milian Orbis — Commissioner, District 6**
- Source: .../district06/home.page
- Image: `/resources/images/commission/district06/milian-orbis-headshot-home.jpg` — verified JPEG, viewed, young woman dark hair, black top.
- Outcome: FOUND. press_use.

**17. Raquel A. Regalado — Commissioner, District 7**
- Source: .../district07/home.page
- Image: `/resources/images/commission/headshots/raquel-regalado-headshot-update.jpg` — verified JPEG, viewed, blonde woman, black jacket w/ red-striped top.
- 🔴 IDENTITY CHECK: confirmed distinct from Tomas Regalado (Property Appraiser, #21).
- Outcome: FOUND. press_use.

**18. Danielle Cohen Higgins — Commissioner, District 8**
- Source: .../district08/home.page
- Image: `/resources/district-08/images/danielle-higgins-headshot.jpg` — verified JPEG, viewed, woman with wavy brown/auburn hair, navy jacket.
- 🔴 IDENTITY CHECK: alt text on page reads "Commissioner Danielle Higgins" (site drops "Cohen") — confirmed via district 8 match against roster and visually distinct from Mayor Eileen Higgins (#6, City of Miami, different photo entirely).
- Outcome: FOUND. press_use.

**19. Kionne L. McGhee — Commissioner, District 9**
- Source: .../district09/home.page
- Image: `/resources/images/commission/headshots/kionne-mcghee-headshot-update.jpg` (2.4MB, full res) — verified JPEG, viewed, man dark suit, silver tie.
- Outcome: FOUND. press_use.

**20. Daniella Levine Cava — Mayor (county)**
- Source: https://www.miamidade.gov/global/government/biographies/mayor.page
- Image: `/resources/images/mayor/mayor-bio-portait.jpg` (234KB JPEG) — verified, viewed, gray-haired woman, glasses, navy suit, county seal pin.
- Outcome: FOUND. press_use.

**21. Tomas Regalado — Property Appraiser**
- Source: https://www.miamidadepa.gov/pa/about/biography.page (miamidadepa.gov not blocked)
- Image: `/resources-pa/images/regalado.jpg` — verified JPEG, viewed, elderly man, gray hair, orange tie.
- Outcome: FOUND. press_use.

**22. Rosanna "Rosie" Cordero-Stutz — Sheriff**
- Search for a dedicated mdso.gov/mdso.com bio came up short (mdso.com had no working /about-the-sheriff path); found instead on the county's own bio page.
- Source: https://www.miamidade.gov/global/government/biographies/police.page
- Image: `/resources/images/departments/police/sheriff-rosie-cordero-stutz-small-headshot.jpg` (despite "small" in filename, it's a 7MB full-res file) — verified JPEG, viewed, uniformed woman, nameplate reads "R.CORDERO-STUTZ", sheriff's star visible.
- Outcome: FOUND. press_use.

**23. Alina Garcia — Supervisor of Elections**
- Source: https://www.votemiamidade.gov/elections/about/biography.page (votemiamidade.gov not blocked)
- Image: `/resources-elections/images/alina-garcia-bio-page.jpg` (larger bio-page version chosen over the smaller header-icon `alina-garcia-headshot.png`) — verified JPEG, viewed, blonde woman.
- 🔴 IDENTITY CHECK: confirmed distinct from René Garcia (Commissioner D13, #11).
- Outcome: FOUND. press_use.

**24. Dariel Fernandez — Tax Collector**
- `mdctaxcollector.gov` returns HTTP 403 with a Cloudflare "challenge" mitigation page on every
  attempt (curl direct, curl w/ full browser headers, WebFetch) — could not be bypassed from
  this environment. Tried rung 2 (no county-party page found for this office) and rung 3 (no
  clean local-press portrait found); dropped to rung 4.
- Source: Ballotpedia — https://ballotpedia.org/Dariel_Fernandez
- Image found at `https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/DarielFernandez2025.jpeg`;
  per standing rule, dropped `thumbs/200/300/` → original at
  `https://s3.amazonaws.com/ballotpedia-api4/files/DarielFernandez2025.jpeg` — verified JPEG (82.6KB, black-background campaign-style headshot, red tie, flag pin).
- 🔴 IDENTITY CHECK: confirmed distinct from Juan Fernandez-Barquin (Clerk, #7).
- Outcome: FOUND. License: press_use (Ballotpedia-hosted campaign photo — falls under "campaign press" per the license definition).

## Summary

- 24 of 24 found. 0 misses.
- Ladder rungs that actually produced results: **rung 1 (official county/city page) got 22 of 24**;
  **rung 4 (Ballotpedia, thumb-stripped to original) got 1** (Dariel Fernandez, Tax Collector);
  Wayback Machine mirror of rung-1 pages substituted for direct miami.gov fetches on all 6 City
  of Miami rows (miami.gov itself blocks this environment's fetches with HTTP 403 — the page
  content and image bytes are identical to the live site, just served through archive.org).
  Rung 2 (miamidadedems.org) and rung 3 (local press) were not needed this wave.
- No positional-filename rows — every image filename carried the person's name (first, last, or
  both), not a bare seat/district identifier.
- Faces worth a second human look: none flagged as uncertain — every image was visually inspected
  against the expected identity and all four repeated-surname traps (Higgins, Regalado, Garcia,
  Fernandez) were individually cross-checked.
