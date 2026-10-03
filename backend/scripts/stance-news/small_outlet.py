"""Name-only sweep for a SMALL local outlet, then topic-filter the passages.

Query breadth has to match outlet size. On WFAE, name-only was under-powered and
name+topic was right. On The Bradenton Times the opposite holds: plain "Kocher"
returns 20 results including her own Council Corner column, while
"Jayne Kocher economic development incentives" returns none and falls back to
the default listing. A big outlet needs narrowing; a small one needs widening.

    python small_outlet.py <out-dir> <cfg.json> <search-url-with-{q}>
"""
import html as H, io, json, os, re, subprocess, sys, time, urllib.parse

from links import article_links

TOPIC_WORDS = {
    "housing": r"affordable housing|housing|rent|apartment",
    "residential-zoning": r"zoning|density|rezon|duplex|single-family",
    "growth-and-development": r"growth|development|annex|comprehensive plan",
    "homelessness": r"homeless|encampment",
    "homelessness-response": r"homeless|shelter|services",
    "public-safety-approach": r"police|public safety|crime|officer",
    "transportation-priorities": r"transit|traffic|road|sidewalk|bike|bus",
    "climate-change": r"climate|energy|solar|carbon|resilien",
    "local-environment": r"environment|water|tree|river|bay|stormwater",
    "data-centers": r"data cent",
    "city-sanitation": r"sanitation|garbage|trash|litter|solid waste",
    "economic-development": r"economic development|incentive|business|redevelop",
    "civil-rights": r"equity|discriminat|civil rights|racial",
    "religious-freedom": r"religio|nondiscriminat|lgbt",
    "childcare": r"child ?care",
    "cannabis-policy": r"cannabis|marijuana",
    "2020-election": r"2020 election|election fraud|stolen election",
}


def curl(url, dest):
    pr = subprocess.run(["curl", "-sS", "-L", "-m", "35", "-o", dest, "-w", "%{http_code}", url],
                        capture_output=True, text=True)
    return (pr.stdout or "").strip()[-3:]


def blocks(raw):
    b = re.sub(r"(?is)<(script|style|noscript|svg|nav|footer|aside)[^>]*>.*?</\1>", " ", raw)
    t = H.unescape(re.sub(r"(?s)<[^>]+>", "\n", b)).replace("​", "")
    t = re.sub(r"[ \t\xa0]+", " ", t)
    t = re.sub(r"\n\s*\n+", "\n", t)
    return [l.strip() for l in t.split("\n") if len(l.strip()) > 90]


def main():
    out, cfgp = sys.argv[1], sys.argv[2]
    # Accept either one template on argv[3] or every outlet in the config.
    tpls = [sys.argv[3]] if len(sys.argv) > 3 else None
    cfg = json.load(io.open(cfgp, encoding="utf-8"))
    raw_dir = os.path.join(out, "raw")
    os.makedirs(raw_dir, exist_ok=True)
    hits = {}
    for member, aliases in cfg["members"].items():
        surname = aliases[0].split()[-1]
        # Query the SURNAME alone: on a small outlet a multi-word query returns
        # nothing and falls back to the default listing, which reads as "no
        # coverage". Topic filtering happens below, on the article text.
        templates = tpls or [o["search"] for o in cfg["outlets"]]
        arts = []
        for tpl in templates:
            url = tpl.replace("{q}", urllib.parse.quote(surname))
            tmp = os.path.join(raw_dir, "_s.html")
            if curl(url, tmp) != "200":
                continue
            raw = io.open(tmp, encoding="utf-8", errors="replace").read()
            arts += [a for a in article_links(raw, url, limit=25) if a not in arts]
        hits[member] = {t: [] for t in TOPIC_WORDS}
        kept_any = 0
        for u in arts:
            key = re.sub(r"[^a-z0-9]+", "-", u.lower())[-80:]
            af = os.path.join(raw_dir, key + ".html")
            if curl(u, af) != "200":
                continue
            txt = "\n".join(blocks(io.open(af, encoding="utf-8", errors="replace").read()))
            low = txt.lower()
            if not any(a.lower() in low for a in aliases):
                continue
            kept_any += 1
            for topic, pat in TOPIC_WORDS.items():
                if re.search(pat, low, re.I):
                    hits[member][topic].append(u)
            time.sleep(0.15)
        print("%-22s results=%2d naming_member=%2d topics_hit=%2d"
              % (member, len(arts), kept_any,
                 len([t for t, v in hits[member].items() if v])), flush=True)
    io.open(os.path.join(out, "hits.json"), "w", encoding="utf-8").write(
        json.dumps(hits, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    main()
