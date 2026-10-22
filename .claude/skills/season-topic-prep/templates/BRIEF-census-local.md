# Stage 0 census brief (local bodies) — {{TOPIC_KEY}} — {{DATE}}

<!-- Orchestrator: fill every {{…}}, delete these comments, and give each collector its own task line
     (bodies to search, its caps, its output path). Generalised from the equity-programs census supplement
     brief (2026-10-19). For state laws and Congress use BRIEF-census-state.md instead. -->

🔴 **Stage 2 drafters must not read this folder.** It names bodies, votes and bill texts.

Shared by every collector in this pass. We only COUNT and INVENTORY records. Do NOT judge anyone's stance, do NOT
rate, rank or place anyone on any scale.

🔴 Do not open {{FORBIDDEN_FOLDERS}}. Write only your own file.

🔴 **Meeting and bill portals (BoardDocs, Legistar, Municode, legiscan, and the like): NO scripted bulk requests.**
Bulk curl got earlier collectors blocked (BoardDocs CloudFront 403 after about 700 requests; legiscan sits behind
Cloudflare; Municode refuses curl). No loops, no scripts, no wget. Fetch ONE known item or minutes page at a time
with WebFetch, only when you have a reason to think it holds a relevant vote, and stop at your fetch cap. When
WebFetch returns a binary PDF or an iframe, one `curl` of that one document URL, then `pdftotext`, is allowed. If a portal returns 403 or a challenge page, stop using it; try the Wayback Machine
(`https://web.archive.org/web/2024/<url>`) once, then move on and list the portal under `blocked`. **A blocked portal
is a gap, never "none".** Respect robots and site terms (some sites forbid automated access entirely).

## Already in the source store (do not collect again)

{{STORE_SUMMARY}}

## Why this pass exists

{{WHY_THIS_PASS}}

## What counts as on-topic

The topic question: "{{TOPIC_QUESTION}}"

`kind` = **POLICY** when the body sets a rule on:
{{ON_TOPIC_POLICY_LIST}}

`kind` = **ADJACENT** (record in one line only):
{{ADJACENT_LIST}}

🔴 **Flag every mixed item.** {{MIXED_ITEM_FLAGS}} Record each such clause, quoted. We decide; you list.

## Record types (every local-body record gets one)

- `ACTION_ITEM_NAMED` — taken up on its own (regular, action, new or old business, or "removed from consent and
  voted separately"), its own motion, and each member's vote can be named: a roll call, or minutes that name the
  members present and say the motion carried unanimously, or that name the No votes.
- `ACTION_ITEM_TALLY` — own item, but only a tally ("carried 5-2"); members present not listed.
- `CONSENT` — adopted on a consent agenda or en bloc. One line only.
- `OTHER` — discussion only, first reading with no vote, staff or executive decision, news only.

## Per local-body record (ACTION_ITEM_NAMED and ACTION_ITEM_TALLY)

- body, date (YYYY-MM-DD), agenda item number and title, exactly as printed; `kind`.
- `body_size`: the number of voting members of the body on that date.
- `section`: the agenda heading the item sat under, **quoted verbatim**, plus `section_quote` (≤25 words).
- `motion_quote` (≤25 words); mover and seconder if printed. `own_motion`: did this body move it itself, or did it
  act on another body's or officer's motion or recommendation? Quote what shows it.
- `members`: [{name, vote: yes|no|abstain|absent|recused}] exactly as the minutes name them.
- `tally` as printed.
- `content_terms`: what the item sets up, funds, requires, limits, ends or bans. Quote the operative line(s),
  ≤40 words.
- `other_subjects`: does the same item ALSO cover anything else ({{OTHER_TOPICS_TO_FLAG}}, or anything not on
  this topic)? Quote it. "none" is fine.
- `state_duty_note`: does the item say it carries out a state or federal law, rule or order (e.g.
  {{STATE_DUTY_EXAMPLES}})? Quote it; else "none cited".
- `url_minutes`, `url_item` (policy, ordinance or resolution text), `url_other`, `notes`.
- `names_from`: where the member names came from — `page text`, `pdf text`, `reader summary` (a page reader that
  summarised rather than copied) or `news`. The identity check re-reads anything not from the page or PDF text.
- 🔴 A record counts only once its operative text has been read. A title or an agenda line is a lead: give
  `content_terms` from the item text, or say "text not read".

## Roster

Only bodies whose members are in our database matter for counting, but **record good finds anywhere** (the lead
lists which bodies would need adding). Rosters: {{ROSTER_PATHS}} (tab-separated, read from
`essentials.office_terms`). Prefer votes from **{{SINCE_YEAR}} onward**; older votes are worth one line if current
members sat then. A local-body record is only useful if at least 3 named voters are DB members seated on the vote
date, so prefer recent votes. Do not match people yourself beyond the names as printed; the identity check is done
later against official session lists.

## Rules

- Do not invent. "None found" is a useful result. Record what you searched (queries and sites) and what blocked you.
- 🔴 WebSearch is scarce: your cap is {{WEBSEARCH_CAP}}; never exceed it. Prefer WebFetch on known URLs. Stop at
  {{WEBFETCH_CAP}} fetches. No loops or scripted fetching of any portal.
- Write your JSON file early and update it after each body or bill, so partial work survives.
- Return a ≤150-word summary: counts per type per body.

## Output: ONE JSON file at {{OUT_PATH}}

Local bodies:
{"agent":"<id>","bodies":[{"body":..,"state":..,"in_roster":true|false,"searched":[".."],"blocked":[".."],
  "records":[{"type":..,"kind":..,"date":..,"item_no":..,"item_title":..,"body_size":..,"section":..,
   "section_quote":..,"motion_quote":..,"mover":..,"seconder":..,"own_motion":..,"members":[..],"tally":..,
   "content_terms":..,"other_subjects":..,"state_duty_note":..,"url_minutes":..,"url_item":..,"url_other":..,
   "names_from":..,"notes":..}],"notes":..}],
 "websearch_count":N,"webfetch_count":N}

