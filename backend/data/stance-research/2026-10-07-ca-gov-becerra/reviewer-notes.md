# Xavier Becerra (CA Governor, general 2026-11-03) — reviewer notes, Opus-alone run 2026-10-07

Proposals are the Opus coder's (slot 1) labels, copied by `scripts/gold-desk/labels_to_research.py`.
Coder batches: `data/stance-research/2026-10-07-shadow-becerra-*` (one topic per batch, at most 8 sources
chosen by topic terms; no-source topics in `-nosource`). Level `state`, office = Governor of California.
Sources: 20 On the Record transcripts (his own turns), including the 2026-09-30 CNN general-election debate
(meeting 5a98c7c9, ingested for this run) and the 2026-10-01 CBS LA gas-prices segment (38e71313), plus 11
campaign priority pages. His congressional, AG and HHS records are `pre-seating` for this office (codebook V5).

Round 2 re-coded 24 topics after adding each visible Season 1 chair's own cited sources (operator ruling
2026-10-07 Q3). Round-1 labels are kept as `labels/coder-1.round1.json`.

## Queued (25) — `inform.stance_research_review`, batch `2026-10-07-ca-gov-becerra`

- **medicare/aid = 1** (statement; replaces-published-chair, Season 1 also shows 1). "I am absolutely for
  Medicare for all" — debates 2026-05-29 and 2026-05-15, forum 2026-02-10. A governor holds no lever on
  Medicare, so this rests on his own words only.
- **24 blanks** that would replace a Season 1 chair voters see now (`blank-replaces-published-chair`); each
  examined that chair's cited sources. Reasons are `direction-only`, `no-evidence` or `compound-partial`;
  the coder's reason is in research.csv.

## Not queued

- **deportation** — blank, held (`blank-unexamined-fallback`): its Season 1 chair cites the bare homepage
  `https://www.xavierbecerra2026.com/`, which a batch manifest refuses. The Season 1 chair stays visible.
- 21 blanks with no visible chair: nothing to write.

## Leads not used

- SF Chronicle 10-question candidate Q&A (2026-05-04; Becerra answered, Hilton did not): JS-only Hearst page,
  "never bypassed" under spec 2026-09-25 §5.4. Answers cover homelessness, housing, Prop 36, AI and jobs,
  the billionaire tax, high-speed rail and transit.
- On the Record meeting 4d53e045 (Commonwealth Club, 2026-02-10): 13 snippets did not verify against the
  OTR API text; the other 131 OTR citations did.
