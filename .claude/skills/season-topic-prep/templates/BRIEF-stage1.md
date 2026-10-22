# Stage 1 collection brief — {{TOPIC_KEY}} test set (shared by collector agents)

<!-- Orchestrator: fill every {{…}}, delete these comments, and give each collector a task line with its list of
     instrument ids and its output path. Generalised from the equity-programs Stage 1 brief (2026-10-19). -->

Goal: collect the EXACT operative text of each instrument listed in your task, and its prime sponsor(s), so a coder
can later read what it does. You do NOT judge stances, rungs or sides. No ladder is given to you; do not invent one.
Offline research, free sources only, no logins.

🔴 Fetch pages **one at a time**. No scripted bulk downloads and no loops against meeting or bill portals. When
WebFetch returns a binary PDF or an iframe, one `curl` of that one document URL, then `pdftotext`, is allowed.
🔴 **Struck-through text:** many bills print deleted words as strike-through, and text extraction keeps the struck
words. When a section shows markup, render the page (`pdftoppm -png`) and read the image; say so in `access_note`. If a
portal blocks you (403, challenge page), stop using it, try the Wayback Machine once, then report it as blocked. **A
blocked portal is a gap, never "not found in the law".** Respect robots and site terms.

🔴 Do not open {{FORBIDDEN_FOLDERS}}. Write only your own file.

For each instrument give:
- id (from your task), title, jurisdiction, session or meeting date, chapter or ordinance number, date adopted or
  approved.
- `operative_text`: verbatim passages (quote exactly; up to about 300 words in total, split into several quotes with
  the section number) that state WHAT THE INSTRUMENT DOES on these points, where present:
  {{OPERATIVE_POINTS}}
  Say "not stated" for points the text does not cover.
- `other_subjects`: any operative part that is NOT about {{TOPIC_OBJECT}} (e.g. {{OTHER_TOPICS_TO_FLAG}}). Quote
  briefly. "none" if none.
- `higher_law_note`: does the text say it carries out a duty set by a higher law (state statute, federal law or
  order)? Quote it; else "none cited".
- `source_url` (the enrolled, chaptered or adopted text, not an introduced draft), `source_type` (bill-text,
  ordinance, policy, minutes), `access_note` (how you got it: WebFetch, browser, Wayback, PDF and OCR). Quotes must
  come from the enrolled, chaptered or adopted text. If you could only read an introduced or engrossed version, say
  so plainly.
- `saved_copy`: if you saved a PDF or page capture, its path under {{RAW_DIR}} and its SHA-256.
- `sponsors`: the PRIME sponsor (or chief patron) as printed on the official bill page, with chamber, and the
  version they filed (the store keeps them as `sponsors: [{name, role, version}]`; the identity step ties each
  printed name to a roster person, as for roll-call names). If the instrument has an official companion or cross-file in the other chamber that your task
  names, give that bill's prime sponsor too. Give the source URL. Do not list co-sponsors unless the official page
  prints no single prime sponsor (then list the first-named and say so).
- If the adopted text cannot be reached, say "NOT FOUND" and list what you tried.

Do not collect roll calls or member votes (they are already on file). Do not report anything about
{{PEOPLE_TO_SKIP}}.

Write ONE JSON file at {{OUT_PATH}}: {"instruments":[{...}], "blocked":[".."], "notes":"..."}.
Budget: about {{WEBSEARCH_CAP}} WebSearch calls and {{WEBFETCH_CAP}} fetches. Reply with a 5-line summary.
