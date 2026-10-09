"""Turn the Opus coder's labels (slot 1) for one person into that person's research.csv + evidence.csv,
for the normal verify-stance-research path (ruling 2026-10-07: Opus alone proposes, a person reviews
every row). Run from backend/:

    python3 scripts/gold-desk/labels_to_research.py <person-batch-dir> <spec.json>

<person-batch-dir> holds the person's full bundle (topics.json, politicians.json). spec.json is the
build_batch.py spec whose batches coded that person; each batch dir must hold labels/coder-1.json.

The coder's answer is copied, never changed: value = v6_value, reasoning = the coder's reasoning,
sources = the URLs of its rests_on snapshots (first three — research.csv has three URL columns; a
longer rests_on is reported). evidence_type is `record` when any rests_on passage is a V3 record,
else `statement`.

A BLANK (v6_value null + v6_blank_reason) is written as value = 0, blank_reason = the coder's reason,
evidence_type = blank (spec docs/superpowers/specs/2026-10-07-season2-blank-review-design.md §3.1, CA_0303).
Its sources are every page the coder EXAMINED — every snapshot that loaded in the row's batch, since the
coder reads all of them — as source_url_1..N (stance-gate reads any number of them). Each examined URL
needs a verbatim snippet of 25+ words: a window around the person's surname first (the verifier looks for
the name near the match), else around the coder's own quote, else the page's opening words (such a page
stays listed as examined but cannot verify, so it is never published). A page under 25 words is left out and
listed in labels-summary.json as examined_without_snippet — it cannot be shown as examined, and if it is
the visible chair's own source, verify-stance-research's blank-unexamined-fallback check will say so.
The reasoning is copied as is: approval adds "Blank in Season N (<reason>) — researched on <date>.".

Each cited URL gets one or two evidence.csv snippets: a verbatim window of the snapshot text (about 60 words)
around the coder's own quote on that page (provision_quote, actor_quote or tally_quote), else around
the person's surname, and a second window around the instrument's number when the first lacks it. It is the page text the coder read, not a paraphrase.
Writes <person-batch-dir>/research.csv, evidence.csv and labels-summary.json.
"""
import csv, json, os, re, subprocess, sys

# Mirrors stanceGate.ts POINTER_ONLY_SOURCE: LWV terms bar citing these, so they are never listed.
POINTER_ONLY = re.compile(r'vote411\.org|thevoterguide\.org', re.I)
MIN_SNIPPET_WORDS = 25  # researchVerifier.ts MIN_SNIPPET_WORDS

person_dir, spec_path = sys.argv[1], sys.argv[2]
spec = json.load(open(spec_path))
date = spec.get('date')
pols = json.load(open(os.path.join(person_dir, 'politicians.json')))
pid = spec['batches'][0]['politician_id']
full_name = next(p['full_name'] for p in pols if p['politician_id'] == pid)
surname = re.sub(r'\b(jr|sr|ii|iii|iv)\.?$', '', full_name.strip(), flags=re.I).split()[-1]
topics = {t['topic_id']: t['topic_key'] for t in json.load(open(os.path.join(person_dir, 'topics.json')))}

OTR_STAMP = re.compile(r'\[\d{1,2}(?::\d{2}){1,2}\]\s*')
def page_text(snap):
  """The snapshot text without a saved-copy provenance line; for an On the Record transcript file (extract-otr.mjs): its header lines are not
  in the transcript and its [m:ss] stamps break the run the verifier matches against the OTR API text, so
  keep only the turn lines, without stamps."""
  # A human-saved copy may open with a provenance line ("Saved from <url> (...)"); it is not page text.
  text = re.sub(r'^\s*Saved from \S+ \([^)]*\)\s*', '', snap['snapshot_text'])
  if 'ontherecord.empowered.vote/meetings/' not in snap['url'] or not text.lstrip().startswith('# On the Record'):
    return text
  first = OTR_STAMP.search(text)  # the snapshot collapses newlines: the header is everything before the first stamp
  return OTR_STAMP.sub('', text[first.start():]).strip() if first else text

