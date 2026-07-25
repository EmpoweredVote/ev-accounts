---
name: school-board-axis-drift-traps
description: The specific wrong-axis temptations that appear on school-board stance research, and which board artifacts are real evidence vs. institutional noise
metadata:
  type: feedback
---

On school-board cohorts, the dominant failure mode is **axis drift** — grabbing a document that is
adjacent to a topic and scoring it as if it were on the topic. Skip instead.

**Why:** in an earlier Bend-OR wave, 14 of ~57 agent-produced rows were rejected on spot-check, and one
rejection was literally a county employee health-plan vote scored as an abortion-legality stance. The
operator re-fetches every source and string-matches every quote, so a wrong-axis row costs more than a
missing row. A person with zero stances is an explicitly acceptable outcome.

**How to apply** — the recurring near-misses, all confirmed real on Bend-La Pine:

- A **trans/LGBTQ+ affirming resolution is not a `trans-athletes` position** unless it actually names
  athletics, sports, teams, or participation eligibility. Read the resolution body; Bend-La Pine's
  Resolution 1985 never does. Check the board's minutes for OSAA / eligibility action separately.
- **"I support public schools" / "advocate for funding of public education" is not an anti-voucher
  position.** Every board member says it; it discriminates no chair on `school-vouchers`.
- **Public open-enrollment regulations** ("Choice Option Programs", intradistrict transfer) and
  **public charter renewals** are not private-school voucher positions. A unanimous, staff-recommended
  charter renewal with no director argument cannot discriminate voucher chairs 2/3/4 — skip.
- The annual **"Resolution to Impose Tax"** and **"Resolution Making Appropriations"** are statutorily
  required ministerial acts. They are not `taxes` positions. Expect to skip `taxes` for board members.
- A district **running** a preschool or after-school program is institutional activity, not a
  `childcare` stance. So is a **school-based health center** funding bill — that is youth mental
  health, not childcare cost or availability.
- **Special-education or general funding advocacy** is about spending levels, not about who pays —
  wrong half of the `taxes` scale.

- **The Board Chair is the highest-risk person in the cohort.** The Chair appears in the most
  sources, but almost always *announcing* or *reading* board action — which is institutional
  attribution, not a personal position. Reading a resolution aloud is ceremonial, not authorship
  (Chadwick read both Res. 1982 on undocumented students/ICE and Res. 1985 on transgender students;
  neither is her stance). Expect the Chair to end up with the FEWEST scorable rows despite the most
  coverage. Confirmed on Amy Tatom: every BoardBook hit was ceremonial.
- **"Advance equity and inclusion" as a bare platform bullet** has no mechanism. It corroborates a
  civil-rights row built on a real quote; it cannot carry one alone.

**Which of the five board topics actually land** (Bend-La Pine, 3 directors, 15 cells → 3 rows):
- `civil-rights` is the most likely to land, because the Feb-2025 federal directive to end district
  DEI forced board candidates to state a position out loud. Defending an active equity program **plus**
  naming achievement-gap closure for underserved students = chair 2, discriminable from chair 3's
  passive "maintain current laws / equal opportunity."
- `taxes` occasionally lands via an old campaign page endorsing a **named enacted state revenue law**
  with known incidence (e.g. Oregon's Student Success Act → Corporate Activity Tax, businesses over
  $1M Oregon commercial activity, revenue to the Fund for Student Success). A named law with a real
  mechanism discriminates chairs even when the page is years old; a vague "fund our schools" bullet
  does not, and a bond referral never counts.
- `school-vouchers`, `childcare`, `trans-athletes` were **structurally empty** for all three. Oregon
  has no voucher program, so a board member has had no occasion to take a position. Do not grind on
  these three absent a new state ballot measure.

**What DOES count:** the director's own roll-call vote; who **moved** or **seconded** a resolution
(named in both the minutes and the resolution's signature block); a director's own amendment request;
their own first-person voters'-pamphlet platform. What does NOT count: minutes of a *briefing*, a
superintendent's report, a staff presentation, or a policy that merely took effect during their term.

**Quotes:** minutes are written in the clerk's indirect speech ("Director X requested that…"). That is
never `quote_text`. Put it in reasoning and in `quote_deidentified`; leave `quote_text` empty. This
specific error recurred twice in earlier waves despite an explicit warning.

See also [[boardbook-and-pdf-extraction]] for how to get at the underlying documents.
