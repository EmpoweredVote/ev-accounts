# PR alcalde sourcing artifacts

Working data behind migration 1728 (the 78 municipios and their alcaldes) and the still-open
headshot pass. Kept in the repo because two of these are expensive to regenerate — one because
its source rate-limits, one because it is the authoritative roster the migration was built from.

Full narrative + verified negatives: `.planning/todos/2026-08-13-pr-alcalde-headshots.md`.

| File | What it is | Regenerating it |
|---|---|---|
| `cee-mayors-2024-certified.json` | The 78 elected alcaldes: municipio, winner, party, votes, margin. **CEE certified count (2025-02-11), reconciled 78/78 against the es.wikipedia per-municipio tables.** This is the roster migration 1728 was built from. | Cheap but fiddly: fetch `elecciones2024.ceepur.org/Escrutinio_General_123/data/ALCALDES_Municipios.xml` **from inside a Playwright page** (a plain fetch gets HTTP 999), decode ISO-8859-1, then re-parse the es.wikipedia wikitext to cross-check. |
| `ballotpedia-probe.json` | Per-alcalde Ballotpedia probe: which of the 78 have a page (50), which expose a portrait (12 — **an OVERCOUNT, see below**), the working title form. | 🔴 **Expensive — BP rate-limits silently with HTTP 202 + a zero-byte body.** Do not re-run casually. |
| `ballotpedia-infobox-negatives.json` | ✅ **BALLOTPEDIA IS CLOSED.** The 43 BP-paged alcaldes with no photo, each confirmed to carry Ballotpedia's own `SubmitPhoto-150px.png` placeholder in its infobox — BP explicitly stating no photo on file. **The true infobox-portrait count across all 50 pages is 4, all imported in mig 1733.** | **Don't.** It is a closed negative, proven with a 4/4 positive control. |
| `muni-site-liveness.json` | The 78 Wikidata `P856` values probed for liveness AND self-naming. Only 17 pass; 24 point at the defunct `gobierno.pr/OCAM` directory. | Cheap. |
| `muni-domain-sweep.json` | 13 further municipal sites found by testing 18 domain patterns; plus the 48 still unknown. | Cheap (~1,300 requests, no search quota). |
| `eswiki-person-sweep.json` | Per-alcalde es.wikipedia probe: best-matching article title, how many of our name tokens it contains, its lead image and Wikidata QID. Asks whether an article *about the person* carries a portrait — a different question from the municipio item's `P6`. **5 real hits; net new = Gurabo, plus upgrades for Humacao and San Juan.** | Cheap (~78 searches + 78 pageimages calls, ~1 min). |

## 🔴 Before using `eswiki-person-sweep.json`

`name_tokens_in_title` is a **weak** signal: **3 of the 8 apparent hits are the wrong person**, all
three the two-surname trap — Carolina's José Carlos Aponte **Dalmau** matched *José Luis Dalmau*,
Coamo's Juan Carlos **García Padilla** matched *Alejandro García Padilla* (the former **Governor**),
and Toa Baja's **Bernardo Márquez García** matched *José Bernardo Márquez*. **Two shared surname
tokens is not a match.** Confirm against the `LOCAL_EXEC` seat before using any row, and prefer a
filename that names the office (`Alcaldesa_<name>.jpg`).

## 🔴 Before using `ballotpedia-probe.json`

The `img` field in it is **NOT TRUSTWORTHY** — it was extracted by taking the first
`ballotpedia-api4` image on the page, and on a BP page that is often **another candidate in the
same race**. Eight of the twelve are demonstrably the wrong person (Caguas's mayor resolved to
`RobertoLopez.jpe`). Only Humacao, Mayagüez, Ponce and San Juan survive a filename-vs-surname
check — and the 2026-08-12 infobox pass proved those 4 are **all** that exist.

**The mechanism, now confirmed:** the subject's portrait is `<img class="widget-img">` inside
`<div class="infobox person">`; the decoys are `<img class="image-candidate-thumbnail">` inside
`<table class="results_table">`, **one per candidate in the race**. On all 8 wrong-person pages the
infobox holds no portrait at all, and that lone results-table thumbnail was an opponent's. Only the
`bp_url` / `bp_title` fields here are safe to reuse.
