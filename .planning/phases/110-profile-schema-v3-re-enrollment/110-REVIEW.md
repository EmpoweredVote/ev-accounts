---
phase: 110-profile-schema-v3-re-enrollment
reviewed: 2026-04-11T12:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - CouncilScribe/reenroll_profiles.py
  - CouncilScribe/src/config.py
  - CouncilScribe/src/enroll.py
  - CouncilScribe/src/roster.py
  - CouncilScribe/tests/test_profile_v3.py
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 110: Code Review Report

**Reviewed:** 2026-04-11T12:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The profile schema v3 changes add `politician_slug` and `politician_id` identity fields to `StoredProfile`, introduce roster-aware enrollment keying via `resolve_enrollment_key`, and wire body-slug awareness into the re-enrollment script. The core enrollment path (`enroll_speakers`, `enroll_confirmed`, `reenroll_profiles.py`) is well-implemented and thoroughly tested.

Two areas of concern: (1) pickle deserialization of profile data from disk is an arbitrary code execution risk, and (2) `fix_profiles_with_roster` and `rename_profile` do not use the new `resolve_enrollment_key` function, so roster-matched profiles will not be promoted to `essentials:` keys when those functions are used.

## Critical Issues

### CR-01: Arbitrary code execution via pickle.load on profile database

**File:** `CouncilScribe/src/enroll.py:49`
**Issue:** `pickle.load(f)` deserializes arbitrary Python objects from a file on disk. If the profile pickle file is tampered with (e.g., via a supply-chain issue, shared drive compromise, or malicious file substitution), it can execute arbitrary code. The profile DB is stored on Google Drive (Colab path) or a local home directory, both of which could be writable by other processes.
**Fix:** Consider migrating to a safer serialization format. For numpy arrays, store embeddings separately as `.npy` files and use JSON for metadata. Alternatively, validate the unpickled object more defensively:

```python
import io
import pickle

class RestrictedUnpickler(pickle.Unpickler):
    """Only allow unpickling of known safe types."""
    SAFE_MODULES = {"src.enroll", "numpy", "numpy.core.multiarray", "builtins"}

    def find_class(self, module, name):
        if module.split(".")[0] in {"numpy", "builtins"} or module == "src.enroll":
            return super().find_class(module, name)
        raise pickle.UnpicklingError(f"Blocked unpickling of {module}.{name}")

def load_profiles() -> ProfileDB:
    path = _db_path()
    if path.exists():
        with open(path, "rb") as f:
            db = RestrictedUnpickler(f).load()
        # ... rest of validation
```

## Warnings

### WR-01: fix_profiles_with_roster does not produce essentials-keyed profiles

**File:** `CouncilScribe/src/enroll.py:313-333`
**Issue:** `fix_profiles_with_roster` calls `rename_profile`, which uses `_name_to_slug(new_display_name)` to compute the new key. It does not call `resolve_enrollment_key`, so even when a roster match with a `politician_slug` is found, the profile will be keyed as a local slug (e.g., `piedmont-smith_councilmember`) rather than `essentials:isabel-piedmont-smith`. This creates an inconsistency: profiles enrolled via `enroll_speakers` get the `essentials:` prefix, but profiles corrected via `fix_profiles_with_roster` do not.
**Fix:** Pass the roster into `fix_profiles_with_roster` (it already receives it) and use `resolve_enrollment_key` for re-keying:

```python
def fix_profiles_with_roster(db: ProfileDB, roster) -> list[str]:
    from .roster import correct_speaker_name

    changes = []
    renames = []
    for slug, profile in list(db.profiles.items()):
        corrected = correct_speaker_name(profile.display_name, roster)
        if corrected != profile.display_name:
            renames.append((slug, corrected, profile.display_name))

    for old_slug, new_name, old_name in renames:
        new_key, pol_slug, pol_id = resolve_enrollment_key(new_name, roster)
        if old_slug == new_key:
            continue
        profile = db.profiles.pop(old_slug)
        if new_key in db.profiles:
            target = db.profiles[new_key]
            target.embeddings.extend(profile.embeddings)
            for mid in profile.meetings_seen:
                if mid not in target.meetings_seen:
                    target.meetings_seen.append(mid)
            target.total_segments_confirmed += profile.total_segments_confirmed
            if pol_slug and not target.politician_slug:
                target.politician_slug = pol_slug
                target.politician_id = pol_id
            target.recompute_centroid()
        else:
            profile.speaker_id = new_key
            profile.display_name = new_name
            profile.politician_slug = pol_slug
            profile.politician_id = pol_id
            db.profiles[new_key] = profile
        changes.append(f"{old_slug} ({old_name}) -> {new_key} ({new_name})")

    return changes
```

### WR-02: rename_profile does not preserve or set identity fields

**File:** `CouncilScribe/src/enroll.py:250-280`
**Issue:** When `rename_profile` re-keys a profile, it updates `speaker_id` and `display_name` but does not set `politician_slug` or `politician_id`. If the rename moves a profile to a name that should be roster-matched (and thus essentials-keyed), the identity fields remain None. Additionally, when merging into an existing profile (line 266-273), the source profile's identity fields are silently dropped.
**Fix:** Add optional `politician_slug` and `politician_id` parameters to `rename_profile`, or have it accept a roster and call `resolve_enrollment_key` internally. At minimum, preserve identity fields during merge:

```python
def rename_profile(
    db: ProfileDB,
    old_slug: str,
    new_display_name: str,
) -> bool:
    if old_slug not in db.profiles:
        return False

    new_slug = _name_to_slug(new_display_name)
    profile = db.profiles.pop(old_slug)

    if new_slug in db.profiles:
        target = db.profiles[new_slug]
        target.embeddings.extend(profile.embeddings)
        for mid in profile.meetings_seen:
            if mid not in target.meetings_seen:
                target.meetings_seen.append(mid)
        target.total_segments_confirmed += profile.total_segments_confirmed
        # Preserve identity fields from source if target lacks them
        if profile.politician_slug and not target.politician_slug:
            target.politician_slug = profile.politician_slug
            target.politician_id = profile.politician_id
        target.recompute_centroid()
    else:
        profile.speaker_id = new_slug
        profile.display_name = new_display_name
        db.profiles[new_slug] = profile

    return True
```

## Info

### IN-01: add_alias only supports legacy roster path, not per-body slug path

**File:** `CouncilScribe/src/roster.py:234-290`
**Issue:** `add_alias` hardcodes the legacy `council_roster.json` path and does not support the per-body slug path (`CONFIG_DIR/rosters/{body_slug}.json`). This means aliases cannot be added to per-body roster caches, which are the new standard for Phase 108+ bodies.
**Fix:** Add a `body_slug` parameter mirroring `load_roster`'s dual-path pattern, or document that `add_alias` is legacy-only and aliases for per-body rosters should be managed through the refresh workflow.

---

_Reviewed: 2026-04-11T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
