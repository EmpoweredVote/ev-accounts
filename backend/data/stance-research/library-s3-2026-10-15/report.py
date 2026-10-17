"""Summarise the 33 batches: coder chair, report outcome, Stage 3 expected chair, cost. Run from backend/ after
store-snapshots + code-stance-batch --apply + queue-coded-batch --apply (finish.sh)."""
import glob, json, os
here = os.path.dirname(os.path.abspath(__file__))
spec = {}
for f in ('spec-dry.json', 'spec-wave1.json', 'spec-utah.json', 'spec-boards.json'):  # spec-r2.json batches are found by suffix
  for b in json.load(open(os.path.join(here, f)))['batches']: spec[b['name']] = b
rows, total = [], 0.0
for name, b in sorted(spec.items(), key=lambda kv: kv[1]['row_id']):
  d = f'data/stance-research/2026-10-15-shadow-{name}'
  cost = json.load(open(f'{d}/coder-logs/coder-1.out')).get('total_cost_usd') or 0
  if os.path.isdir(d + '-r2'):  # round 2: the coder's requested sources added; that run is the one that counts
    d += '-r2'; cost += json.load(open(f'{d}/coder-logs/coder-1.out')).get('total_cost_usd') or 0
  total += cost
  lab = json.load(open(f'{d}/labels/coder-1.json'))['rows'][0]
  rep = json.load(open(f'{d}/coding-report.json'))['rows'][0]
  chair = lab['v6_value']
  rows.append({'row': b['row_id'], 'person': b['person'], 'expected': b['expected_chair'], 'chair': chair,
               'blank_reason': lab['v6_blank_reason'], 'outcome': rep['outcome']['kind'], 'reasons': rep['shadow_reasons'],
               'match': chair == b['expected_chair'], 'needs_source': lab['needs_source'], 'cost': round(cost, 2),
               'reasoning': lab['reasoning']})
json.dump(rows, open(os.path.join(here, 'results.json'), 'w'), indent=2)
print('| Row | Person | Stage 3 | Coder | Outcome | Cost |\n|---|---|---|---|---|---|')
for r in rows:
  print(f"| {r['row']} | {r['person']} | {r['expected']} | {r['chair'] if r['chair'] is not None else 'blank: ' + str(r['blank_reason'])} "
        f"| {r['outcome']}{' [' + ', '.join(r['reasons']) + ']' if r['reasons'] else ''} | ${r['cost']} |")
q = [r for r in rows if r['outcome'] == 'unanimous-chair']
print(f"\nqueued {len(q)} / {len(rows)}; match Stage 3 {sum(r['match'] for r in rows)} / {len(rows)} "
      f"(queued and matching {sum(r['match'] for r in q)}); coder cost ${total:.2f}")
