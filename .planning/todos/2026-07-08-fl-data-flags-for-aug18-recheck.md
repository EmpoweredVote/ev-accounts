# FL data flags found during headshot sweep (2026-07-08) — fold into the ≥ Aug-18 FL re-check

Found while sweeping FL headshots (Phase 153 re-check is calendar-gated ≥ 2026-08-18; these are
reconciliation inputs, not urgent fixes):

1. **FL 20–25 geo/office rotation**: sitting reps sit on wrong geo districts —
   Wasserman Schultz pid `097623b0` on geo 1220 (really FL-25, her external_id -12025 is correct),
   Frankel pid `b4040115` on geo 1223 (really FL-22, ext -12022 correct),
   Moskowitz pid `1cb8827c` on geo 1225 (really FL-23, ext -12023 correct).
   external_ids are authoritative; office_id→district linkage looks rotated for those seats.
2. **Sheila Cherfilus-McCormick** (sitting FL-20 rep, pid in geo 1220 challenger set): record has
   NO party and NO is_incumbent flag — she surfaced in the challenger-gap query. Her headshot was
   imported via the challenger path 2026-07-08.
3. **Name corrections** (agent-verified vs Ballotpedia + FEC):
   - "Seth Haskins" (FL-19) → real name **Seth Haskin** (BP `Seth_Haskin`, campaign site sethhaskinforfl.com)
   - "Kedner MaximeDe" (FL-20) → real name **Kedner Maxime** (BP `Kedner_Maxime`; FEC "MAXIME, KEDNER";
     committee "DR KEDNER MAXIME FOR CONGRESS")
   - "Mayonna Te Brown" (FL-24) → ballot name **Te Brown** / full "Te Mayonna Brown" (BP `Te_Brown`,
     floridapolitics qualifying coverage)
4. **Photo-less pinned skips** (search trails in agent outputs, session 2026-07-08): Mike Sell FL-4
   (B&W-only — monochrome rule), Christopher Dennison FL-7, Brian Lambert FL-14 (beware judge homonym
   whose BP photo file is literally `Brian_Lambert.JPG`), Michael Quirk FL-17, Mark Piper FL-23,
   Deborah Ann Meidinger Hosey FL-26.
