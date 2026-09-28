"""Build one Blind Gold Desk item doc from a coded batch. Never reads labels/ or coding-report.json."""
import json, sys
def build(batch_dir, item_id, order, sources_meta, glossary, practice, state, office, instrument, files_dir=None):
    ctx = json.load(open(f'{batch_dir}/coding-context.json'))
    topic = json.load(open(f'{batch_dir}/topics.json'))[0]
    snaps = {s['url']: s for s in json.load(open(f'{batch_dir}/snapshots.json'))}
    srcs = []
    for url, label, summary in sources_meta:
        s = snaps[url]; assert s['ok'], url
        srcs.append({'label': label, 'url': url.split('#')[0], 'summary': summary, 'text': s['snapshot_text'],
                 'has_deleted': '[deleted: ' in s['snapshot_text']})
    doc = {'order': order, 'practice': practice, 'batch': ctx['batch_id'], 'politician_id': ctx['seat']['politician_id'],
           'office_id': ctx['seat']['office_id'], 'topic_key': topic['topic_key'], 'topic_title': topic['title'],
           'person': ctx['seat']['full_name'], 'office': office, 'state': state, 'instrument': instrument,
           'question': topic['question_text'], 'rungs': topic['stances'], 'sources': srcs, 'glossary': glossary}
    # A page-database document holds at most 256 KiB. A long text goes to a file published beside the
    # page (texts/<item>-<n>.txt, see files_dir); the item then names it in text_file.
    import os
    for k, src in enumerate(doc['sources']):
      if len(src['text'].encode()) > 60_000 and files_dir:
        name = f'texts/{item_id}-{k}.txt'
        os.makedirs(os.path.join(files_dir, 'texts'), exist_ok=True)
        open(os.path.join(files_dir, name), 'w').write(src['text'])
        src['text_file'] = name; src['text'] = ''
    n = len(json.dumps(doc).encode())
    assert n < 250_000, f'{item_id} is {n} bytes'
    return doc, n
if __name__ == '__main__':
    spec = json.load(open(sys.argv[1]))
    doc, n = build(**spec['args'])
    json.dump(doc, open(spec['out'], 'w'))
    print(spec['out'], n, 'bytes')
