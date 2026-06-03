# Phase 89 — Gap-Fill Audit

## Metadata

- **Run date:** 2026-06-03
- **Total politicians with < 10 stances (live SQL result):** 440
- **Description:** Every politician currently in `inform.politician_answers` with fewer than 10 stance rows, classified into three priority tiers based on evidence availability and politician prominence. Wave 2 executor should work the "Wave 2 Work Order" list top-to-bottom without further judgment.

Note: Live count matches the 2026-06-03 RESEARCH.md baseline of 440. No drift detected.

---

## Tier 1 — Research Immediately

Politicians where evidence is plausibly available and prominence warrants it. Total: **50 politicians**.

### Federal (NATIONAL_UPPER, NATIONAL_LOWER) — 2 politicians

| full_name | party | stance_count | office_title | notes | post_fill_count | final_status |
|-----------|-------|-------------|--------------|-------|-----------------|--------------|
| James Byrd | Democratic | 5 | Candidate for U.S. Senate — Wyoming | single-source evidence floor — re-attempt with 2026 campaign sources | 7 | evidence floor — no additional sources found beyond WyoFile announcement article; deportation and immigration stances added from protest attendance, all other topics lack sourceable evidence |
| Derek Dooley | Republican | 7 | Candidate for U.S. Senate — Georgia | post-Phase 88; migration 127 fixed source URLs — gap-fill from 7 to >=10 | 12 | complete — 5 new stances added (deportation, fossil-fuels, taxes, social-security, medicare/aid, ukraine-support) from dooleyforgeorgia.com campaign platform |

### State Executive — 7 politicians

| full_name | party | stance_count | office_title | state |
|-----------|-------|-------------|--------------|-------|
| Deborah B. Goldberg | Democratic | 2 | Treasurer and Receiver-General | MA |
| William Francis Galvin | Democratic | 4 | Secretary of the Commonwealth | MA |
| Karen Ross | Unknown | 5 | Secretary of Agriculture | CA |
| Marlo M. Oaks | Unknown | 6 | Utah State Treasurer | UT |
| Diana DiZoglio | Democratic | 7 | Auditor of the Commonwealth | MA |
| Malia M. Cohen | Democratic | 9 | Controller | CA |
| Robert Garcia | Democratic | 9 | Board of Equalization Member | CA |

### CA State Legislators (STATE_LOWER + STATE_UPPER) — 21 politicians

| full_name | party | stance_count | office_title | notes |
|-----------|-------|-------------|--------------|-------|
| Catherine Stefani | Democratic | 3 | Assembly Member | |
| Gregg Hart | Democratic | 3 | Assembly Member | |
| Phillip Chen | Republican | 4 | Assembly Member | |
| Dr. Corey A. Jackson | Democratic | 5 | Assembly Member | |
| Heather Hadwick | Republican | 5 | Assembly Member | |
| James C. Ramos | Democratic | 5 | Assembly Member | |
| Michelle Rodriguez | Democratic | 5 | Assembly Member | |
| Sharon Quirk-Silva | Democratic | 5 | Assembly Member | |
| Steve Bennett | Democratic | 5 | Assembly Member | |
| Tom Lackey | Republican | 5 | Assembly Member | |
| Liz Ortega | Democratic | 6 | Assembly Member | |
| Patrick J. Ahrens | Democratic | 6 | Assembly Member | |
| Tina S. McKinnor | Democratic | 6 | Assembly Member | |
| Alexandra M. Macedo | Republican | 7 | Assembly Member | |
| Mark Gonzalez | Democratic | 7 | Assembly Member | |
| Jose Luis Solache Jr. | Democratic | 8 | Assembly Member | |
| Lisa Calderon | Democratic | 8 | Assembly Member | |
| Maggy Krell | Democratic | 8 | Assembly Member | |
| Juan Carrillo | Democratic | 9 | Assembly Member | |
| Nick Schultz | Democratic | 9 | Assembly Member | |
| Steven "Steve" Choi | Republican | 9 | Senator | STATE_UPPER |

