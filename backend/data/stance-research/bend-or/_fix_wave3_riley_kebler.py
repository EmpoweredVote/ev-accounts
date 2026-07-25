#!/usr/bin/env python3
"""Validation fixes applied to the Riley/Kebler agent output before pushing.

Four changes, all recorded so the calibration decisions stay auditable:
  1. DROP  Riley local-environment=3  — institutional attribution (a policy took effect during his
     term) with no quote and no confirmed personal vote.
  2. DROP  Kebler public-safety-approach=3 — sourced to subcommittee minutes of the POLICE CHIEF
     briefing council, which is not the mayor stating a position.
  3. HOLD  Kebler growth-and-development at 3, rejecting the proposed override to 4.
  4. LOWER Riley homelessness-response 4 -> 3; his own words pair the enforcement vote with the
     city's shelter progress, and Kebler is scored 3 on the same vote.
Run: py data/stance-research/bend-or/_fix_wave3_riley_kebler.py
"""
import json
from collections import Counter

P = 'data/stance-research/bend-or/wave3-riley-kebler.json'

KEBLER_GROWTH = (
    "OVERRIDE REJECTED - value held at 3, but re-evidenced. The agent proposed 4 on the strength "
    "of her December 2024 vote to fast-track a 100-acre UGB expansion (Caldera Ranch) under SB "
    "1537, where she said 'I don't think we can wait' and backed the option offering 'a quicker "
    "path', over Riley's and Campbell's objection that the process was rushed. That is genuinely "
    "more permissive than growth limits, but chair 4's defining content - reducing fees and "
    "actively recruiting development TO GROW THE TAX BASE - is absent: her stated motive "
    "throughout is housing need, and her wider record (income-restricted homes, deed-restricted "
    "units, the tree-code balance) reads as proactive planning. Reviewer note: a defensible case "
    "for 4 exists on the streamlining mechanism alone; it was not taken because overriding a live "
    "value should require decisive rather than arguable evidence."
)

RILEY_HOMELESS = (
    "Riley voted FOR the October 2024 code change cutting allowed vehicle-camping dwell time from "
    "three days to 24 hours, which rules out chair 2 (services first, enforcement only after "
    "services are offered). But the same Bulletin report has him pairing that vote with the city's "
    "shelter build-out - he said the city has made \"incredible progress\" on providing shelter "
    "beds, but there is a lot of work still to do - which is the services-plus-reasonable-rules "
    "midpoint, not chair 4's enforcement-as-primary-tool. Lowered from the agent's proposed 4 for "
    "that reason, and for consistency with Kebler, who is scored 3 on the same vote."
)

DROPS = {
    ('Mike Riley', 'local-environment'):
        'institutional attribution (2024 tree code took effect during his term); no quote, no '
        'confirmed personal vote. KPOV podcast appearance is audio - unmined, logged for next wave.',
    ('Melanie Kebler', 'public-safety-approach'):
        'sourced to Stewardship Subcommittee minutes of the police chief briefing council on a '
        'county deflection program - a staff briefing, not the mayor stating a funding position.',
}

rows = json.load(open(P, encoding='utf-8'))
kept = []
for r in rows:
    key = (r['name'], r['topic_key'])
    if key in DROPS:
        print(f'DROPPED  {key[0]} / {key[1]}={r["value"]}\n         {DROPS[key]}')
        continue
    if key == ('Melanie Kebler', 'growth-and-development'):
        print(f'HELD     Kebler growth-and-development at 3 (agent proposed override to {r["value"]})')
        r['value'] = 3
        r['reasoning'] = KEBLER_GROWTH
    if key == ('Mike Riley', 'homelessness-response'):
        print(f'LOWERED  Riley homelessness-response {r["value"]} -> 3')
        r['value'] = 3
        r['reasoning'] = RILEY_HOMELESS
    kept.append(r)

json.dump(kept, open(P, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
print(f'\nrows kept: {len(kept)}')
for name, n in sorted(Counter(r['name'] for r in kept).items()):
    print(f'  {name:16} {n}')
