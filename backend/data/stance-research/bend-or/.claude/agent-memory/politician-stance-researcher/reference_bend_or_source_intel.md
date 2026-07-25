---
name: bend-or-source-intel
description: Fetch tooling for stance research — the WebFetch verbatim-refusal trap, Wayback CDX for deleted campaign platform pages, and Bend-area outlet/Ballotpedia behaviour
metadata:
  type: reference
---

Fetch-layer behaviour learned on the Bend-La Pine school board wave (2026-07-24). For BoardBook and
PDF handling see [[boardbook-and-pdf-extraction]]; for the topic-scoring traps see
[[school-board-axis-drift-traps]].

## The verbatim-quote trap — applies to EVERY wave, not just Bend

`WebFetch` pipes the page through a summariser model that **refuses to reproduce long passages
verbatim** ("guidelines prevent me from reproducing lengthy passages, even from web pages"). It
returns a paraphrase instead. Using that output to build `quote_text` guarantees a fabricated quote —
which is the exact failure the operator re-fetches and string-matches for. This happens even when the
URL is wrapped in `r.jina.ai`.

**Always** fetch with `curl -sL "https://r.jina.ai/<url>" -o file.txt` via Bash, then verify with
`grep -cF '<quote>' file.txt` before recording. Re-verify against a **freshly fetched** copy at the
end, since that is what the reviewer does.

Punctuation gotcha: source pages use curly quotes/apostrophes. `It’s` (U+2019) fails a `grep -F`
written with a straight `'`. Prefer quote spans containing **no apostrophes at all**.

## Recovering deleted campaign platform pages — Wayback CDX

Local candidates' policy planks usually live on a campaign page that is later deleted. This is often
the *only* first-person policy text that exists for them, so always check:

    curl "http://web.archive.org/cdx/search/cdx?url=<domain>*&output=text&fl=original,timestamp&collapse=urlkey&limit=200"

Then plain-`curl` the snapshot. This is how Chadwick's dead `/priorities/` page (with her staff-diversity
plank and Youth Truth disparity data) and Tatom's 2019 `/99-2/` Issues page (with her Student Success
Act endorsement — the basis of her only scorable row) were recovered. Both are cited as `web.archive.org`
URLs, which re-fetch fine.

- `r.jina.ai` is **blocked** for `web.archive.org` (AbuseAlleviationError, "until 2035"). Use plain curl.
- WordPress **accordion/tab markup** hides the planks: neither the summariser nor a naive
  `sed 's/<[^>]*>//g'` surfaces them. Extract with `grep -oE '>[^<>]{60,}<'` over the raw HTML.

## Ballotpedia

No articles exist for Bend-La Pine school board directors. Confirm with
`curl -A "<browser UA>" https://ballotpedia.org/<First_Last>` and check `wgArticleId` in the inline
`RLCONF` blob — **`wgArticleId: 0` with an HTTP 200 means genuinely absent, not walled.** Separately,
`r.jina.ai` blocks ballotpedia.org outright. Don't spend a second wave re-checking.

## Bend-area outlets

- `lite.duckduckgo.com/lite/?q=` via `r.jina.ai` works reliably and is the best discovery tool here.
  Note it returns **"No results found"** for over-specific quoted/boolean queries — always retry with
  fewer operators before concluding evidence doesn't exist.
- **`bendbulletin.com` is the best local source and is not paywalled** through `r.jina.ai`. It prints
  *attributed direct quotes* from candidate forums. `centraloregondaily.com` covering the same forum
  gave only reporter's indirect speech — same event, one source usable for quotes and one not. Always
  prefer The Bulletin for `sources[0]`.
- `centraloregondaily.com` did **not** 429 on 2026-07-24 (earlier waves saw rate limits) — retry it.
- `kinafororegon.com` ModSecurity **406s** `wp-sitemap.xml` and `wp-json/*`; page HTML is fine.

## Environment

No `python` on this box (the shim opens the Microsoft Store). Use `sed`/`awk`/`grep`, `pdftotext`
(`/mingw64/bin`), and `node -e` for JSON validation.