### MA State Legislators — 20 politicians

| full_name | party | stance_count | office_title | notes |
|-----------|-------|-------------|--------------|-------|
| Rob Consalvo | Democratic | 1 | Representative, 14th Suffolk District | |
| Daniel J. Ryan | Democratic | 2 | Representative, 2nd Suffolk District | |
| David Biele | Democratic | 2 | Representative, 4th Suffolk District | |
| Daniel J. Hunt | Democratic | 3 | Representative, 13th Suffolk District | |
| Hannah L. Bowen | Democratic | 3 | Representative, 6th Essex District | |
| Greg Schwartz | Democratic | 4 | Representative, 12th Middlesex District | |
| Jay Livingstone | Democratic | 4 | Representative, 8th Suffolk District | |
| Amy M. Sangiolo | Democratic | 6 | Representative, 11th Middlesex District | |
| Daniel F. Cahill | Democratic | 6 | Representative, 10th Essex District | |
| Danillo Sena | Democratic | 6 | Representative, 37th Middlesex District | |
| Dennis C. Gallagher | Democratic | 6 | Representative, 8th Plymouth District | |
| Kevin G. Honan | Democratic | 6 | Representative, 17th Suffolk District | |
| Daniel M. Donahue | Democratic | 8 | Representative, 16th Worcester District | |
| David K. Muradian | Republican | 8 | Representative, 9th Worcester District | |
| James M. Murphy | Democratic | 8 | Representative, 4th Norfolk District | |
| Hadley Luddy | Democratic | 9 | Representative, 4th Barnstable District | |
| Hannah E. Kane | Republican | 9 | Representative, 11th Worcester District | |
| Homar Gómez | Democratic | 9 | Representative, 2nd Hampshire District | |
| Jeffrey R. Turco | Democratic | 9 | Representative, 19th Suffolk District | |
| Michael J. Rodrigues | Democratic | 9 | Senator, First Bristol and Plymouth District | STATE_UPPER |

---

## Tier 2 — Research If Time Allows

Politicians where evidence may be available but expect ~40–50% no-evidence rate. Total: **220 politicians**.

> **Warning:** "Expect ~40–50% no-evidence rate for OR state legislators based on prior Phase 76 experience." OR politicians should be attempted but documented as evidence-floor if no sources are found.

### OR State Legislators — 82 politicians

OR politicians with < 10 stances (STATE_LOWER + STATE_UPPER). Ballotpedia profiles, OregonVotes.gov vote records, and local news coverage may yield sources for some.

