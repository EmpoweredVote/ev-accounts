# Source profiles

A **source profile** is one Markdown file describing one official record source — one page layout
CONFIRM has learned to read. It has two parts: a YAML front-matter **header** that CONFIRM (code) reads,
and a prose **body** for the collector (agent or person) doing the research. Design:
[`docs/superpowers/specs/2026-09-26-source-profiles-design.md`](../superpowers/specs/2026-09-26-source-profiles-design.md).

## Who reads which part

| Reader | Needs | Form |
|---|---|---|
| Collector session (agent or person) | where the records are, what can be fetched, which page proves what, traps | prose (the body) |
| CONFIRM (code) | where the chamber is, what separates one vote from the next, how names print | exact values (the header) |
| Coders | nothing new | unchanged: codebook + topic annex, the same input for every state — **coders never read this folder** |

**The header chooses from rule kinds defined in code. It never holds a regex.** A profile with no
matching rule kind, a missing field, or zero `expect: pass` controls fails to load — the error names the
file and the key.

## How to add a source

1. Copy the template below into `docs/sources/states/<USPS>/…md` (or `counties/<fips>-…/…md`,
   `places/<geoid>-…/…md` — the same scope keys the steward's jurisdiction leases use).
2. Fill in `match.url_prefixes` (the longest prefix that identifies this page layout), `page_kind`, and
   pick each `rules.*` value from the **rule-kind catalogue** below. Add a new rule kind (with its test in
   `recordBasis.ts`) only when none of the existing ones fit.
3. Add at least one real saved page as an `expect: pass` control — the exact `actor_quote` /
   `tally_quote` copied verbatim from a real `snapshot_text` in a batch's `snapshots.json`. Where the page
   has a trap (a wrong chamber read, a namesake, two votes on one page), add a second control that shows
   the trap failing the way it should (an `expect` naming the finding). The controls prove each rule
   gives the right answer on real pages. On the pages we have, the generic rule gives the same answer,
   so they do not yet prove a profile *needs* its rule. When a page is found where only the declared rule
   is right, add it as a control.
4. Run `npx vitest run scripts/lib/sourceProfiles.real.test.ts` from `backend/` and confirm every control
   passes.
5. Write the body: how to find the record, access (robots-disallowed, JavaScript-only, human-saved vs.
   fetchable by code), what the page proves and does not prove, and any hard cases.

## Rule-kind catalogue

### Built now

| Rule | Kind | Meaning |
|---|---|---|
| `vote_block` | `aye-count` | a vote runs from one labelled aye count to the next (today's rule) |
| | `whole-page` | the page is one vote (or carries no vote at all — an author/bill-text page) |
| `chamber` | `nearest-before` | the nearest chamber word before the surname (today's rule) |
| | `word-before-floor` | the chamber word directly before "Floor" in the actor's own vote block (CA) |
| | `page-header` | the first chamber word on the page (IN roll call) |
| | `bill-origin` | the chamber comes from the bill prefix — SB → upper, AB/HB → lower; for a primary author on a bill page. A co-author printed in the OTHER chamber overrides this (a namesake co-author cannot borrow the bill's chamber of origin) — see `recordBasis.ts` `actorChamber`. |
| | `none` | no chamber: a council, a board, a unicameral body (Nebraska) — the chamber test is skipped. **Not valid when `seat_titles` names both an `upper` and a `lower` chamber** — that pairing is the signal that this body needs the chamber test, not that it can be skipped (`parseSourceProfile` rejects it). |
| `name_format` | `surname` | members print by surname; the collision rules of today apply |
| | `surname-initial` | accepted; today behaves as `surname` (no separate code path yet) |
| | `last-first` | accepted; today behaves as `surname` (no separate code path yet) |
| | `full-name` | "Councilmember Jane Roe" — the full name is required |

### Planned, not yet built

Designed in the parent spec, built with the first local batch that needs them:
`page_kind: minutes` with `vote_rule: named-roll | motion | unanimous-consent`.

## Template header

```yaml
---
profile: <profile-id>                 # unique id, e.g. ca-leginfo-bill-votes
version: 1                            # bump on any header change — the coding report records profile@version
scope: state:<USPS> | county:<fips> | place:<geoid>
body: legislature                     # the body this source covers (legislature, city council, board, …)
match:
  url_prefixes:                       # plain strings, longest prefix wins
    - https://example.gov/path/
page_kind: vote                       # vote | author | bill-text | minutes
rules:
  vote_block: aye-count               # aye-count | whole-page
  chamber: nearest-before              # nearest-before | word-before-floor | page-header | bill-origin | none
  not_chamber_after: []               # optional: extra single words that make a chamber word a bill origin/stage, not a location
  name_format: surname                # surname | surname-initial | last-first | full-name
seat_titles:                          # office_title → chamber, for this body
  Senator: upper
  Representative: lower
controls:                             # real saved pages; at least one `expect: pass`
  - batch: <batch-dir-name>
    snapshot: <snapshot_id prefix>
    person: <full name>
    office_title: <one of seat_titles above>
    instrument: <bill/instrument label, e.g. "SB 1174 (2023-2024)">
    record_kind: vote                 # vote | sponsor | author | other-act
    actor_quote: "<verbatim from the page>"
    tally_quote: "<verbatim from the page, or omit/null for a non-vote>"
    expect: pass                      # pass, or a finding name (e.g. chamber-not-evidenced) for a negative control
---
```

The rule: **bump `version` on any header change.** `coding-report.json` records `profile@version` per
row, so a result can be reproduced after a profile changes, and drift is visible.
