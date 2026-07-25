# Wave 6 — Bend-La Pine Administrative School District 1, Zones 5/6/7

Researched 2026-07-24. Topic scope: `school-vouchers`, `childcare`, `civil-rights`,
`trans-athletes`, `taxes` only (per `_TOPIC_SCALE_BOARDS.txt`).

Result: **3 stances / 3 people / 3 quotes** (1 each). 12 of 15 person-topic cells honestly skipped.

---

## Method note — why so few rows

The single most useful discovery is a negative one: **BoardBook minutes for this district do
not record individual director arguments.** Verified by pulling an actual minutes PDF
(`meetings.boardbook.org/Public/Minutes/2413?meeting=746779` →
`/Documents/DownloadPDF/<guid>?org=2413`, the June 2 2026 special meeting). The format is
roll-call attendance, a one-line institutional summary of discussion
("Board members had an opportunity to ask questions of both the complainant and the district
before deliberating"), the motion text, and the Yea/Nay tally. Individual reasoning is never
transcribed. So minutes here yield **votes only**, and I found no vote in scope on any of the
five topics.

I then ran BoardBook's URL-addressable search per director
(`/Search/Index/2413?q=%22Director%20<Full%20Name>%22&i=4&i=8&i=9`), which is the fastest way to
separate a substantive director from a ceremonial one. Result for all three: **no substantive
recorded comment on any of the five topics.**
- **Tatom** — every hit is ceremonial or procedural: reading Teacher Appreciation resolutions (1987
  in 2025, 1963 in 2024, 1947 in 2023), reading Resolution 1960 Classified Employee Appreciation
  Week, reading the 2023 Welcoming Week Proclamation in English, leading the Pledge, adjourning the
  meeting. This is exactly the Board-Chair institutional-attribution pattern — most appearances,
  fewest positions.
- **Tomlin** — every hit is a minutes-attendance mention. Zero recorded remarks.
- **Chadwick** — she *read* Resolution 1982 (Affirming Rights of Undocumented Students / ICE access
  protocols, Jan 14 2025) and Resolution 1985 (Affirming Gender Identity, Expression, and Equity for
  Transgender and Gender-Expansive Students and Staff, Feb 11 2025). Reading a resolution aloud is
  ceremonial, not authorship — and per prior-wave verification Resolution 1985 never names
  athletics, so it is **not** `trans-athletes` evidence. Neither resolution's subject is in this
  wave's five topics regardless (immigration is out of scope for this office).

I also walked the 2025 spring agendas (`677225` 3/11/25, `681670` 4/8/25, `685585` 4/22/25,
`686318` 5/13/25) looking for a board DEI resolution to attach a roll call to. There is none.
The DEI-adjacent items are all **institutional briefings** — "Climate and Culture Task Force
Update", "Bullying Prevention within a Culture of Belonging" (staff presenters: Kinsey Martin,
Jennifer Hauth, Eric Powell) — which under hard rule 3 are not any director's stance. The
district's response to the Feb 2025 federal DEI letter was made by **Superintendent Steve Cook**,
not the board, so it is likewise unusable for these three people.

Consequence: every scored row below rests on the individual's **own first-person words**, from a
candidate forum or their own campaign site.

---

## Amy Tatom (Zone 5, Board Chair) — external_id -4101985

**1 stance: `taxes` = 1**

Sources fetched:
- `amytatom.com` (live) — 2023 re-election page. COVID reopening, school security bond, "safer,
  healthier, and more just". Nothing in scope.
- `web.archive.org/web/20190718043800/https://amytatom.com/99-2/` — her 2019 **"Issues"** page.
  **This is where the one usable row came from.** Content sits inside accordion markup, so
  neither WebFetch's summariser nor a naive tag-strip surfaces it; I extracted it with a
  `>text<` regex over the raw HTML.
- `web.archive.org/web/20190718054939/https://amytatom.com/home/` — 2019 Priorities page
  (educator burnout, safety net, inclusive learning environment for students with disabilities).