| full_name | party | stance_count | district_type |
|-----------|-------|-------------|---------------|
| Bobby Levy | Republican | 3 | STATE_LOWER |
| Boomer Wright | Republican | 3 | STATE_LOWER |
| Court Boice | Republican | 3 | STATE_LOWER |
| Darcey Edwards | Republican | 3 | STATE_LOWER |
| Darin Harbick | Republican | 3 | STATE_LOWER |
| David Brock Smith | Republican | 3 | STATE_UPPER |
| Diane Linthicum | Republican | 3 | STATE_UPPER |
| Dick Anderson | Republican | 3 | STATE_UPPER |
| Dwayne Yunker | Republican | 3 | STATE_LOWER |
| E. Werner Reschke | Republican | 3 | STATE_LOWER |
| Ed Diehl | Republican | 3 | STATE_LOWER |
| Emily McIntire | Republican | 3 | STATE_LOWER |
| Gregory Smith | Republican | 3 | STATE_LOWER |
| Jami Cate | Republican | 3 | STATE_LOWER |
| Jeff Helfrich | Republican | 3 | STATE_LOWER |
| Lucetta Elmer | Republican | 3 | STATE_LOWER |
| Mark Owens | Republican | 3 | STATE_LOWER |
| Noah Robinson | Republican | 3 | STATE_UPPER |
| Rick Lewis | Republican | 3 | STATE_LOWER |
| Todd Nash | Republican | 3 | STATE_UPPER |
| Virgle Osborne | Republican | 3 | STATE_LOWER |
| Anna Scharf | Republican | 4 | STATE_LOWER |
| Cedric Hayden | Republican | 4 | STATE_UPPER |
| Kim Wallan | Republican | 4 | STATE_LOWER |
| Matt Bunch | Republican | 4 | STATE_LOWER |
| Suzanne Weber | Republican | 4 | STATE_UPPER |
| Vikki Breese-Iverson | Republican | 4 | STATE_LOWER |
| Cyrus Javadi | Democratic | 5 | STATE_LOWER |
| Shelly Boshart Davis | Republican | 5 | STATE_LOWER |
| Sue Rieke Smith | Democratic | 5 | STATE_LOWER |
| Alek Skarlatos | Republican | 6 | STATE_LOWER |
| Annessa Hartman | Democratic | 6 | STATE_LOWER |
| Anthony Broadman | Democratic | 6 | STATE_UPPER |
| April Dobson | Democratic | 6 | STATE_LOWER |
| Ben Bowman | Democratic | 6 | STATE_LOWER |
| Bruce Starr | Republican | 6 | STATE_UPPER |
| Courtney Neron Misslin | Democratic | 6 | STATE_UPPER |
| Dacia Grayber | Democratic | 6 | STATE_LOWER |
| Daniel Nguyễn | Democratic | 6 | STATE_LOWER |
| David Gomberg | Democratic | 6 | STATE_LOWER |
| Emerson Levy | Democratic | 6 | STATE_LOWER |
| Farrah Chaichi | Democratic | 6 | STATE_LOWER |
| Fred Girod | Republican | 6 | STATE_UPPER |
| Hai Pham | Democratic | 6 | STATE_LOWER |
| Jason Kropf | Democratic | 6 | STATE_LOWER |
| John Lively | Democratic | 6 | STATE_LOWER |
| Jules Walters | Democratic | 6 | STATE_LOWER |
| Ken Helm | Democratic | 6 | STATE_LOWER |
| Lamar Wise | Democratic | 6 | STATE_LOWER |
| Lesly Muñoz | Democratic | 6 | STATE_LOWER |
| Lisa Fragala | Democratic | 6 | STATE_LOWER |
| Mari Watanabe | Democratic | 6 | STATE_LOWER |
| Nathan Sosa | Democratic | 6 | STATE_LOWER |
| Paul Evans | Democratic | 6 | STATE_LOWER |
| Ricki Ruiz | Democratic | 6 | STATE_LOWER |
| Sarah Finger McDonald | Democratic | 6 | STATE_LOWER |
| Susan McLain | Democratic | 6 | STATE_LOWER |
| Thủy Trần | Democratic | 6 | STATE_LOWER |
| Tom Andersen | Democratic | 6 | STATE_LOWER |
| Willy Chotzen | Democratic | 6 | STATE_LOWER |
| Zach Hudson | Democratic | 6 | STATE_LOWER |
| Andrea Valderrama | Democratic | 7 | STATE_LOWER |
| Chris Gorsek | Democratic | 7 | STATE_UPPER |
| James I. Manning Jr. | Democratic | 7 | STATE_UPPER |
| Janeen Sollman | Democratic | 7 | STATE_UPPER |
| Kathleen Taylor | Democratic | 7 | STATE_UPPER |
| Kevin Mannix | Republican | 7 | STATE_LOWER |
| Kim Thatcher | Republican | 7 | STATE_UPPER |
| Mark Meek | Democratic | 7 | STATE_UPPER |
| Mike McLane | Republican | 7 | STATE_UPPER |
| Pam Marsh | Democratic | 7 | STATE_LOWER |
| Shannon Isadore | Democratic | 7 | STATE_LOWER |
| Travis Nelson | Democratic | 7 | STATE_LOWER |
| Wlnsvey Campos | Democratic | 7 | STATE_UPPER |
| Deb Patterson | Democratic | 8 | STATE_UPPER |
| Jeff Golden | Democratic | 8 | STATE_UPPER |
| Nancy Nathanson | Democratic | 8 | STATE_LOWER |
| Kayse Jama | Democratic | 9 | STATE_UPPER |
| Khanh Pham | Democratic | 9 | STATE_UPPER |
| Mark Gamba | Democratic | 9 | STATE_LOWER |
| Rob Nosse | Democratic | 9 | STATE_LOWER |
| Tawna D. Sanchez | Democratic | 9 | STATE_LOWER |

