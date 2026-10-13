# Brief — source-yield + speech-content study (education / LGBTQ+ issues in schools). READ-ONLY web research.

You research 8 politicians (your batch file). Do NOT touch any database, do NOT run repo scripts, do NOT
open any folder named s3-pilot-egi* on disk. Fetch every URL you report (WebFetch, or curl with a browser
User-Agent if WebFetch fails). A search snippet is a lead, never a source. Never use party as evidence.

## Topic domain (broad on purpose)
LGBTQ+ issues that touch K-12 schools or minors: student names/pronouns; telling parents about a student's
gender identity; trans students in school sports; bathrooms/locker rooms; library books; curriculum and
instruction on gender/sexuality; anti-bullying / nondiscrimination for LGBTQ+ students; "parental rights"
in education when tied to these; ALSO (tag as adjacent) gender-affirming medical care for minors, and
general LGBTQ+ equality statements by the person.

## Part 1 — source yield. For EACH person, check EACH source type below and record a result:
  - "found-on-topic" (the source exists and has something in the domain),
  - "found-off-topic" (exists, nothing in the domain),
  - "not-found" (you looked and the person has no such source),
  - "inaccessible" (exists but cannot be read: login wall, 403, JS-only — say which).
Source types:
  T01 campaign website (issues / priorities page)
  T02 news-outlet or civic candidate questionnaire (local paper, Ballotpedia Candidate Connection, LWV
      Vote411 as POINTER only -> look for the candidate's own published answers elsewhere)
  T03 interest-group questionnaire or rating questionnaire with the person's own answers (e.g. Vote Smart
      Political Courage Test, iVoterGuide, Moms for Liberty, Equality/LGBTQ PACs, teachers' unions,
      family-policy groups)
  T04 pledge the person signed (fixed text)
  T05 paid political ads (Meta Ad Library, Google political ads transparency) — record accessibility
  T06 social media posts on own accounts (X, Facebook, Instagram, Threads) — record accessibility
  T07 debate / forum / town hall transcript or video (incl. YouTube, League forums, local TV)
  T08 own press releases, newsletters, op-eds, official website statements
  T09 news interview or article with DIRECT quotes of the person
  T10 sign-on letters, public comments on federal/state rules (e.g. 2024 Title IX rule), amicus briefs,
      lawsuits the person joined
  T11 endorsements RECEIVED from issue groups (who endorsed them) — note the group and its side
  T12 scorecards / ratings (HRC, Heritage Action, ACLU, Equality state groups, etc.)
  T13 official record in office (votes, bills, board votes) — brief check only
Positive control: before you write "not-found" for a person, confirm you found SOME page about them as
that office holder/candidate (record it). If you find none at all, mark the person "unfindable".
Budget: about 25-40 fetches per person at most; local officials will often be quick "not-found"s.

## Part 2 — collect statements (the corpus)
For every passage in the domain that is the person's OWN words (or a fixed text they signed or answered),
copy it VERBATIM (one to four sentences; never retype or trim mid-sentence), with URL, date (or "undated"),
source type (T01-T13), and the context (e.g. "answer to: should schools tell parents...").
Also record T11/T12/T13 items as "acts" (not statements) with URL and a one-line description.
Include statements even when vague ("I will stand up for every student") — vague speech is DATA here.
Do not code or judge the statements; just collect them faithfully.

## Output — one JSON file per batch at the path you are given:
{"people":[{"id":"P01","name":"...","findable":true,"found_page":"<url proving you found them>",
  "yield":{"T01":{"result":"found-off-topic","url":"...","note":""}, ... "T13":{...}},
  "statements":[{"text":"verbatim","url":"...","date":"2024-03-01","source_type":"T09","context":"...","sub_issue_hint":"sports"}],
  "acts":[{"kind":"endorsement|scorecard|letter|lawsuit|vote|bill|board-vote","desc":"...","url":"...","side_hint":"..."}]}]}
Return a summary under 200 words.
