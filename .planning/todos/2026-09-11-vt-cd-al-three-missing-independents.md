# VT At-Large — three certified independents are missing from our field

**Opened:** 2026-09-11 (during the VT 2026 primary certification pass, migration 1854)
**Blocks:** clearing `provisional_until` on the VT U.S. Representative At-Large race. All three
surviving rows are pinned at 2026-09-18 until this is closed — deliberately, so the race keeps
telling readers it is not fully verified.

## What is missing

The Vermont Secretary of State's **2026 General Election qualified-candidates list** holds SIX
names under "REPRESENTATIVE TO CONGRESS"
(outside.vermont.gov/dept/sos/Elections_Division/election_info_resources/candidates/2026_general_election_qualified_candidates.xlsx,
fetched 2026-09-11):

| candidate | party | town | in our data? |
|---|---|---|---|
| PHOENIX K. ALTAIR | INDEPENDENT | Irasburg | ❌ **missing** |
| BECCA BALINT | DEMOCRATIC | Brattleboro | ✅ |
| GERALD MALLOY | REPUBLICAN | Weathersfield | ✅ |
| ADAM ORTIZ | INDEPENDENT | Newport City | ✅ |
| SUZANNE "SUZ" SEYMOUR | INDEPENDENT | Highgate | ❌ **missing** |
| RYAN P. WALTON | INDEPENDENT | Rutland City | ❌ **missing** |

Mark Coester is in our data and is NOT on this list — he lost the Republican primary and was
culled by 1854.

## Why a post-primary pass could not see them

Independents never appear in a Vermont primary; they petition straight onto the general ballot,
with a filing deadline after the primary. The seeding pass took the **pre-primary** qualified list,
which predates their qualification, and a cull driven by primary results can only ever remove
names — it cannot discover one that was never in a primary.

🔴 **This is the general lesson, and it is not Vermont-specific.** Every state where independents
or minor-party candidates petition directly onto the general ballot has the same hole. A cluster is
not reconciled by culling losers; it is reconciled by diffing our field against the state's
certified GENERAL-election list. Where a state publishes one, use it — it answers the question
directly instead of inferring it from a primary.

## How to close it

Seeding work, not a cull — it needs the Wave-1/2 methodology: a `politician_id` (never NULL on a
House race), the `external_id` scheme `-(state_fips * 10000 + cd * 100 + seq)` with VT = 50,
headshots, and the federal 24-topic stance set at 3-concurrency with the 0-unsourced gate. The
addresses, towns and (for two of them) websites and phone numbers are in the spreadsheet above.

When the three are seeded and verified, clear `provisional_until` on all six rows.
