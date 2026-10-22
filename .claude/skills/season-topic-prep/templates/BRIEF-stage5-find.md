# Stage 5 search brief — {{TOPIC_KEY}} — {{DATE}}

<!-- Orchestrator: fill every {{…}}, delete these comments, and give each collector ONE person: one line of the
     batch file from `topic:stage5-find next` (politician_id, full name, office, level, state). Run each as a
     `source-collector` subagent. Its output path is <research folder>/stage5/raw/find/<politician_id>.json.
     Then `topic:stage5-find import`. -->

🔴 **You search. You do not judge.** Find what this person has done and said on the subject below, and copy it
exactly. Do NOT place them on any scale, give a rung or a number, or say which side they are on. Another agent
codes the stance later, from what you saved. A file with a `value`, `rung` or `stance` field is refused.

🔴 Do not open {{FORBIDDEN_FOLDERS}} or any other folder under the research root except your own output path.
Write only your own file. No party names, no party colours, and never use a party as evidence of anything.

## The person

{{PERSON_LINE}}

## The subject (search broadly, not only the five positions)

The topic question: "{{TOPIC_QUESTION}}"

Search for anything this person did or said on the **subject**, including parts no position names:
{{SUBJECT_LIST}}

## Already on file (do not collect again)

{{ON_FILE}}

A vote on file saves you the record search, **not** the own-words search. Search for their own words anyway.

## First: is this person still in scope?

Confirm who they are (a page that names them in this office or race). For a candidate, confirm they are on the
2026 general-election ballot. If they lost a primary or withdrew, stop: write the file with `findings: []` and put
`status: lost the <date> primary` (or `status: withdrew <date>`) first in `places`, with the page that says so.

## Where to look, in this order

Check **every** place on this list, and name each in `places` (with `nothing on the subject`, `blocked: <url>` or
`not reviewed: <url>` as it went). Stopping after the first page of a press-release list is not a search.

1. **On the Record first.** `node .claude/skills/research-stances/scripts/extract-otr.mjs --politician {{POLITICIAN_ID}}
   --names "{{FULL_NAME}}"` (add `--city` for a local official). Each meeting file is an own-words source; its
   OTR page is the URL.
2. **Their official site** (and campaign site): search the site for the subject words ("voter ID", "photo ID",
   "SAVE Act", "proof of citizenship", "election integrity", "mail ballot"), not only page 1 of the news list.
3. **Their record:** for a legislator, the legislature's own bill pages for sponsorships and co-sponsorships on the
   subject (congress.gov for Congress; if it blocks you, say so).
4. **Ballotpedia** and one news search on their name plus the subject words.
5. **The URL patterns** in `.claude/agents/politician-stance-researcher.md`, `### URL Patterns — Fetch These in
   Order` (official page, campaign site, Ballotpedia, then the rest). ontheissues.org and vote411 are leads only:
   find the original and cite that.
3. **Records:** votes, sponsorships, vetoes and signatures, lawsuits, official letters, amendments; for a local
   official, ordinances and resolutions they voted for or sponsored.
4. **Own words:** questionnaires, debate and forum answers, issue pages, pledges, speeches, interviews, posts.

A debate or interview video you cannot read is `not reviewed: <url>` in `places`, never "nothing".

Search to find, fetch to cite: every URL you save was fetched by you, and the passage is on that page.
🔴 **The fetch tool may summarise a page.** Copy a passage only from the page's own text: when in doubt, one
`curl -sL <url>` of that page and copy from the HTML text. Never copy a passage from a summary. A search
result snippet is a lead, never a source. Fetching manners: one page at a time; no loops, no scripts, no wget. A
blocked page is a gap, never "nothing": list it in `places` as `blocked: <url>`.

## What to save

- **Own words:** the **exact passage**, copied word for word (at least one full sentence; keep the speaker's
  wording, including mistakes). Only words this person said or wrote, or a statement issued in their name. Words
  about them by a reporter or an opponent are not their own words. A direct quote of them in a news story counts;
  say in the note which outlet quoted them, and prefer the original (their site, the transcript) when you can
  reach it.
- **A record:** the act (`yea`, `nay`, `abstain`, `sponsor`, `author`, `signed`, `vetoed`, `other`), the bill or
  ordinance number in `instrument_id` form if you know it (`IN-SB-483-2011`), the motion for a vote, and the
  official URL. Set `local_record: true` for a city, county or school-board ordinance or resolution. With no
  `instrument_id`, `motion` must name the act ("Ordinance 2024-7, clinic buffer zone"), so two acts on one
  minutes page stay apart.
- **The date** of the act or the words (not the date you fetched it), with its precision.
- **A short plain note** of what it says, in your own words, with no judgement of the person. 🔴 Never name a
  party, in notes, subjects or places (an import refuses it). Name a bill by its number and short title.
- **Subjects in plain words** (for example "voter ID at the polls", "mail-ballot ID", "proof of citizenship to
  register"). Never rung numbers.
- Save off-subject material only if it is on the subject above. Save nothing else.

## Output — exactly this JSON, nothing else in the file

```json
{
  "politician_id": "{{POLITICIAN_ID}}",
  "searched": {
    "subjects": ["voter ID at the polls", "…"],
    "places": ["On the Record (3 meetings)", "campaign site", "Ballotpedia", "blocked: https://…"]
  },
  "findings": [
    {
      "kind": "own-words",
      "url": "https://…",
      "date": "2026-09-14",
      "date_precision": "day",
      "passage": "exact words",
      "note": "what it says, plainly",
      "subjects": ["voter ID at the polls"]
    },
    {
      "kind": "record",
      "url": "https://…",
      "date": "2023-03-02",
      "date_precision": "day",
      "instrument_id": "VA-HB-1444-2023",
      "act": "sponsor",
      "note": "what the bill does, plainly",
      "subjects": ["voter ID at the polls"]
    }
  ]
}
```

`findings` may be empty: an honest "found nothing" is a result. `searched.places` must list where you looked
either way. Return a two-line summary: how many findings, and anything blocked.
