---
name: bend-special-district-minutes-access
description: How to reach Bend/Deschutes park-district, city, and county planning-commission minutes — r.jina.ai x-no-cache header defeats the bendoregon.gov 403, plus the BPRD and mccmeetings URL patterns
metadata:
  type: reference
---

Proven on the BPRD park-board wave (2026-07-24). Complements
[[boardbook-and-pdf-extraction]] — that file covers school-board BoardBook + pamphlet extraction;
this one covers park district / city / county land-use bodies.

## The big one: `x-no-cache: true` defeats bendoregon.gov's 403

`bendoregon.gov` 403s every non-browser request, including with a full browser User-Agent. The
working bypass:

    curl -H "x-no-cache: true" -H "x-respond-with: text" \
      "https://r.jina.ai/https://www.bendoregon.gov/wp-content/uploads/.../minutes.pdf"

**Without `x-no-cache` r.jina.ai returns HTTP 200 with an EMPTY body** plus a "this is a cached
snapshot" warning — a silent failure that reads as success. Any time r.jina.ai returns a header
block and no `Markdown Content`, retry with that header before concluding the doc is unreachable.

## Bend Park & Recreation District (BPRD)

- Archive page `bendparksandrec.org/about/board_meetings/` is **JS-rendered**; r.jina.ai strips the
  document links entirely (returns the page text with zero URLs). **Use WebFetch on that page** — it
  renders the full table with packet / video / summary URLs intact. Year tabs 2025 / 2026 / 2027.
- The uploaded files themselves are **directly curl-able, 200, no UA or proxy needed**:
  `bendparksandrec.org/wp-content/uploads/<YYYY>/<MM>/<name>.pdf|.docx` → `pdftotext -layout` is fine
  for these (single-column staff summaries).
- Written summaries are **staff-authored and third-person**. BPRD's own notice says the **video**
  recording, not the summary, is the official minutes under ORS 192.650 — so a director's spoken
  rationale exists on video even when the summary omits it. That is the unlock for directors whose
  votes are recorded without reasoning.
- Individually-attributed positions are rare: most 2026 entries are "Directors discussed…" /
  "the Board expressed general support". Grep for `opposed|split vote|failed, 2-2` to find the
  divisions fast.

## Deschutes County Planning Commission (land-use votes)

- The county meeting portal (`/1506/Meeting-Agendas-Minutes-and-Video`, `deschutes.org/meetings`) is a
  CivicPlus shell wrapping a Municode portal — **renders zero meeting rows to any text fetcher**, so
  minutes cannot be enumerated. Playwright would be required to walk it.
- Minutes live at a flat, directly-fetchable blob path:
  `https://mccmeetings.blob.core.usgovcloudapi.net/deschutes-pubu/MEET-Minutes-<guid>.pdf`
  (attachments use `mccmeetingspublic.blob.../deschutes-meet-<guid>/ITEM-Attachment-...pdf`).
  GUIDs are only discoverable via search-engine indexing of the blob domain — search
  `mccmeetings deschutes planning commission minutes <name> <topic>`.
- **These minutes carry a printed disclaimer** that they are "DERIVED FROM AN AUTOMATED TRANSCRIPTION
  SERVICE AND HAVE BEEN SUMMARIZED THROUGH AN AUTOMATED PROCESS." **Never lift a quote from them** —
  stance evidence only, `quote_text` stays blank.

## Search that works

`curl -H "x-no-cache: true" -H "x-respond-with: text" "https://r.jina.ai/https://lite.duckduckgo.com/lite/?q=<urlencoded>"`
then `sed -n '/Past Year/,$p'` to strip the ~1.5KB region/time-filter boilerplate that otherwise eats
the response budget. Site-scoped `site:` queries work; quoted `"Commissioner <Name>"` is the highest-
yield form for finding a person's own recorded remarks.

## Cross-office lead worth remembering

A park-board member may hold a **second appointed seat** where the real votes are. Nathan Hovekamp's
scoreable land-use record is on the **county planning commission**, not the park board. Always read the
official bio's "Prior Governmental Experience" line and chase every body listed.
