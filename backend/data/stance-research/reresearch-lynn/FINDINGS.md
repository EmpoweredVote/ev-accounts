# Lynn MA — re-research of the 30 rows retired by migration 1564

**Date:** 2026-08-06 · **Outcome: 0 of 30 assignable. No migration written.**

This is the only cluster in the re-research programme that yields nothing, and the reason is worth more
than the rows would have been.

## 🔴 Lynn does not publish council agendas or minutes to the public web

Every route was tried and each was closed:

| Route | Result |
|---|---|
| `lynnma.gov/city_government/citycouncil/archive` | Rendered with Playwright. Contains **one link — a council group photo**. No documents. |
| `lynnma.gov/city_government/citycouncil/meeting/` | Raw HTML contains an "Agenda & Minutes … Documents Loading … Add / Display Settings / Security / Activity" block — a CivicLive **admin** component. Rendered with Playwright and waited 15s: the public page contains **only the meeting-date schedule**, 1,848 characters. No document list, no iframe, and **no network request to any document-listing endpoint** (26 candidates inspected, all scripts and stylesheets). |
| Legistar | No client. `webapi.legistar.com/v1/{lynnma,lynn,cityoflynn,lynnmass}` all return **500**. |
| `lynnma.gov/city-council/minutes` (the retired citation) | Composed path — it is the shape 1564 retired, and there is no real page behind it. |

⚠ `lynnma.gov` runs **CivicLive behind Cloudflare**; several paths 403 to a plain fetch. That is a bot
block and proves nothing on its own — the pages above were reached with a browser UA and, where it
mattered, with a real browser. **The absence here is verified, not inferred from a 403.**

## 🔴 The press that would substitute is paywalled or fabricated

* **`itemlive.com` — The Daily Item of Lynn — is real, live, and the city's paper of record.** It is
  also **paywalled and fails open**: the article on the council's May 2026 vote returns HTTP 200 and
  35 KB, of which the story is a single lede ending in an ellipsis. This is the
  `beverlyhillscourier` pattern — a 200 that looks like content and is not.
  ⚠ WebFetch gets **403** from itemlive; `curl -A` gets the lede. Classify before concluding.
* **`lynnjournal.com` is a REAL, LIVE outlet** (HTTP 200) whose cited paths were fabricated — the
  fourth instance of that shape after `lowellsun.com`, `sgvtribune.com` and `dailybreeze.com`.
  **Do not host-block it.**
* `lynnincommon.com` (the city's zoning-rewrite site) is real and substantive — it records that
  **Lynn reached MBTA Communities compliance on 2025-05-12** — but it names no individual official, so
  it is the attribute-prior class and supports no member's chair.

## What was verified, and why it still is not enough

The one council action reachable in full is the lede of the 2026-05-12 Item story: *"In a unanimous
vote, the city of Lynn became a member of the North Shore Resolutions Project…"*, introduced by
**Councilor Brian LaPierre**, whom the paper describes as "an outspoken advocate for immigrant
protections in Lynn."

That does not support a row, for three separate reasons — any one of which would be enough:

1. **The resolution's accessible subject is resisting federal overreach generally, not local
   immigration enforcement.** The compass chairs for that topic are specifically about detainers,
   information sharing and police cooperation with ICE. Matching on the topic's *title* rather than its
   *chair texts* is the error that nearly produced two bad Carson rows.
2. **"Unanimous" is not per-member evidence** without an attendance roll — the standing rule from the
   Beverly Hills cluster.
3. **LaPierre is not owed Local Immigration Enforcement** in the first place; his two retired rows are
   Affordable Housing and Economic Development Incentives.

A newspaper's characterisation of someone as an advocate is also not that person's stated position.

## The point worth keeping

**Lynn is the city where the fabrication had the most room to operate, precisely because there is no
public record to check it against.** 19 of the 30 retired rows cited `lynnma.gov/city-council/minutes`
— a page that has never existed, standing in for minutes that are not published. The generator invented
a plausible-looking citation for exactly the thing the city does not provide.

🔑 **Where a city publishes nothing, expect fabrication to be densest, and expect re-research to yield
nothing.** Absence of a public record is a predictor of the defect, not merely an obstacle to fixing it.

## Status

* **No migration written.** All 12 Lynn officials remain at zero answers.
* `hasContext` for Lynn stays **false** (flipped by 1564) — correctly: the city has no compass coverage.
* All 30 rows remain in the voter-visible gap.

**The one route that would unlock this cluster** is a subscription to The Daily Item, which covers Lynn
council votes in detail. That is a paid source, and the operator's standing ruling on this workstream is
**free sources only** — so this is a decision to take, not a gap to grind at. Nothing else found here
will move it.
