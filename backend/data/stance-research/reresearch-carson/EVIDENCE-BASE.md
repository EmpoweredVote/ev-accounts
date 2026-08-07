# Carson CA — evidence base for the 34 rows retired by migration 1564

**Date:** 2026-08-06 · **Status:** evidence base established, NO rows re-researched yet.
Written so the next pass does not rediscover any of this.

## What is owed — 34 rows, 5 members, 9 topics

| Member | Owed |
|---|---|
| Lula Davis-Holmes (Mayor) | 9 — Homelessness, Affordable Housing, Public Safety, Econ Dev Incentives, Env Protection vs Development, Growth & Development Pace, Taxes, Transportation, Local Immigration Enforcement |
| Jim Dear (District 2) | 8 — as above minus Transportation and Env/Growth variance |
| Cedric L. Hicks Sr. (District 3) | 6 |
| Arleen B. Rojas (District 4) | 6 |
| Jawane Hilton (District 1) | 5 |

By topic: Homelessness 5 · Affordable Housing 5 · Public Safety 5 · Env Protection vs Development 5 ·
Local Immigration Enforcement 5 · Econ Dev Incentives 4 · Growth & Development Pace 2 · Taxes 2 ·
Transportation 1.

**Roster verified 2026-08-06** against `ci.carson.ca.us/Government/CityCouncil.aspx` — all five match
exactly, including Jim Dear at District 2 (he is genuinely seated; an earlier suspicion of mine that he
was a stale entry was wrong).

## Why nothing is re-pointable

All 16 retired sources were fabricated. Thirteen are `dailybreeze.com` article paths — **a real, live
outlet carrying invented paths, the same shape as `sgvtribune.com` (Alhambra) and `lowellsun.com`
(Lowell)** — plus `precinctreporter.com`, a `latimes.com` path, and two `carsonca.gov` 404s.

⚠ `carsonca.gov` **resolves and returns 200** — it is a real host; only the cited paths are dead. The
city's primary site is `ci.carson.ca.us`. Do not host-block either.

⚠ The Local Immigration Enforcement rows rested on a claimed 2017 "Trust Act resolution"
(`dailybreeze.com/2017/03/03/carson-city-council-immigration-resolution-trust-act/`). **Carson's Legistar
contains no immigration or sanctuary matter at all** — `substringof('immigration',MatterTitle)` returns
0, and the only `sanctuary` hit is a pastor's church name from 2016. Treat that resolution as unproven
until a primary record is found; the topic may have to stay blank for all five.

## The evidence base — split across two systems, and Legistar is STALE

### 1. Legistar — good, but ends 2024-09-17
`carson.legistar.com` · **73 minutes PDFs**, calendar spans **2023-01-03 → 2024-09-17**. Nothing later.

🔴 **The Legistar Web API is open and unauthenticated**: `https://webapi.legistar.com/v1/carson/…`
(`persons`, `matters`, `events`, `eventitems`). `$filter=substringof('homeless',MatterTitle)` works and
is far faster than reading PDFs for *finding* the right meeting.

🔴 **But Carson publishes NO structured vote data.** `matters/{id}/histories` returns `[]`;
`events/{id}/eventitems` returns items with `EventItemPassedFlag = null`, no mover, no seconder, on all
76 items sampled. Minutes status on every event is **"Draft"**. **Use the API to locate items, then read
the minutes PDF for the actual vote.** Do not expect roll calls from the API.

✅ **The minutes PDFs do carry full roll calls and per-member discussion**, e.g.:
> `ACTION: It was moved to approve staff recommendation on motion of Hicks, seconded by Hilton and
> unanimously carried by the following vote:` … `Ayes: / Noes: Abstain: Absent:` … then the five names,
> then `None None None`.

🔴 **SAME VOTE-BLOCK TRAP AS ALHAMBRA, AND IT SURVIVES PLAIN `pdftotext`.** The labels
(`Ayes:` `Noes:` `Abstain:` `Absent:`) are emitted as one run and the values as a separate run. A naive
"names on the line after `Noes:`" read assigns every aye to the noes. **Map positionally — first value
run belongs to `Ayes`, and confirm against the "unanimously carried" narrative in the same ACTION line.**
See the Alhambra FINDINGS.md for the version of this that nearly published inverted votes.

### 2. AgendaLink — current, but JS-rendered
2025–2026 meetings moved to `horizon.agendalink.app/carsonca/…`. Plain fetch returns a **12-character
shell** ("AgendaLink") — a JS app, not an empty page. `read-site-js.mjs` (Playwright) is the tool.
Packets are also served as direct PDFs from
`s3.us-west-004.backblazeb2.com/agendalink-pdf/carsonca/pdfs/packets/<id>/<Meeting>_packet.pdf`.
⚠ `horizon.agendalink.app/carsonca` (bare) 404s — the path needs a document id.

## Recommended order for the next pass

1. Legistar API keyword search per topic → collect MatterIds and agenda dates.
2. Pull only the minutes PDFs for those dates (not all 73).
3. Read votes positionally; confirm each against the ACTION narrative.
4. For 2025–2026 currency, render AgendaLink with Playwright or pull the S3 packet PDFs.
5. Expect Local Immigration Enforcement to stay blank for all five unless a primary record surfaces.

Useful matters already located:
* `2024-0697` (2024-08-06) — initiate a **Homeless Employment Initiative Program**
* `2023-0833` (2023-11-07) — Resolution 23-178, allocate **$276,486.67 PLHA grant** funds
* `2022-1013` (2023-01-03) — Housing Authority funds for **homeless prevention and rapid rehousing**
* `2024-0312` (2024-05-07) / `2023-0186` (2023-03-21) — annual **Housing Element** progress reports
* `2024-0531` / `2024-0532` (2024-07-02) — **oppose AB 1886 and SB 1037** (housing element enforcement)
* `2024-0580` (2024-07-02) — **oppose-unless-amended AB 3093**
