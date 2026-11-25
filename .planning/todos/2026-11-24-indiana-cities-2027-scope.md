# Indiana cities for the 2027 municipal election — scope

**Status:** scoped, NOTHING APPLIED. Measured against production on 2026-11-24.
**Goal:** every Indiana city has its offices, current officeholders and council district maps in
Essentials before candidate filing opens (Jan 6, 2027), so the 2027 races can be loaded onto them
once filing closes (early February 2027). Towns are a separate, later scope.

## Where we are

- Indiana has **119 cities, 446 towns and Indianapolis** (Census 2024 place estimates,
  `sub-est2024_18.csv`, SUMLEV 162).
- **Done (4 cities + 2 towns):** Indianapolis (Mayor + 25 council districts, 26/26 seated, 25/25 maps),
  Fort Wayne (`CC_0090`/`CC_0091`), Gary (`CC_0092`/`CC_0093`/`CC_0096`), Bloomington, Ellettsville,
  Stinesville. The 2026-07-30 note that only 5 of 25 Indianapolis districts existed is out of date.
- **Missing: 116 cities, 2.41M people.** For each we hold only the city outline (all 566 places have a
  `G4110` row in `geofence_boundaries`). No government, chamber, office, holder or council district.
- No 2027 election row exists yet.

## What state law fixes for every city (read from IC Title 36, iga.in.gov, 2025 code)

| Class | Council | Clerk | Source |
|---|---|---|---|
| Second class (34,000+, or kept the status) | 6 district + 3 at-large = 9 | City Clerk | IC 36-4-6-3(h); IC 36-4-10-2 |
| Third class (default) | 5 district + 2 at-large = 7 | Clerk-Treasurer | IC 36-4-6-4(h) |
| Third class, alternative ordinance | 4 district + 3 at-large = 7 | Clerk-Treasurer | IC 36-4-6-4(j)-(l) |
| Third class under 10,000, by ordinance | 4 district + 1 at-large = 5 (or 3 + 2) | Clerk-Treasurer | IC 36-4-6-5 |
| Former town that became a city | 3-district variant | Clerk-Treasurer | IC 36-4-6-4(m) |

Plus a Mayor in every city. Some cities also elect a **city court judge**; the 2023 candidate list
shows them. (Decision needed: in scope or not.)

- ⚠ **Class cannot be read from population.** A city that reaches 34,000 stays second class after it
  shrinks, and a third-class city that grows stays third class unless it adopts the change by
  ordinance (IC 36-4-1-1(b)-(c), 1.1). Goshen (34,800) and every city near the line must be checked.
- ⚠ **Third-class cities choose among four layouts by ordinance.** The seat count is a per-city fact.
  Confirm it from the city's own council page or code before writing a structure migration.

## Sources for each piece

1. **Structure (seats, district or at-large):** the statute table above sets the default. Each city's
   own council page confirms which layout it uses.
2. **Council district maps:** there is **no statewide city council district layer**. Checked:
   - the state WAYEO service (`WAYEO_WebMap_WFL1`) has county council districts (layer 8, already used by
     `load-indiana-wayeo-council-boundaries.ts`) but its City layer (10) is city outlines only;
   - `Voting_District_Boundaries_2026` (5,121 precincts) carries county, congressional, senate and house
     codes, but no city council district.
   - ▶ **Two routes per city:** (a) the city's or county's own ArcGIS service, the pattern of
     `load-fort-wayne-council-boundaries.ts` and `load-gary-council-boundaries.ts`; (b) build the map
     from precincts. By law, district lines follow precinct lines (IC 36-4-6-3(b)(3), 4(b)(3)), and the
     district ordinance filed with the circuit court clerk lists the precincts. Dissolving those
     precincts from the 2026 statewide layer gives the map. Route (b) works for small cities with no GIS
     of their own.
   - 🔴 A district seat with no map cannot be reached from an address. Do not hang district seats on the
     whole-city outline as a stopgap: every resident would then see every district member.
   - 🔴 A new `X…` boundary layer needs its routing registration on master **the same day** the
     migration is applied, or `check:reachability` goes red for everyone (CLAUDE.md, Verification rules).
3. **Current officeholders:** each city's own website (the chamber's own roster outranks aggregators).
   The 2023 general results tell who won; check each against the city site for changes since.
4. **2027 candidates:** the Secretary of State publishes **one statewide municipal candidate list**.
   The 2023 one exists as a PDF (`in.gov/sos/elections/files/2023-Municipal-Primary-Election-Candidate-List.pdf`,
   233 mayor lines, plus council, clerk, clerk-treasurer and city court judge). Expect the same for 2027
   after filing closes. 🔴 It is a PDF: parse by coordinates, not stream order (CLAUDE.md, PDF rule).
   `import-indiana-sos-xlsx.ts` reads the even-year XLSX and may need a PDF path.

