# 107-OCF-ASSESSMENT.md — DC Office of Campaign Finance Accessibility Assessment

**Assessed:** 2026-06-08
**Requirement:** DCFI-02
**Disposition:** Branch B — no accessible API or bulk download; DCFI-02 closed with this finding.

---

## URLs Probed

1. **https://ocf.dc.gov** — main site (HTTP 200)
2. **https://ocf.dc.gov/page/data-and-reports** — OCF's primary data landing page (HTTP 200)
3. **https://ocf.dc.gov/page/campaign-finance-data-and-reports** — campaign finance data sub-page (HTTP 200)
4. **https://ocf.dc.gov/service/view-contributions-expenditures** — contributions and expenditures search service (HTTP 200)
5. **https://ocf.dc.gov/service/financial-reports** — financial reports service page (HTTP 200)
6. **https://ocf.dc.gov/external-link/reports-and-summaries-filer-type** — external link to EFTS summary search (HTTP 200, JS-rendered)
7. **https://opendata.dc.gov** — DC Open Data portal (powered by ArcGIS Hub) (HTTP 200)
8. **https://hub.arcgis.com/api/v3/search?q=campaign+finance+washington+dc** — ArcGIS Hub dataset search for DC campaign finance (HTTP 200, no OCF datasets returned)
9. **https://ocf.dc.gov/api**, **https://ocf.dc.gov/page/developer-resources** — direct API/developer paths (HTTP 404)
10. **https://efts.ocf.dc.gov** — EFTS subdomain (connection refused/no response)

---

## What Was Found

DC OCF's "Data and Reports" section (`ocf.dc.gov/page/data-and-reports`) lists the following access options: Financial Reports (image archive of scanned documents, beginning 2006), Contributions & Expenditures (HTML search form), Registration Disclosures (HTML search form), Biennial Reports (biennial PDF documents), Summary of Campaign Committee Reports (HTML search), and Financial Disclosure Statements (HTML archive). All data access points lead to the agency's EFTS (Electronic Filing and Tracking System) — a web-based search UI that accepts form inputs and returns HTML results. There are no REST API endpoints, no JSON or CSV bulk export downloads, and no downloadable dataset files (aside from PDF biennial reports and scanned image archives of filed documents).

The DC Open Data portal (`opendata.dc.gov`, powered by ArcGIS Hub) was also searched for OCF datasets. A search for "campaign finance" and "OCF" returned no datasets published by the DC Office of Campaign Finance. No Socrata/SODA endpoints exist for OCF campaign contribution data. The OCF is not a contributing agency to the District's open data program as of 2026-06-08.

---

## Disposition

No REST API endpoint or bulk machine-readable download (JSON, CSV, or similar) was identified for DC OCF data. The agency's public data interface is an HTML-only search UI that does not meet the D-05 accessibility threshold.

**DCFI-02 is closed with this finding per D-04/D-05. No OCF ingestion is feasible from public interfaces as of 2026-06-08.** Finance data for Mayor Bowser and DC Council members is not available via automated ingestion; it would require manual extraction from the EFTS HTML interface, which is out of scope per D-05.
