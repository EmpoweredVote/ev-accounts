# 143-05 SUMMARY — Batch E (AL/LA/KY SoS+Treasurer+LtGov)

**Status:** ✅ Complete — 7/9 execs covered + 2 documented Treasurer whole-record honest-skips, 0 unsourced.

## Result
- **45 answers + 45 contexts** pushed to prod, 13 quotes, 13 selected, 0 surname leaks.
- `verify-stance-coverage.mjs 7 …` (all 9 ids, expected 7) → **PASS covered=7/7 unsourced=0**.
- Per-exec rows: Ainsworth(AL LtGov) 13, Allen(AL SoS) 3, Boozer(AL Treas) **0 — whole-skip**, Nungesser(LA LtGov) 4, Landry(LA SoS) 2, Fleming(LA Treas) 14, Coleman(KY LtGov) 5, Adams(KY SoS) 4, Metcalf(KY Treas) **0 — whole-skip**.

## Documented honest-skips-of-whole-record (pin in 143-11 gate)
- **Young Boozer, AL Treasurer (-100005)** — career banker; only a fiduciary Investment Policy Statement (Board doc) + an Israel-bond action; no documentable stance on any compass topic.
- **Mark Metcalf, KY Treasurer (-2100005)** — sworn Jan 2024; treasury.ky.gov + campaign site both ECONNREFUSED, all ESG-boycott news 403/404, Wikipedia bio-only. Genuine structural source wall confirmed on re-research (0→0).

## Notes / deviations
- ≤3 researcher concurrency held throughout.
- **CSV repair:** fleming.csv line 11 had a malformed `"" …"""` quote_text artifact → blanked the row's optional quote fields, re-merged (Fleming's 14 rows then loaded). (Distinct from the trailing-comma/quad-quote artifacts.)
- **Auto-re-research (<5):** Allen 2→3, Landry 1→2, Adams 3→4, Nungesser 3→4 — all confirmed **genuine thin/walled records** (AL/LA legislature bill-search 404, VoteSmart/Legiscan 403, news paywalled; SoS/LtGov documentable scope is narrow). Honest-partial beats inference.
- **Proxy-row drop (1 SSM=5):** Ainsworth same-sex-marriage=5 dropped — evidence was urging officials to refuse licenses + "immoral attack on traditional marriage" (service-refusal advocacy + platform statement → supports religious-freedom=5, not SSM=5; no documented vote/amendment/bill). Consistent with Patrick/LaRose drops.
- Fleming SSM=4 KEPT (State Marriage Defense Act — state-authority bill, scores 4 not 5). No Governor-mirroring; no party inference; no isidewith.

Data record: `backend/data/stance-research/exec-w2-batch-e/` (9 CSVs incl. header-only boozer.csv + metcalf.csv + scripts).
