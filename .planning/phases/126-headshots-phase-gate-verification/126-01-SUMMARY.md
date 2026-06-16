---
phase: 126-headshots-phase-gate-verification
plan: 01
status: complete
completed: 2026-06-16
requirements: [USHR-04]
---

# 126-01 Summary — Headshots for the 299 new House reps

## What was done

- Extended `backend/scripts/seed-national-house-reps.ts` with `--check-photos` (HEAD-validate
  congress photo URLs, bounded-concurrency 20) and `--generate-photos` (emit idempotent UPDATE
  migration). Reuses the bioguide-keyed roster.
- **`--check-photos`**: 292/299 resolved at `https://unitedstates.github.io/images/congress/225x275/{bioguide}.jpg`; 7 MISS (recent members not yet in the images repo).
- **`backend/migrations/769_national_house_rep_photos.sql`** (generated, applied): set
  `photo_origin_url` for the 292 validated reps. `UPDATE 292`, idempotent (guarded `IS NULL`).
  Migration 769 tracked in `schema_migrations`. (Number 769 not 740 — pre-flight found higher DB max.)
- **The 7 misses → `find-headshots`**: all 7 had official 119th-Congress portraits on Wikimedia
  Commons (US govt work, public domain). Downloaded, cropped 4:5, resized 600×750, mirrored to the
  `politician_photos` storage bucket; inserted `politician_images` rows (license `public_domain`);
  set `photo_origin_url` to the self-hosted storage URL.
  - AK-AL Begich, AZ-7 Grijalva, MO-1 Bell, MI-7 Barrett, TN-7 Van Epps, NJ-11 Mejía, GA-14 Fuller

## Verification (USHR-04 met)

- Batch reps (external_id -56999..-1000) with photo: **299 / 299**
- 292 use the canonical `unitedstates.github.io/images/congress/225x275/` format (consistent with existing 148 federal photos)
- 7 use storage-mirrored official congressional portraits + `politician_images` rows
- 0 non-canonical/other-host photos among the 292; photo migration idempotent

## Notes

- The 7 misses are 2026 special-election winners / freshmen the `unitedstates/images` repo hasn't
  published yet (AZ-7 Grijalva, TN-7 Van Epps, NJ-11 Mejía, GA-14 Fuller, plus Begich/Bell/Barrett).
  Their Wikimedia portraits ARE the official congressional portraits, so quality is equivalent.
- Two photo storage patterns now coexist for the batch (both displayable): 292 via direct
  `photo_origin_url` image URL; 7 via storage bucket + `politician_images`. The Phase 126-02 gate
  accommodates both.
