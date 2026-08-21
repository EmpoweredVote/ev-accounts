---
name: project_colorado_springs_appointee_and_legistar_api
description: How Ken Casey (D2 appointee, no campaign) still yielded 2/22 chairs via his council-vacancy application, and that Legistar's WebForms UI is un-fetchable but its attachments ARE reachable once you have the direct legistar2.granicus.com attachment URL.
metadata:
  type: project
---

## Appointees with no campaign still have a first-person record: the vacancy application

Ken Casey was appointed (not elected) to Colorado Springs Council D2 on 2026-04-06, so there is no
campaign questionnaire (no CPR/KRCC file for him). Initial pass (WebFetch only, no Legistar API)
correctly returned **zero rows** — a real KOAA article confirmed a compiled "candidate responses"
document existed but every WebFetch attempt to reach it 404'd or hit Legistar's WebForms UI, which
requires interactive postback (dropdowns + search-box submit) and cannot be driven by a plain GET.
**That zero was the right call on the evidence available at the time** — see
[[feedback_predicate_shape_not_value]] pattern: don't confabulate, report the gap instead.

**The gap was closed by the orchestrator, not by a different WebFetch URL guess**: it used the
**Legistar Web API** (not the WebForms calendar UI) to resolve event ID 2840 (the 2026-04-06 special
meeting) and pull the agenda item's attachment metadata, landing on a direct
`legistar2.granicus.com/<jurisdiction>/attachments/<uuid>.pdf` URL. That URL IS fetchable/Readable
as an ordinary PDF once you have it — the blocker was discovery (finding the ID), not access.
**Lesson for next appointee/vacancy case:** if a "compiled candidate responses" or similar packet is
referenced by a news article but not linked, say so explicitly in the report rather than declaring
the topic permanently dead — it may be one Legistar API call away (a job for an agent/orchestrator
with API access, not more WebFetch URL guessing on the WebForms UI).

## What the application packet yielded (Casey, pages 8-11 of the 25-applicant PDF)

Ten questions total. Only **2 of 10 answers were chair-grade** for the 22-topic local scale; the
rest either don't map to any topic (parks funding, CSU utility rates, staff engagement, personal
qualifications) or **failed the deference test**:

- **Seated:** `growth-and-development` = 2 — "it is vital to ensure development does not outpace the
  ability of City services to support" is his own stated principle (growth capped by capacity), not
  a pointer to a plan.
- **Seated:** `public-safety-approach` = 4 — "maintaining a steady flow of new police officers &
  firefighters through their respective COS academies is critical" is a staffing/funding-increase
  position, cleanly distinct from chair 3 (crisis-response teams, which he never mentions).
- **Failed the deference test, correctly left blank:** `transportation-priorities` — his entire
  answer is "I would expect to address/prioritize any transportation needs in light of ConnectCOS"
  (the 2023 city transportation plan) — he never states whether he favors road capacity vs.
  transit/pedestrian investment, just defers to the adopted plan. Capital-infrastructure question
  similarly deferred to the "2025 Strategic Doing Action Items" list.
- Growth-and-development's own answer ALSO name-drops PlanCOS/AnnexCOS ("great opportunities to
  engage the public to solidify an approach") — that clause is deference and was NOT what earned the
  chair; the chair rests on the separate, self-articulated "does not outpace... ability to support"
  sentence in the same paragraph. **A single answer can contain both a deferred clause and a
  self-stated position — read the whole paragraph, cite only the load-bearing sentence.**

Applies to any future Colorado Springs (or other Legistar-jurisdiction) appointee: check for a
vacancy-application packet before writing off a topic as unsourceable.
