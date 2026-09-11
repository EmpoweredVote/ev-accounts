# AZ and MA — one row each, both blocked at the source

Attempted 2026-09-11. **No migration.** Two rows stay stale, 21 and 17 days past their dates,
because neither state's authoritative list could be read.

Both are the same shape: a declared independent or minor-party candidate whose presence on the
November ballot can only be settled by the state's certified general-election candidate list.

---

## AZ-02 — Curtis Goodwin (21 days overdue, `provisional_until` 2026-08-21)

Migration 1579 already worked this row carefully and declined to retire it. Its note:

> re-checked 2026-08-07 (AZ statewide canvass was 2026-08-06): absent from the certified AZ-02
> general field (Crane, Nez), BUT ballotpedia.org records NO result for the CD2 Libertarian primary
> it says he ran in — empty vote table, no winner marked. azsos.gov returns HTTP 403 to scripted
> fetches (bot block), so the official canvass could not be read. NOT retired on a source that has
> not recorded the result.

**That is still exactly the situation.** Arizona blocks every host tried on 2026-09-11:

| host | result |
|---|---|
| `azsos.gov` | 403 |
| `azsos.gov/elections/results-data/2026-election-information` | 403, to WebFetch as well as curl |
| `results.arizona.vote` | 403 |
| `my.arizona.vote` | 403 |

Nothing was worked around. The row stands, correctly, on the reasoning 1579 set: he ran in a
Libertarian primary whose result no accessible source records, and absence from a secondary
source's general-election field is not proof he lost.

**To close it:** open the Arizona SoS 2026 General Election candidate list, or the official
statewide canvass of the 2026-08-04 primary, in a browser. One question — is Curtis Goodwin on the
AZ-02 general ballot? Our AZ-02 field is otherwise Elijah Crane and Jonathan Nez (plus Eric
Descheenie, already withdrawn).

---

## MA-01 — Nadia Milleron (17 days overdue, `provisional_until` 2026-08-25)

Seeded as a "declared independent (news-evidenced)", with the flag set to the **Massachusetts
independent filing deadline of 2026-08-25**. That deadline has passed, so the question is simply
whether she filed and qualified.

The Secretary of the Commonwealth's candidate page could not be read:

| host | result |
|---|---|
| `sec.state.ma.us/.../candidates-for-state-election.htm` | **redirect loop** — 302 to itself, curl exits 47; WebFetch fails at 10 redirects |
| `sec.state.ma.us` root | same redirect loop |
| `electionstats.state.ma.us` | **200 — reachable**, but it is a past-results archive and carries no prospective candidate list for the 2026 general |

**To close it:** the Secretary of the Commonwealth's certified list of candidates for the
November 3, 2026 State Election, Representative in Congress, First District. Our MA-01 field is
Richard Neal (incumbent) and Jeromie Whalen alongside Milleron — and note the Vermont lesson: check
the full certified field, not just her, because an independent who qualified after our seeding run
would be missing from our data the same way.

---

## Both belong on the browser list

Add AZ and MA to the MN / TN / NH / WI / KS group: states that publish the document and block the
fetch. Each is a single yes-or-no question, and both together are about five minutes of someone's
time in a browser.