### TX State Legislators — 116 politicians

TX politicians with < 10 stances (STATE_LOWER + STATE_UPPER). Highly variable evidence availability; attempt larger-name legislators first. Expect high no-evidence rate.

| full_name | party | stance_count | district_type |
|-----------|-------|-------------|---------------|
| Angie Button | Republican | 2 | STATE_LOWER |
| Joe Moody | Democratic | 2 | STATE_LOWER |
| Josey Garcia | Democratic | 2 | STATE_LOWER |
| Aicha Davis | Democratic | 3 | STATE_LOWER |
| Alma Allen | Democratic | 3 | STATE_LOWER |
| Brent Money | Republican | 3 | STATE_LOWER |
| Charles Cunningham | Republican | 3 | STATE_LOWER |
| John Lujan | Republican | 3 | STATE_LOWER |
| Linda Garcia | Democratic | 3 | STATE_LOWER |
| Trey Wharton | Republican | 3 | STATE_LOWER |
| Vincent Perez | Democratic | 3 | STATE_LOWER |
| Brian Harrison | Republican | 4 | STATE_LOWER |
| Charlie Geren | Republican | 4 | STATE_LOWER |
| Dade Phelan | Republican | 4 | STATE_LOWER |
| Daniel Alders | Republican | 4 | STATE_LOWER |
| David Lowe | Republican | 4 | STATE_LOWER |
| Harold Dutton Jr. | Democratic | 4 | STATE_LOWER |
| Jose Manuel Lozano | Republican | 4 | STATE_LOWER |
| Ken King | Republican | 4 | STATE_LOWER |
| Keresa Richardson | Republican | 4 | STATE_LOWER |
| Lauren Ashley Simmons | Democratic | 4 | STATE_LOWER |
| Venton Jones | Democratic | 4 | STATE_LOWER |
| Alan Schoolcraft | Republican | 5 | STATE_LOWER |
| Ana Hernandez | Democratic | 5 | STATE_LOWER |
| Brooks Landgraf | Republican | 5 | STATE_LOWER |
| Candy Noble | Republican | 5 | STATE_LOWER |
| Cecil Bell Jr. | Republican | 5 | STATE_LOWER |
| Hubert Vo | Democratic | 5 | STATE_LOWER |
| Janis Holt | Republican | 5 | STATE_LOWER |
| John Smithee | Republican | 5 | STATE_LOWER |
| Jon Rosenthal | Democratic | 5 | STATE_LOWER |
| Keith Bell | Republican | 5 | STATE_LOWER |
| Lacey Hull | Republican | 5 | STATE_LOWER |
| Morgan Meyer | Republican | 5 | STATE_LOWER |
| Robert Guerra | Democratic | 5 | STATE_LOWER |
| Sam Harless | Republican | 5 | STATE_LOWER |
| Sergio Munoz | Democratic | 5 | STATE_LOWER |
| Sheryl Cole | Democratic | 5 | STATE_LOWER |
| Trent Ashby | Republican | 5 | STATE_LOWER |
| Trey Martinez Fischer | Democratic | 5 | STATE_LOWER |
| Vikki Goodwin | Democratic | 5 | STATE_LOWER |
| Wesley Virdell | Republican | 5 | STATE_LOWER |
| Yvonne Davis | Democratic | 5 | STATE_LOWER |
| Taylor Rehmet | Republican | 5 | STATE_UPPER |
| Adam Hinojosa | Republican | 6 | STATE_UPPER |
| Ana-Maria Ramos | Democratic | 6 | STATE_LOWER |
| Jessica Gonzalez | Democratic | 6 | STATE_LOWER |
| Joanne Shofner | Republican | 6 | STATE_LOWER |
| John McQueeney | Republican | 6 | STATE_LOWER |
| Katrina Pierson | Republican | 6 | STATE_LOWER |
| Oscar Longoria | Democratic | 6 | STATE_LOWER |
| Richard Hayes | Republican | 6 | STATE_LOWER |
| Richard Raymond | Democratic | 6 | STATE_LOWER |
| Tony Tinderholt | Republican | 6 | STATE_LOWER |
| Valoree Swanson | Republican | 6 | STATE_LOWER |
| Ann Johnson | Democratic | 7 | STATE_LOWER |
| Borris Miles | Democratic | 7 | STATE_UPPER |
| Christina Morales | Democratic | 7 | STATE_LOWER |
| David Cook | Republican | 7 | STATE_LOWER |
| Diego Bernal | Democratic | 7 | STATE_LOWER |
| Don McLaughlin | Republican | 7 | STATE_LOWER |
| Gene Wu | Democratic | 7 | STATE_LOWER |
| Helen Kerwin | Republican | 7 | STATE_LOWER |
| Hillary Hickland | Republican | 7 | STATE_LOWER |
| Jeff Leach | Republican | 7 | STATE_LOWER |
| Jeffrey Barry | Republican | 7 | STATE_LOWER |
| John Bucy III | Democratic | 7 | STATE_LOWER |
| Jolanda Jones | Democratic | 7 | STATE_LOWER |
| Mitch Little | Republican | 7 | STATE_LOWER |
| Ryan Guillen | Republican | 7 | STATE_LOWER |
| Salman Bhojani | Democratic | 7 | STATE_LOWER |
| Senfronia Thompson | Democratic | 7 | STATE_LOWER |
| Stan Kitzman | Republican | 7 | STATE_LOWER |
| Stan Lambert | Republican | 7 | STATE_LOWER |
| AJ Louderback | Republican | 8 | STATE_LOWER |
| Andy Hopper | Republican | 8 | STATE_LOWER |
| Armando Martinez | Democratic | 8 | STATE_LOWER |
| Armando Walle | Democratic | 8 | STATE_LOWER |
| Barbara Gervin-Hawkins | Democratic | 8 | STATE_LOWER |
| Ben Bumgarner | Republican | 8 | STATE_LOWER |
| Caroline Harris Davila | Republican | 8 | STATE_LOWER |
| David Spiller | Republican | 8 | STATE_LOWER |
| Gina Hinojosa | Democratic | 8 | STATE_LOWER |
| James Frank | Republican | 8 | STATE_LOWER |
| Jared Patterson | Republican | 8 | STATE_LOWER |
| Jay Dean | Republican | 8 | STATE_LOWER |
| Mary Ann Perez | Democratic | 8 | STATE_LOWER |
| Mihaela Plesa | Democratic | 8 | STATE_LOWER |
| Mike Schofield | Republican | 8 | STATE_LOWER |
| Nicole Collier | Democratic | 8 | STATE_LOWER |
| Ramon Romero Jr. | Democratic | 8 | STATE_LOWER |
| Ray Lopez | Democratic | 8 | STATE_LOWER |
| Rhetta Bowers | Democratic | 8 | STATE_LOWER |
| Shelby Slawson | Republican | 8 | STATE_LOWER |
| Shelley Luther | Republican | 8 | STATE_LOWER |
| Stan Gerdes | Republican | 8 | STATE_LOWER |
| Will Metcalf | Republican | 8 | STATE_LOWER |
| Angela Paxton | Republican | 9 | STATE_UPPER |
| Angelia Orr | Republican | 9 | STATE_LOWER |
| Brad Buckley | Republican | 9 | STATE_LOWER |
| Brent Hagenbuch | Republican | 9 | STATE_UPPER |
| Cassandra Garcia Hernandez | Democratic | 9 | STATE_LOWER |
| Christian Manuel | Democratic | 9 | STATE_LOWER |
| Cole Hefner | Republican | 9 | STATE_LOWER |
| Dennis Paul | Republican | 9 | STATE_LOWER |
| Giovanni Capriglione | Republican | 9 | STATE_LOWER |
| Greg Bonnen | Republican | 9 | STATE_LOWER |
| Janie Lopez | Republican | 9 | STATE_LOWER |
| Lulu Flores | Democratic | 9 | STATE_LOWER |
| Mano DeAyala | Republican | 9 | STATE_LOWER |
| Mary Gonzalez | Democratic | 9 | STATE_LOWER |
| Matt Morgan | Republican | 9 | STATE_LOWER |
| Nate Schatzline | Republican | 9 | STATE_LOWER |
| Philip Cortez | Democratic | 9 | STATE_LOWER |
| Ron Reynolds | Democratic | 9 | STATE_LOWER |

