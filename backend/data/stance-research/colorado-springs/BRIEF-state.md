# Researcher brief — Colorado legislators, STATE scale

Read this whole file before recording a single row.

## The scale

The 28 live state topics, with the full five-value ladder for each, are in:

    backend/data/stance-research/colorado-springs/scale-state.json

**Read that file with the Read tool.** Do not work from memory and do not invent `topic_key`
values — a row whose `topic_key` is not in that file is discarded. Note this is the **state**
scale (28 topics), not the local one and not the 44-topic full set.

## Five chairs, not a rating

Each topic's five values are five *distinct, substantive positions* a real person could hold,
defend, and point to a policy for. They are not "strongly agree → strongly disagree".

To seat someone in a chair you need evidence describing **that chair**. When a voter matches this
legislator on a topic, the product says *"you both believe X"*, quoting the chair text. Your value
must survive that sentence being read aloud to the legislator.

- 🔴 **Never assume polarity.** Read each ladder. The convention is that value 1 is the
  maximum-government-action end, but **AI Oversight and Tariffs run the other way**, and Growth
  and Development Pace is off-axis entirely. The ladder text is the only authority.
- 🔴 **Never infer from party.** A legislator's caucus tells you nothing admissible. Two members
  of the same party routinely sit in different chairs on the same topic, and that difference is
  the entire product. A party-inferred value is a fabricated claim about a real person.
- 🔴 **"The least extreme option the reasoning supports" is a tiebreaker, not evidence.** If you
  reach for it, the row is not evidenced. Skip it.
- **A blank spoke is a correct answer.** If two adjacent chairs both fit, skip the topic.

## 🔴 The sponsorship trap — read this twice

Your richest source is prime sponsorship, and it is the easiest way to record a wrong row.

**A bill citation proves DIRECTION. It does not automatically prove MAGNITUDE.** Sponsoring a bill
to raise taxes on high earners to fund public services proves someone is on the pro-progressive-
taxation side. It cannot distinguish *"significantly raise taxes on the wealthy"* (one chair) from
*"moderately raise"* (the next chair over). Two chairs fit ⇒ **skip**.

What decides whether a sponsorship can seat a chair is **the shape of the bill**, not the fact of
sponsorship:

- A bill whose operative text *is* the chair — a total ban, a specific numeric target, a repeal —
  can seat that chair. HB26-1083 "Protect Female Sports Act" is a categorical restriction and
  names its chair on `trans-athletes`.
- A bill that nudges in a direction — a study, a pilot, an appropriation, a reporting requirement,
  a narrow technical amendment — proves direction only. It cannot seat a chair on its own.
- 🔴 **A compound chair needs EVERY clause evidenced.** If the chair text says "ban X *and*
  criminally penalise Y", a bill that only does X does not seat it.
- 🔴 **If your citation is a sponsorship, you may not record a row at the anti pole of that
  topic** — the citation would contradict the position displayed to the voter.
- **Co-sponsorship is weaker than prime sponsorship**, and a member voting with their caucus on a
  party-line bill is close to no evidence at all.

Committee votes, floor statements, and the member's own issues page are usually better chair
evidence than a bill list. Prefer them.

## Sources

**Tier 1 — harvested locally, read yours first.** In
`backend/data/stance-research/colorado-springs/sources/`, one file per legislator:

    leg-<slug>.md      e.g. leg-amy-paschal.md, leg-scott-bottoms.md

Each contains the `leg.colorado.gov` member page — committee assignments and **current-session
prime sponsorships with bill numbers, long titles, subject tags and outcomes** — and, where the
member page linked one, the text of their caucus or personal site, which is usually where an
actual issues statement lives.

⚠ Two limits recorded in every file's header, and they matter:
1. leg.colorado.gov shows the **current session only**. There is no session selector, and the site
   is currently displaying a banner that legacy session data is mid-migration and those links may
   not work. Do not assume the bill list is a complete career record.
2. Sponsorship proves direction, not magnitude. See the trap above.

