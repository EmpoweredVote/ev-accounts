---
name: boardbook-and-pdf-extraction
description: How to actually read BoardBook school-board minutes and voters'-pamphlet PDFs (DownloadPDF GUID pattern, URL-addressable search, pdftotext without -layout)
metadata:
  type: reference
---

Techniques proven on the Bend-La Pine Schools board wave (2026-07-24). Reusable for any district
that hosts minutes in BoardBook Premier, and for any Oregon county voters' pamphlet.

## BoardBook (meetings.boardbook.org) — org id is in the URL, Bend-La Pine = 2413

**Search is URL-addressable**, so skip the click-through entirely:
`https://meetings.boardbook.org/Search/Index/2413?q=<terms>&i=4&i=8&i=9`
(`i=4` agenda items, `i=8` files/documents, `i=9` meetings; supports quoted phrases and `OR`).
Searching `"Director <Full Name>"` finds every meeting where the clerk recorded that person speaking —
the fastest way to tell a substantive director from a ceremonial one.

**Minutes are NOT HTML.** `/Public/Minutes/2413?meeting=N` redirects to
`/Documents/CustomMinutesForMeeting/2413?meeting=N`, which is an empty shell wrapping an Apryse
WebViewer iframe; `innerText` returns only page chrome. Get the real file with:

    https://meetings.boardbook.org/Documents/DownloadPDF/<GUID>?org=<orgId>

`<GUID>` is the id in the `href` of a search result (`/Search/GoToResult/<GUID>`). Cite this URL — it
is stable and re-fetchable.

## Reading the PDFs

`WebFetch` **cannot** extract text from these — it returns "binary/compressed, cannot extract" every
time. But it **does** save the file to the session `tool-results/` directory and prints the path. Two
working follow-ups:
- `Read` tool (vision) — fine for scanned/image pages.
- `pdftotext`, already installed at `/mingw64/bin/pdftotext` (v4.00, via Git Bash). Faster and gives
  exact text for `grep`-verifying a quote.

**Run `pdftotext` WITHOUT `-layout` when the source is a multi-column voters' pamphlet.** `-layout`
preserves columns but mangles letter-spaced text (`-closing` came out as `-c losing`) and hyphen-breaks
sentences across lines, which makes exact-substring quote verification fail. Plain `pdftotext` joins
each paragraph into one clean line. Always confirm a candidate quote with
`grep -c "<quote>" out.txt` before recording it.

Oregon county voters' pamphlets are text-layer PDFs (not scans) and carry **first-person candidate
statements** — the best available source for unopposed local candidates who get no press questionnaire.
Deschutes May 2025:
`https://www.deschutescounty.gov/DocumentCenter/View/2929/May-20-2025-Special-District-Election-Voters-Pamphlet`

**The pamphlet is on `deschutescounty.gov`, NOT `webapps.deschutes.org`.** The latter
(`/elections/Home/List`) publishes results only, and it is easy to conclude from it that no pamphlet
exists. It does. Also note the two county domains are different hosts — `deschutes.org` vs
`deschutescounty.gov`.

**Earlier pamphlet editions are hard to find.** For the May **2023** special district election I could
not locate an English edition anywhere: not on DocumentCenter, and the Oregon SOS records system
(ORMS/WebDrawer, `records.sos.state.or.us/ORSOSWebDrawer/`) exposes only *translations* in its
sequential ID block 9590806–9590874 (ordered language-then-county; e.g. 9590866 = Vietnamese
Deschutes 2023). WebDrawer's own query endpoint
(`/Record?t1=title&q1=<phrase>&op1=AND&arch=0&page=1&size=200`) returns an empty ~4.5KB results page
for every phrase tried, so do not trust its search to prove absence. Untried: the Laserfiche repo
`weblink.deschutes.org/CLK/Browse.aspx?id=1051&dbid=0&repo=LFCLK`, or browsing ORMS by container.

**What the per-director name search actually yields on Bend-La Pine (checked for all 7 directors'
zones 5-7):** nothing substantive. Minutes here record roll-call attendance, a one-line
*institutional* discussion summary ("Board members had an opportunity to ask questions…"), the motion
text, and the tally — never a director's reasoning. Hits for a director are ceremonial: reading
Teacher Appreciation / Classified Employee Appreciation resolutions, reading the Welcoming Week
Proclamation, leading the Pledge, adjourning. **Budget time on forum coverage and archived campaign
platform pages instead; use the name search to confirm a skip, not to find a stance.**

## Traps confirmed on this wave

- **Unopposed candidates are evidence deserts.** No questionnaire from The Bulletin or Bend Source, and
  LWV forums cover only contested zones. Expect honest-zero for them and say so.
- **`citizenportal.ai` links rot** and it is an AI summarizer — usable only as a pointer to a real
  primary document, never as a source.
- **oregonlegislature.gov testimony is not name-indexed** by DuckDuckGo; site-scoped name searches
  return zero even when the testimony exists. Found one only via a plain-name search.
- centraloregondaily.com / bendbulletin.com / bendsource.com all need the `r.jina.ai/<url>` proxy.

See also [[school-board-axis-drift-traps]].