### UT State Legislators — 6 politicians

| full_name | party | stance_count | district_type |
|-----------|-------|-------------|---------------|
| J. Stuart Adams | Unknown | 3 | STATE_UPPER |
| Steve Eliason | Unknown | 4 | STATE_LOWER |
| Doug Fiefia | Unknown | 5 | STATE_LOWER |
| Sandra Hollins | Unknown | 6 | STATE_LOWER |
| Luz Escamilla | Unknown | 6 | STATE_UPPER |
| Rosalba Dominguez | Unknown | 8 | STATE_LOWER |

### CA Local Officials — 16 politicians

CA local officials with < 10 stances (LOCAL, LOCAL_EXEC, COUNTY). Major-city CA officials with active local journalism may have sufficient evidence.

| full_name | party | stance_count | office_title | district_type |
|-----------|-------|-------------|--------------|---------------|
| Raymond Liu | Unknown | 5 | Council Member | LOCAL |
| Desrie Campbell | Unknown | 6 | Council Member | LOCAL |
| Carmen Chu | Unknown | 7 | City Administrator | LOCAL_EXEC |
| Joaquín Torres | Unknown | 7 | Assessor-Recorder | LOCAL_EXEC |
| Kent Lee | Unknown | 7 | Council Member | LOCAL |
| Phil Pluckebaum | Unknown | 7 | Council Member (District 4) | LOCAL |
| Yajing Zhang | Unknown | 7 | Council Member | LOCAL |
| Jeff Prang | Unknown | 8 | Assessor | COUNTY |
| Jenny Wong | Unknown | 8 | City Auditor | LOCAL_EXEC |
| Kathy Kimberlin | Unknown | 8 | Council Member | LOCAL |
| Lisa Kaplan | Unknown | 8 | Council Member (District 1) | LOCAL |
| Roger Dickinson | Unknown | 8 | Council Member (District 2) | LOCAL |
| David Cohen | Unknown | 9 | Council Member (District 4) | LOCAL |
| Manohar Raju | Unknown | 9 | Public Defender | LOCAL_EXEC |
| Teresa Keng | Unknown | 9 | Council Member | LOCAL |
| Yang Shao | Unknown | 9 | Council Member | LOCAL |

