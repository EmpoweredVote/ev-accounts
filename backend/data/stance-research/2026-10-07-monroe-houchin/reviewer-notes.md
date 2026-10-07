# Erin Houchin (US House IN-9) — reviewer notes, Opus-alone run 2026-10-07

Proposals are the Opus coder's (slot 1) labels, copied unchanged by `scripts/gold-desk/labels_to_research.py`.
Coder batches: `data/stance-research/2026-10-07-shadow-houchin-*` (one topic per batch; 19 no-source
topics in `-nosource`; the 7 education topics in `-education`). Two collection rounds; round-1 labels kept as
`labels/coder-1.round1.json`.

## Queued (4) — `inform.stance_research_review`, batch `2026-10-07-monroe-houchin`

| Topic | Chair | Queue reason | Basis |
|---|---|---|---|
| trans-athletes | 4 | replaces-published-chair (S1 shows 4) | H.R. 734 (118th) + H.R. 28 (119th): cosponsor + Yea on passage |
| voting-rights | 5 | replaces-published-chair (S1 shows 5) | H.R. 8281 (118th) + H.R. 22 (119th) SAVE Act: cosponsor + Yea |
| gun-policy | 4 | review-all-mode | H.R. 38 (119th) cosponsor + Yea on H.J.Res. 44 (118th) |
| israel-military-aid | 1 | review-all-mode | H.R. 8369 (118th) cosponsor + Yea; H.R. 8034 Yea as context |

## Doubts for the reviewer (the chair was not changed)

- **israel-military-aid — the coder changed its answer between rounds on the same record.** Round 1 coded
  BLANK `direction-only`: "Neither instrument states that aid carries 'no new conditions'". Round 2 added only
  the campaign issues page (coded `rhetorical`) and seated chair 1 on the same H.R. 8369 passages. Decide
  whether a bill that forbids withholding deliveries states "no new conditions".
- **gun-policy** rests on the annex line "a reciprocity record plus a vote against a new restriction"; the
  verifier matched only the H.J.Res. 44 roll call (H.R. 38 is a cosponsorship, read from congress.gov).

## Blanks (42) — NOT queued

`verify-stance-research` skips a blank (`value` empty), and the gate refuses `value = 0`, so no blank reaches
the review queue. **20 of these blanks sit over a Season 1 chair that voters see today** (no Season 2 row):
abortion 4, ai-regulation 2, campaign-finance 5, childcare 4, civil-rights 4, climate-change 5, data-centers 4,
deportation 4, fossil-fuels 4, healthcare 4, homelessness 4, medicare/aid 4, misinformation 4, redistricting 5,
religious-freedom 4, school-vouchers 5, social-security 3, tariffs 4, taxes 4, ukraine-support 4.
The coder's reason for each is in `research.csv` (`reasoning` starts "Blank (<reason>)").