**Tier 2 — fetch these yourself with WebFetch:**
- `leg.colorado.gov/bills/<billnum>` for the operative text of any bill you intend to cite —
  🔴 if you are seating a chair on a bill, read the bill, do not rely on the title
- Ballotpedia (survey answers only — the "Candidate Connection" preamble is identical boilerplate
  on every page; only the person's own answers count)
- Vote Smart (`justfacts.votesmart.org`) political courage test responses
- `coloradohouserepublicans.com` / `cohousedems.com` / senate caucus sites — issues pages
- `koaa.com`, `krdo.com` (article URLs; krdo search endpoints 404)
- ✅ **`coloradopolitics.com` and `completecolorado.com` WORK and were the two most productive
  tier-2 sources found for a legislator** — op-eds and statewide political coverage in the
  member's own words. Not obvious, easily missed, use them.
- ⚠ `coloradosun.com` and `coloradonewsline.com` were unreachable in at least one session; try
  them but don't burn attempts if they fail.
- ⚠ `denvergazette.com` shares the `gazette.com` WAF — both 403.
- The member's own campaign site

🔴 **cpr.org is behind a WAF** — WebFetch and curl both get HTTP 403. Do not spend attempts on it.

🔴 **Ballotpedia returns an EMPTY BODY for this cohort** (not a 403 — an empty 200, which looks
like a fetch failure but is the real response). Six agents are now 0-for-6 on it. Skip it.

✅ **`pikespeakbulletin.org/?s=` and `socoinsider.com/?s=` both work** (verified server-rendered
search) and cover El Paso County politics in real depth. Under-used.

✅ **On `koaa.com/search?q=<name>`, look specifically for a "one-on-one with…" or profile-interview
headline and fetch that first.** Measured across this cohort: a sit-down interview is far richer
per fetch than vote-report coverage, which tends to quote everyone *except* the person you are
researching.


🔴 **WEBFETCH PARAPHRASES — NEVER TRUST IT FOR A QUOTE.** WebFetch runs a summarising model over the
page. It will sometimes hand back paraphrased talking points *formatted as if quoted*, and two
"reproduce verbatim" calls on the same page can return two different "exact quotes". Two agents on
this wave hit this independently. Before you put anything in `quote_text`:
- re-fetch with an explicit instruction to return **only text inside quotation marks**, and
- treat a quote as safe only if it reproduces identically across independent fetches.
If you cannot confirm it, leave `quote_text` blank and record the stance from the record. Every
quote in this wave is re-checked against raw source bytes afterwards, so an invented one will be
caught — but catching it costs a rewrite, and a dropped real quote costs coverage.

**Tool rule:** prefer the local file (Read), then WebFetch. Do not use WebSearch or Playwright.

## Output

Append rows to the CSV path given in your dispatch prompt. RFC-4180: any field containing a comma,
quote or newline must be wrapped in double quotes, and embedded double quotes doubled (`""`).
A malformed row breaks the merge parser for the whole file.

Columns, exactly:

    full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified,editor_note

- `reasoning` — 🔴 **this is PUBLIC, voter-facing text** rendered on the legislator's Essentials
  profile under "Why this position?". Write it for a voter, in plain language, and make it justify
  *the specific chair you chose*, naming the instrument, vote or statement it rests on. Never write
  reasoning that argues a neighbouring chair. **Name the bill number when you cite a bill.**
- `quote_text` — only if it passes all three gates: **forward-looking** (reasoning about what
  should be done, not a résumé of what they passed), **on-question** (answers this topic's axis),
  and **a position, not a personal attack**. Otherwise leave blank and still record the stance.
- `quote_deidentified` — remove identity leaks (party tells, "as chair of…", self-record touting),
  marking every cut with `…` and every substitution in `[brackets]`. Never silently reword. Blank
  it rather than paraphrase.
- `editor_note` — required whenever `quote_text` is non-blank. One or two jargon-free sentences:
  why this quote, how it matches the value, and what you edited ("verbatim, no edits" if nothing).

## Report back

When you finish, state: rows recorded, topics skipped **and why**, how many rows rest on
sponsorship alone versus a stated position, and anything about the sources a later pass should know.
