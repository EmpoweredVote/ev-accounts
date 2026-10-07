"""Turn the Opus coder's labels (slot 1) for one person into that person's research.csv + evidence.csv,
for the normal verify-stance-research path (ruling 2026-10-07: Opus alone proposes, a person reviews
every row). Run from backend/:

    python3 scripts/gold-desk/labels_to_research.py <person-batch-dir> <spec.json>

<person-batch-dir> holds the person's full bundle (topics.json, politicians.json). spec.json is the
build_batch.py spec whose batches coded that person; each batch dir must hold labels/coder-1.json.

The coder's answer is copied, never changed: value = v6_value, reasoning = the coder's reasoning,
sources = the URLs of its rests_on snapshots (first three — research.csv has three URL columns; a
longer rests_on is reported). evidence_type is `record` when any rests_on passage is a V3 record,
else `statement`. A BLANK is written with an empty value (verify-stance-research records it as
"insufficient evidence"; it is not queued — there is no blank path into the review queue yet).

Each cited URL gets one evidence.csv snippet: a verbatim window of the snapshot text (about 60 words)
around the coder's own quote on that page (provision_quote, actor_quote or tally_quote), else around
the person's surname. It is the page text the coder read, not a paraphrase.
Writes <person-batch-dir>/research.csv, evidence.csv and labels-summary.json.
"""
import csv, json, os, re, subprocess, sys

person_dir, spec_path = sys.argv[1], sys.argv[2]
spec = json.load(open(spec_path))
date = spec.get('date')
pols = json.load(open(os.path.join(person_dir, 'politicians.json')))
pid = spec['batches'][0]['politician_id']
full_name = next(p['full_name'] for p in pols if p['politician_id'] == pid)
surname = re.sub(r'\b(jr|sr|ii|iii|iv)\.?$', '', full_name.strip(), flags=re.I).split()[-1]
topics = {t['topic_id']: t['topic_key'] for t in json.load(open(os.path.join(person_dir, 'topics.json')))}

def window(text, anchor, words=60):
  """A verbatim run of `text` of about `words` words centred on `anchor` (case-insensitive)."""
  if not anchor: return None
  i = text.lower().find(anchor.lower()[:200])
  if i < 0: return None
  toks = [(m.start(), m.end()) for m in re.finditer(r'\S+', text)]
  k = next((n for n, (a, b) in enumerate(toks) if b > i), 0)
  lo, hi = max(0, k - words // 3), min(len(toks), k + words)
  return text[toks[lo][0]:toks[hi - 1][1]]

research, evidence, summary = [], [], []
for b in spec['batches']:
  d = f"data/stance-research/{date}-shadow-{b['name']}"
  lab = os.path.join(d, 'labels', 'coder-1.json')
  snaps = {s['snapshot_id']: s for s in json.load(open(os.path.join(d, 'snapshots.json'))) if s.get('ok')}
  keys = b.get('topic_keys') or [b['topic_key']]
  if not os.path.exists(lab):
    summary += [{'topic_key': k, 'batch': b['name'], 'status': 'coder-missing'} for k in keys]; continue
  v = subprocess.run(['npx', 'tsx', 'scripts/gold-desk/validate-label.ts', d, '1'], capture_output=True, text=True,
                     env=dict(os.environ, ADMIN_INGEST_TOKEN='x'))
  val = json.loads(v.stdout.strip().splitlines()[-1])
  raw = json.load(open(lab))
  seen = set()
  for n, row in enumerate(raw.get('rows', [])):
    tk = topics.get(row.get('topic_id'))
    errs = val['fileErrors'] + (val['rows'][n]['errors'] if n < len(val['rows']) else ['no validation row'])
    if tk not in keys or tk in seen:
      summary.append({'topic_key': tk, 'batch': b['name'], 'status': 'row-not-in-batch-or-duplicate'}); continue
    seen.add(tk)
    if errs:
      summary.append({'topic_key': tk, 'batch': b['name'], 'status': 'invalid-label', 'errors': errs}); continue
    value = row['v6_value']
    rests = [s for s in row.get('rests_on', []) if s in snaps]
    passages = {p['snapshot_id']: p for p in row.get('passages', [])}
    urls = []
    for s in rests:
      if snaps[s]['url'] not in urls: urls.append(snaps[s]['url'])
    etype = 'record' if any(passages.get(s, {}).get('v3_class') == 'record' for s in rests) else 'statement'
    reasoning = row['reasoning'].strip()
    if value is None: reasoning = f"Blank ({row['v6_blank_reason']}). {reasoning}"
    research.append({'full_name': full_name, 'topic_key': tk, 'value': '' if value is None else str(value),
      'evidence_type': etype, 'reasoning': reasoning,
      'source_url_1': urls[0] if len(urls) > 0 else '', 'source_url_2': urls[1] if len(urls) > 1 else '',
      'source_url_3': urls[2] if len(urls) > 2 else '', 'quote_text': '', 'quote_deidentified': '', 'editor_note': ''})
    for idx, u in enumerate(urls[:3]):
      sid = next(s for s in rests if snaps[s]['url'] == u)
      p, text = passages.get(sid, {}), snaps[sid]['snapshot_text']
      snip = next((w for w in (window(text, p.get(f)) for f in ('provision_quote', 'actor_quote', 'tally_quote')) if w), None) or window(text, surname)
      if snip: evidence.append({'full_name': full_name, 'topic_key': tk, 'source_url': u, 'snippet': snip, 'snippet_index': '1'})
    summary.append({'topic_key': tk, 'batch': b['name'], 'status': 'ok', 'value': value, 'blank_reason': row['v6_blank_reason'],
      'evidence_type': etype, 'rests_on': len(rests), 'urls_dropped': max(0, len(urls) - 3),
      'needs_source': row.get('needs_source', [])})
  for k in keys:
    if k not in seen and not any(x['topic_key'] == k and x['batch'] == b['name'] for x in summary):
      summary.append({'topic_key': k, 'batch': b['name'], 'status': 'row-missing'})

cols_r = ['full_name', 'topic_key', 'value', 'evidence_type', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3', 'quote_text', 'quote_deidentified', 'editor_note']
with open(os.path.join(person_dir, 'research.csv'), 'w', newline='') as f:
  w = csv.DictWriter(f, cols_r, quoting=csv.QUOTE_MINIMAL); w.writeheader(); w.writerows(research)
with open(os.path.join(person_dir, 'evidence.csv'), 'w', newline='') as f:
  w = csv.DictWriter(f, ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index']); w.writeheader(); w.writerows(evidence)
json.dump(summary, open(os.path.join(person_dir, 'labels-summary.json'), 'w'), indent=1)
ok = [s for s in summary if s['status'] == 'ok']
print(f"{full_name}: {len(research)} research rows ({sum(1 for s in ok if s['value'] is not None)} chairs, "
      f"{sum(1 for s in ok if s['value'] is None)} blanks), {len(evidence)} snippets; not ok: "
      + (', '.join(f"{s['topic_key']}={s['status']}" for s in summary if s['status'] != 'ok') or 'none'))
