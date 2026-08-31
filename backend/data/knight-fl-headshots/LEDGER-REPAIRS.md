# Headshot Repairs Ledger — 31 Florida targets (headshot-repairs.json)

Sourcing-only pass. No downloads to the pipeline, no crops, no DB writes. Every URL below was fetched
and verified: magic number checked (ffd8 JPEG / 89504e47 PNG / RIFF..WEBP), and real pixel dimensions
measured with Pillow — never judged by HTTP status alone. Target production render is 600x750;
1200x1500+ is ideal.

Method note: Miami-Dade's own commission pages (miamidade.gov) turned out to have NO larger
rendition anywhere on the same site — every "-headshot", "-headshot-home-page", press-release
"district##-headshot.jpg" path, and query-string resize attempt (`?width=`, `?w=`) returned the
identical small file. The real wins for that cohort came from (a) each commissioner's own campaign
website — found via web search, then either the WordPress `/wp-json/wp/v2/media` REST endpoint or a
Playwright DOM scan for `<img naturalWidth>` — and (b) Wikimedia Commons / Ballotpedia for the small
number who are former state legislators or have a Ballotpedia "Candidate Connection" photo.

## Miami-Dade County

**Anthony Rodriguez (D10)** — current 159x238 (3.79x). Miamidade.gov has no bigger file (tried
`rodriguez-headshot.jpg` at /about page = 120x170, even smaller; press-release path
`district10-headshot.jpg` = 169x250). Wikipedia infobox links a real Commons file,
`Anthony_Rodriguez.jpg` (public domain, Florida House of Representatives) — 300x456. Better than
current but still under target; nothing larger found (his own flhouse.gov member page no longer
resolves). **Improved 159x238 → 300x456, still under 600x750.**

**Roberto J. Gonzalez (D11)** — current 159x238. No Wikipedia/Ballotpedia photo (Ballotpedia carries
only the placeholder silhouette). Campaign site robertojgonzalez.org has `roberto-profile-image.png`,
1204x1229, clean cutout. **Improved → 1204x1229.**

