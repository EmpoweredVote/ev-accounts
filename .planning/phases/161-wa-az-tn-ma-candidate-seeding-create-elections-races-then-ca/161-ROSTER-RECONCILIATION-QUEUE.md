# Phase 161 — Roster Reconciliation Queue (for 161-11 gate + Phase 167 cull)

## AZ: 5 ballot-ineligible candidates seeded as active (discovered during 161-03 stance research)

These were seeded `candidate_status='active'` in 161-02 (they filed) but live Ballotpedia
checks during 161-03 found them withdrawn/disqualified from the 2026 primary. They have NO
stances (honest-skip: ineligible, not an evidence gap). They must NOT surface as active
candidates on /elections. 161-11 (gate/reconciliation) should set these to
`candidate_status='withdrawn'` (or the project's inactive value) — a targeted correction,
not a Phase-167 post-primary cull item (their ineligibility is known now).

| external_id | name | district |
|-------------|------|----------|
| -40108 | Christopher Ajluni | AZ-1 |
| -40201 | Eric Descheenie | AZ-2 |
| -40402 | Jerone Davison | AZ-4 |
| -40503 | Blake Bracht | AZ-5 |
| -40602 | Iman Bah | AZ-6 |

## AZ: 4 genuine evidence-gap honest-skips (no record found; leave active, no stances)
Aversa (-40301), Fillmore (-40405), Peters (-40603), Butierez (-40701) — documented search
trails in 161-03-SUMMARY.md. These stay active (they are on the ballot) with pinned skips.
