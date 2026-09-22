# VA-04 and VA-07 — our field disagrees with the certified list in both directions

**Opened:** 2026-09-11 (during the MO+VA confirmations, migration 1859)
**Scope note:** 1859 fixed only the two *provisional* rows. Everything below is in rows carrying
**no provisional flag**, so it was never in Phase 167's scope and nobody was going to look at it.

## Source

Virginia Department of Elections, **"2026 November Federal Offices Candidate List"**, revision
9-8-2026 — `elections.virginia.gov/casting-a-ballot/candidate-list/november-3-2026-gen-elect-federal-offices/`,
fetched and read from the raw page 2026-09-11. The page states: *"If an office had no candidates
qualify for ballot access, the office will not be included in the above candidate lists."*

## VA-04

| certified | in our data? |
|---|---|
| Jennifer L. McClellan (Democratic) | ✅ |
| **Robert P. "Family Man" Murray, Jr. (Republican)** | ❌ **missing — this is the Republican nominee** |
| **Joan E. "Andrews" Bell (Independent)** | ❌ missing |

We also carry **Andre Kersey** (retired by 1859) and **Jason Brown II**. The string "Brown" occurs
**zero times** in the certified list.

⚠ **After 1859, VA-04 has no flagged row**, because the only provisional row in it was the one
retired. The staleness flag lives on candidate rows, so this race cannot signal that it is missing
its Republican nominee. Same structural gap as Deschutes County Treasurer in 1858.

## VA-07

| certified | in our data? |
|---|---|
| Eugene S. Vindman (Democratic) | ✅ |
| Doug A. Ollivant (Republican) | ✅ |
| Randall A. Terry (Independent) | ✅ (confirmed by 1859) |
| **Taner E. Demirci Lopez (Libertarian)** | ❌ missing |
| **Alaha Ahrar (Independent)** | ❌ missing |
| **Joshua E. Ertle (Independent)** | ❌ missing |

We also carry **Philip Harding** and **Ricky Smithers**; "Harding" and "Smithers" each occur **zero
times** in the certified list. VA-07 keeps a flag on Terry's row because of the three missing names.

## Why the extra rows were not retired here

They carry no provisional flag, which means they were seeded on a different basis with its own
rationale — the VA seeding note for the provisional rows mentions candidates "federally filed with
the FEC", so an FEC-filer basis is the likely origin. Retiring an FEC-derived row against a state
ballot list is a decision for whoever owns that basis. **Being federally filed is not the same as
being on a ballot**, and if that is how they got here, the same pattern will exist in other states.

## How to close it

1. Decide the rule: does an FEC filing alone justify a `race_candidates` row for a state's general
   election? If not, sweep every state against its certified list, not just Virginia.
2. Seed Murray, Bell, Demirci Lopez, Ahrar and Ertle. Murray is a major-party nominee and should be
   treated as urgent.
3. Then clear the flag on Terry, and give VA-04 a flag while it is incomplete — or accept that an
   incomplete race with no provisional rows is currently unrepresentable.
