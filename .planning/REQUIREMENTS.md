# Requirements: Empowered Accounts — v2.7 Source Integrity

**Defined:** 2026-06-05
**Core Value:** Every stance in the DB can be traced to a real primary source — no unverifiable claims, no directional guesses passed off as confirmed positions.

## v2.7 Requirements

### SRCA — Source Coverage Audit

- [ ] **SRCA-01**: DB audit report produced — total stances in `inform.politician_answers`, count and % with a real source URL (non-empty `sources[]` in `inform.politician_context` with at least one non-placeholder URL), breakdown by tier (Federal / State / Local / City); defines the operationalized "sourced" standard for the rest of the milestone
- [ ] **SRCA-02**: Prioritized target list produced — all politicians with any unsourced stances ranked by tier (federal → state → local → city) then prominence within tier; politicians with majority of stances unsourced flagged as likely old-methodology seeding requiring full re-research pass

### FEDX — Federal Remediation

- [ ] **FEDX-01**: Every US Senator stance: re-researched with Chair methodology → has real source URL in `politician_context`, or has been deleted from `politician_answers`
- [ ] **FEDX-02**: Every US House representative stance: re-researched with Chair methodology → has real source URL, or has been deleted

### STAX — State + Local Remediation

- [ ] **STAX-01**: Every CA state legislator (CA Assembly + CA Senate) stance: sourced or deleted
- [ ] **STAX-02**: All MD politicians in DB (added in migrations 269–271 — MD executive branch officials): stances do not yet exist; research and add full stance coverage using Chair methodology with at least one real source URL per stance
- [ ] **STAX-03**: Every city official (SF, San Jose, San Diego, Berkeley, Fremont) stance: sourced or deleted

### QUAL — Quality Methodology

- [ ] **QUAL-01**: Every stance updated, confirmed, or added during this milestone: value verified against the specific Chair text for that topic — the politician's known position must match the exact stance text for that value, not just the directional lean
- [ ] **QUAL-02**: Deletion log produced — each deleted stance records politician full_name, topic_key, former value, and reason ("no evidence found" or "value incorrect and no correcting source found")

## Future Requirements

### Source Monitoring

- **SMON-01**: Automated URL health check — flag context rows whose source URLs return 404 or redirect unexpectedly
- **SMON-02**: Source quality scoring — distinguish primary sources (official statements, legislative votes) from secondary (news reporting, endorsements)

### API Source Transparency

- **APIX-01**: `has_source: boolean` derived field on `GET /api/essentials/politicians/:id/stances` — allows frontends to visually distinguish sourced vs. pending stances without changing the data model

## Out of Scope

| Feature | Reason |
|---------|--------|
| Adding stances for politicians not currently in DB | New politician records are outside v2.7 scope; MD officials (269–271) are the only exception per milestone definition |
| Automated web scraping or NLP source extraction | Manual research with research-stances skill is the established methodology; automation is a future project |
| Election data source integrity | Elections have a different schema (`essentials.elections`) and separate data pipeline |
| Finance data source integrity | `finance_summary` is FEC-sourced by definition; out of scope for this audit |
| Re-researching stances that already have sources | Audit only — if a stance has a real source URL already, it is not touched unless the value is clearly wrong |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SRCA-01 | — | Pending |
| SRCA-02 | — | Pending |
| FEDX-01 | — | Pending |
| FEDX-02 | — | Pending |
| STAX-01 | — | Pending |
| STAX-02 | — | Pending |
| STAX-03 | — | Pending |
| QUAL-01 | — | Pending |
| QUAL-02 | — | Pending |

**Coverage:**
- v2.7 requirements: 9 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 9 ⚠

---
*Requirements defined: 2026-06-05*
*Last updated: 2026-06-05 after initial definition*
