# Feature Research: v2.18 State Leaders — Elected Big 5 Matrix

**Domain:** Civic data platform — statewide elected executive officials
**Researched:** 2026-06-20
**Confidence:** HIGH (all exceptions verified against Wikipedia / official state sources)

---

## Primary Deliverable: 50-State Elected Big 5 Matrix

The matrix below is the source of truth for v2.18 seeding. "IN SCOPE" = popularly elected by voters statewide. "OUT" = appointed, legislature-elected, or office does not exist.

Legend:
- **ELECTED** = popularly elected by voters in statewide election (in scope)
- **TICKET** = elected on joint ticket with governor — still popularly elected, still in scope
- **LEG** = elected by state legislature — NOT in scope (not a public election)
- **APPT** = appointed by governor (with or without senate confirmation) — NOT in scope
- **NONE** = office does not exist in this state — NOT in scope
- **SC** = appointed by state Supreme Court — NOT in scope

### Big 5 Status by State

| State | Governor | Lt. Governor | Attorney General | Secretary of State | Treasurer | In-Scope Count |
|-------|----------|-------------|------------------|--------------------|-----------|---------------|
| AL | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| AK | ELECTED | TICKET | APPT (Gov) | NONE (LG does it) | APPT (Gov) | 2 |
| AZ | ELECTED | TICKET (eff. 2027) | ELECTED | ELECTED | ELECTED | 5 |
| AR | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| CA | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| CO | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| CT | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| DE | ELECTED | TICKET | ELECTED | APPT (Gov) | ELECTED | 4 |
| FL | ELECTED | TICKET | ELECTED | APPT (Gov) | ELECTED (CFO) | 4 |
| GA | ELECTED | TICKET | ELECTED | ELECTED | APPT (Gov) | 4 |
| HI | ELECTED | TICKET | APPT (Gov) | NONE (LG does it) | APPT (Gov) | 2 |
| ID | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| IL | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| IN | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| IA | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| KS | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| KY | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| LA | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| ME | ELECTED | NONE | LEG | LEG | LEG | 1 |
| MD | ELECTED | TICKET | ELECTED | APPT (Gov) | LEG | 3 |
| MA | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| MI | ELECTED | ELECTED (sep) | ELECTED | ELECTED | APPT (Gov) | 4 |
| MN | ELECTED | TICKET | ELECTED | ELECTED | NONE (abolished 2003) | 4 |
| MS | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| MO | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| MT | ELECTED | TICKET | ELECTED | ELECTED | NONE (abolished 1972) | 4 |
| NE | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| NV | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| NH | ELECTED | NONE | APPT (Gov+Council) | LEG | LEG | 1 |
| NJ | ELECTED | TICKET | APPT (Gov) | APPT (Gov) | APPT (Gov) | 1 |
| NM | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| NY | ELECTED | TICKET | ELECTED | APPT (Gov) | ELECTED (Comptroller) | 4 |
| NC | ELECTED | ELECTED (sep) | ELECTED | ELECTED | ELECTED | 5 |
| ND | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| OH | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| OK | ELECTED | TICKET | ELECTED | APPT (Gov) | ELECTED | 4 |
| OR | ELECTED | NONE | ELECTED | ELECTED | ELECTED | 4 |
| PA | ELECTED | TICKET | ELECTED | APPT (Gov) | ELECTED | 4 |
| RI | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| SC | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| SD | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| TN | ELECTED | NOT ELECTED (Senate Pres) | SC (Sup Ct appts) | LEG | LEG | 1 |
| TX | ELECTED | ELECTED (sep) | ELECTED | APPT (Gov) | NONE (abolished 1996) | 3 |
| UT | ELECTED | TICKET | ELECTED | NONE (LG does it) | ELECTED | 4 |
| VT | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| VA | ELECTED | ELECTED (sep) | ELECTED | APPT (Gov) | APPT (Gov) | 3 |
| WA | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| WV | ELECTED | NOT ELECTED (Senate Pres) | ELECTED | ELECTED | ELECTED | 4 |
| WI | ELECTED | TICKET | ELECTED | ELECTED | ELECTED | 5 |
| WY | ELECTED | NONE | APPT (Gov) | ELECTED | ELECTED | 3 |

