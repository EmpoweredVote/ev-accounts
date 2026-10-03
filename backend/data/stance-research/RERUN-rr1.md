# Coder re-run rr1 (2026-10-03)

The three headless coders re-run over the saved inputs of all 104 batches that carry blind gold, after
codebook clarifications H13–H17 (codebook 0.4, commit 2849d42e). Made by
`scripts/gold-desk/rerun_coders.py rr1`; stored under batch ids `<batch>-rr1`; reported with
`npx tsx scripts/reliability-report.ts --run rr1`.

Committed per batch: `labels/`, `coding-report.json`, `coding-context.json`, `sources.json`
(batch_id renamed), `topics.json`, `disagreement-digest.json`. Not committed, because they are byte
copies of the original batch (`snapshots.json`, `topics.all.json`, `politicians.json`,
`human-saved/`) or are rebuilt from the codebook at 2849d42e (`coder-inputs/`, by `coding:inputs`).

Leakage control: seven gold items prompted H13–H17 (ramos-aca5, gonzalez, carrasco-sb285,
fernandez-hcr2060, wiener-sb770, gipson-sb32, lee-ab1279). Report the re-run with and without them
(`--exclude-batches`).
