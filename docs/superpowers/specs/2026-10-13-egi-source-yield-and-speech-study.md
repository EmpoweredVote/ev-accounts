# Where positions on LGBTQ+ issues in schools can be found, and what politicians commit to when they speak

Date: 2026-10-13. For Chris Andrews. **Findings only. Nothing was written to prod** (read-only roster queries;
no stance, revision or queue row). Follows the A1 v2 broad research (PR #950), which seated 6–10 of 476 people.

**Two questions.**
1. *Sources:* beyond the official record, where do politicians show a position on this domain, in their own
   words or by an act?
2. *Content:* when they speak, what do they actually commit to? Is there an issue or axis where many people,
   on both sides, state a rule specific enough to seat a chair?

## Short answer

1. **The official record is still the best source by far, and it exists only for incumbents.** Of 49
   incumbents in the sample, 30 have an on-topic record. **Challengers have almost nothing anywhere:** of 15,
   5 have an on-topic line on a campaign site and 3 have issue-group endorsements; no questionnaire, debate,
   release, interview, letter or scorecard reached any challenger. Local officials are the same: 2 of 15
   local people have anything in any source.
2. **Speech is mostly sides, not rules.** 30 of 64 people have own words in the domain, but only **11 state
   a rule** (C2/C3), and those 11 rules spread over **7 different sub-issues**: no sub-issue has more than
   three people stating a rule. No re-drawn topic or ladder could seat many people from these words.
3. **The two sides talk about different things.** The inclusive side speaks mostly about general equality
   and nondiscrimination (rights frame); the restrictive side speaks about sports and parents' rights
   (fairness and parental-rights frames). So a ladder on one sub-issue catches one side's speech. This
   repeats, in speech, the asymmetry the record showed in PR #950 (each side acts on its own bills).
4. **Sports is the only sub-issue where both sides speak, and both state something rule-like** (6
   restrictive, 4 inclusive, 1 mixed name a side). But the inclusive "rule" is jurisdictional: *eligibility
   is for state and local bodies, not the federal government* (Baldwin, Schiff). That is the "who decides"
   kind of answer you called a cop-out. `trans-athletes` is already its own topic.

## Method

- **Sample (64 people):** 56 drawn at random (seed 20261013), stratified by area (Monroe IN, Racine WI,
  Utah County UT, LA County CA) × level (school, state, federal, local) × status (incumbent, challenger),
  from the four rosters (`roster-la.sql` for LA; the PR #950 roster for the others). Plus 8 purposive
  federal incumbents (the 5 US senators not already drawn, 1 Utah and 2 LA House members), because
  federal members speak most. Judges excluded. Short strata: no Racine school-board or local challengers exist in
  the database; Utah and LA had no school challenger on the roster.
- **Domain (broad on purpose):** LGBTQ+ issues touching K-12 schools or minors — names and pronouns,
  parent notice, sports, facilities, library books, curriculum, bullying and nondiscrimination; and,
  tagged adjacent, youth medical care and general LGBTQ+ equality.
- **Collection:** 8 research agents, 8 people each, checked 13 source types per person with a positive
  control (a page proving the person was found). Verbatim statements and acts were kept with URLs.
  On the Record was checked in-house for all 64 (`extract-otr.mjs --politician … --names …`).
- **Coding:** 175 statements coded independently by two Opus coders (sub-issue, side, commitment level,
  frame, a normalized proposition). Agreement: own words κ 0.94, sub-issue κ 0.89, side κ 0.94,
  **commitment κ 0.92**, frame κ 0.87; "states a rule (C2+)" agreement 98%. The analysis uses the lower
  of the two commitment codes.
- Commitment levels: **C0** value only ("every child matters"); **C1** side on a named issue, no rule;
  **C2** a rule anyone could write down; **C3** a rule plus its mechanism or limit; **C4** the person
  reports their own act (vote, bill) that states a rule.

**Limits.**
- The agents shared a budget of 200 web searches, which ran out part-way through every batch. Later checks
  used direct fetches only, so news, questionnaire and debate cells are **under-counted** for about a
  third of the people (each such cell carries a note in `collection/`).
- **Paid ads (Meta, Google) and social media could not be read by any agent:** login walls, 403 errors
  or JavaScript-only pages (51 and 44 of 64 people "inaccessible"). These may be the largest untested
  sources, especially for challengers. Reading them needs a browser session or a supported API.
- Vote Smart, Ballotpedia (late in the run), LegiScan, leginfo and some house.gov pages blocked the agents.
- 64 people is a pilot: read the counts as orders of magnitude.

## 1. Source yield

On-topic = the source exists and holds something in the domain. Counts are people.

| source type | incumbents (49) | challengers (15) | note |
|---|---:|---:|---|
| T13 official record (votes, bills, board votes) | **30** | 0 | the backbone; incumbents only |
| T08 own releases, newsletters, op-eds | 16 | 0 | mostly federal |
| T12 scorecards (HRC, Equality CA, etc.) | 14 | 0 | direction only; derived from votes |
| T09 news interviews with direct quotes | 12 | 0 | |
| T11 issue-group endorsements received | 10 | **3** | direction only; near party |
| T01 campaign website | 8 | **5** | the one own-words source challengers have |
| T10 sign-on letters, rule comments, amicus, lawsuits | 7 | 0 | e.g. Title IX comment letters, Skrmetti amicus |
| T07 debates, forums, town halls | 6 | 0 | On the Record: 2 of 64 people appear at all |
| T02 news / civic questionnaires | 2 | 0 | |
| T03 interest-group questionnaires (iVoterGuide etc.) | 1 | 0 | where answered, specific (a Racine alderman: C2 on library books); several candidates left the items blank |
| T04 pledges | 1 | 0 | |
| T06 social media | 1 | 0 | **inaccessible for 44** |
| T05 paid ads | 0 | 0 | **inaccessible for 51** |

**Direction from any source** (statement, record, endorsement or scorecard): federal incumbents 16/16,
state incumbents 11/12, state challengers 6/7 (3 of them from endorsements alone), federal challengers 4/4,
school incumbents 3/9, local incumbents 2/12, local and school challengers 0/4.

## 2. What the speech commits to

149 statements were the person's own words (incl. signed fixed text). Their commitment, lower of two coders:

| C0 value only | C1 side, no rule | C2 rule | C3 rule + mechanism | C4 own act |
|---:|---:|---:|---:|---:|
| 22 | **77** | 16 | 4 | 30 |

Per person (30 people with own words): best level reached — C4 11, C3 2, C2 6, C1 8, C0 3. So **11 of 64
people state a rule in words**; another 11 only *report* an act the record already shows.

**People who named a side, per sub-issue** (C1 or higher, own words):

| sub-issue | inclusive | restrictive | mixed |
|---|---:|---:|---:|
| general LGBTQ+ equality (mostly not schools) | 13 | 2 | 2 |
| sports | 4 | 6 | 1 |
| youth medical care (adjacent) | 6 | 1 | |
| curriculum | 2 | 3 | |
| parent notice | 1 | 3 | |
| bullying / nondiscrimination | 4 | | |
| general parental rights | | 3 | |
| books and library | 2 | | 1 |
| facilities | | 2 | |
| pronouns and names | | 1 | |

**Every stated rule (C2/C3) in the sample** — 11 people:

| person | side | rule |
|---|---|---|
| Erin Houchin | restrictive | Only biological females may compete in women's and girls' sports |
| Tammy Baldwin, Adam Schiff | inclusive | Trans athlete eligibility is for state and local bodies, not the federal government |
| Tammy Baldwin | inclusive | Federal law / Title IX bars discrimination by sexual orientation and gender identity |
| Burgess Owens | restrictive | Schools must inform parents before socially transitioning a student |
| Larry Thompson | restrictive | Schools must disclose to parents what is taught in class |
| April Hennessey (board resolution) | inclusive | The district must adopt an anti-bullying policy covering LGBTQ+ people |
| Greta Neubauer | inclusive | The state should not ban gender-affirming care for minors |
| Sara Hernandez | inclusive | Access to gender-affirming care should be expanded |
| Dorothy Granger (council resolution) | inclusive | State law should make sexual orientation and gender identity protected classes |
| Grace Allen (iVoterGuide) | mixed | Sexually explicit materials should be kept from children in school libraries |
| Alan Wessman | inclusive | A book removal should apply only to the district that decided it (statewide only if two-thirds agree) |

**Frames.** Inclusive: rights/discrimination 34, inclusion 13, local control 6, mental health 6, child
safety 6. Restrictive: fairness 19, parental rights 17, child safety 7. Each side justifies itself with
its own vocabulary; "parental rights" is used by both (Pierce: parents' right to decide on their child's
gender-affirming care).

## 3. What this means for the topic

- **A broader topic does not help.** Speech spreads across seven sub-issues, and each one gets one to three
  rules. Five chairs on a broad topic would need a rule per person on one axis; the data shows almost none.
- **Own words cannot carry this topic for challengers or local officials**: most of them say nothing
  findable. Where challengers say anything, it is a side (C1) on a campaign site.
- **Records seat one side per state.** Speech has the same split by sub-issue. A ladder seats both sides
  only when both sides have acted on the same axis. Sports and parent notice are the two axes where that
  happens across states (sports bans vs. inclusive state policies; Indiana HEA 1608 vs. California AB 1955).
- **Direction is the information that exists.** Nearly every incumbent and most state challengers show a
  side (record, endorsement, scorecard or speech). Very few show a rung. Whether the product shows a *side*
  as a separate, lesser signal from a *chair* is a product decision, not a research one; the data says a
  side is available for most incumbents and a chair for few.
- **The questionnaire remains the only route to a rung for challengers.** Note from this sample:
  candidates who received an issue questionnaire (iVoterGuide) often skipped exactly these items
  (Syczylo, Pittsford, Croft). A questionnaire of our own should expect non-response on this topic and
  record it as data.

## 4. Sources worth a next step

1. **Ad libraries and social media**, through a supported route (Meta Ad Library API needs an access token;
   Google's transparency report can be downloaded as a bulk file). Untested here and possibly the largest
   own-words source for challengers. Cost: setup, then cheap.
2. **Issue-group questionnaires as pointers**: iVoterGuide gave the one local C2 in the sample. Low reach,
   but specific when answered.
3. **Sign-on letters and rule comments** (Title IX comments, amicus briefs): 7 incumbents; these state
   rules in fixed text, so they can be rung evidence where the letter names the rule.
4. Endorsements and scorecards: useful to **find** a person's votes and to show direction; not chair
   evidence.

## Files

`backend/data/stance-research/2026-10-13-egi-source-yield/`: `sample.json` (64 people, strata, seed),
`collection/batch1-8.json` + `otr.json` (per-person yield cells, statements, acts), `corpus-merged.json`,
`statements.json` (175), `codes-A.json`, `codes-B.json`, `codes-consensus.json`, the two briefs, and
`roster-la.sql`.