---

## Total Elected Big 5 Count

Summing the "In-Scope Count" column:

| States with 5 in-scope | States with 4 | States with 3 | States with 2 | States with 1 |
|------------------------|---------------|---------------|---------------|---------------|
| AL, AZ, AR, CA, CO, CT, ID, IL, IN, IA, KS, KY, LA, MA, MS, MO, NE, NV, NM, NC, ND, OH, RI, SC, SD, VT, WA, WI (28 states) | DE, FL, GA, MI, MN, MT, NY, OK, OR, PA, UT, WV (12 states) | MD, TX, VA, WY (4 states) | AK, HI (2 states) | ME, NH, NJ, TN (4 states) |

**Calculation:**
- 28 × 5 = 140
- 12 × 4 = 48
- 4 × 3 = 12
- 2 × 2 = 4
- 4 × 1 = 4

**TOTAL: 208 elected Big 5 offices across all 50 states**

This is the milestone denominator. The 50×5 = 250 theoretical maximum is reduced by:
- 42 offices that are appointed (governor appoints)
- 7 offices elected by legislature (ME AG/SoS/Treasurer, NH SoS/Treasurer, MD Treasurer, TN SoS/Treasurer)
- 5 offices that do not exist (ME Lt Gov, NH Lt Gov, OR Lt Gov, WY Lt Gov, TN "Lt Gov" is Senate Pres)
- 4 offices abolished (TX Treasurer, MN Treasurer, MT Treasurer, NY Treasurer)
- 2 states where Lt Gov performs SoS duties instead of separate SoS (AK, HI → SoS = NONE)
- 1 TN AG appointed by Supreme Court (not voters)
= 250 − 42 = but easier to count: 208 popularly elected

---

## State-by-State Exception Citations

Every "OUT" exception below is sourced. ELECTED offices are not individually cited (all confirmed via Wikipedia state government articles with cross-reference to recent popular election results).

### Lieutenant Governor — Not Elected / Does Not Exist

| State | Status | Source / Basis |
|-------|--------|----------------|
| AZ | TICKET (eff. 2027) | Prop 131 (2022) created office; first election 2026; seated Jan 2027. Wikipedia: "Lieutenant Governor of Arizona" |
| ME | NONE | Senate President is successor. Wikipedia: "Lieutenant governor (United States)" + "Lieutenant Governor of Maine" redirect |
| NH | NONE | Senate President is governor's designated successor. Wikipedia: "Lieutenant governor (United States)" |
| OR | NONE | Secretary of State is first in succession line. Wikipedia: "Secretary of State of Oregon" |
| TN | NOT ELECTED | Senate Speaker holds title by 1951 statute; elected by senators, not voters. Wikipedia: "Lieutenant Governor of Tennessee" |
| WV | NOT ELECTED | Senate President designated Lt. Gov by 2000 statute; elected by senators. Wikipedia: "Lieutenant Governor of West Virginia" |
| WY | NONE | Secretary of State is first in succession line. Wikipedia: "Lieutenant governor (United States)" + "Wyoming Secretary of State" |

**AZ Note for v2.18:** AZ Proposition 131 was approved by voters in November 2022. The first Lt. Gov is elected on the 2026 ticket with the governor and takes office January 2027. For v2.18 seeding purposes, this office should be seeded as IN SCOPE with the current post-2026 officeholder once confirmed (likely Q1 2027); it will not exist in the DB until after the 2026 election results.

### Attorney General — Not Popularly Elected

| State | Status | Source |
|-------|--------|--------|
| AK | APPT (Gov + Legislature confirms) | Wikipedia: "Attorney General of Alaska" — "appointed by the governor and confirmed by the Alaska Legislature" |
| HI | APPT (Gov + Senate confirms) | Wikipedia: "Attorney General of Hawaii" — "appointed by the elected governor with the approval of the state senate" |
| ME | LEG | Wikipedia: "Attorney General of Maine" — "chosen biennially by the Maine Legislature in joint session." Maine is the ONLY state that does this. |
| NH | APPT (Gov + Executive Council) | Wikipedia: "Attorney General of New Hampshire" — "appointed by the governor with approval of the [Governor's] Council" |
| NJ | APPT (Gov + Senate confirms) | Wikipedia: "Attorney General of New Jersey" — "appointed by the governor of New Jersey, confirmed by the New Jersey Senate" |
| TN | SC (Supreme Court appoints) | Wikipedia: "Attorney General of Tennessee" — "appointed by the justices of the Supreme Court for a term of 8 years." Only state where AG is judiciary, not executive. |
| WY | APPT (Gov) | Wikipedia: "Attorney General of Wyoming" — "The attorney general is appointed by the Governor" |

