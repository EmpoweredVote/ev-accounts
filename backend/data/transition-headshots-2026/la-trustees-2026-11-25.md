# LA County sitting trustees — sourcing pass, 2026-11-25

28 people from `headshot-queue-2026-11-25`, chosen because they are the **only** cohort in the
316 who held a seat **before** the 2026 election and still hold it — so a published portrait
could already exist. Everybody else in the queue is new to the seat, and a body publishes a
portrait only after a member is sworn in.

**Nothing here is imported.** Headshot approval is always a contact sheet, batch-reviewed, and
this pass was stopped before the sheet so the six confirmed sources can be folded into the
December wave instead of spending a second approval on six faces.

⚠ **This machine had no image tooling** — no ImageMagick, no `sharp`/`jimp`/`canvas`, no Python —
so none of these has been cropped to the production 4:5 600×750 yet. The contact sheet must show
the production crop, not the source, so the crop is the first step when this resumes.

## 🟢 Banked — sourced, looked at, usable (6 of 28)

`sha256` is of the bytes actually downloaded on 2026-11-25, so a re-fetch can be proved identical
rather than assumed. Our storage overwrites a file in place at the same URL, which is why the
hash is the load-bearing half of the record and the URL alone is not.

| person | politician_id | board | source url | px | sha256 (16) |
| --- | --- | --- | --- | --- | --- |
| Steve Gibson | `8be2d3dc-0ca5-508d-a147-c456027514c5` | Pasadena Area CC, Area 3 | `https://www.pasadena.edu/about/board-of-trustees/images/members/Steve-Gibson.jpg` | 2304×3456 | `120e1bba3d2138ce` |
| Kristine Kwong | `85bc5bfd-edfa-5279-ba0d-897c2c7e3709` | Pasadena Area CC, Area 5 | `https://www.pasadena.edu/about/board-of-trustees/images/members/Kristine-Kwong.jpg` | 3456×5184 | `a4a0f1deea549564` |
| Soo Yoo | `3bb1823f-5de6-4196-884c-daf1c8cccc66` | ABC Unified, Area 2 | `https://3.files.edl.io/0acf/26/08/10/224623-c3fd2ee3-169b-4dda-89af-3f4352a6c2eb.png` | 669×919 | `7b80bfb3123d6fb6` |
| Christine Chacon Kennedy | `f71bc6eb-b367-52eb-8f5c-e2daf96add10` | East Whittier City, Area 3 | `https://3.files.edl.io/a85e/24/12/19/211223-ddbd38cc-79b5-4101-bda5-27c9ad621591.jpg` | 1631×… | `38ab0419127f9de8` |
| Joyce L. Randall | `6aae60e6-7739-42b5-adbc-341bc1f5257e` | Inglewood Unified, Area 1 | `https://3.files.edl.io/01d7/25/01/22/191730-d904a3dd-83c9-49b5-946b-d7f2bdfc1148.jpg` | 1440×1920 | `ec323632849d99ac` |
| Norma Amezcua | `019a2ba6-1a04-482c-9aa0-db79090956ac` | Norwalk-La Mirada, Area 2 | finalsite `t_image_size_6/v1708935627/nlmusdorg/nqqetzard6o9gaowq3vl` | 2200×2750 | `323d69f41d974ebd` |

**Each is bound to its person by the image's own alt text or filename**, never by position in the
markup. That is deliberate: an ancestry walk once bound fourteen Fulton portraits to one name,
and taking the largest image on a roster published a colleague's face at 8× the resolution.

⚠ **Licence is NOT settled for any of the six.** Each comes from the district's own site, which
is in policy as an official source, but no credit line has been read on any of them. Read the
terms before import and record `unknown` where a site is silent — never a guessed `press_use`.

## 🔴 Rejected after looking (8)

The eye is the check: nothing we run asks whether an image contains a face, is in colour, or is a
disc on a matte.

| person | board | why |
| --- | --- | --- |
| Sion Roy | Santa Monica CC | **monochrome**, 480×480 |
| Tom Peters | Santa Monica CC | **monochrome**, 415×415 |
| Luis Barrera Castañón | Santa Monica CC | **monochrome**, 480×480 |
| Gino Kwok | Hacienda La Puente, Area 4 | **disc on a matte**, 500×500 — the file is named `CircleHeadshot` |
| Nancy Loera | Hacienda La Puente, Area 2 | **disc on a matte**, 500×500 — same |
| Barbara Gaines | Antelope Valley CC, Area 5 | 100×150 |
| Simon Wright | Covina-Valley, Area 4 | 140×196 |
| Anna Griese | Saugus Union, Area 2 | 160×200 |

▶ Santa Monica College's whole board is published in black and white, so all three fail together
and a fourth SMC seat would too. ▶ A circular source is usable only if a rectangular crop *inside*
the disc still clears the hair with the ear-length headroom; at 500px with the head filling the
disc it does not. Re-source or leave blank — a blank beats a matte-cornered frame.

## ⚠ No member portraits published (2)

**Andres Ramos** and **Nicole J. Jones** (Compton CC, Areas 1 and 2). The board page carries only
stock campus photography. Not a fetch problem: the page was read and its images listed.

## Not yet attempted (12)

MyLoc Dinh (El Camino CC) · Yesenia Cuarenta (Paramount Unified) · Agnes P. Gonzalez (Rowland
Unified) · Charles Hughes (Antelope Valley Joint Union) · Gabriela Arellanes (Azusa Unified) ·
Brad Crihfield (Bellflower Unified) · Blanca Nava and Alma Rodriguez (Keppel Union) · Ricardo
Padilla (El Monte Union) · Lisa Nashua and Roberta A. Perlman (Pomona Unified) · Armando Urteaga
(Whittier Union).

Three districts would not resolve at all (Antelope Valley Joint Union, Azusa, Keppel — connection
failures, not 404s, so worth retrying rather than concluding the sites are gone). Three more serve
a board page whose images name nobody, which is the Fulton shape: bind by column geometry and a
screenshot, never by DOM distance or file size.

## How the board pages were found

Guessing canonical paths found **4 of 17**. Reading each district's **own navigation** for a link
whose text or href matches `board of (education|trustees)` found **7 more**. ▶ A site's own link
is what the site says its board page is; a guessed path is what we think it should be.

Every candidate was confirmed by **the trustee's surname appearing on the fetched page**, because
a CMS returns 200 for a landing page and a soft 404 alike and the status code cannot tell them
apart.

## ▶ When this resumes

1. Install an image tool outside the repo (`sharp` in a scratch directory keeps it out of
   `package.json`), crop the six to 4:5 600×750 with roughly an ear's length above the hair, and
   **look at the crops** before they go on a sheet. A green render count says the pipeline ran,
   not that the pictures are right.
2. Finish the remaining 12 boards and re-source the 8 rejects from campaign sites, press coverage
   or Commons — ⚠ never social platforms.
3. Fold all of it into the December contact sheet, which will also carry the Maine and California
   legislators once those chambers organise (Maine's 133rd convenes **2026-12-02**, California's
   legislature **2026-12-07**, the California locals **12-11**).
