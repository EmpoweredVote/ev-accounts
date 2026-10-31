import * as fs from 'fs';
import * as path from 'path';

const SP = path.dirname(new URL(import.meta.url).pathname.replace(/^\//, ''));
const rows = JSON.parse(fs.readFileSync(path.join(SP, 'jx-processed.json'), 'utf8'));

// 🔴 PER-IMAGE ALT IS THE LOAD-BEARING PART. A contact sheet is blind when the wrong person is
// also plausible; only an alt that describes THIS person catches an off-by-one.
const ALT = {
  mayor: 'John Horhn, Mayor of Jackson: an older Black man with grey hair, glasses and a grey moustache, in a grey suit with a red tie, against a dark green studio background.',
  ward1: 'Ashby M. Foote III, Ward 1: an older white man with white hair and a full white beard, in a navy suit with a red and navy striped tie, on the City Hall staircase.',
  ward2: 'Montyne "Tina" Clay, Ward 2: a Black woman with long dark hair worn straight, in a navy jacket over a white blouse, smiling, on the City Hall staircase.',
  ward3: 'Kenneth Stokes, Ward 3: a Black man with short dark hair and a moustache, in a dark suit with a grey and burgundy striped tie, on the City Hall staircase.',
  ward4: 'Brian C. Grizzell, Ward 4: a bald Black man with a grey and white beard, in a navy suit with a gold patterned tie and a white pocket square, smiling broadly.',
  ward5: 'Vernon Hartley, Ward 5: a Black man with close-cropped hair and glasses, in a bright blue suit with a blue and white checked tie, smiling, on the staircase.',
  ward6: 'Lashia Brown-Thomas, Ward 6: a Black woman with long dark hair, wearing a cream jacket and a pearl necklace, against a pale staircase background.',
  ward7: 'Kevin Parkinson, Ward 7: a younger white man with short brown hair, in a navy suit with a red tie, smiling, on the City Hall staircase.',
};

const b64 = (f) => fs.readFileSync(path.join(SP, f)).toString('base64');

const cards = rows.map((r) => {
  const up = Number(r.upscale);
  const flags = [
    `<span class="chip ok">face ${r.face.split(' ')[0]}</span>`,
    `<span class="chip ok">colour ${r.spread}</span>`,
    up > 1
      ? `<span class="chip warn">upscaled &times;${up}</span>`
      : `<span class="chip ok">no upscale</span>`,
  ].join('');
  return `
  <figure class="card">
    <img src="data:image/jpeg;base64,${b64(r.processed)}" alt="${ALT[r.key]}" width="600" height="750">
    <figcaption>
      <p class="seat">${r.title}</p>
      <h2 class="name">${r.name.replace(/"/g, '&ldquo;').replace(/&ldquo;([^&]*)&ldquo;/, '&ldquo;$1&rdquo;')}</h2>
      <p class="alt">${ALT[r.key]}</p>
      <div class="chips">${flags}</div>
      <dl class="meas">
        <div><dt>source</dt><dd>${r.src_w}&times;${r.src_h}</dd></div>
        <div><dt>crop</dt><dd>${r.crop}</dd></div>
        <div><dt>face box</dt><dd>${r.face}</dd></div>
        <div><dt>output</dt><dd>600&times;750 q90</dd></div>
      </dl>
      <p class="src"><a href="${r.url}">${r.url.split('/').pop()}</a></p>
    </figcaption>
  </figure>`;
}).join('\n');

const page = `<title>Jackson Portrait Sheet</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wght@500;600;700&family=Source+Sans+3:ital,wght@0,400;0,600;1,400&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
/* Layout: a records sheet — one header band stating the decision, then a portrait grid whose
   cards carry the measurement trail beneath each face. */
:root{
  --ground:#f4f5f7; --panel:#ffffff; --ink:#15191f; --muted:#5a6472; --rule:#d9dde4;
  --brass:#9a6b1f; --ok:#1f6b4a; --warn:#8a5a00; --okbg:#e6f1ec; --warnbg:#fbf0dc;
  --display:'Archivo',system-ui,sans-serif; --body:'Source Sans 3',system-ui,sans-serif;
  --mono:'IBM Plex Mono',ui-monospace,monospace;
}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
  --ground:#13161b; --panel:#1b2027; --ink:#e9edf3; --muted:#9aa5b4; --rule:#2c333d;
  --brass:#d6a75a; --ok:#6fd3a4; --warn:#e3b55f; --okbg:#17302a; --warnbg:#332a16;
  color-scheme:dark}}
:root[data-theme="dark"]{
  --ground:#13161b; --panel:#1b2027; --ink:#e9edf3; --muted:#9aa5b4; --rule:#2c333d;
  --brass:#d6a75a; --ok:#6fd3a4; --warn:#e3b55f; --okbg:#17302a; --warnbg:#332a16;
  color-scheme:dark}
body{background:var(--ground);color:var(--ink);font-family:var(--body);line-height:1.5}
.wrap{max-width:1180px;margin:0 auto;padding-left:max(16px,env(safe-area-inset-left,0px));
  padding-right:max(16px,env(safe-area-inset-right,0px));padding-block:32px 56px}
header{border-bottom:2px solid var(--brass);padding-bottom:20px;margin-bottom:28px}
.eyebrow{font-family:var(--mono);font-size:.74rem;letter-spacing:.14em;text-transform:uppercase;
  color:var(--brass);margin:0 0 8px}
h1{font-family:var(--display);font-weight:700;font-size:clamp(1.6rem,4vw,2.3rem);margin:0 0 10px;
  text-wrap:balance;letter-spacing:-.01em}
.lede{margin:0;max-width:62ch;color:var(--muted);font-size:1.02rem}
.note{margin:18px 0 0;padding:14px 16px;background:var(--panel);border:1px solid var(--rule);
  border-left:3px solid var(--brass);border-radius:3px;max-width:72ch}
.note p{margin:0 0 8px}.note p:last-child{margin:0}
.note strong{font-weight:600}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(248px,1fr));gap:22px}
.card{margin:0;background:var(--panel);border:1px solid var(--rule);border-radius:4px;
  overflow:hidden;display:flex;flex-direction:column;min-width:0}
.card img{display:block;width:100%;height:auto;aspect-ratio:4/5;object-fit:cover;max-width:100%}
figcaption{padding:14px 15px 16px;display:flex;flex-direction:column;gap:9px;min-width:0}
.seat{margin:0;font-family:var(--mono);font-size:.72rem;letter-spacing:.07em;text-transform:uppercase;color:var(--muted)}
.name{margin:0;font-family:var(--display);font-weight:600;font-size:1.06rem;letter-spacing:-.005em}
.alt{margin:0;font-size:.83rem;color:var(--muted);font-style:italic;line-height:1.45}
.chips{display:flex;flex-wrap:wrap;gap:6px}
.chip{font-family:var(--mono);font-size:.68rem;padding:3px 7px;border-radius:2px;white-space:nowrap}
.chip.ok{background:var(--okbg);color:var(--ok)}
.chip.warn{background:var(--warnbg);color:var(--warn)}
.meas{margin:0;display:grid;grid-template-columns:1fr;gap:2px;font-family:var(--mono);font-size:.71rem}
.meas div{display:flex;justify-content:space-between;gap:10px;border-bottom:1px dotted var(--rule);padding-bottom:2px}
.meas dt{color:var(--muted)}.meas dd{margin:0;font-variant-numeric:tabular-nums;text-align:right;min-width:0;overflow-wrap:anywhere}
.src{margin:0;font-size:.72rem;overflow-wrap:anywhere}
.src a{color:var(--brass)}
footer{margin-top:36px;border-top:1px solid var(--rule);padding-top:18px;color:var(--muted);font-size:.86rem;max-width:72ch}
footer h2{font-family:var(--display);font-size:1rem;margin:0 0 8px;color:var(--ink)}
footer ul{margin:0;padding-left:1.1rem}footer li{margin-bottom:5px}
a:focus-visible,.card:focus-visible{outline:2px solid var(--brass);outline-offset:2px}
</style>

<div class="wrap">
<header>
  <p class="eyebrow">Contact sheet &middot; approval needed</p>
  <h1>Jackson, Mississippi &mdash; eight officeholder portraits</h1>
  <p class="lede">All eight seats are seated in production and every one currently renders blank.
    These are the candidates. Nothing is uploaded until you approve this sheet.</p>
  <div class="note">
    <p><strong>Source and licence.</strong> Every image is published by the City of Jackson on its
      own site. The seven council portraits are one official sitting uploaded 21 November 2025 at
      720&times;780; the mayor&rsquo;s is the studio headshot his own page uses.</p>
    <p><strong>The cut-outs were refused.</strong> Each council page shows a background-removed PNG.
      The original sitting is still in the media library, so the originals are used here.</p>
    <p><strong>Bound by seat, never by filename.</strong> Ward 1&rsquo;s file is named
      <span class="mono">Ashby-M-Forte</span> &mdash; the wrong surname. The ward page it appears on
      is the binding, and its alt text reads &ldquo;ashby foote&rdquo;.</p>
  </div>
</header>

<div class="grid">
${cards}
</div>

<footer>
  <h2>What was measured</h2>
  <ul>
    <li>A face was detected in all eight. The detector was first run on flat grey and found none, so it can report absence.</li>
    <li>No image is monochrome: per-pixel colour spread runs 25.8 to 54.1, well clear of the greyscale floor.</li>
    <li>Only the mayor is enlarged, &times;1.245, because his is the one source smaller than 600&times;750. The seven council portraits are all downscaled.</li>
    <li>Crops are placed from the measured face box, not centred.</li>
    <li>A face-proportional zoom was tried and reverted: normalising every face to the same share of the frame pushed five of eight into upscaling to buy a consistency the city&rsquo;s own set already had.</li>
  </ul>
</footer>
</div>`;

fs.writeFileSync(path.join(SP, 'jackson-portraits.html'), page);
console.log('wrote jackson-portraits.html', (page.length / 1024 / 1024).toFixed(2), 'MB');