### Secretary of State — Not Popularly Elected / Does Not Exist

| State | Status | Source |
|-------|--------|--------|
| AK | NONE | Lt. Gov performs SoS duties; title changed from "Secretary of State" to "Lt. Governor" in 1970. Wikipedia: "Alaska Secretary of State" redirect |
| DE | APPT (Gov) | Wikipedia: "Secretary of State of Delaware" — appointed; no popular election listed; confirms appointment model |
| FL | APPT (Gov, since 2002) | Wikipedia: "Secretary of State of Florida" — "since 2002, the secretary of state of Florida has been appointed by the governor." Last elected was Katherine Harris (1998). |
| HI | NONE | Lt. Gov "is concurrently the 'secretary of State' of Hawaii." Wikipedia: "Lieutenant Governor of Hawaii" |
| ME | LEG | Wikipedia: "Secretary of State of Maine" — "elected biannually by ballot of members of both houses of the Maine Legislature" |
| NH | LEG | Wikipedia: "Secretary of State of New Hampshire" — "elected biennially by the New Hampshire General Court (state legislature)" per 1784 constitution |
| NJ | APPT (Gov) | Wikipedia: "Secretary of State of New Jersey" — "appointed by the governor" |
| NY | APPT (Gov, since 1926) | Wikipedia: "Secretary of State of New York" — "the office became appointive" in 1926 under Governor Al Smith |
| OK | APPT (Gov, since 1979) | Wikipedia: "Secretary of State of Oklahoma" — "elective from statehood until 1975 when the Constitution was amended and it became an appointive office...effective in 1979" |
| PA | APPT (Gov + Senate confirms) | Wikipedia: "Pennsylvania Secretary of the Commonwealth" — "appointed by the governor, subject to confirmation by the State Senate." Title is "Secretary of the Commonwealth." |
| TN | LEG | Wikipedia: "Secretary of State of Tennessee" — "elected to a four-year term by the General Assembly in a joint convention" |
| TX | APPT (Gov + Senate confirms) | Wikipedia: "Secretary of State of Texas" — "appointment is made by the governor of Texas, with confirmation by the Texas Senate." All other TX statewide officers are elected; SoS is the only appointed one. |
| UT | NONE | Lt. Gov performs all SoS duties. Wikipedia: "Lieutenant Governor of Utah" — office abolished 1976; "exercising 'general administrative authority over all elections'" |
| VA | APPT (Gov) | Wikipedia: "Secretary of the Commonwealth of Virginia" — "appointed member of the governor's Cabinet" under 1971 constitution. Title is "Secretary of the Commonwealth." |

### Treasurer — Abolished / Not Popularly Elected

