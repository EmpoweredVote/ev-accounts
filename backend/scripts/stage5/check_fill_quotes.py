"""Check that each quote a bill-text fill gives is in the saved bill text (9 states each kept their own copy of this).

usage: python3 -I scripts/stage5/check_fill_quotes.py --fills <dir> --texts <dir> --state xx [--flag <key>] [--skip <id>]...
                                                      [--worktree <dir>]

--fills  the folder of fill files, one <ID>.json per bill, each with `id` and `operative_text` (one quote per line).
         Only this state's files are read (<XX>-*.json).
--texts  the saved texts, <ID>.<version>.txt, with added words saved as {+ +} and struck words as [- -].
--flag   check only fills where this key is true (the fill brief's on-topic flag). Without it every fill is checked.
--skip   a bill to leave out (for example one whose stored text was kept as it was).

A quote passes when its letters are in the text as printed, or in the text as it reads once struck words are removed.
Section labels at the start of a line are removed first: the common ones ("Sec. 3:", "SECTION 2 (…):", "(a)", "[…]"),
then the legislature's own, from its profile (`fill_quotes.label_strips` in backend/data/legislatures/<xx>.json). A
long quote may break across lines of the text, so it is compared in windows of 8 words and passes when at most a
quarter of the windows miss. Parts of a quote on either side of "..." are checked apart; a part under 6 words is not.
Prints each miss and exits 1 when there is one. 🔴 Run it once on a planted wrong quote before trusting a clean result.
"""
import glob, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, opts
import legislature

USAGE = 'check_fill_quotes.py --fills <dir> --texts <dir> --state xx [--flag <key>] [--skip <id>]... [--worktree <dir>]'
SEC = r'(Sec(tion)?\.?|SECTION|SEC\.)'
def norm(s): return re.sub(r'[^a-z]+', ' ', s.lower()).strip()


def main():
    fills, texts = opt('--fills', required=True, usage=USAGE), opt('--texts', required=True, usage=USAGE)
    xx = opt('--state', required=True, usage=USAGE).lower(); flag, skip = opt('--flag'), set(opts('--skip'))
    leg = legislature.load(xx, opt('--worktree')) or {}
    strips = [re.compile(rx, re.I) for rx in (leg.get('fill_quotes') or {}).get('label_strips') or []]
    files = sorted(glob.glob(os.path.join(fills, f'{xx.upper()}-*.json')))
    if not files: raise SystemExit(f'no {xx.upper()}-*.json in {fills}')
    tot = bad = bills = notext = 0
    for f in files:
        x = json.load(open(f)); iid = x['id']
        if iid in skip or (flag and not x.get(flag)): continue
        raws = [open(p).read() for p in glob.glob(os.path.join(texts, f'{iid}.*.txt'))]
        if not raws: notext += 1; print('NO TEXT', iid); continue
        bills += 1
        plain = lambda r: r.replace('{+', '').replace('+}', '')
        t = ' || '.join(norm(plain(r).replace('[-', '').replace('-]', '')) + ' || ' + norm(plain(re.sub(r'\[-.*?-\]', '', r, flags=re.S))) for r in raws)
        for line in (x.get('operative_text') or '').split('\n'):
            for rx in strips: line = rx.sub(' ', line, count=1)
            m = re.match(r'^\s*' + SEC + r'\s*[\w.\-]+\s*\(.{0,160}?\)\s*:\s*', line, flags=re.I) or re.match(r'^\s*' + SEC + r'\s*[\w.\-]+\s*:\s*', line, flags=re.I)
            q = line[m.end():] if m else line
            if re.match(r'^\s*(Sec|SEC)', q): q = re.sub(r'^\s*' + SEC + r'\s*[\w.\-]+[^:]{0,160}:\s*', '', q, flags=re.I)
            q = re.sub(r'^\s*\[[^\]]*\]\s*', '', q)
            q = re.sub(r'^\s*(\([a-zA-Z0-9]{1,4}\)\s*)+', '', q)
            for part in re.split(r'\s*(?:\.\.\.|…)\s*', q):
                n = norm(part)
                if len(n.split()) < 6: continue
                tot += 1
                if n in t: continue
                w = n.split(); idx = range(0, max(1, len(w) - 7), 4); miss = [i for i in idx if ' '.join(w[i:i + 8]) not in t]
                if len(miss) > len(idx) * 0.25: bad += 1; print('MISS', iid, len(miss), '/', len(idx), '|', part[:120])
    print(f'{bills} bill(s), checked {tot} quote parts; misses {bad}' + (f'; {notext} bill(s) with no saved text' if notext else ''))
    return 1 if bad or notext else 0


if __name__ == '__main__':
    sys.exit(main())
