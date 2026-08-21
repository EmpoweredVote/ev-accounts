---
name: project_colorado_springs_county_chair_no_questionnaire_geitner
description: County commissioner with a documented KRCC survey refusal, sourced entirely from KOAA search — worked example of a strong seat (local-immigration=5) and a genericness-forced skip (public-safety tax renewal)
metadata:
  type: project
---

Subject: Carrie Geitner, El Paso County Commissioner D2, 2026 Board Chair. KRCC 2024 guide
records her as "candidate did not fill out survey" (a documented refusal, distinct from a
collection gap — do not treat it as a hole to fill from other sources at any cost).

## What worked

- `koaa.com/search?q=<Name>` surfaced her by name directly (unlike other county officials in
  this cohort where koaa.com only returns institution-level coverage). Two of the three hits
  were gold: a public-safety sales-tax article and an ICE-lawsuit article, both with her quoted
  by name and title ("Vice Chair and District 2 County Commissioner" / "Chair of the ... Board
  of County Commissioners").
- The dispatch's two leads (ICE lawsuit, Nov 2025 public-safety tax) were BOTH real and both
  produced an individually-attributed quote — but only one was usable (see below). Trust
  specific dated leads handed to you; they were pre-verified by whoever wrote the brief.
- Re-fetching the same URL twice with the strict "only text inside quotation marks" instruction
  reproduced BOTH quote sets identically — a genuine confirmation, not a coincidence to be
  suspicious of. When it reproduces clean, use it.
- `?s=` search worked fine on `coloradopolitics.com` for this subject (unlike the brief's general
  warning that outlet `?s=` endpoints are often dead) — it surfaced two more articles (an Xcel
  Energy powerline permit denial, and a Cami-Bremer-departure piece) neither of which panned out
  substantively, but the search itself returned real content. `pikespeakbulletin.org` and
  `socoinsider.com` were confirmed empty/irrelevant for her specifically, matching the brief's
  general county-officials warning.

## The seat: local-immigration = 5

Her ICE-lawsuit quote is forward-looking policy reasoning, not a vote record: she said the county
board authorized joining Douglas County's suit against HB19-1124/HB23-1100 because those laws
prevent the sheriff from **contracting with the federal government to help arrest and detain
individuals** — i.e., restoring the ability to actively participate in immigration
enforcement/detention operations (287(g)-style), not merely "share information when federal
agencies request it" (chair 4). The forward-looking sentence used as `quote_text` ("Ultimately, we
want to see the laws overturn so that we can provide more safety...") needed ZERO de-identification
edits — it contains no name, title, or party, so `quote_deidentified` was an exact verbatim copy.
Don't over-edit a quote that's already clean; marking a cut or bracket that isn't needed is its own
dishonesty.

## The skip: public-safety-approach / jail-capacity (tax renewal)

The Nov 2025 public-safety sales-tax vote (5-0) was, per the dispatch, the one item she spoke on
individually — and she did produce an individually-attributed quote. But investigating the actual
ballot measure (a flat RENEWAL of an existing 0.23% rate first passed in 2012, extending 2029→2037,
funding EXISTING sheriff deputies/jail operations/wildland fire, not new capacity or new positions)
plus her quote's own content ("critical that our Sheriff's Office **continues** to receive the
necessary funding") showed this was generic get-out-the-vote messaging for a status-quo renewal,
not a substantive articulation of ANY of the five `public-safety-approach` chairs. Chairs 2 and 3
are both compound ("maintain staffing + shift calls to co-responders" / "keep funding + add crisis
teams") and neither addition was evidenced; chair 4 requires an INCREASE, which a flat-rate renewal
is not. Lesson: **"the one commissioner who spoke on it" having a real quote is not the same as that
quote answering the ladder's actual axis** — check what the underlying ballot measure/bill actually
DOES (renewal vs. expansion) before assuming a funding vote seats a funding-level chair.

## Other dead ends specific to her

- `elpasoco.com/carrie-geitner/`, `bocc.elpasoco.com/carrie-geitner-district-2/` — both 404,
  guessed URL patterns don't exist for this office.
- `krcc.org` / `www.krcc.org/2024-election-guide` redirects to `cpr.org` (301) — same WAF-dead
  domain as always; don't chase the redirect.
- `lwvpph.org` and `lwvpikespeak.org` — both DNS-fail (`ENOTFOUND`), not just 403. The LWV
  Commissioner-District-2 forum video mentioned in KRCC's guide has no locatable written
  transcript/report anywhere tried; video-only, so unusable per brief rule.
- A quasi-judicial rezoning vote ("Commissioners deny controversial rezoning request north of
  Colorado Springs") recorded her vote by name but carried NO quote from her at all — confirms
  the brief's rule 2 that a bare land-use vote is not fetchable-into a stance even when you go
  looking for the policy-level statement that would rescue it.
- An Xcel Energy transmission-permit denial (`coloradopolitics.com`, Jul 2025) quoted her being
  "disturbed" at the company's dismissiveness toward local authority — procedural/jurisdictional
  concern about how a company treated county government, not a policy statement on energy,
  climate, or environment. Doesn't seat `local-environment`, `climate-change`, or `fossil-fuels`
  despite looking topically adjacent.
- `vote411.org` — 403 for the ballot lookup URL tried.

Net: 1/22 seated (local-immigration=5) for a subject with no questionnaire, from name-searchable
KOAA coverage as sitting Board Chair. This is a normal, honest yield — resist stretching the
tax-renewal quote to fill a second row.