def coder_quotes(row, sid):
  """The coder's verbatim quotes from this page (statement evidence carries no provision/actor quote)."""
  return [q.get('text') for q in row.get('quotes', []) if q.get('snapshot_id') == sid and q.get('text')]

def window(text, anchor, words=60):
  """A verbatim run of `text` of about `words` words centred on `anchor` (case-insensitive)."""
  if not anchor: return None
  i = text.lower().find(anchor.lower()[:200])
  if i < 0: return None
  toks = [(m.start(), m.end()) for m in re.finditer(r'\S+', text)]
  k = next((n for n, (a, b) in enumerate(toks) if b > i), 0)
  lo, hi = max(0, k - words // 3), min(len(toks), k + words)
  if hi - lo < 40: lo = max(0, hi - 40)  # near the end of a page: reach back so the snippet keeps 25+ words
  return text[toks[lo][0]:toks[hi - 1][1]]

def instrument_window(text, instrument):
  """A verbatim window around the first place the page prints the instrument ("H.R. 734" as "H. R. 734")."""
  if not instrument: return None
  m = re.match(r'\s*([A-Za-z.\s]+?)\s*(\d+)', instrument.split('(')[0])
  if not m: return None
  letters = [c for c in m.group(1) if c.isalpha()]
  pat = r'\b' + r'\.?\s?'.join(map(re.escape, letters)) + r'\.?\s?' + m.group(2) + r'\b'
  hit = re.search(pat, text, re.I)
  return window(text, text[hit.start():hit.end()]) if hit else None

def blank_rows(row, tk, snaps):
  """A blank's research row and snippets: every examined page that yields a 25+-word verbatim window."""
  passages = {p['snapshot_id']: p for p in row.get('passages', [])}
  by_url = {}
  for sid, snap in snaps.items():
    if not POINTER_ONLY.search(snap['url']): by_url.setdefault(snap['url'], sid)
  urls, ev, without = [], [], []
  for u, sid in by_url.items():
    p, text = passages.get(sid, {}), page_text(snaps[sid])
    # Last resort, the page's opening words: a bill text or bill page often never prints the member's
    # name. The verifier then cannot match the name near it, so it is never PUBLISHED as a citation —
    # but the page stays listed as examined, which is what the fallback rule asks.
    opening = ' '.join(text.split()[:60]) or None
    snip = next((w for w in [window(text, surname)] + [window(text, p.get(f)) for f in ('provision_quote', 'actor_quote', 'tally_quote')] + [window(text, q) for q in coder_quotes(row, sid)] + [opening]
                 if w and len(w.split()) >= MIN_SNIPPET_WORDS), None)
    if not snip: without.append(u); continue
    urls.append(u)
    ev.append({'full_name': full_name, 'topic_key': tk, 'source_url': u, 'snippet': snip, 'snippet_index': '1'})
  r = {'full_name': full_name, 'topic_key': tk, 'value': '0', 'blank_reason': row['v6_blank_reason'], 'evidence_type': 'blank',
       'reasoning': row['reasoning'].strip(), 'quote_text': '', 'quote_deidentified': '', 'editor_note': ''}
  for n, u in enumerate(urls, 1): r[f'source_url_{n}'] = u
  return r, ev, {'examined': len(by_url), 'examined_cited': len(urls), 'examined_without_snippet': without}

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
    if value is None:
      blank_research, blank_evidence, info = blank_rows(row, tk, snaps)
      research.append(blank_research); evidence += blank_evidence
      summary.append({'topic_key': tk, 'batch': b['name'], 'status': 'ok', 'value': 0, 'blank_reason': row['v6_blank_reason'],
        'evidence_type': 'blank', 'needs_source': row.get('needs_source', []), **info})
      continue
    rests = [s for s in row.get('rests_on', []) if s in snaps]
    passages = {p['snapshot_id']: p for p in row.get('passages', [])}
    urls = []
    for s in rests:
      if snaps[s]['url'] not in urls: urls.append(snaps[s]['url'])
    # A bill the reasoning names but rests_on leaves out (context, e.g. an earlier vote) still needs a cited
    # page, or the gate refuses the row (instrument-not-cited): use a free URL slot for the coder's own page.
    ctx_urls = []
    canon = lambda x: re.sub(r'[^a-z0-9]', '', (x or '').split('(')[0].lower())
    named = re.sub(r'[^a-z0-9]', '', row['reasoning'].lower())
    for p in row.get('passages', []):
      sid, ins = p.get('snapshot_id'), canon(p.get('instrument'))
      if sid in snaps and sid not in rests and ins and ins in named and snaps[sid]['url'] not in urls and len(urls) < 3:
        urls.append(snaps[sid]['url']); rests.append(sid); ctx_urls.append(snaps[sid]['url'])
    etype = 'record' if any(passages.get(s, {}).get('v3_class') == 'record' for s in rests) else 'statement'
    reasoning = row['reasoning'].strip()
    research.append({'full_name': full_name, 'topic_key': tk, 'value': '' if value is None else str(value),
      'evidence_type': etype, 'reasoning': reasoning,
      'source_url_1': urls[0] if len(urls) > 0 else '', 'source_url_2': urls[1] if len(urls) > 1 else '',
      'source_url_3': urls[2] if len(urls) > 2 else '', 'quote_text': '', 'quote_deidentified': '', 'editor_note': ''})
    for idx, u in enumerate(urls[:3]):
      sid = next(s for s in rests if snaps[s]['url'] == u)
      p, text = passages.get(sid, {}), page_text(snaps[sid])
      snip = next((w for w in [window(text, p.get(f)) for f in ('provision_quote', 'actor_quote', 'tally_quote')] + [window(text, q) for q in coder_quotes(row, sid)] if w), None) or window(text, surname)
      if snip: evidence.append({'full_name': full_name, 'topic_key': tk, 'source_url': u, 'snippet': snip, 'snippet_index': '1'})
      # A second window around the instrument's number, so the snippets name the bill the reasoning names.
      ins = instrument_window(text, p.get('instrument'))
      if ins and ins != snip: evidence.append({'full_name': full_name, 'topic_key': tk, 'source_url': u, 'snippet': ins, 'snippet_index': '2'})
    summary.append({'topic_key': tk, 'batch': b['name'], 'status': 'ok', 'value': value, 'blank_reason': row['v6_blank_reason'],
      'evidence_type': etype, 'rests_on': len(rests), 'urls_dropped': max(0, len(urls) - 3),
      'needs_source': row.get('needs_source', []), 'context_urls': ctx_urls})
  for k in keys:
    if k not in seen and not any(x['topic_key'] == k and x['batch'] == b['name'] for x in summary):
      summary.append({'topic_key': k, 'batch': b['name'], 'status': 'row-missing'})

# At least three URL columns (the classic shape); more when a blank examined more pages.
n_urls = max([3] + [int(k[11:]) for r in research for k in r if re.fullmatch(r'source_url_\d+', k)])
cols_r = (['full_name', 'topic_key', 'value', 'blank_reason', 'evidence_type', 'reasoning']
          + [f'source_url_{n}' for n in range(1, n_urls + 1)] + ['quote_text', 'quote_deidentified', 'editor_note'])
with open(os.path.join(person_dir, 'research.csv'), 'w', newline='') as f:
  w = csv.DictWriter(f, cols_r, quoting=csv.QUOTE_MINIMAL, restval=''); w.writeheader(); w.writerows(research)
with open(os.path.join(person_dir, 'evidence.csv'), 'w', newline='') as f:
  w = csv.DictWriter(f, ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index']); w.writeheader(); w.writerows(evidence)
json.dump(summary, open(os.path.join(person_dir, 'labels-summary.json'), 'w'), indent=1)
ok = [s for s in summary if s['status'] == 'ok']
print(f"{full_name}: {len(research)} research rows ({sum(1 for s in ok if s['value'] != 0)} chairs, "
      f"{sum(1 for s in ok if s['value'] == 0)} blanks), {len(evidence)} snippets; not ok: "
      + (', '.join(f"{s['topic_key']}={s['status']}" for s in summary if s['status'] != 'ok') or 'none'))
