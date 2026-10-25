# Stage 0 census brief (state laws and Congress) — {{TOPIC_KEY}} — {{DATE}}

<!-- Orchestrator: fill every {{…}}, delete these comments, and give each collector its own task line: the
     NAMED BILLS it inventories (from the annex, the shadow coder labels and one search pass; SKILL.md Stage 0
     step 2), its caps and its output path. Session member lists are a separate collector task (see the end).
     Generalised from the voting-rights census brief (2026-10-20). For local bodies use BRIEF-census-local.md. -->

🔴 **Stage 2 drafters must not read this folder.** It names bills, votes and people.

Shared by every collector in this pass. We only COUNT and INVENTORY records. Do NOT judge anyone's stance, do NOT
rate, rank or place anyone on any scale.

🔴 Do not open {{FORBIDDEN_FOLDERS}} or any other folder under the research root except your own output path and
the roster files named below. Write only your own file.

🔴 **Bill and vote portals (legiscan, state legislature sites, congress.gov, clerk.house.gov, senate.gov, and the
like): no loops, no scripts, no wget.** Fetch ONE known bill, history or roll-call page at a time with WebFetch, only
when you have a reason to think it holds a relevant vote, and stop at your fetch cap. When WebFetch returns a binary
PDF or an iframe, one `curl` of that one document URL, then `pdftotext`, is allowed. If a portal returns 403 or a
challenge page, stop using it; try the Wayback Machine (`https://web.archive.org/web/2024/<url>`) once, then move on
and list the portal under `blocked`. **A blocked portal is a gap, never "none".** Respect robots and site terms.
legiscan sits behind Cloudflare: prefer the legislature's own site.

🔴 **Struck-through text.** Many bills print deleted words as strike-through, and text extraction (`pdftotext`, the
fetch tool) silently keeps the struck words. When a section shows markup, render the page (`pdftoppm -png`) and read
the image; say in `notes` that you did.

## Already in the source store (do not collect again)

{{STORE_SUMMARY}}

## Why this pass exists

{{WHY_THIS_PASS}}

## What counts as on-topic

The topic question: "{{TOPIC_QUESTION}}"

`kind` = **POLICY** when the law (or the bill, or the floor amendment) sets a rule on:
{{ON_TOPIC_POLICY_LIST}}

`kind` = **ADJACENT** (record in one line only):
{{ADJACENT_LIST}}

🔴 **Flag every mixed item.** A law that sets an on-topic rule AND does anything else: list every other operative
part, quoted. Pay special attention to parts on {{OTHER_TOPICS_TO_FLAG}} — those are other topics this season. We
decide single- versus multi-subject; you only list.

## Per state law (or federal act, or failed bill with a floor roll call)

- state, bill, session year, status (enacted, vetoed, died, or "floor amendment, failed/adopted"), one-line subject.
- `version_voted`: the version the final roll call adopted (as filed, engrossed, enrolled, conference report).
  `sponsor_version`: the version the prime sponsor filed, and whether it is substantially the same text.
- `sponsors`: [{name as printed, role: prime | co | author | patron, version}] from the official bill page. Give the
  prime sponsor (or chief patron); list co-sponsors and co-authors when the page prints them.
- `companion`: an identical bill in the other chamber with its own roll calls, if any (it counts as a separate
  record).
- `operative_parts`: list EVERY operative section in a few words each, with a ≤25-word verbatim quote of each. For
  the on-topic part, quote the operative sentence(s) that state the rule (≤60 words). 🔴 **Quote from the bill or
  amendment text itself.** A title, a digest or a news line is a lead, not a record: if you could not read the text,
  say "text not read".
- `higher_law_note`: does the law say it carries out a federal or state requirement, or impose a duty on local
  bodies? Quote it; else "none cited".
- `rollcalls`: [{chamber, date, motion, yeas, nays, other, body_size, pct_no, url, yea_names:[..], nay_names:[..],
  absent_names:[..], not_voting_names:[..], names_from}] — names **exactly as printed**, with absent or excused
  members apart from those present and not voting. `names_from` is `page text`, `pdf text`, `reader summary` or
  `news`. Give each chamber's **final vote** (final passage, concurrence, conference report, or veto override), plus
  a recorded vote on a floor amendment that is itself an on-topic provision; skip procedural motions (cloture,
  table, recommit, rules). One record is one instrument's final vote per chamber (RULINGS.md "Census — what one
  record is"); earlier roll calls may go in `notes`.
- `urls`: official bill page, enrolled text, roll-call pages. `notes`.

## Roster

Rosters (tab-separated, read from `essentials.office_terms`): {{ROSTER_PATHS}}. Prefer votes from
**{{SINCE_YEAR}} onward**; a roll call matters when current roster members sat on it, so check `term_start` (often
unknown for legislators) or the session member list before spending fetches on an old vote. Do not match people
yourself beyond the names as printed; the identity check is done later against official session member lists.

## Session member lists (separate collector task)

For each chamber and session whose roll calls the census will count, fetch the official member list (the
legislature's own roster page or journal for that session, one page at a time). Give {state, chamber, session,
source_url, members:[{full_name}]} with full names exactly as printed. These feed `npm run census:identity`.

## Rules

- Do not invent. "None found" is a useful result. Record what you searched (queries and sites) and what blocked you.
- 🔴 WebSearch is scarce: your cap is {{WEBSEARCH_CAP}}; never exceed it. Prefer WebFetch on known URLs. Stop at
  {{WEBFETCH_CAP}} fetches.
- Write your JSON file early and update it after each bill, so partial work survives.
- Return a ≤150-word summary: laws found, roll calls captured with names, blocked portals.

## Output: ONE JSON file at {{OUT_PATH}}

{"agent":"<id>","states_searched":{"XX":[".."]},"blocked":[".."],"laws":[{"state":..,"bill":..,"session":..,
  "status":..,"subject":..,"version_voted":..,"sponsor_version":..,"sponsors":[..],"companion":..,
  "operative_parts":[{"part":..,"quote":..,"flag":..}],"higher_law_note":..,"rollcalls":[..],"urls":[..],"notes":..}],
 "session_lists":[{"state":..,"chamber":..,"session":..,"source_url":..,"members":[{"full_name":..}]}],
 "websearch_count":N,"webfetch_count":N}