## Waves

| Wave | Cities | People | Notes |
|---|---|---|---|
| A — 34,000+ | 25 | 1.54M | Most have their own GIS and council pages. Hand-check class. |
| B — 10,000-34,000 | 35 | 0.59M | Mostly third class, 7 seats. Mixed GIS. |
| C — under 10,000 | 56 | 0.27M | Many use the 4+1 layout. Expect the precinct route for maps. 18 are under 3,500. |

## How to build it (do not write 116 × 3 hand files)

Fort Wayne took a structure migration (189 lines), a people migration (172) and a boundary loader (318).
Repeating that 116 times is the wrong shape. Instead:

1. One config file per wave: city, GEOID, class, layout, clerk title, map source, roster URL.
2. A generator that writes the structure migration for the whole wave from the config (one migration
   per file; ask the allocator for each slot).
3. Map loads through the config-driven loader (`load-arcgis-from-config.ts` is Utah-only today, with
   `STATE_FIPS = '49'` hard-coded) or a precinct-dissolve script.
4. People migrations per wave, sourced from city rosters, with the occupancy rules in
   `backend/migrations/CLAUDE.md`.
5. Take a `state:in` jurisdiction claim before starting.

## Open decisions

1. City court judges: include or not.
2. Towns (446): when, and whether convention-nominated small towns get candidate pages.
3. Wave order: by population (recommended) or by region.

## The 116 cities