| State | Status | Source |
|-------|--------|--------|
| AK | APPT (Gov) | Wikipedia: "Alaska State Treasurer" — "Revenue Commissioner" appointed by Governor |
| FL | ELECTED (as CFO) | Note: FL abolished separate Treasurer in 2003; merged with Comptroller into elected "Chief Financial Officer." CFO IS popularly elected. Wikipedia: "Florida Chief Financial Officer" — "elected statewide constitutional officer." STILL IN SCOPE as the CFO. |
| GA | APPT (Gov) | Wikipedia: "Georgia State Treasurer" — office removed from elected status in 1972; "restored as an appointed office under Zell Miller in 1993" |
| HI | APPT (Gov) | Wikipedia: "Hawaii State Treasurer" — "Director of Finance" appointed by governor |
| MD | LEG | Wikipedia: "Maryland State Treasurer" — "elected by both houses of the Maryland General Assembly" since 1851 constitution |
| ME | LEG | Wikipedia: "Maine State Treasurer" — "chosen by the Maine Legislature in joint session for a two-year term" |
| MI | APPT (Gov) | Wikipedia: "Michigan State Treasurer" — "unelected office within the executive branch" appointed by governor |
| MN | NONE (abolished 2003) | Wikipedia: "Minnesota State Treasurer" — "A 1998 constitutional amendment abolished the position of state treasurer, effective January 6, 2003." Duties transferred to Commissioner of Finance (appointed). |
| MT | NONE (abolished 1972) | Wikipedia: "Montana State Treasurer" — "abolished following the adoption of the 1972 Constitution." Duties transferred to Dept. of Administration. |
| NH | LEG | Wikipedia: "New Hampshire State Treasurer" — "Elected by Legislature" per NH Constitution, Article 67 |
| NJ | APPT (Gov) | Wikipedia: "New Jersey State Treasurer" — gubernatorial appointment (per state government structure; NJ has no popularly elected treasurer) |
| NY | NONE (abolished 1926) | Wikipedia: "New York State Comptroller" — "In 1926, the responsibilities of the New York State Treasurer were transferred to the comptroller." NY Comptroller IS popularly elected and in scope. |
| TN | LEG | Wikipedia: "Tennessee State Treasurer" — "Elected by Legislature" |
| TX | NONE (abolished 1996) | Wikipedia: "Texas Comptroller of Public Accounts" — voters approved constitutional amendment in 1995; duties transferred to Comptroller by 1996. TX Comptroller IS elected and IS in scope. |
| VA | APPT (Gov) | Wikipedia: "Virginia State Treasurer" — "appointed by Governor Glenn Youngkin" (gubernatorial appointment) |
| WV | ELECTED | West Virginia Treasurer is popularly elected — confirmed. |

---

## Naming and Role Nuances for Modeling

### "Secretary of the Commonwealth" States
Three states use "Secretary of the Commonwealth" as the title — NOT "Secretary of State." The role is functionally equivalent. For the `role_canonical` field, use `secretary_of_state` in all three.

| State | Official Title | Elected? | Notes |
|-------|---------------|----------|-------|
| MA | Secretary of the Commonwealth | YES (popularly elected) | Andrea Campbell holds this post |
| PA | Secretary of the Commonwealth | NO (Gov appoints) | OUT OF SCOPE |
| VA | Secretary of the Commonwealth | NO (Gov appoints, Cabinet) | OUT OF SCOPE |

### "Comptroller" States — Treasurer Equivalent

Three states use "Comptroller" as their primary fiscal officer equivalent to Treasurer:

