# OnBoard feed fixtures

Verbatim downloads of the City of Bloomington OnBoard JSON feeds (public city data).
Fetched 2026-11-26.

- `legislation-2026.json`: https://bloomington.in.gov/onboard/committees/1/legislation?year=2026;format=json (54 items)
- `meetings-2026.json`: https://bloomington.in.gov/onboard/committees/1/meetings?year=2026;format=json
- `minutes/*.txt` (2026-10-07, 2021-05-05, 2021-04-07, 2021-05-19, 2022-05-04): approved Common Council minutes
  (public city records, OnBoard meeting files) as layout text, copied verbatim from the local inventory's
  `store-staging/minutes/` folder (`.planning/research/local-inventory/bloomington-in/`).
- `minutes/2026-10-07.pdf`: the clerk's Memorandum for the 2026-10-07 Special Session ("2026.10.07.SS.Memo.pdf",
  OnBoard meeting file 17565, https://bloomington.in.gov/onboard/meetingFiles/17565/download), verbatim, 101,711 bytes.
  It is a Memorandum, not formal Minutes; `2026-10-07.txt` is the layout text of the same document. The test
  checks that parsing the PDF gives the same result as parsing the text.
- `minutes/2023-04-19-page3.runs.json`: the positioned text runs (`extractPdfItems`) of page 3 of the 2023-04-19 Regular
  Session minutes (OnBoard meeting file 12969, https://bloomington.in.gov/onboard/meetingFiles/12969/download),
  verbatim. The margin heading "Vote to adopt" starts 2.8 character widths after the body text ends.
