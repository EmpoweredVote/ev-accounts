# Curation decisions — 260420-rh4

Tracks user selections for (politician, topic) groups with >2 quotes. Each decision:
- `KEEP` IDs are quotes to retain (with optional `edit:` if text should be modified).
- All other quote IDs in the group are DELETE (with cascade to `inform.compass_verdicts`).

---

## Group 1 — David G Henry / jail-capacity (7 → 2)

- **KEEP** `1067d55a-df7d-42e6-8e22-d8b25db122ae` — unchanged
  > "I have long believed that the answer to the criminal justice system problem in our community is a system and not a building, and we should be working most certainly to make sure we're not filling the jail—whatever it may be at the end."
- **KEEP** `5b8091a1-928e-43a6-a6f5-6b6101bc2868` — edit: append "[the jail]" after "that facility"
  > "It's a civil rights [issue] and making sure we're not over spending taxpayer dollars to build a palace instead of answering the specific questions of constitutional care, of overcrowding and exercise in that facility [the jail]."
- **DELETE**: `0f6c7582`, `aacddc56`, `5e316990`, `6070e36d`, `ca3ff01c`

## Group 2 — David G Henry / deportation (5 → 2)

- **KEEP** `06854041-5789-4c84-972e-ba1521bb5732` — edit: trim dated tail, end with ellipsis
  > "We're the only county in Indiana that has stood up against the cooperation with ICE ..."
- **KEEP** `a88fc8fb-28d3-4c41-87ef-c97e7d0ee8de` — edit: add bracketed context
  > "I took an oath of the Constitution. I'm not going to violate it for anybody [referring to the Fourth Amendment, in the context of ICE enforcement]."
- **DELETE**: `ea1f1ef1`, `d8f3a965`, `d6a05327`

## Group 3 — David G Henry / housing (5 → 2)

- **KEEP** `ea883128-b9ba-42db-ae94-e5e353880912` — unchanged (reveals to deidentify: "affordable housing commission", "Monroe County")
  > "I was on the affordable housing commission in this county, where we declared, once upon a time in 2021 that housing is a human right in Monroe County. And we haven't done anything since to move that needle."
- **KEEP** `80370fad-26a7-4a16-a3f3-95d38f6931b5` — unchanged (reveals to deidentify: "State House", "Democratic Party")
  > "We are well behind on [housing], and we have a lot of work to do. It's going to take creativity, curiosity, conviction, and the courage to stand up to the State House and even people in our own community and in our own Democratic Party to finally get stuff done."
- **DELETE**: `25e41686`, `b9152de3`, `11d06ac7`

## Group 4 — Trent Deckard / deportation (5 → 2)

- **KEEP** `93d67bc5-204c-48c5-a99b-f8f9a7b2f2d3` — reveals to deidentify: "As long as I'm a commissioner—and I will work with any other elected official that will help me championing that—"
  > "As long as I'm a commissioner—and I will work with any other elected official that will help me championing that—it is our job to stand at the doors… to prevent a bully from getting either a child in this school or a child in this community, or any person that wishes to make this home and otherwise has caused us no harm."
- **KEEP** `24cf159e-2736-497b-abb9-adfe3ff87c61` — unchanged (clean standalone)
  > "I don't want ICE doing anything here at all, and I don't want ICE coming in here."
- **DELETE**: `124f9f56`, `c66469cc`, `01e02f4e`

## Group 5 — Trent Deckard / housing (4 → 2)

- **KEEP** `3bf66db2-0014-4295-b0a0-afcb7bd2590d` — reveals to deidentify: "the commissioners"
  > "We have to begin to take the steps … that begins with the commissioners creating a housing department."
- **KEEP** `a3a38485-03f3-4994-b2b1-03078612c48e` — unchanged
  > "I want to make it so that when you come here for a home, for child care, to have quality of life, that it's not this lottery ticket that says I got in the country club no one else does."
- **DELETE**: `b8e11188`, `958f08ad`

## Group 6 — Trent Deckard / jail-capacity (4 → 1)

- **KEEP** `9a517688-0f44-49b1-be9b-4456a5e01533` — unchanged
  > "Once we're done with the politics, we still have to get back to having a constitutional care jail, and the bottom line is, on location, it has to be a place that meets the needs of access to the facility."
- **DELETE**: `292687fb`, `5d21cd59`, `86036232`

## Group 7 — David G Henry / homelessness (3 → 2)

- **KEEP** `b7ac9d96-1588-4228-9f73-d5057d3c02aa` — unchanged
  > "These are people that were trying to survive the winter, we almost unhoused them with no plan whatsoever before Christmas."
- **KEEP** `2141c13b-46de-49f7-96b1-e9e14b3b89cf` — reveals to deidentify: "our board of commissioners"
  > "It shouldn't be the responsibility of our private sector to clean up a mess made by our board of commissioners."
- **DELETE**: `06ebc2d5`

## Group 8 — Trent Deckard / homelessness (3 → 1)

- **KEEP** `c04b17b6-05e4-4f39-bc7f-b4612e1a9ae3` — unchanged
  > "When this issue developed … and the eviction began, I joined the chorus of individuals that said: Let's not do this. We're in the dead of winter. This is inhumane in every way that inhumanity exists."
- **DELETE**: `71f70414`, `420c90cc`

---

## Application order

1. After all groups decided: apply text edits via `UPDATE essentials.quotes SET quote_text = '...' WHERE id = '...'` for KEEPs with edits.
2. Delete unpicked rows via `DELETE FROM essentials.quotes WHERE id IN (...)` — cascades to `inform.compass_verdicts`.
3. Verify: `SELECT politician_id, topic_key, COUNT(*) FROM essentials.quotes GROUP BY 1,2 HAVING COUNT(*) > 2` returns zero rows.
