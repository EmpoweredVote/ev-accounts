# PR alcalde sourcing artifacts

Working data behind migration 1728 (the 78 municipios and their alcaldes) and the still-open
headshot pass. Kept in the repo because two of these are expensive to regenerate — one because
its source rate-limits, one because it is the authoritative roster the migration was built from.

Full narrative + verified negatives: `.planning/todos/2026-08-13-pr-alcalde-headshots.md`.

| File | What it is | Regenerating it |
|---|---|---|
| `cee-mayors-2024-certified.json` | The 78 elected alcaldes: municipio, winner, party, votes, margin. **CEE certified count (2025-02-11), reconciled 78/78 against the es.wikipedia per-municipio tables.** This is the roster migration 1728 was built from. | Cheap but fiddly: fetch `elecciones2024.ceepur.org/Escrutinio_General_123/data/ALCALDES_Municipios.xml` **from inside a Playwright page** (a plain fetch gets HTTP 999), decode ISO-8859-1, then re-parse the es.wikipedia wikitext to cross-check. |
| `ballotpedia-probe.json` | Per-alcalde Ballotpedia probe: which of the 78 have a page (50), which expose a portrait (12), the working title form. | 🔴 **Expensive — BP rate-limits silently with HTTP 202 + a zero-byte body.** Do not re-run casually. |
| `muni-site-liveness.json` | The 78 Wikidata `P856` values probed for liveness AND self-naming. Only 17 pass; 24 point at the defunct `gobierno.pr/OCAM` directory. | Cheap. |
| `muni-domain-sweep.json` | 13 further municipal sites found by testing 18 domain patterns; plus the 48 still unknown. | Cheap (~1,300 requests, no search quota). |

## 🔴 Before using `ballotpedia-probe.json`

The `img` field in it is **NOT TRUSTWORTHY** — it was extracted by taking the first
`ballotpedia-api4` image on the page, and on a BP page that is often **another candidate in the
same race**. Eight of the twelve are demonstrably the wrong person (Caguas's mayor resolved to
`RobertoLopez.jpe`). Only Humacao, Mayagüez, Ponce and San Juan survive a filename-vs-surname
check. Use the `bp_url` / `bp_title` fields, re-extract from the **infobox**, and keep the
filename guard.
