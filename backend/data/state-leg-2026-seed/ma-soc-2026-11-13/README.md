# Massachusetts' own ballot, read 2026-11-13

`candidates.tsv` is the legislative half of the Secretary of the Commonwealth's **2026 State
Election Candidates** page:

<https://www.sec.state.ma.us/divisions/elections/research-and-statistics/2026-state-election-candidates.htm>

One row per district, pipe-separated: `U|L` for the chamber · the district exactly as the
Secretary prints it · the candidates' names with accents folded, case dropped and every space
and punctuation mark removed. **200 rows — 40 senate and 160 house — and the extraction
dropped no line.**

## 🔴 It had to be read in a browser, and a bare fetch looks like it worked

`sec.state.ma.us` sits behind an Incapsula WAF. `curl`, with browser headers and a cookie jar,
answers **HTTP 200 with a 212-byte challenge page** that carries no candidate at all, and a
redirect loop before that. Neither is a status code you can judge. The page was read with
Playwright instead.

## ⚠ Two things in this file are deliberately NOT a source for anything

- **The party column is dropped.** The Secretary prints `name, address…, party`, the address
  holds commas, and the party is sometimes missing — so the last comma-separated field is the
  party for most rows and the home town for a few ("Barnstable", "Brockton", "Worcester").
  Nothing here needs it: party in this repo lives on `races.primary_party`, never on a
  candidacy, so the ambiguity costs nothing. It is recorded here so nobody later reads that
  column as a party.
- **Names are squashed, so this file cannot be a source for how a name is spelled.** It exists
  to answer one question: is the same set of people on the Secretary's ballot and on AP's?

## How the extraction decided what a district header is

A header is a line that ends in `District` **and carries no digit**; every candidate line
carries a street number. The obvious rule — "a header has no comma" — is wrong here and
silently ate five senate districts whose names list three counties
("Berkshire, Hampden, Franklin & Hampshire"), folding each one into the previous district as a
candidate named "Hampden". That mis-parse produced a complete, plausible, wrong table.
