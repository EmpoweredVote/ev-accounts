# Backend security notes

Accepted risks and the reasoning behind them. This file is for risks we
have deliberately decided to live with. It is **not** a vulnerability
disclosure policy — that belongs in a `SECURITY.md` at the repo root.

---

## Accepted risk: `xlsx` (SheetJS) has two unpatched high-severity advisories

**Status:** accepted, reviewed 2026-08-26
**Package:** `xlsx@0.18.5` (declared in `backend/package.json`)

### The advisories

| Advisory | CVSS | Defect |
|---|---|---|
| [GHSA-4r6h-8v6p-xvw6](https://github.com/advisories/GHSA-4r6h-8v6p-xvw6) | 7.8 | Prototype pollution |
| [GHSA-5pgg-2g8v-p4x9](https://github.com/advisories/GHSA-5pgg-2g8v-p4x9) | 7.5 | Regular expression denial of service (ReDoS) |

### Why there is no patch

SheetJS stopped publishing to npm. The registry copy is frozen at 0.18.5
and will never receive a fix there. Current releases are distributed from
the vendor's own CDN (`https://cdn.sheetjs.com/`). Dependabot therefore
reports "no patched version available" and will keep these alerts open
indefinitely.

### Who can supply a file to the parser

Every `xlsx` call site is in `backend/scripts/`. There are eleven, and
none of them is part of the running service:

| Script | File source |
|---|---|
| `import-indiana-sos-xlsx.ts` | Indiana Secretary of State (`in.gov`), or a local path the operator passes with `--xlsx-path` |
| `importElectionData.ts` | Indiana Secretary of State (`in.gov`) |
| `sample-indiana-candidates.ts` | Indiana Secretary of State (`in.gov`) |
| `census-coverage-report.mts` | US Census Bureau (`census.gov`) |
| `gen-census-enrichment-migration.mts` | US Census Bureau (`census.gov`) |
| `seed-la-county-netfile.ts` | NetFile public portal (`public.netfile.com`) |
| `discover-netfile-filers.ts` | NetFile public portal |
| `_ctl-analysis.ts` | NetFile public portal |
| `_inspect-netfile.ts` | NetFile public portal |
| `_inspect-getexcel.ts` | NetFile public portal |
| `_debug-netfile-raw.ts` | NetFile public portal |

### Why the risk is accepted

Four independent facts, each verifiable:

1. **`src/` contains no reference to `xlsx`.** Not an import, not a
   string. The API surface never touches the parser.
2. **The backend has no file-upload middleware.** No `multer`, no
   `busboy`, no `formidable`, no `multipart/form-data` handling
   anywhere. There is no route through which any user — authenticated
   or not — can submit a spreadsheet.
3. **`scripts/` is not in the server build.** `tsconfig.json` sets
   `include: ["src*"]`, so `scripts/` is never compiled and `dist/`
   contains no `xlsx` code path. The deployed service does not include
   this dependency's call sites at all.
4. **Execution is operator-initiated and local.** These scripts run as
   `npx tsx scripts/<name>.ts` on a developer machine, on demand.

To exploit either advisory an attacker would need to control the bytes
of a spreadsheet that an EV developer then deliberately fetches and
parses. Because the sources are third-party government open-data
portals rather than files we generate ourselves, that is not strictly
impossible — it would require compromising a state or federal data
portal, or intercepting an HTTPS fetch. The payload would then execute
on a developer workstation, not on a server, and would not reach
production data through this path.

We judge that acceptable given the effort required and the absence of
any user-facing route.

### What would change this decision

Re-open this if any of the following becomes true:

- An `xlsx` import appears anywhere under `src/`.
- The backend gains file-upload handling of any kind.
- A script is changed to parse a spreadsheet from a user-supplied or
  arbitrary URL.
- `scripts/` is added to the TypeScript build `include`.

If any of those happens, replace `xlsx` with a maintained parser
(`exceljs`) at the affected call site rather than re-accepting the risk.

### Corresponding alert state

Dependabot alerts #35 and #36 on `EmpoweredVote/ev-accounts` are
dismissed as `tolerable_risk`, pointing at this file. Dismissing keeps
the alert queue meaningful; it does not mean the defect is fixed.