- `bendbulletin.com/2025/05/06/guest-column-.../` — her own guest column, full text.
- `bendbulletin.com/2023/04/26/editorial-fischer-tatom-and-justema-.../`
- `bendsource.com/opinion/vote-barnes-dholakia-chadwick-tatom-.../` (2023 endorsement)
- BoardBook minutes + 2025 agendas (see method note).

Skipped, with reasons:
- **civil-rights** — closest evidence is her 2025 guest column: "all our students, no matter their
  religion or gender identity, deserve to feel safe, loved and nurtured in our schools. Sadly,
  this idea — that excellence should be equitable — has become controversial." Two problems.
  (a) Axis: religion / gender identity / school climate is not the racial-and-social-inequality
  axis the topic asks about. (b) Even read charitably it cannot discriminate chair 2
  ("address systemic discrimination") from chair 3 ("maintain current civil rights laws while
  promoting equal opportunity") — there is no mechanism. Also note the sentence is written as
  "Every one of us on the school board is deeply committed to…", i.e. she is describing the
  board, which is the Chair-specific institutional-attribution trap. Skipped.
- **school-vouchers** — she advocates fully funding public schools, but the scale file explicitly
  warns that public-school enthusiasm is not an anti-voucher position. No statement or vote on
  vouchers, charters, or private-school funding found. Skipped.
- **childcare** — only hit is biographical (her 2019 bio notes her son attended preschool at
  Inspire Early Learning and received HDESD early-intervention services). Personal fact, not a
  position. Skipped.
- **trans-athletes** — nothing on athletic eligibility. Skipped.

Note on the taxes row: the evidence is **2019**, which is old. I kept it because it is not a vague
aspirational bullet — it is a first-person endorsement of a specific enacted revenue law with a
known mechanism and incidence (Corporate Activity Tax, >$1M Oregon commercial activity only,
revenue to the Fund for Student Success), which does discriminate chairs. The date is stated in
the reasoning so a reviewer can down-weight it. No later Tatom statement on tax level or
incidence exists that I could find.

---

## Ross Tomlin (Zone 6) — external_id -4101986

**1 stance: `civil-rights` = 2**

Sources fetched:
- `bendbulletin.com/2025/04/24/special-district-election-bend-la-pine-school-board-candidates-discuss-dei-challenges-ipads/`
  — Deschutes County League of Women Voters forum, 2025-04-23. **Best source in the whole wave.**
  Direct attributed quotes from both Tomlin and Chadwick. Used as `sources[0]` for both.
- `centraloregondaily.com/news/local/bend-la-pine-school-board-candidates-speak-out-on-dei-tech-policies-at-forum/...`
  — the same forum covered by Central Oregon Daily. Its DEI paragraph is **reporter's indirect
  speech** ("voiced broad agreement on several issues — including strong support for…"), so it is
  cited as corroboration only; no quote was taken from it.
- `bendbulletin.com/2024/11/13/ross-tomlin-named-to-bend-la-pine-school-board/` and
  `bendsource.com/news/bend-la-pine-schools-board-of-directors-fills-empty-seat-22189143/`
  — Nov 2024 appointment coverage. Biography and the 5-0 appointment vote; no positions.
- `deschutescounty.gov/DocumentCenter/View/2929/May-20-2025-Special-District-Election-Voters-Pamphlet`
  — his **own first-person statement** (p. 9-14). Under "With your vote, I will continue to" he lists
  "Advance equity and inclusion" alongside CTE expansion, student-centered learning, teacher support
  and "Use district resources wisely to prioritize success." Cited as source 2 on the civil-rights
  row. I did **not** take `quote_text` from it: `pdftotext` renders the bullet list as one run-on
  line, so a clean verifiable substring isn't available — the Bulletin forum quote is better.
  (His statement also carries an endorsement blurb from Amy Tatom; that is affiliation, not stance
  evidence, and was not mined.)
- `ktvz.com/news/bend/2025/02/13/five-bend-la-pine-school-board-candidates-announce-slate-.../`
  — the 5-candidate slate press release. Third-person campaign copy ("a commitment to fiscal
  responsibility and academic excellence"), joint, not his words. **Not used** — "fiscal
  responsibility" is not a position on tax level or incidence.

Skipped: **taxes** (his forum remarks about the budget are descriptive — 6% of the budget is
federal, legislative allocation unknown until June — not a claim about who should pay or whether
the overall level should rise), **school-vouchers**, **childcare**, **trans-athletes** (no
evidence at all on any of these three).

Followed the tip about his community-college background: searched for Tillamook Bay Community
College op-eds/columns and for any Tomlin statement on childcare. **Zero results both times.**
That lead is exhausted.

---

## Kina Chadwick (Zone 7) — external_id -4101987

**1 stance: `civil-rights` = 2**

Sources fetched:
- `bendbulletin.com/2025/04/24/special-district-election-.../` — LWV forum, her direct quote.
- `web.archive.org/web/20231209160530/https://kinafororegon.com/priorities/` — her 2023
  **Priorities** page. Not on the live site anymore; recovered via the Wayback CDX index. This is
  the substantive plank: educator/staff demographics vs. student demographics, Youth Truth survey
  disparities for students of color and LGBTQIA2S+ students, more counselors, peer mentorship.
- `deschutescounty.gov/DocumentCenter/View/2929/...Voters-Pamphlet` — her **own first-person
  statement** (p. 9-15), now cited as source 3 in place of her campaign About page (same text, but
  the pamphlet is the primary county-published document). Priorities: increase early literacy,
  "Ensure ALL students and staff experience belonging", reduce absenteeism, improve board/family
  connection.
- `kinafororegon.com/about-kina/` (live) and `kinafororegon.com/` (live) — biography and
  endorsements; carries the same "It's imperative to remain consistent and proactive in safeguarding
  ALL students and staff from far-right extremists" line as the pamphlet. First-person and
  forward-looking, but too unspecific about *which* axis to score on alone. Superseded by the
  pamphlet as a citation.
- `bendsource.com/opinion/vote-barnes-dholakia-chadwick-tatom-.../` (2023 endorsement).

Skipped: **trans-athletes** — this is the sharpest same-axis trap in her file and I deliberately
did not score it. She is Program Director at Gender Hive (trans-inclusive and gender-affirming
care), is endorsed by Basic Rights PAC and Stonewall, is a member of the LGBTQIA2S+ community, and
she **read Resolution 1985** (Affirming Gender Identity, Expression, and Equity for Transgender and
Gender-Expansive Students and Staff) aloud at the Feb 11 2025 meeting. None of that is a position on
athletic eligibility, which is what the topic asks — and reading a resolution aloud is ceremonial,
not authorship. Targeted searches for Chadwick + transgender/athletes/sports and for Bend-La Pine +
OSAA + trans athletes returned nothing. Per the scale file's own note, skipped.

Also skipped: **taxes** (her forum remarks describe the CFO's contingency budgets — institutional,
descriptive), **school-vouchers**, **childcare**.

---

## Sources that fought back

| Source | Behaviour | Workaround |
|---|---|---|
| **WebFetch + `r.jina.ai`** | The summariser model **refuses verbatim reproduction** ("guidelines prevent me from reproducing lengthy passages"). This silently destroys the ability to string-match quotes. | Switched to `curl -sL https://r.jina.ai/<url>` via Bash for every source, so I held the raw markdown and could `grep -F` each quote. All 3 quotes were verified as exact substrings before writing. |
| **Ballotpedia** | No articles exist for any of the three (`wgArticleId: 0` on all three name URLs). Separately, `r.jina.ai` is blocked for ballotpedia.org until 2026-07-25 with an `AbuseAlleviationError`. | Direct `curl` with a browser UA works and confirms the pages are genuinely absent. Dead end, not a fetch failure. |
| **`r.jina.ai` + web.archive.org** | Blocked with `AbuseAlleviationError` "until Sun Sep 30 2035". | Plain `curl` to `web.archive.org` works fine, including the CDX API (`/cdx/search/cdx?url=<domain>*`). Use plain curl for Wayback, never the jina proxy. |
| **kinafororegon.com** | ModSecurity returns **406 Not Acceptable** for `wp-sitemap.xml` and the `wp-json` REST API. | Page HTML itself fetches fine; enumerate pages via the Wayback CDX index instead. |
| **centraloregondaily.com** | Did **not** rate-limit this time (earlier waves saw 429). Fetched cleanly. | — |
| **BoardBook minutes** | Minutes render in a JS PDF viewer; the HTML contains no body text. | The document GUID is in a hidden input (`name="…DocumentID" value="<guid>"`); fetch `https://meetings.boardbook.org/Documents/DownloadPDF/<guid>?org=2413` and read the PDF. Meeting-ID→date map: parse `Agenda/2413?meeting=<id>` links off `/Public/Organization/2413` (offset is +20 chars, not +21 — easy off-by-one that silently truncates the leading digit). |
| **Deschutes County elections** | `webapps.deschutes.org/elections/Home/List` publishes **results only** — the voters' pamphlet is NOT there. I initially concluded no pamphlet existed; that was wrong. | It lives on the other county domain: `https://www.deschutescounty.gov/DocumentCenter/View/2929/May-20-2025-Special-District-Election-Voters-Pamphlet` (text-layer PDF, 2.7MB). Contains first-person statements for Tomlin (p. 9-14) and Chadwick (p. 9-15). Use `pdftotext` without `-layout`. |
| No Python on this box | `python` shim opens the Microsoft Store. | Used `sed`/`awk`/`grep` for all HTML stripping. |

---

## What would unlock more later

1. **YouTube `@blsschoolboard6373` recordings with auto-captions.** This is the only realistic path
   to individual director reasoning, because the written minutes structurally do not contain it.
   Auto-caption text is not quotable verbatim with confidence, but it would identify *which*
   meeting to then pull a clip from, and would support `quote_text: ""` rows with real sources.
   Highest-value next step by a wide margin.
2. **The Bulletin's 2023 candidate video interview with Tatom**
   (`facebook.com/bendbulletin/videos/.../5809634842498447/`) and the **City Club of Central Oregon**
   Zone 3 & 5 forum of 2023-04-26 (`cityclubco.org/bend-lapine-schools-zone-3-5-virtual-candidate-forum/`,
   Tatom vs. Sherrie Grieef, moderated by OPB's Joni Land). Both are video with no transcript found.
   Tatom is the person most likely to gain rows from these, since she is the one whose thin coverage
   is a sourcing artifact rather than genuine silence — she is a two-term Chair who simply has not
   been quoted on these five topics in text.
3. **The May 2023 Deschutes special district voters' pamphlet — the single most likely source of
   more Tatom rows**, since 2023 was her contested Zone 5 re-election and the pamphlet carries
   first-person candidate statements. I hunted it and did **not** find the English edition:
   - Not on `deschutescounty.gov/DocumentCenter` at any ID I could discover (the May **2025**
     edition is `View/2929`; a site-scoped search surfaces only a 2026 blank candidate-statement
     form at `View/3337`).
   - The Oregon SOS records system (ORMS/WebDrawer, `records.sos.state.or.us/ORSOSWebDrawer/`) **does**
     hold the 2023 May county pamphlets, but the sequential ID block 9590806–9590874 contains
     *translations only*, ordered by language then county. I could not locate the English block:
     the WebDrawer query interface (`/Record?t1=title&q1=...&op1=AND&arch=0&page=1&size=200`)
     returns an empty 4,556-byte results page for every phrase I tried, so its search is either
     differently parameterised or not indexing these titles.
   - Fallback pointer if someone wants it badly: **record 9590866** is the *Vietnamese* translation
     of the 2023 May Deschutes pamphlet and does contain Tatom's statement — but a translation
     cannot supply a verbatim English `quote_text`, so it is a locator only, not a citable source.
   - Next things to try: the Laserfiche repo `weblink.deschutes.org/CLK/Browse.aspx?id=1051&dbid=0&repo=LFCLK`,
     or ORMS browsed by container rather than searched.
4. **Tatom's `taxes` row should be re-checked** if she ever comments on Oregon school funding again
   — a 2025-26 statement would replace the 2019 basis and could confirm or move the value between
   chairs 1 and 2.
5. `school-vouchers`, `childcare` and `trans-athletes` look genuinely empty for all three, not
   merely under-searched. Oregon has no voucher program, so a Bend school board member has had no
   occasion to take a position; the district's "Choice Options" and its Desert Sky Montessori
   charter are intra-district public school choice, not vouchers, and routine charter/lottery
   administration is institutional activity either way. I would not spend more effort on these
   three topics for this board absent a new state ballot measure.

---

# VALIDATION PASS (orchestrator, 2026-07-24) — Tatom `taxes`=1 DROPPED, other 2 kept

All three quotes re-fetched and confirmed EXACT substrings. All secondary claims checked.
The single drop is a judgment call about what the verified evidence supports.

## Verified accurate
- Tomlin's forum quote is exact in The Bulletin. `"Advance equity and inclusion"` is genuinely
  in **Tomlin's own** pamphlet block — checked against the `(This information furnished by
  Ross Tomlin.)` delimiter, which mattered because **LeGrand's block uses the identical
  heading** "With your vote, I will continue to". Presence in the PDF would NOT have proven
  attribution in a two-column pamphlet; the delimiter check does.
- Chadwick's 2023 priorities page verifies in full: `"Currently, the demographics of our
  Educators and Staff do not represent the diversity of our students"` and the Youth Truth
  finding that LGBTQIA2S+ students and students of color give `"significantly less favorable"`
  responses about `"feeling welcomed"`. That is a measured group disparity plus a remediation
  mechanism — a sound chair 2.

## Corrected in Tomlin's row (not a drop)
The agent's reasoning wrapped **the reporter's indirect speech** in quotation marks:
`he is 'looking forward to improving achievement gaps and working with underserved students.'`
The article actually reads *"He's looking forward to improving achievement gaps…"* — third
person, the reporter's words, and located in the **budget** section rather than the DEI
section. Rewritten to state explicitly that this is indirect speech and not a quotation.
`quote_text` was never affected. This is the same failure mode that has now appeared in three
consecutive waves; it keeps surfacing in `reasoning`, where it is easy to miss because the
validator only string-matches `quote_text`.

## Why Amy Tatom `taxes`=1 was DROPPED
Her quote is real and exact, but it does not place her on this scale. Full text:
> "To address the persistent gaps in outcomes among our most vulnerable students and to prevent
> losing some of recent gains, our state legislature must fully fund our education system.
> **Although I would have preferred a different mechanism for generating revenue**, I believe the
> positive aspects of the Student Success Act outweigh its drawbacks…"

1. Chair 1 is "**Significantly raise taxes on wealthy people and large companies** to fund more
   public services." Tatom never advocates raising any tax. She expresses **qualified, reluctant**
   support for a bill while **explicitly distancing herself from its revenue mechanism** — the
   one part of it that is a tax position at all.
2. The corporate-tax content enters only through a **third-party institutional description** —
   the Oregon Dept. of Revenue page explaining that the Corporate Activity Tax applies to firms
   over $1M in receipts. Scoring her from a fact about the bill rather than from her own words
   is the same wrong-axis inference that killed Adair's abortion row.
3. Even reading it generously, chairs 1 and 2 are indistinguishable: "must fully fund" cannot be
   graded into "significantly" vs "moderately."
4. The evidence is from **2019** — seven years stale, the ground that dropped Boozell's 2020
   climate bullet.

**Do NOT re-add without new evidence.** What would unlock Tatom legitimately: the **May 2023
Deschutes voters' pamphlet** (her contested re-election, her own statement — the agent could not
locate it; untried paths are listed above), or any first-person statement on tax level/incidence.
Her `civil-rights` skip was independently reviewed and is correct — her strongest line is
scoped to religion and gender identity and phrased institutionally ("Every one of us on the
school board is…").

## Confirmed: the agent's structural finding is right
Bend-La Pine BoardBook minutes record attendance, a one-line **institutional** discussion
summary, the motion and the tally — never an individual director's reasoning. Useful to
**confirm a skip**, not to source a stance. (Independently corroborated in this wave: the same
minutes format is why zones 1-4's Fischer and Olson rows had to be dropped.)
