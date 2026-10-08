# Steve Hilton (CA Governor, general 2026-11-03) — reviewer notes, Opus-alone run 2026-10-07

Proposals are the Opus coder's (slot 1) labels, copied by `scripts/gold-desk/labels_to_research.py`.
Coder batches: `data/stance-research/2026-10-07-shadow-hilton-*` (one topic per batch, at most 8 sources
chosen by topic terms, plus each visible Season 1 chair's own cited sources). Level `state`.
Sources: 17 On the Record transcripts (his own turns), including the 2026-09-30 CNN general debate and the
2026-10-01 CBS LA segment, and 38 campaign policy pages.

**Campaign pages are human-saved copies.** stevehiltonforgovernor.com is a JavaScript app; the raw HTML holds
no text. The rendered text of all 38 `/policies/*` pages was saved from the built-in browser on 2026-10-07
(`human-saved/site-*.txt`; `sources.json` lists them, ruling 2026-10-07 option B). They never machine-verify;
all 129 of their snippets were checked present in the saved copies. The review page marks them
"human-saved copy on file".

**Golden Together PDFs** (his 2024 policy reports, cited by Season 1 chairs) were snapshotted as raw PDF
bytes (bug, task chip "Fix coding:snapshot storing raw PDF bytes"); the batches use `pdftotext` copies
(`human-saved/pdf-*.txt`).

## Queued (10) — batch `2026-10-07-ca-gov-hilton`

- **taxes = 4** (statement; replaces-published-chair, Season 1 shows 5). From 2026-04-01 remarks: no income
  tax "under 100 grand", a flat 7.5% above. His current site says $150,000 and 8% — same direction, different
  figures. The coder did not find "as far as possible" (rung 5).
- **9 blanks** that replace a visible Season 1 chair, each with that chair's sources examined (one of them,
  childcare, rests on a human-saved source).

## Not queued — 12 blanks held (`blank-unexamined-fallback`), Season 1 chairs stay visible

ai-regulation, civil-rights, climate-change, data-centers, economic-development, fossil-fuels, healthcare,
housing, jail-capacity, medicare/aid, school-vouchers, transportation-priorities.
Their Season 1 chairs cite pages that no longer exist: old flat paths (`/crime`,
`/keep-california-the-ai-capital-of-the-world`, `/rebalancing-…`, `/steve-hilton-pledges-…`,
`/bring-back-…`) redirect to the homepage in a browser, `/policy/hilton-launches-califordable-…` shows
"Policy not found", and some cite the bare domain. The server answers HTTP 200 for every path, so the
verifier counts them as still loading. **Needs an operator ruling** (treat a client-side redirect or
"not found" page as dead?) or a verifier change.
