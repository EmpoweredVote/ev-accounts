# Codebook note — Ballotpedia Candidate Connection (PROPOSED, not applied)

Ruling 2026-10-07 (Chris Andrews): a Candidate Connection survey answer is the candidate's own words and
may stand as a stance source. The codebook is NOT changed by this PR and its version stays 0.4. This is the
wording proposed for the operator's approval. It adds no new coded variable or value, so it reads as a
"Clarified" entry like the 2026-10-06 ones.

## Proposed V1 "Hard" example (after the newspaper-questionnaire example, ~L138)

> **Hard.** A Ballotpedia Candidate Connection survey answer, cited at `ballotpedia.org/<Page>#Campaign_themes`.
> → `own-words`: Ballotpedia is the channel, the words are the candidate's, and they are published nowhere
> else. The same page's editorial bio, election results or ballot-measure text is not the candidate's act or
> words (`third-party-characterization`), and a bare `ballotpedia.org/<Page>` citation stays refused when it is
> the only source. The passage you code must be inside the survey section; the section id is
> `#Campaign_themes` (there is no `#Candidate_Connection` id).

## Proposed V3 line (add to the `statement-answer` row, after "a questionnaire (…)")

> …a Ballotpedia Candidate Connection survey answer, when the passage is inside the `#Campaign_themes`
> section and answers a posed question. (A survey answer that is not a response to a question the survey
> posed — a free-text bio the candidate wrote — is `statement-other`.)

## Proposed V6 line (under "Evidence tier")

> A Candidate Connection survey answer is one occasion of the person's own words. On its own it is
> `single-source`. It is `corroborated` only with a second independent source, and a second Ballotpedia page
> is not independent of it.

## Code that enforces it

- `backend/scripts/lib/candidate-connection.mjs` — the one definition (URL anchor + page-text check).
- `check-stance-sources.mjs` (SQL, URL test only) and `stanceGate.ts` C57 (URL + page text, fails closed).
- `own-words` tagging stays with the coder (V1); code does not set it from the URL.