| # | City | Place GEOID | 2024 pop. | Wave |
|---|---|---|---|---|
| 1 | Evansville | 1822000 | 115,395 | A |
| 2 | Fishers | 1823278 | 103,986 | A |
| 3 | South Bend | 1871000 | 103,713 | A |
| 4 | Carmel | 1810342 | 103,606 | A |
| 5 | Hammond | 1831000 | 76,030 | A |
| 6 | Noblesville | 1854180 | 75,239 | A |
| 7 | Lafayette | 1840788 | 71,757 | A |
| 8 | Greenwood | 1829898 | 68,175 | A |
| 9 | Muncie | 1851876 | 65,320 | A |
| 10 | Westfield | 1882700 | 62,994 | A |
| 11 | Kokomo | 1840392 | 60,093 | A |
| 12 | Terre Haute | 1875428 | 58,531 | A |
| 13 | Anderson | 1801468 | 55,851 | A |
| 14 | Elkhart | 1820728 | 53,690 | A |
| 15 | Jeffersonville | 1838358 | 52,912 | A |
| 16 | Columbus | 1814734 | 51,970 | A |
| 17 | Mishawaka | 1849932 | 51,020 | A |
| 18 | Lawrence | 1842426 | 49,817 | A |
| 19 | West Lafayette | 1882862 | 46,338 | A |
| 20 | Portage | 1861092 | 38,576 | A |
| 21 | New Albany | 1852326 | 37,652 | A |
| 22 | Richmond | 1864260 | 35,561 | A |
| 23 | Crown Point | 1816138 | 35,097 | A |
| 24 | Valparaiso | 1878326 | 35,065 | A |
| 25 | Goshen | 1828386 | 34,458 | A |
| 26 | Michigan City | 1848798 | 31,466 | B |
| 27 | Hobart | 1834114 | 29,418 | B |
| 28 | Marion | 1846908 | 28,216 | B |
| 29 | Greenfield | 1829520 | 26,268 | B |
| 30 | Franklin | 1825450 | 26,158 | B |
| 31 | East Chicago | 1819486 | 25,768 | B |
| 32 | Seymour | 1868832 | 22,524 | B |
| 33 | La Porte | 1842246 | 22,444 | B |
| 34 | Shelbyville | 1869318 | 20,845 | B |
| 35 | Logansport | 1844658 | 18,168 | B |
| 36 | Lebanon | 1842624 | 17,608 | B |
| 37 | New Castle | 1852740 | 17,382 | B |
| 38 | Huntington | 1835302 | 17,033 | B |
| 39 | Jasper | 1837782 | 16,967 | B |
| 40 | Crawfordsville | 1815742 | 16,594 | B |
| 41 | Vincennes | 1879208 | 16,506 | B |
| 42 | Frankfort | 1825324 | 16,459 | B |
| 43 | New Haven | 1852992 | 16,200 | B |
| 44 | Warsaw | 1880306 | 16,111 | B |
| 45 | Beech Grove | 1804204 | 14,566 | B |
| 46 | Auburn | 1802674 | 13,989 | B |
| 47 | Bedford | 1804114 | 13,853 | B |
| 48 | Connersville | 1814932 | 13,282 | B |
| 49 | Lake Station | 1841535 | 13,033 | B |
| 50 | Washington | 1880504 | 12,881 | B |
| 51 | Greensburg | 1829718 | 12,317 | B |
| 52 | Madison | 1845990 | 12,108 | B |
| 53 | Martinsville | 1847448 | 11,952 | B |
| 54 | Plymouth | 1860822 | 11,042 | B |
| 55 | Peru | 1859328 | 11,003 | B |
| 56 | Bluffton | 1806220 | 10,556 | B |
| 57 | Kendallville | 1839402 | 10,326 | B |
| 58 | Wabash | 1879370 | 10,275 | B |
| 59 | Columbia City | 1814716 | 10,185 | B |
| 60 | Decatur | 1817074 | 10,072 | B |
| 61 | Greencastle | 1829358 | 9,907 | C |
| 62 | Angola | 1801666 | 9,432 | C |
| 63 | Charlestown | 1812124 | 8,559 | C |
| 64 | Elwood | 1821070 | 8,495 | C |
| 65 | Princeton | 1862046 | 8,481 | C |
| 66 | Brazil | 1807174 | 8,239 | C |
| 67 | Tell City | 1875248 | 7,515 | C |
| 68 | Scottsburg | 1868526 | 7,413 | C |
| 69 | Batesville | 1803664 | 7,353 | C |
| 70 | Nappanee | 1852020 | 6,902 | C |
| 71 | Boonville | 1806616 | 6,687 | C |
| 72 | Garrett | 1826386 | 6,663 | C |
| 73 | North Vernon | 1855116 | 6,565 | C |
| 74 | Huntingburg | 1835284 | 6,512 | C |
| 75 | Salem | 1867464 | 6,463 | C |
| 76 | Mount Vernon | 1851732 | 6,341 | C |
| 77 | Portland | 1861236 | 6,233 | C |
| 78 | Rushville | 1866438 | 6,208 | C |
| 79 | Rochester | 1865214 | 6,110 | C |
| 80 | Gas City | 1827054 | 6,091 | C |
| 81 | Hartford City | 1832242 | 5,927 | C |
| 82 | Rensselaer | 1863792 | 5,632 | C |
| 83 | Monticello | 1850760 | 5,519 | C |
| 84 | Tipton | 1875986 | 5,285 | C |
| 85 | Linton | 1844190 | 5,281 | C |
| 86 | Lawrenceburg | 1842462 | 5,216 | C |
| 87 | Alexandria | 1800910 | 5,211 | C |
| 88 | Clinton | 1813780 | 4,802 | C |
| 89 | Winchester | 1884752 | 4,800 | C |
| 90 | Ligonier | 1843686 | 4,650 | C |
| 91 | Greendale | 1829448 | 4,581 | C |
| 92 | Whiting | 1884122 | 4,491 | C |
| 93 | Berne | 1804888 | 4,310 | C |
| 94 | Sullivan | 1874006 | 4,240 | C |
| 95 | Austin | 1802800 | 4,156 | C |
| 96 | Mitchell | 1849950 | 3,964 | C |
| 97 | Knox | 1840374 | 3,630 | C |
| 98 | Aurora | 1802782 | 3,515 | C |
| 99 | Union City | 1877768 | 3,435 | C |
| 100 | Attica | 1802620 | 3,247 | C |
| 101 | Delphi | 1817614 | 3,018 | C |
| 102 | Bicknell | 1805176 | 2,999 | C |
| 103 | Covington | 1815490 | 2,751 | C |
| 104 | Butler | 1809532 | 2,669 | C |
| 105 | Loogootee | 1844910 | 2,617 | C |
| 106 | Oakland City | 1855710 | 2,269 | C |
| 107 | Petersburg | 1859364 | 2,269 | C |
| 108 | Rising Sun | 1864674 | 2,219 | C |
| 109 | Dunkirk | 1819054 | 2,106 | C |
| 110 | Southport | 1871486 | 2,081 | C |
| 111 | Jasonville | 1837764 | 2,003 | C |
| 112 | Rockport | 1865484 | 1,989 | C |
| 113 | Woodburn | 1885184 | 1,613 | C |
| 114 | Jonesboro | 1838862 | 1,506 | C |
| 115 | Montpelier | 1850796 | 1,502 | C |
| 116 | Cannelton | 1810108 | 1,498 | C |