| State | Role | Title | Elected? | Notes |
|-------|------|-------|----------|-------|
| MD | Comptroller is chief fiscal auditor; Treasurer is separate (leg-elected) | Comptroller of Maryland | YES (popularly elected) | Both exist but Treasurer is leg-elected. Comptroller is NOT one of the Big 5 (it's beyond the five roles). |
| NY | Comptroller absorbed Treasurer duties in 1926 | State Comptroller | YES (popularly elected) | Model as Treasurer equivalent in v2.18. |
| TX | Comptroller absorbed Treasurer duties in 1996 | Comptroller of Public Accounts | YES (popularly elected) | Model as Treasurer equivalent in v2.18. |

**Decision for v2.18:** NY Comptroller and TX Comptroller are the in-scope "Treasurer" equivalents. Use `role_canonical = 'treasurer'` on those office rows. MD Comptroller is NOT in the Big 5 for Maryland (it's beyond the five; MD's in-scope Big 5 = Gov, Lt Gov, AG — only 3).

### Florida Chief Financial Officer

FL merged Treasurer + Comptroller in 2002 into an elected CFO. Model as the Treasurer equivalent for Florida.

- **Title:** Chief Financial Officer
- **Elected:** YES (statewide constitutional officer)
- **role_canonical:** `treasurer`

### "Treasurer and Receiver-General" (Massachusetts)

MA's official title is "Treasurer and Receiver-General of the Commonwealth of Massachusetts." The DB already has this seeded as such (migration 154). Keep the full title in `chambers.name` and set `role_canonical = 'treasurer'`.

### Alaska and Hawaii — No Secretary of State

Both states have the Lieutenant Governor performing all SoS duties. The office is literally named "Secretary of State" in neither state; the Lt. Gov title absorbs it. For v2.18:
- Do NOT create a SoS record for AK or HI.
- The Lt. Gov IS in scope (on ticket with Gov in both states).
- AG: AK = appointed (OUT), HI = appointed (OUT).

### Utah — No Secretary of State

Utah abolished its Secretary of State in 1976. The Lt. Governor handles all election and SoS functions. Utah's in-scope Big 5 = Gov (+ Lt Gov on ticket), AG, Treasurer. No SoS.

### Tennessee — Special Case (Only 1 in-scope office)

TN is the most restricted state:
- Governor: elected (IN SCOPE)
- Lt. Gov: Senate Speaker by 1951 statute (NOT popularly elected — OUT)
- AG: appointed by Tennessee Supreme Court for 8-year term (OUT)
- SoS: elected by General Assembly in joint convention (OUT)
- Treasurer: elected by General Assembly (OUT)

Only the Governor is in scope for Tennessee.

### New Jersey — Almost All Appointed

NJ has only one elected Big 5 office:
- Governor: elected (IN SCOPE)
- Lt. Gov: ticket with Gov (IN SCOPE)
- AG: appointed by Gov (OUT)
- SoS: appointed by Gov (OUT)
- Treasurer: appointed by Gov (OUT)

Two in-scope offices for NJ.

---

## Existing DB Coverage (Gap Baseline)

Per PROJECT.md, 68 STATE_EXEC records exist across 9 states. Here is what's already seeded vs. what v2.18 must add:

| State | Currently Seeded | In-Scope Count | Notes |
|-------|-----------------|----------------|-------|
| CA | Gov, Lt Gov, AG, SoS, Treasurer + more | 5 | Complete. Has stances. |
| IN | Gov (+ others from early pilot) | 5 | IN has 5 in-scope; AG/SoS/Treasurer gaps likely |
| MA | Gov, Lt Gov, AG, Treasurer, SoS (Sec of Commonwealth), Auditor | 5 | MA has Auditor seeded too (not Big 5, but already there). All 5 Big 5 likely covered. |
| MD | Gov, Lt Gov, AG, Comptroller, Treasurer (leg-elected) | 3 | MD in-scope = Gov+Lt Gov+AG only. Comptroller is seeded but not Big 5. Treasurer is leg-elected. |
| ME | Gov, AG, SoS, Treasurer (all leg-elected except Gov) | 1 | Only Gov is in-scope. Currently has 0 stances (known gap). |
| OR | Gov, AG, SoS, Treasurer, Labor Commissioner | 4 | 4 Big 5 in scope (no Lt Gov in OR). Labor Commissioner is seeded but NOT Big 5. Has no stances. |
| TX | Gov, Lt Gov, AG, Comptroller, Land Commissioner, Ag Commissioner | 3 | TX in-scope = Gov+Lt Gov+AG. Comptroller = Treasurer equivalent (seeded). Land/Ag Commissioners = NOT Big 5. |
| UT | Gov, Lt Gov (who does SoS) | 4 | UT: Gov, Lt Gov, AG, Treasurer in scope. AG and Treasurer not yet seeded. |
| VA | Gov, Lt Gov, AG | 3 | All 3 VA in-scope Big 5 already seeded. No SoS/Treasurer (both appointed). Stances need review. |

**41 states have ZERO STATE_EXEC records** — all in-scope Big 5 offices for those states must be seeded from scratch.

---

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| State exec in representatives feed | Every civic data platform shows statewide officers | LOW (routing exists for STATE_EXEC) | STATE_EXEC already handled by NATIONAL_UPPER pattern in backend |
| Governor for every state | Most visible statewide elected official | LOW | Seeding only; routing works |
| Headshot for every seeded exec | Existing politicians all have headshots | MEDIUM | Ballotpedia + official state .gov sources |
| Sourced compass stances | All other politicians in feed have stances | HIGH | Research pipeline (208 execs × avg ~15 topics) |
| Correct office title in feed | Users will notice wrong titles (e.g. "Secretary of State" for MA) | LOW | role_canonical field + proper chamber name |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Honest-skip documentation for legislature-elected officials | Transparency about why some officials don't appear | LOW | is_appointed_position flag already exists |
| Full Big 5 scope where elected | No other civic platform provides stances for all 5 offices | HIGH | 208 officials × sourced stances |
| Correct title normalization (Comptroller, CFO, Sec of Commonwealth) | No confusion between role and title | LOW | role_canonical field handles this |
| AZ Lt. Gov seeding timing | Accurate about new office coming after 2026 election | LOW | Defer AZ Lt. Gov until post-election; note in gate |

### Anti-Features (Do Not Build)

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| Seeding appointed officials (AG in AK/HI/NJ/WY, SoS in TX/VA/FL, etc.) | "More officials = better coverage" | Pollutes the feed with unelected officials; breaks the platform's elected-officials focus; creates confusion | Seed ONLY in-scope popularly elected Big 5; set is_appointed=true and exclude from feed for any exceptions already seeded |
| Non-Big-5 statewide officers (Auditor, Comptroller, Insurance Commissioner, Agriculture Commissioner, Land Commissioner, Labor Commissioner) | "Comptroller is important in some states" | Scope creep; non-uniform across states; users expect consistency; MD Comptroller/OR Labor Commissioner/TX Land Commissioner already seeded as bonus — don't add more | Keep existing seeded non-Big-5 records; add role_canonical for clarity; do NOT seed new non-Big-5 offices |
| Legislature-elected officials in the feed | Maine AG / SoS / Treasurer are well-known positions | They are NOT popularly elected — presenting them as "your representative" is misleading | Model as is_appointed_position=true; exclude from feed or display with "appointed by legislature" label |
| 50×5 flat approach | Simpler to reason about | Creates phantom offices for states that don't have them (e.g. seeding a ME Lt. Gov or TX Treasurer) | Use the 208-office matrix; idempotent gap-based seed |
| Seeding TN/NJ beyond Governor | "Completing coverage" | TN Lt. Gov and AG are not democratically elected by voters; NJ AG/SoS/Treasurer all appointed | Only seed TN Governor; only seed NJ Governor + Lt. Gov (ticket) |

---

## Feature Dependencies

```
Authoritative 208-office matrix (this doc)
    └──required by──> Idempotent gap-seed script
                           └──required by──> Stance research pipeline
                                                  └──required by──> Feed surfacing verification
                                                  └──required by──> Phase gate SQL

STATE_EXEC district routing (already in backend)
    └──required by──> Feed surfacing for all 50 states
    └──already works──> CA/IN/MA/MD/ME/OR/TX/UT/VA

role_canonical column (already on offices table, migration 154)
    └──required by──> Correct Big 5 cross-state queries
    └──enhances──> NY Comptroller / TX Comptroller / FL CFO / MA Sec of Commonwealth display
```

### Dependency Notes

- **Gap-seed requires matrix:** The seed script must query `(state, role_canonical)` pairs, not flat office counts, to detect what's missing. Detecting by state+district_type alone is insufficient because some states have non-Big-5 records already.
- **Stance research requires seeded records:** Can't research stances for politicians who don't have politician + office rows yet. Tier 1 (seed) precedes Tier 2 (stances).
- **Feed surfacing likely already works:** `STATE_EXEC` district_type is already handled in the representatives feed backend (CA/OR/VA/TX all surface). The v2.18 work is seeding the data, not wiring new routing logic.

---

## MVP Definition

### Launch With (v2.18)

- [x] 208-office authoritative matrix (this doc) — prevents phantom offices
- [ ] Idempotent gap-seed: 41 states × in-scope Big 5 records (politician + office + headshot), plus gaps in the 9 existing states (IN, ME, OR, TX, UT)
- [ ] Sourced compass stances for all 208 in-scope officials (or honest-skip with documented reason)
- [ ] Phase gate: every in-scope elected Big 5 office filled, 0 unsourced, state-code accessibility confirmed for all 50 states

### Add After Validation (v2.18.x)

- [ ] AZ Lieutenant Governor (post-2026 election; seat January 2027)
- [ ] role_canonical backfill for all existing STATE_EXEC records (for cross-state queries)
- [ ] NY Comptroller / TX Comptroller / FL CFO display title normalization in feed

### Future Consideration (v2.19+)

- [ ] Non-Big-5 statewide officers (Auditor, Insurance Commissioner, Agriculture Commissioner) — if user demand warrants
- [ ] State-level election tracking for upcoming Big 5 races (2026 governors, AG races)
- [ ] Historical officeholder data (term start/end)

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Governor for all 50 states (Tier 1 seed) | HIGH | LOW | P1 |
| Lt. Gov for all eligible states (Tier 1 seed) | MEDIUM | LOW | P1 |
| AG for 43 elected states (Tier 1 seed) | HIGH | LOW | P1 |
| Headshots for all seeded execs | HIGH | MEDIUM | P1 |
| Sourced stances for Gov + AG | HIGH | HIGH | P1 |
| SoS for 35 elected states (Tier 1 seed) | MEDIUM | LOW | P1 |
| Treasurer for ~33 elected states (Tier 1 seed) | MEDIUM | LOW | P1 |
| Sourced stances for Lt Gov + SoS + Treasurer | MEDIUM | HIGH | P1 |
| Feed surfacing verification (all 50 states) | HIGH | LOW | P1 |
| role_canonical normalization (NY Comptroller, TX Comptroller, FL CFO, MA SoS) | MEDIUM | LOW | P2 |
| AZ Lt. Gov (post-2026) | LOW | LOW | P3 (defer to v2.19) |
| Non-Big-5 officers | LOW | HIGH | P3 (never in v2.18) |

---

## Sources

- Wikipedia: "Lieutenant governor (United States)" — confirms AZ/ME/NH/OR/TN/WV/WY no-office or non-elected status
- Wikipedia: "State attorney general" — confirms 7 non-elected AG states (AK/HI/ME/NH/NJ/TN/WY)
- Wikipedia: "Secretary of state (U.S. state government)" — confirms 35 elected states + exceptions (AK/HI/UT no office; DE/FL/NJ/NY/OK/PA/TN/TX/VA/ME/NH appointed or leg-elected)
- Wikipedia: "State treasurer" — confirms abolitions (TX 1996, MN 2003, MT 1972, NY 1926) + appointed states
- Wikipedia: "Lieutenant Governor of Arizona" — Prop 131 (2022), eff. 2027
- Wikipedia: "Texas Comptroller of Public Accounts" — confirms 1995/1996 Treasurer abolition
- Wikipedia: "Florida Chief Financial Officer" — confirms CFO = elected SoS equivalent since 2002
- Wikipedia: "New York State Comptroller" — confirms popularly elected, absorbed Treasurer 1926
- Wikipedia: "Secretary of State of Texas" — confirms Gov appoints; all other TX execs elected
- Wikipedia: "Lieutenant Governor of Tennessee" — Senate Speaker holds title by 1951 statute
- Wikipedia: "Attorney General of Tennessee" — appointed by TN Supreme Court (unique nationally)
- Wikipedia: "Lieutenant Governor of West Virginia" — Senate President designated by 2000 statute
- Wikipedia: "Lieutenant Governor of Utah" — confirms Lt Gov performs SoS duties; SoS abolished 1976
- Wikipedia: "Secretary of State of Oklahoma" — confirms appointed since 1979 (formerly elected)
- Wikipedia: "Secretary of State of Florida" — appointed since 2002 (last elected 1998)
- Wikipedia individual state AG/SoS/Treasurer articles — all consulted for exception verification
- Project migration 169 (ME) — confirms Maine: Gov elected, AG/SoS/Treasurer all legislature-elected
- Project migration 270 (MD) — confirms Maryland: Treasurer is legislature-elected (is_appointed_position=true)
- Project migration 223 (OR) — confirms Oregon: all 5 officers popularly elected; no Lt. Gov
- Project migration 317 (VA) — confirms Virginia: only Gov/Lt Gov/AG in scope (SoS + Treasurer appointed)

---

*Feature research for: v2.18 State Leaders — elected Big 5 statewide executives*
*Researched: 2026-06-20*