---

## Tier 3 — Documented Evidence Floor (No Research)

These politicians are documented as "no additional evidence available." Do NOT research them in Wave 2.

**Total Tier 3: 170 politicians**

| Category | Count | Reason |
|----------|-------|--------|
| No office record (district_type = NULL) | 62 | Identity and role unclear; research likely fruitless or produces low-confidence matches |
| LOCAL/LOCAL_EXEC/COUNTY (non-CA) | 108 | Small-city nonpartisan officials in low-journalism jurisdictions (TX, OR, UT, IN, MA local, etc.) |

**Detail:** The 108 non-CA local politicians are concentrated in TX small cities (Mansfield, Burleson, Weatherford area), OR city officials (Portland city councilors with < 10 stances are counted here but are borderline — check the CSV for specific entries), UT city councils, and IN local officials. The 62 "no-office" politicians include Utah County commissioners and others whose office data is missing or misaligned.

The full per-politician list is in `89-GAP-FILL-AUDIT.csv` (all 170 rows have `tier=3`).

---

## Unfixable Orphans (No Sources Found)

The following (politician, topic) pairs had existing stance values in `inform.politician_answers` but no defensible source could be located to support that value. Context rows were NOT inserted for these topics. The existing stance value remains in the DB unchanged — these entries are flagged here for future review.

