# Phase 75-01 Photo URL Table

**Verified:** 2026-05-22
**Method:** HTTP HEAD requests to each URL; 200 = verified, NULL = no stable public photo found

## Pre-flight Findings

- **Migration number:** 196 (last applied: 195_ca_state_assembly.sql)
- **Chamber UUID:** `7cbe07bc-84b8-433b-952b-540e7de18a92` (confirmed from CA NATIONAL_UPPER office)
- **NATIONAL_UPPER districts:** 50 rows, exactly 1 per state — no disambiguation needed
- **Sherrod Brown existing record:** 0 rows — INSERT new at external_id -400137
- **Husted (-400061):** confirmed, is_appointed=true
- **Armstrong (-400064):** confirmed, is_appointed=true

## CDN Bioguide IDs (unitedstates.github.io)

| Name | Bioguide | CDN URL | Status |
|------|----------|---------|--------|
| Barry Moore | M001212 | https://unitedstates.github.io/images/congress/225x275/M001212.jpg | 200 |
| Mike Collins | C001129 | https://unitedstates.github.io/images/congress/225x275/C001129.jpg | 200 |
| Ashley Hinson | H001091 | https://unitedstates.github.io/images/congress/225x275/H001091.jpg | 200 |
| Andy Barr | B001282 | https://unitedstates.github.io/images/congress/225x275/B001282.jpg | 200 |
| Julia Letlow | L000595 | https://unitedstates.github.io/images/congress/225x275/L000595.jpg | 200 |
| Seth Moulton | M001196 | https://unitedstates.github.io/images/congress/225x275/M001196.jpg | 200 |
| Haley Stevens | S001215 | https://unitedstates.github.io/images/congress/225x275/S001215.jpg | 200 |
| Angie Craig | C001119 | https://unitedstates.github.io/images/congress/225x275/C001119.jpg | 200 |
| Chris Pappas | P000614 | https://unitedstates.github.io/images/congress/225x275/P000614.jpg | 200 |
| Kevin Hern | H001082 | https://unitedstates.github.io/images/congress/225x275/H001082.jpg | 200 |
| Harriet Hageman | H001096 | https://unitedstates.github.io/images/congress/225x275/H001096.jpg | 200 |
| John Fleming | F000456 | https://unitedstates.github.io/images/congress/225x275/F000456.jpg | 200 |
| Mike Rogers | R000572 | https://unitedstates.github.io/images/congress/225x275/R000572.jpg | 200 |
| Mary Peltola | P000619 | https://unitedstates.github.io/images/congress/225x275/P000619.jpg | 200 |
| John Sununu | S001078 | https://unitedstates.github.io/images/congress/225x275/S001078.jpg | 200 |
| Sherrod Brown | B000944 | https://unitedstates.github.io/images/congress/225x275/B000944.jpg | 200 |

## Full Candidate Photo URL Table

