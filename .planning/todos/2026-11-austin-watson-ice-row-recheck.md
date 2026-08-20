# Re-check: Kirk Watson `local-immigration` stance (Austin, Mayor)

**Created** 2026-08-19 · **Re-check from** Nov 2026 (event-driven, see triggers)
**Row** `inform.politician_answers` — Watson `d3e165d2-27df-4c27-a2b7-807013c20bba`,
topic `local-immigration`, **value 3**

## Why this row is dated

Chair 3 is *"Follow federal law as required but do not use local resources for proactive
immigration enforcement."* It was seated on Watson's own statement that APD officers
*"do not have the capacity — and should not be asked — to do the jobs of other entities."*

But the policy itself **changed under coercion** in April 2026:

- March 2026: APD general orders required supervisor approval before contacting ICE about
  a civil **administrative** warrant (contact stayed required for criminal charges).
- 14 Apr: AG Paxton opened an investigation, arguing the change "materially limits"
  cooperation contrary to SB 4 (2017).
- 16 Apr: Gov. Abbott threatened to pull ~$2.5M in state grants.
- 24 Apr: the city revised the orders so officers "should, when operationally feasible"
  contact ICE about administrative warrants.

Watson's framing of the revision: *"I believe the City was following state requirements and
I feel strongly that too often politics overwhelms good policy,"* and *"The threatened loss
of these grants would have meant the loss of important public safety services for people we
want protected."*

The row therefore treats the revision as **compliance under duress, not a change of
position** — the same call made for the Bainbridge builder's-remedy vote. That judgment is
what expires, not the sourcing.

## The test that resolves it — binary

**Does the city revert the general orders once the pressure lifts?**

| outcome | meaning | action |
|---|---|---|
| Orders reverted | duress reading confirmed | keep value 3, add the revert as a source |
| Orders left revised after pressure ends | position has effectively moved | **value change to 4** (*honor ICE detainers and share information proactively*) — needs explicit sign-off per the value-change guard |
| Still unresolved | no new fact | leave the row, re-date this todo |

## Triggers to check

1. **AG investigation conclusion** — closed, dropped, or suit filed?
2. **Did the $2.5M actually get withheld, or was it restored?** This is the coercion's
   real resolution and the precondition for the test above.
3. **Any council re-amendment of the general orders.**
4. **New Watson statements.**

## How to check (procedure)

Trigger 3 is queryable, no scraping — the council voting record is an open Socrata dataset:

```bash
curl -s "https://data.austintexas.gov/resource/3c89-i35a.json?\$where=meeting_date%20%3E%20'2026-08-19'%20AND%20upper(item_description)%20like%20'%25GENERAL%20ORDER%25'&\$limit=200"
# also try: '%IMMIGRATION%', '%ICE %', '%SB 4%'
```

Triggers 1, 2 and 4 are press checks. Free and readable:
- KUT `kut.org` (no paywall; carried every beat of this story)
- Austin Monitor tag `state-senator-kirk-watson` — **note the slug is a stale
  "state-senator-" label from his Texas Senate days**

Full source map: `backend/data/stance-research/austin-source-map.json`.

## 🔴 Read "no news" as UNRESOLVED

As of 2026-08-19 there had been **no reporting since early May** — roughly 3.5 months of
silence on an open investigation. Silence is not vindication; an investigation can lapse
quietly rather than conclude. Do not upgrade confidence in the row just because nothing
appeared. Confirm an actual outcome or leave the row and re-date this file.

## Related

- Sources on the row: two KUT pieces (2026-04-24 funding-threat/policy-change, 2026-04-16
  grant threat).
- Only one other Austin `local-immigration` row exists — **Mike Siegel, also chair 3**,
  seated on ending the Flock ALPR contract because city surveillance data was reaching ICE.
  Nothing else in the whole board corpus addresses detainers or sanctuary policy, so this
  topic is thin by measurement, not by oversight.
