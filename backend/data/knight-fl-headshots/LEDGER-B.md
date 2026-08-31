# Headshot sourcing ledger — Roster B (Palm Beach County + Leon County, FL)

Sourcing only. No downloads/crops/uploads performed. All URLs below were fetched
via a Playwright browser session (curl was WAF-blocked on both counties' CMS —
`cms.leoncountyfl.gov`, `discover.pbc.gov`, `leonclerk.com` etc. all return HTTP 403
to a bare curl/UA request but load fine in a real browser) and verified by magic
number (`ffd8ff` JPEG, `89504e47` PNG, `52494646...57454250` WEBP) via in-page
`fetch()`, not by HTTP status alone.

Ladder actually used: rung 1 (official county / constitutional-officer sites) produced
24 of 25. Rung 4 (a professional-association bio page, not strictly Ballotpedia but same
tier) produced the 25th (Wendy Sartory Link) after the county elections site's only
non-icon photos turned out to be group shots. Rungs 2 (countydems.org) and 3 (local press)
were not needed — never reached, not found dead.

## Leon County

1. **Gwen Marshall** (Clerk of the Circuit Court and Comptroller)
   - Tried: `cvweb.leonclerk.com/public/general_information/clerk_bio.asp` (redirects to
     homepage, dead link) → `leonclerk.com/about-us/meet-the-clerk/` (404) → found via
     sitemap: `leonclerk.com/about/about-the-clerk/`.
   - NOTE: the office now publicly refers to her as "**Gwen Knight**" (bio text: "Gwen Knight
     was elected Clerk... November 8, 2016... first woman and African American..." — same
     bio facts as Marshall, so same person, apparently married/changed name since the roster
     was compiled). Flagged for human confirmation just in case, but bio facts match
     one-to-one.
   - Image: `leonclerk.com/images/clerk-headshot.png`. Filename is generic ("clerk-headshot")
     → **positional: true**. Verified PNG, 32,894 bytes.
   - Outcome: FOUND. License: press_use (official .gov-adjacent county clerk site).

2. **Carolyn D. Cummings** — Leon Commissioners page
   (`cms.leoncountyfl.gov/leadingtheway/County-Commissioners`) lists all 7 current
   commissioners with linked detail pages and portrait images under
   `/Portals/15/adam/Kiosk People/<id>/Image/<Name>-CROP.webp`. Removed the
   `?mode=crop&w=266&h=260` query suffix to get full-resolution originals (7.8KB thumb →
   118KB original for Caban, similarly for others). Filename contains surname →
   **positional: false**. Verified WEBP (RIFF/WEBP magic), 60KB.
   - Outcome: FOUND.

3. **Nick Maddox** — same commissioners page/pattern. Verified WEBP, 82KB. positional: false.
   - Outcome: FOUND.

4. **Bill Proctor** — same pattern. Verified WEBP, 80KB. positional: false.
   - Outcome: FOUND.

5. **Christian Caban** — same pattern (current Chairman). Verified WEBP, 118KB.
   positional: false.
   - Outcome: FOUND.

6. **Rick Minor** — same pattern. Verified WEBP, 72KB. positional: false.
   - Outcome: FOUND.

7. **Brian Welch** — same pattern. Verified WEBP, 147KB. positional: false.
   - Outcome: FOUND.

8. **David O'Keefe** — same pattern (current Vice Chairman, page slug
   `david-t-o-keefe`). Verified WEBP, 89KB. positional: false.
   - Outcome: FOUND.

9. **Akin Akinyemi** (Property Appraiser) — `leonpa.gov/Our-Office/About-Us/Meet-Akin`.
   Image `headshot_akin.jpg` (dropped `?mode=max&w=150` query for full res, 175KB).
   Filename contains first name → positional: false.
   - Outcome: FOUND.

10. **Walt McNeil** (Sheriff) — `leoncountyso.com/about-us/meet-the-sheriff`. Image
    `mcneilwalt-4546.jpg`, 31.5KB JPEG. Filename contains surname → positional: false.
    - Outcome: FOUND.