| external_id | name | state | photo_origin_url | http_status | notes |
|-------------|------|-------|-----------------|-------------|-------|
| -400101 | Steve Marshall | AL | https://upload.wikimedia.org/wikipedia/commons/8/87/Steve_Marshall_%2841773693585%29.jpg | 200 | Wikipedia |
| -400102 | Barry Moore | AL | https://unitedstates.github.io/images/congress/225x275/M001212.jpg | 200 | CDN bioguide M001212 |
| -400103 | Dakarai Larriett | AL | NULL | — | No stable public photo found 2026-05-22 |
| -400104 | Mary Peltola | AK | https://unitedstates.github.io/images/congress/225x275/P000619.jpg | 200 | CDN bioguide P000619 |
| -400105 | Hallie Shoffner | AR | NULL | — | No stable public photo found 2026-05-22 |
| -400106 | Janak Joshi | CO | NULL | — | Wikipedia page exists but no image 2026-05-22 |
| -400107 | Alex Vindman | FL | https://upload.wikimedia.org/wikipedia/commons/0/07/Alexander_Vindman_on_May_20%2C_2019.jpg | 200 | Wikipedia |
| -400108 | Angie Nixon | FL | https://upload.wikimedia.org/wikipedia/commons/5/54/Angie_Nixon_newer.jpg | 200 | Wikipedia |
| -400109 | Mike Collins | GA | https://unitedstates.github.io/images/congress/225x275/C001129.jpg | 200 | CDN bioguide C001129 |
| -400110 | Derek Dooley | GA | https://upload.wikimedia.org/wikipedia/commons/c/cf/Derekdooleyorangewhite.jpg | 200 | Wikipedia |
| -400111 | David Roth | ID | NULL | — | No stable public photo found 2026-05-22 |
| -400112 | Juliana Stratton | IL | https://upload.wikimedia.org/wikipedia/commons/a/a8/Juliana_Stratton_2023_%28cropped%29.jpg | 200 | Wikipedia |
| -400113 | Don Tracy | IL | NULL | — | No stable public photo found 2026-05-22 |
| -400114 | Ashley Hinson | IA | https://unitedstates.github.io/images/congress/225x275/H001091.jpg | 200 | CDN bioguide H001091 |
| -400115 | Zach Wahls | IA | https://upload.wikimedia.org/wikipedia/commons/d/d9/Member_of_the_Iowa_Senate_Zacharia_Wahls.jpg | 200 | Wikipedia |
| -400116 | Charles Booker | KY | https://upload.wikimedia.org/wikipedia/commons/3/3d/Charles_solar_panels_%28cropped%29.jpg | 200 | Wikipedia (Charles Booker American politician) |
| -400117 | Andy Barr | KY | https://unitedstates.github.io/images/congress/225x275/B001282.jpg | 200 | CDN bioguide B001282 |
| -400118 | Julia Letlow | LA | https://unitedstates.github.io/images/congress/225x275/L000595.jpg | 200 | CDN bioguide L000595 |
| -400119 | John Fleming | LA | https://unitedstates.github.io/images/congress/225x275/F000456.jpg | 200 | CDN bioguide F000456 (historical) |
| -400120 | Graham Platner | ME | https://upload.wikimedia.org/wikipedia/commons/1/1a/Platner_headshot.jpg | 200 | Wikipedia |
| -400121 | Seth Moulton | MA | https://unitedstates.github.io/images/congress/225x275/M001196.jpg | 200 | CDN bioguide M001196 |
| -400122 | Abdul El-Sayed | MI | https://upload.wikimedia.org/wikipedia/commons/2/26/Abdul_El-Sayed.jpg | 200 | Wikipedia |
| -400123 | Mallory McMorrow | MI | https://upload.wikimedia.org/wikipedia/commons/6/6f/Mallory_McMorrow_in_2023_-_8R4A5252.jpg | 200 | Wikipedia |
| -400124 | Haley Stevens | MI | https://unitedstates.github.io/images/congress/225x275/S001215.jpg | 200 | CDN bioguide S001215 |
| -400125 | Mike Rogers | MI | https://unitedstates.github.io/images/congress/225x275/R000572.jpg | 200 | CDN bioguide R000572 (historical) |
| -400126 | Peggy Flanagan | MN | https://upload.wikimedia.org/wikipedia/commons/c/c6/2026PeggyFlanagan.jpg | 200 | Wikipedia |
| -400127 | Angie Craig | MN | https://unitedstates.github.io/images/congress/225x275/C001119.jpg | 200 | CDN bioguide C001119 |
| -400128 | Royce White | MN | https://upload.wikimedia.org/wikipedia/commons/c/c9/Royce_White_speaks_at_Native_Lives_Matter_Rally_%28cropped%29.jpg | 200 | Wikipedia |
| -400129 | Scott Colom | MS | NULL | — | Wikipedia page exists but no image 2026-05-22 |
| -400130 | Kurt Alme | MT | https://upload.wikimedia.org/wikipedia/commons/5/5e/Kurt_G._Alme_official_photo.jpg | 200 | Wikipedia (DOJ official photo) |
| -400131 | Seth Bodnar | MT | https://upload.wikimedia.org/wikipedia/commons/3/31/Seth_Bodnar_-_President_at_University_of_Montana_%28cropped%29.jpg | 200 | Wikipedia |
| -400132 | Dan Osborn | NE | https://upload.wikimedia.org/wikipedia/commons/9/95/Osborn_Headshot_2_%28cropped%29.jpg | 200 | Wikipedia |
| -400133 | Chris Pappas | NH | https://unitedstates.github.io/images/congress/225x275/P000614.jpg | 200 | CDN bioguide P000614 |
| -400134 | John Sununu | NH | https://unitedstates.github.io/images/congress/225x275/S001078.jpg | 200 | CDN bioguide S001078 (historical senator) |
| -400135 | Roy Cooper | NC | https://upload.wikimedia.org/wikipedia/commons/3/30/Roy_Cooper_in_November_2023_%28cropped2%29.jpg | 200 | Wikipedia |
| -400136 | Michael Whatley | NC | https://upload.wikimedia.org/wikipedia/commons/b/b5/Michael_Whatley_%2854670563614%29_%28cropped%29.jpg | 200 | Wikipedia |
| -400137 | Sherrod Brown | OH | https://unitedstates.github.io/images/congress/225x275/B000944.jpg | 200 | CDN bioguide B000944 (historical senator); INSERT new (no existing record) |
| -400138 | Kevin Hern | OK | https://unitedstates.github.io/images/congress/225x275/H001082.jpg | 200 | CDN bioguide H001082 |
| -400139 | David Brock Smith | OR | https://upload.wikimedia.org/wikipedia/commons/1/10/DBS_FB_Profile.jpg | 200 | Wikipedia |
| -400140 | Annie Andrews | SC | NULL | — | No stable public photo found 2026-05-22 |
| -400141 | Rachel Fetty Anderson | WV | NULL | — | No stable public photo found 2026-05-22 |
| -400142 | Harriet Hageman | WY | https://unitedstates.github.io/images/congress/225x275/H001096.jpg | 200 | CDN bioguide H001096 |
| -400143 | James Byrd | WY | https://upload.wikimedia.org/wikipedia/commons/6/61/James_W._Byrd_at_Campbell_County_League_of_Women_Voters%27_General_Election_Candidates%27_Forum_in_Gillette%2C_Wyoming_%28cropped%29.jpg | 200 | Wikipedia |

## Summary

- **With photo URL (200):** 35 candidates
- **Explicit-null (no stable public photo):** 8 candidates
  - -400103 Dakarai Larriett (AL-D)
  - -400105 Hallie Shoffner (AR-D)
  - -400106 Janak Joshi (CO-R)
  - -400111 David Roth (ID-D)
  - -400113 Don Tracy (IL-R)
  - -400129 Scott Colom (MS-D)
  - -400140 Annie Andrews (SC-D)
  - -400141 Rachel Fetty Anderson (WV-D)
- **Sherrod Brown:** INSERT new at -400137 (no existing DB record found)
