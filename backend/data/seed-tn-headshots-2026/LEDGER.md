# Tennessee General Assembly portraits — extraction ledger, 2026-09-24

**131 seated legislators extracted, 0 failures, 130 to import.** Proof sheet published for
approval: <https://claude.ai/artifact/7ksjh4rCa2pfg1ksjRRzJ7>

Licence and ruling: [`.planning/research/2026-09-24-tennessee-legislature-portraits.md`](../../../.planning/research/2026-09-24-tennessee-legislature-portraits.md)
· request letter: [`GENERAL-ASSEMBLY-RESOLUTION-REQUEST.md`](./GENERAL-ASSEMBLY-RESOLUTION-REQUEST.md)

```
extracted        131
vacant on the GA   1   H84 -- and the GA's own page says "Vacant"
problems           0
name agreement   {'exact': 131}
already ours       1   H86 Justin J. Pearson
carrying rights   16   (author named on 14)
accounted for    132 of 132
```

## ⚠ `portraits/` IS NOT COMMITTED — REGENERATE IT

34 MB of PNGs, against a repo that carries 3 image files in `backend/data` in total. The
extractor is deterministic and the page cache makes a re-run free:

```bash
py scripts/tn-ga-portrait-extract.py --out-dir data/seed-tn-headshots-2026
```

`tn-candidates.json` points every row at `portraits/<district>.png` through `bytes_from`, and
both the proof sheet and the importer read **that same file** — so what was approved is what
ships, which is the rule the shared disk cache exists to keep.

## The binding, and why it is not positional

🔴 **`?district=H7` NAMES A SEAT, NOT A PERSON.** A departed member's district page serves
their successor, so binding on the district alone would seat the wrong face silently.

The page that carries the portrait also carries the member's name in its `<h1>`, so every row
is bound by `(mtfcc, geo_id)` **and** asserted against that name. **131 of 131 agree exactly.**
A disagreement would have been reported, never auto-resolved — it is either a nickname or a
roster change, and both need a human.

✅ **AND THE PAIRING WAS CONTROLLED AGAINST A SOURCE WE DID NOT EXTRACT.** One of the 131 —
H86, Justin J. Pearson — already carried a portrait from an independent source. Ours (an
outdoor candid) and the extracted GA studio portrait are unmistakably the same person. That is
the only row where the GA's own name/photo pairing could be checked from outside, and it holds.

✅ **H84 is vacant from two directions**: the GA page says "Vacant", and our database seats 98 of
99 House members. Neither number was inferred from the other.

## What the frames look like

🔴🔴 **ALL 131 WERE LOOKED AT**, as a montage of the production crops, before the sheet was
published. Every one is a genuine studio portrait on a uniform warm-grey gradient — no badges,
no placeholders, no group shots, no seals. Two backdrops differ (a flag behind Lt. Gov. Randy
McNally) and both are real official portraits.

- **Monochrome: 0 of 131**, agreed from two directions. `headshot_crop.monochrome()` ran inside
  the renderer over every shipped crop — **chroma min 21.0, median 37.4, max 98.7, nothing
  flagged** — and an independent hand measure with its own control (a colour frame at 25.8
  against the same frame forced to grey at 0.0) found the same zero.

  🔴 **AND A STALE WORKING TREE ALMOST PUT A FALSE CLAIM IN THIS LEDGER.** A grep for
  `monochrome` over `C:\EV-Accounts\backend\scripts` came back with nothing but a hand-written
  rejection list, and was written up as *"the standing rule is enforced by nothing"* — the exact
  regression SC-5a paid 156 published frames for. It is wrong. That checkout sits on an older
  branch whose `headshot_crop.py` predates SC-5a, so the grep was reading a file from before the
  gate existed. `git grep` over the refs found `def monochrome` on master and on this branch, and
  both the renderer and the importer import it.
  ▶ **GREP A REF, NOT A WORKING TREE, WHEN THE QUESTION IS "DOES THIS REPO DO X".** A shared
  checkout is on whatever branch its last session left it on. ⚠ The commit message on
  `data/tn-legislature-portraits` carries the wrong version of this and is corrected here rather
  than by rewriting a pushed commit.
- **Sizes: 129 at 400x400, one 400x405, one 381x400.** So the crop cannot assume 1:1.
- **House portraits are RGBA**; alpha is composited onto white by `headshot_crop.flatten`, which
  is what stops a transparent PNG shipping as a black square.
- **The 4:5 crop keeps FULL HEIGHT** — 400x400 becomes 320x400 — so no head is newly cut. The
  tightest frames (Timothy Hill, David B. Hawk, Cameron Sexton) are tight **in the source**;
  there are no pixels above the head to recover, and padding them would be inventing some.

### 🔴 A DETECTOR THAT ANSWERED 131 OF 131 — AND WAS BLIND

The first crop check used `headshot_crop.subject_bbox`, which finds "everything that is not
near-white". It reported **every one of the 131 as clipped, with an identical bbox of 0–400**.

That uniform answer is the tell. These portraits have a **full-bleed gradient backdrop**, so
nothing in the frame is near-white and the bounding box is the whole image. The function is
correct for a subject on a white field and **inapplicable to a studio backdrop** — it was
measuring the background, not the person.

It was replaced with a dark-mass-per-column measure (hair, suit and tie against a light
backdrop), which puts the median loss at **12.2%** and the worst at **24.9%** — shoulders, not
heads — and then the riskiest twelve were **looked at, full frame beside shipped crop**.
▶ **Do not use `subject_bbox` on a source whose background fills the frame.**

## Resolution

**Every portrait is 400x400.** After the 4:5 crop that is 320x400, so reaching 600x750 would cost
**1.88x on all 130**. Per the ruling of 2026-09-24 nothing is enlarged: `--max-upscale 1.0`, and
each frame stores at its own cropped size. The proof sheet renders exactly that — the cards lay
out at 600x750 and the browser scales them, as the site does — so the operator approved the real
pixels, not an enlargement.

The resolution request to the Chief Clerks is the upgrade path. If originals arrive, re-run with
`--replace`.

## Licence recorded per row

`photo_license` carries the terms, so the obligation travels with the row rather than living in
a planning file:

> `(C) State of Tennessee — editorial or personal use only (Tennessee General Assembly official
> member portrait)` — plus `. Photo by Jed DeKalb` on the 14 rows whose file names him.

⚠ **The 112 rows carrying no metadata get the same line**, because they are the same photographs
from the same publisher, re-saved by a tool that dropped the fields. **A stripped file is not
unencumbered.** ⚠ `Copyright = x-default` is an empty XMP placeholder and is read as absent —
three rows carry it, which is why this ledger says 16 and a naive count says 19.