| politician | politician_id | topic_key | existing_value | null_reason |
|------------|---------------|-----------|---------------|-------------|
| Roger Niello | 22152e41-31b9-4700-9226-4e274c616f37 | immigration | 2.0 | No defensible source found supporting value=2. Available evidence (NO vote on AB-1306 blocking ICE cooperation) is more consistent with value=4-5. Cannot fabricate sources for the existing value=2 assignment. Flagged as potential inversion requiring re-research. |

---

## Wave 2 Work Order

Wave 2 executor works this list top-to-bottom. No additional judgment needed — the tier classification is deterministic.

1. **Federal politicians (2 politicians):**
   - James Byrd (WY-D, 5 stances) — re-attempt; document if still evidence-floor
   - Derek Dooley (GA-R, 7 stances) — gap-fill from 7 to >= 10

2. **State Executives (7 politicians):**
   - Deborah B. Goldberg (MA-D, 2 stances) — Treasurer
   - William Francis Galvin (MA-D, 4 stances) — Secretary of the Commonwealth
   - Karen Ross (CA, 5 stances) — Secretary of Agriculture
   - Marlo M. Oaks (UT, 6 stances) — State Treasurer
   - Diana DiZoglio (MA-D, 7 stances) — Auditor
   - Malia M. Cohen (CA-D, 9 stances) — Controller
   - Robert Garcia (CA-D, 9 stances) — Board of Equalization Member

3. **CA State Legislators (21 politicians, ordered by stance_count ascending):**
   - Catherine Stefani (3), Gregg Hart (3), Phillip Chen (4), Dr. Corey A. Jackson (5), Heather Hadwick (5), James C. Ramos (5), Michelle Rodriguez (5), Sharon Quirk-Silva (5), Steve Bennett (5), Tom Lackey (5), Liz Ortega (6), Patrick J. Ahrens (6), Tina S. McKinnor (6), Alexandra M. Macedo (7), Mark Gonzalez (7), Jose Luis Solache Jr. (8), Lisa Calderon (8), Maggy Krell (8), Juan Carrillo (9), Nick Schultz (9), Steven "Steve" Choi (9)

4. **MA State Legislators (20 politicians, ordered by stance_count ascending):**
   - Rob Consalvo (1), Daniel J. Ryan (2), David Biele (2), Daniel J. Hunt (3), Hannah L. Bowen (3), Greg Schwartz (4), Jay Livingstone (4), Amy M. Sangiolo (6), Daniel F. Cahill (6), Danillo Sena (6), Dennis C. Gallagher (6), Kevin G. Honan (6), Daniel M. Donahue (8), David K. Muradian (8), James M. Murphy (8), Hadley Luddy (9), Hannah E. Kane (9), Homar Gómez (9), Jeffrey R. Turco (9), Michael J. Rodrigues (9)

---

*After Tier 1 completes, Wave 2 may proceed to Tier 2 (OR, TX, UT, CA Local) at executor discretion, noting the expected ~40–50% no-evidence rate for OR.*