11. **Rocky Hanna** (Superintendent of Schools) — `leonschools.net/superintendent-rocky-hanna`
    (ParentSquare-hosted site). Several repeated small nav photos alt-tagged "Rocky Hanna ";
    used the larger, clearly-labeled `RockyRev_1757697931.jpeg` (alt: "A picture of
    Superintendent Rocky Hanna."), 245KB JPEG. Filename contains first name (abbreviated)
    → positional: false.
    - Outcome: FOUND.

12. **Mark S. Earley** (Supervisor of Elections) — `leonvotes.gov/Your-Elections-Office/
    Meet-the-Supervisor`. Image explicitly named
    `Mark Earley Headshot - 2026-1.png`, verified PNG, 5.6MB (high-res). Filename contains
    full name → positional: false.
    - Outcome: FOUND.

13. **Doris Maloy** (Tax Collector) — official site `leontaxcollector.net` has NO photo
    of her anywhere (checked `/About/Doris-Maloy-Biography` bio page and the homepage;
    no `<img>` and no CSS background-image referencing her). Fell back off-ladder to
    `nacctfo.org/doris-maloy` (National Association of County Collectors & Treasurers
    Financial Officers — a professional-association bio page, same tier as Ballotpedia).
    Image `Doris Maloy Color Photo 9 30 16 en.jpg`, verified JPEG 34.7KB, 200×295.
    Screenshot-checked: single color portrait, pearls/dark blazer, no text overlay, no
    logo — a legitimate formal portrait, not monochrome. Filename contains full name →
    positional: false.
    - Outcome: FOUND (off the primary ladder; official county site has no usable photo).

## Palm Beach County

14. **Shannon Ramsey-Chessman** (Clerk of the Circuit Court & Comptroller) — she was sworn
    in as Clerk **Ad Interim** effective **August 18, 2026** (very recent; search snippets
    conflated her predecessor's name inconsistently — one source said "Joseph Abruzzo" was
    who she served under as Chief Deputy, another headline mentioned "Michael Caruso" arrest
    in the same news cycle — the current official bio page
    `mypalmbeachclerk.com/about-us/about-clerk-ad-interim-shannon-ramsey-chessman` is the
    authoritative, up-to-date source and was used). Image at
    `mypalmbeachclerk.com/home/showpublishedimage/2410/638907638446900000`, alt-text
    "Shannon Ramsey-Chessman", verified JPEG 35KB. Screenshot-checked: single portrait,
    blonde woman, navy blazer, matches recent news photos of her swearing-in. URL is a
    numeric document ID with no name in it → **positional: true**.
    - Outcome: FOUND.

15–21. **Palm Beach Commissioners D1–D7** — roster at
    `discover.pbc.gov/countycommissioners/Pages/default.aspx` confirms current names for
    all 7 districts match the roster exactly (Marino/Weiss/Flores/Woodward/Sachs/Baxter/
    Powell). Portraits live at
    `discover.pbc.gov/countycommissioners/SiteImages/portraits/<file>`.

    - **D1 Maria G. Marino**: `d1.jpg`. Filename is bare district code →
      **positional: true**. Verified JPEG 17.7KB.
    - **D2 Gregg K. Weiss**: `d2-Weiss.jpg` — filename contains surname → positional: false.
      Verified JPEG 13KB.
    - **D3 Joel G. Flores**: `d3.jpg` — **positional: true**. ⚠ IDENTITY RISK FLAGGED AND
      RESOLVED: the `<img>` alt text on the bio page still reads "**Michael Barnett**"
      (Flores's predecessor in that seat), i.e. a stale alt-text/off-by-one trap exactly
      like the one called out in the brief. Bio TEXT on the same page is unambiguously
      about Flores (Army veteran, former Mayor of Greenacres). Did a face-first screenshot
      comparison against `cscpbc.org/directory/joel-flores` (Children's Services Council
      directory bio, independent source, image `JFlores-2.jpg`) — same face, same suit/tie/
      pose style, confirms `d3.jpg` IS Flores's current photo despite the stale alt text.
      Verified JPEG 11.8KB (cropped) / 80KB (original, no query string).
    - **D4 Marci Woodward**: `Woodward_Color_.jpg` — filename contains surname →
      positional: false. Verified JPEG 11.8KB.
    - **D5 Maria Sachs**: `d5.jpg` — **positional: true**, alt text "Maria Sachs" (matches,
      unlike D3). Screenshot-checked: blonde woman, matches known public photos of
      Sachs (former FL state senator). Verified JPEG 14.7KB.
    - **D6 Sara Baxter**: `d6-sbaxter.jpg` — filename contains surname → positional: false.
      Verified JPEG 10.4KB.
    - **D7 Bobby Powell Jr.**: `d7.jpg` — **positional: true**. Bio text on page confirms
      "In November 2024, Bobby Powell Jr. was elected..." with correct FL Senate/House
      background (Chairman of FL Legislative Black Caucus) — NOT confused with Mack
      Bernard per the brief's warning. Screenshot-checked: bald Black man with goatee,
      consistent with known public photos of Powell. Verified JPEG 32.6KB.
    - Outcome: ALL 7 FOUND.

22. **Dorothy Jacks** (Property Appraiser) — official alt domain `pbcpao.gov/dorothy-bio.htm`.
    Image `dorothy-with-background-2019.jpg`, verified JPEG 132KB. Filename contains
    first name → positional: false.
    - Outcome: FOUND.

23. **Ric L. Bradshaw** (Sheriff) — `pbso.org/sheriff-ric-bradshaw`. Two candidate images;
    used the larger `Sheriff-Bradshaw-30x37.jpg` (216KB; the "30x37" in the filename reads
    as a legacy print-size label, not pixel dimensions — actual image is full-size).
    Filename contains surname → positional: false.
    - Outcome: FOUND.

24. **Wendy Sartory Link** (Supervisor of Elections) — official site
    `votepalmbeach.gov/275/Meet-Your-Supervisor` has exactly ONE non-icon photo, and it is
    a **swearing-in ceremony group shot** (Link + judge + a man in the background) —
    REJECTED per the no-group-photos rule (screenshot-checked). Checked five adjacent
    document IDs on the same image host looking for a solo portrait: one was a "Become an
    Election Hero" recruitment graphic (all text, no face), one was a 5-person check-
    presentation group photo (also rejected) — no usable solo shot found on the official
    site. Fell back to `myfloridaelections.com/wendy-sartory-link` (Florida Supervisors of
    Elections, Inc. — the professional association she currently presides over), image
    `Wendy Link Headshot_crop.jpg`, verified JPEG 151.6KB. Filename contains full name →
    positional: false.
    - Outcome: FOUND (off the primary ladder; official county site only had a group photo).

25. **Anne M. Gannon** (Tax Collector) — `pbctax.gov/about-us/`. Two candidate images with
    her name in the filename; used `new-anne-photot-for-tax-talk.png` (2.79MB, high-res),
    screenshot-checked: single color portrait, outdoor greenery background, pearl necklace,
    no text/logo overlay. Filename contains first name → positional: false.
    - Outcome: FOUND.

## Summary

- 25 of 25 found. 0 misses.
- Ladder rungs used: county/constitutional-officer official sites (rung 1) → 23 of 25.
  Professional-association bio pages (rung 4 tier) → 2 of 25 (Doris Maloy, Wendy Sartory
  Link) where the official government site had no usable photo at all.
- 6 rows flagged `positional: true` (filename encodes seat/doc-ID, not person): Gwen
  Marshall (Leon Clerk), Shannon Ramsey-Chessman (PBC Clerk), and PBC Commissioners D1
  (Marino), D3 (Flores), D5 (Sachs), D7 (Powell).
- One live identity trap caught and resolved: PBC D3's bio-page alt text still says
  "Michael Barnett" (predecessor) even though the image and bio text are for the current
  commissioner, Joel Flores — confirmed via independent cross-reference photo before
  accepting.
- One live group-photo trap caught and avoided: PBC Supervisor of Elections' official site
  only offered a multi-person swearing-in photo and a 5-person check-presentation photo;
  neither was used.