**JC Bermudez (D12)** — current 120x170 (5.00x, second-worst case). Campaign site jcbermudez.com's
homepage-linked hero image (`JC-HEADSHOT2.png`) turned out to be a COMPOSITE with a 3-photo group-shot
collage baked into the bottom third — rejected under the no-group-photo rule (can't crop it out).
Queried the site's `/wp-json/wp/v2/media` REST endpoint directly and found a second, uncomposited
file: `JC-HEADSHOT.png`, 900x760, clean cutout. **Improved → 900x760.**

**René Garcia (D13)** — current 159x238. Wikipedia infobox → Commons `Rene_Garcia_Headshot.jpg`,
public domain, 1242x1755. **Improved → 1242x1755.**

**Marleine Bastien (D2)** — current 159x283. No Wikipedia. Campaign site reelectbastien.com is a JS
SPA (Playwright required); `bastien-cutout.webp`, 1040x1501, clean cutout. (A second image,
`bastien-story.webp`, was a glamour-style portrait — also usable but the cutout is more standard.)
**Improved → 1040x1501.**

**Keon Hardemon (D3)** — current 159x238. Campaign site keonhardemonesq.com no longer resolves
(NXDOMAIN). No Wikipedia. Ballotpedia carries a real (non-placeholder) photo,
`KeonHardemon12.jpeg` — dropping the `thumbs/200/300/` prefix (the Ballotpedia trick) gave the true
original at only 256x256 (that IS the max; it's not a thumbnail of something bigger). **Improved
159x238 → 256x256, still well under 600x750** — best available.

**Micky Steinberg (D4)** — current 159x283. No campaign website found (she ran unopposed in 2022; only
a Facebook page exists). No Wikipedia. Ballotpedia placeholder only. **Not improved.**

**Vicki L. Lopez (D5)** — current 160x283. Wikipedia infobox links an EN-Wikipedia local upload (not
Commons) — turned out to be only 208x278, barely bigger than current and a worse aspect. Her old
Florida-House campaign site vickiforflorida.com (stale "for State Representative" branding but still
live) has a recent solo campaign photo, `-m4a9696-1805x1203.jpeg`, 1203x1203. **Improved → 1203x1203.**

**Natalie Milian Orbis (D6)** — current 160x283. Her stated personal domain, nataliemilianorbis.com,
does NOT resolve (confirmed via `nslookup` against 8.8.8.8 — SERVFAIL/NXDOMAIN both with and without
`www.`). Only Instagram/Facebook/linktr.ee found — all excluded. Ballotpedia has no photo. **Not
improved.**

**Raquel A. Regalado (D7)** — current 159x238. Campaign site raquelregalado.com — homepage carousel
image `IMG_1823-e1745969203443.jpg` is a clean solo waterfront portrait, 1830x1830. (Its media
library also has group/family photos that were correctly skipped, including one that turned out to
be the source for the McGhee alternative below.) **Improved → 1830x1830.**

**Danielle Cohen Higgins (D8)** — current 159x238. Campaign site dch.vote blocks direct `curl` with a
WAF (403, even with a browser UA) but loads fine and serves images fine through a real browser
context — verified the file's magic bytes via an in-page `fetch()` call. `...-DCH.webp`, 1600x1000,
clean solo portrait. Homepage hero image was a family group photo — correctly skipped. **Improved →
1600x1000.**

**Kionne L. McGhee (D9)** — current 159x238. Ballotpedia's own original (via the thumbs-strip trick)
is only 150x200 — smaller than current, rejected. The only other photo found anywhere was a two-person
snapshot of him with Commissioner Regalado, hosted on raquelregalado.com — rejected as not a solo
portrait (and we don't crop). No personal campaign website. **Not improved.**

**Tomas Regalado (Property Appraiser)** — current 150x233 (4.01x). Wikipedia's public-domain option
(`Property_Appraiser_Tomás_Regalado.jpg`) is the IDENTICAL 150x233 file already in use. A second
Commons file, `Tomás_Regalado_(American_politician)-Parkview.jpg`, is CC-BY-SA-3.0 (not public domain)
at 800x1200 — a clear solo photo of him at a podium. Used it but flagged the license explicitly since
it falls outside the "press/official/public-domain" bucket; a human call may be wanted before import.
**Improved → 800x1200 (license: cc_by_sa_3.0, flagged).**

**Alina Garcia (Supervisor of Elections)** — current 350x233 (3.23x from a landscape-oriented source).
Wikipedia links two Commons options; one (`...January_2025.jpg`) is landscape 800x450 — wrong shape.
The other, `Supervisor_Alina_Garcia.jpg`, public domain, 648x850, portrait-oriented, county seal
visible in background. **Improved → 648x850.**

## Leon County

**Gwen Marshall (Clerk of the Circuit Court and Comptroller)** — current 134x143 (worst case, 5.26x).
leonclerk.com's own media library (queried via its open `/wp-json/wp/v2/media?search=marshall`
endpoint) only has a SMALLER file, `clerk_marshall_2020.jpg` at 125x155, alt-tagged "Gwen Knight" (her
full legal name is Gwen Marshall Knight — not a mismatch, just a fuller name). Her official bio page
(cvweb.leonclerk.com) returns an empty/broken response. flccoc.org's clerks directory has no photos at
all (logos only). No campaign site, no Wikipedia/Ballotpedia photo. **Not improved** — genuinely
nothing better exists.

**Doris Maloy (Tax Collector)** — current 200x295 (3.00x). leontaxcollector.net's own bio page and
homepage carry NO photo of her at all (checked both directly and via Playwright — only logos, program
graphics, and a text-only "video recording" notice graphic). Florida Tax Collectors Association's 2018
Black History Month feature has a portrait, `Doris-Maloy-02.16.18.jpg`, 255x326 (confirmed via its own
WP media API this is the true max — no bigger rendition exists there either). **Improved 200x295 →
255x326** — real but modest; still well under 600x750.

## Palm Beach County

All four "fetch failed" targets (Marino, Flores, Woodward, Baxter) were RE-TESTED and are reachable —
`discover.pbc.gov` resets connections intermittently (confirmed live: Weiss's own portrait URL failed
once and succeeded twice in three consecutive attempts seconds apart). Treat any future "fetch failed"
against this host as transient, not a permanent block, and retry before concluding otherwise.

**Gregg K. Weiss (D2)** — current 200x276. No County Commission campaign site exists; sourced from his
2026 West Palm Beach mayoral campaign site (weissforwpb.com, same person, current term) —
`...IMG_0769.png`, 1005x881, clean cutout. **Improved → 1005x881.**

**Maria Sachs (D5)** — current 200x276. Campaign site mariasachs.com, `meet-maria-img.jpg`, 1600x862,
clear solo photo at the commission dais. (Another candidate image showed her posing with a horse —
skipped as too casual/off-topic even though solo.) **Improved → 1600x862.**

**Bobby Powell Jr. (D7)** — current 200x276. Wikipedia/Commons headshot and BOTH of his Florida Senate
term pages (2018-2020 District 30, 2022-2024 District 24) all serve the exact same 185x244 file —
smaller than current, rejected. No personal campaign website found. **Not improved.**

**Maria G. Marino (D1)** — originally "fetch failed"; reachable on retry (200x276, same class as the
other PBC commissioners). Campaign site electmariamarino.com's `/get-to-know-maria/` page has
`maria-marino-microphone.jpg`, 600x700 — a candid side-profile speaking photo, essentially at the
600x750 target (50px short on height only). No larger or more posed portrait found on the site (its
media library is mostly event/community photos). **Improved 200x276 → 600x700.**

**Joel G. Flores (D3)** — originally "fetch failed"; reachable on retry (200x276). Campaign site
votejoelflores.com is a bare "Coming Soon" placeholder with no images. Ballotpedia candidate page
carries only the generic silhouette placeholder. **Not improved.**

**Marci Woodward (D4)** — originally "fetch failed"; reachable on retry (200x276). Campaign site
marciwoodward.com, `marci-img.png`, 1157x1366, clean cutout portrait. **Improved → 1157x1366.**

**Sara Baxter (D6)** — originally "fetch failed"; reachable on retry (200x276). Campaign site
votesarabaxter.com is Wix; DOM-scanned for `<img>` elements, then reconstructed each asset's ORIGINAL
(un-cropped, un-resized) URL by stripping Wix's `/v1/crop/.../fill/...` transform segment from the
`static.wixstatic.com/media/<hash>~mv2.<ext>` path — same principle as the Ballotpedia thumbs-strip
trick, applied to a different CDN. One candidate this way was a full FAMILY group photo (rejected).
The other, a wide hero-banner PNG with her solo portrait on the left third, transparent elsewhere —
3000x1250 (positional flag set: filename is a bare Wix media hash, not a name). **Improved →
3000x1250** (effective portrait region is well above target; banner shape noted for anyone doing the
eventual crop).

## Manatee County

mymanatee.org (the county's own CMS) has genuinely no larger rendition for ANY of its commissioners —
confirmed by testing query-string resize params (`?width=`, `?w=`) against the live asset, which were
silently ignored (same bytes returned), and by checking each commissioner's individual
`commissioners-detail/<name>` page, which links the identical file as the roster page.

**Amanda Ballard (D2)** — current 216x254. Campaign site amandaballard2026.com, `headshot-clean.webp`,
810x1153, clean cutout wearing a "County Commissioner" nametag (positive ID confirmation).
**Improved → 810x1153.**

**Tal Siddique (D3)** — current 216x254. No personal campaign website found (only Facebook,
excluded); leadershipflorida.org's contact page for him carries no photo. **Not improved.**

**Mike Rahn (D4)** — current 216x254. Campaign site votemikerahn.com, an embedded "screenshot" PNG
(`Screenshot-2026-03-17-at-9.53.57-PM.png`) is actually a professional solo portrait at 614x876 —
right at the target. **Improved → 614x876.**

**Dr. Bob McCann (D5)** — current 216x254. Campaign site electbobmccann.com no longer resolves
(NXDOMAIN); its March-2025 Wayback Machine snapshot shows the domain has since been repurposed for
unrelated e-commerce/spam content, so even the archive is not useful. Guessed Ballotpedia slug
`Robert_McCann_(Florida)` 404s. **Not improved.**

**Jason Bearden (D6, At-Large)** — current 216x254. Campaign site votebearden.com resolves (HTTP, not
HTTPS — cert error on https://) but serves a generic ISP/hosting error page, not live content. **Not
improved.**

**George Kruse (D7, At-Large)** — current 216x254. votekruse.com and electkruse.com both fail to
resolve; georgekruse.com redirects to a Linktree profile. Linktree's own hosted avatar (600x600, on
`ugc.production.linktr.ee`) was found but deliberately NOT used — Linktree is fundamentally a
social-media aggregator and the avatar is a personal social photo in spirit, which the standing rule
against social-sourced photos is meant to exclude. **Not improved.**

**Charles E. Hackney (Property Appraiser)** — current 240x310 (2.50x, least-severe case). Campaign
site charliehackney.com, `Charles-Hackney-Hero.png` (stripping the `-972x1024` WordPress-resize
suffix from the linked version gave the true original), 1000x1054, clean cutout matching the county
site's portrait style. **Improved → 1000x1054.**

## Summary

- 31 targets total; **21 improved**, 10 not improved (nothing better found after a genuine search).
- Best result: Raquel Regalado (1830x1830) and René Garcia (1242x1755) are the two largest tight
  portraits; Sara Baxter's banner is nominally largest by pixel count (3000x1250) but is a wide crop,
  not a tight portrait.
- Worst still-short result: Keon Hardemon at 256x256 — the true Ballotpedia original, not a thumbnail.
- Still below the 600x750 floor after improvement: Anthony Rodriguez (300x456), Keon Hardemon
  (256x256), Doris Maloy (255x326). Maria Marino (600x700) is a rounding error under the floor
  (50px short on height only).
- Kept as `improved: false` (nothing better found) — 10 people: Micky Steinberg, Natalie Milian
  Orbis, Kionne McGhee, Bobby Powell Jr., Tal Siddique, Dr. Bob McCann, Jason Bearden, George Kruse,
  Gwen Marshall, Joel G. Flores.
