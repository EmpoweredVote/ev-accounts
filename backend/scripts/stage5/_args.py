"""Tiny argv helpers shared by the Stage 5 batch tools (run each tool with python3 -I from any directory)."""
import sys


def opt(name, default=None, required=False, usage=''):
    a = sys.argv
    if name in a and a.index(name) + 1 < len(a): return a[a.index(name) + 1]
    if required: raise SystemExit(f'missing {name}. usage: {usage}')
    return default


def opts(name):
    a = sys.argv
    return [a[i + 1] for i, x in enumerate(a) if x == name and i + 1 < len(a)]


def positional(n, usage):
    out, skip = [], False
    for x in sys.argv[1:]:
        if skip: skip = False; continue
        if x.startswith('--'): skip = True; continue
        out.append(x)
    if len(out) < n: raise SystemExit('usage: ' + usage)
    return out
