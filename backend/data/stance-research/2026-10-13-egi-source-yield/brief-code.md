# Coding brief — what do politicians commit to when they speak about LGBTQ+ issues in schools?

Input: statements.json (same dir). Each item: sid, person, level, status, text (verbatim), source_type, date, context.
Code EVERY item, independently, from the text (and its context line) alone. Do not use outside knowledge of
the person; do not use party. Do not browse. Do not read any other file in this directory except statements.json
and this brief. Do not open any folder named s3-pilot-egi*.

For each item output:
- sid
- own_words: "yes" (the person's own words, incl. a questionnaire answer they wrote or a release in their name
  where they speak), "joint" (a group/caucus statement they joined), "fixed-text" (a pledge/letter/resolution
  text they signed), "no" (a paraphrase, or someone else speaking).
- sub_issue: ONE primary of: pronouns-names | parent-notice | sports | facilities | books-library |
  curriculum | bullying-nondiscrimination | youth-medical-care | general-lgbtq-equality | general-parental-rights |
  off-domain
- side: "inclusive" (protects/affirms LGBTQ+ students or opposes restrictions) | "restrictive" (limits, or
  puts parents/sex-based rules first) | "mixed" | "none"
- commitment (the most specific thing the text commits the speaker to):
  C0 value/identity only — no issue named ("I stand for every child", "parents matter")
  C1 side on a named issue, no rule ("I oppose the attacks on trans kids", "keep gender ideology out of schools")
  C2 a stated policy outcome — a rule anyone could write down ("trans girls should not compete on girls' teams",
     "parents must be told", "books should stay in libraries")
  C3 a rule PLUS its mechanism or limit ("require written parental consent before a teacher uses a new pronoun",
     "parents can see the records on request", "a review committee with parents decides on book removal")
  C4 reports their own act (a vote, a bill they wrote, a policy they voted on) that states such a rule
- frame (the main justification used, ONE): parental-rights | child-safety-protection | fairness-competition |
  inclusion-belonging | rights-discrimination | privacy | local-control | anti-politicization | religion-values |
  mental-health | none
- proposition: if commitment >= C2, the rule in one plain line, written so that two statements with the same rule
  get the same wording (e.g. "Trans girls may not play on girls' school teams"). Else "".
- note: one short line only if something is unclear.

Write a JSON list to the output path you are given. Then return a short summary (under 150 words).
