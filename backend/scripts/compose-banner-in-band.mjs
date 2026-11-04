/**
 * Compose a city banner to the essentials 1700x540 spec and prove it IN THE DESKTOP BAND.
 *
 * Written for the Boise wave (essentials#237) and kept because the band arithmetic is the part
 * that is both easy and expensive to get wrong.
 *
 * 🔴 CROPPING DEPENDS ONLY ON THE BOX ASPECT RATIO, NEVER ON ABSOLUTE SIZE. SectionBanner renders
 *    13:4 on mobile and 6:1 from `md` up, so a 1700x540 asset shows 96.9% on a phone and only
 *    52.5% on a desktop — rows 128-412 of 540. A banner certified on the full frame, or on a
 *    phone, can ship a desktop picture nobody looked at. That is the Bend failure.
 *
 * 🔴 THE SUBJECT MUST LIVE IN ROWS 128-412. Everything above row 128 and below row 412 is for
 *    mobile only.
 *
 * Usage:
 *   node scripts/compose-banner-in-band.mjs --src <file> --out <file> [--top <0..1>] [--sheet <html>]
 *     --top  vertical placement of the crop window in the SOURCE, 0 = flush top, 1 = flush bottom.
 */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const arg = (k, d) => {
  const i = process.argv.indexOf(k);
  return i > -1 ? process.argv[i + 1] : d;
};
const SRC = arg('--src');
const OUT = arg('--out');
const SHEET = arg('--sheet');
const TOPS = (arg('--top') ?? '0.5').split(',').map(Number);

const W = 1700, H = 540;                 // the asset spec, 3.148:1
const DESKTOP = 6, MOBILE = 13 / 4;
const bandRows = (ratio) => {
  const bh = Math.round(W / ratio * (H / W) * W / (W / ratio) * 0 + H * (W / ratio) / W * (W / (W / ratio)) * 0 + (W / ratio));
  // the visible height of a W-wide box at `ratio`, clamped to the asset height
  const vis = Math.min(H, Math.round(W / ratio));
  return { top: Math.round((H - vis) / 2), bottom: Math.round((H + vis) / 2), vis };
};
const D = bandRows(DESKTOP), M = bandRows(MOBILE);

if (!SRC) { console.error('--src is required'); process.exit(1); }

const meta = await sharp(SRC).metadata();
console.log(`source ${meta.width}x${meta.height} (${(meta.width / meta.height).toFixed(3)}:1)`);
console.log(`asset  ${W}x${H} (3.148:1)`);
console.log(`desktop 6:1   -> rows ${D.top}-${D.bottom} of ${H} (${((D.vis / H) * 100).toFixed(1)}% visible)  <- THE SUBJECT MUST LIVE HERE`);
console.log(`mobile  13:4  -> rows ${M.top}-${M.bottom} of ${H} (${((M.vis / H) * 100).toFixed(1)}% visible)`);

// Widest 3.148:1 window the source can give, slid vertically by --top.
const cropW = Math.min(meta.width, Math.round(meta.height * (W / H)));
const cropH = Math.round(cropW * (H / W));
const left = Math.round((meta.width - cropW) / 2);

const made = [];
for (const t of TOPS) {
  const top = Math.max(0, Math.min(meta.height - cropH, Math.round((meta.height - cropH) * t)));
  const out = TOPS.length === 1 ? OUT : (OUT ?? 'banner').replace(/\.jpg$/, '') + `-top${String(t).replace('.', '')}.jpg`;
  await sharp(SRC)
    .extract({ left, top, width: cropW, height: cropH })
    .resize(W, H, { fit: 'fill' })
    .jpeg({ quality: 90, progressive: true, mozjpeg: true })
    .toFile(out);
  const sz = fs.statSync(out).size;
  made.push({ t, out, sz });
  console.log(`  --top ${t}  -> ${path.basename(out)}  source rows ${top}-${top + cropH}  ${(sz / 1024).toFixed(0)} KB`);
}

if (SHEET) {
  const cells = made.map(({ t, out }) => {
    const b64 = fs.readFileSync(out).toString('base64');
    return `<h2>--top ${t} &middot; ${path.basename(out)}</h2>
    <div class="row">
      <div><div class="lbl">DESKTOP 6:1 — what most visitors see (52.5%)</div>
        <div class="crop d"><img src="data:image/jpeg;base64,${b64}"></div></div>
      <div><div class="lbl">MOBILE 13:4 (96.9%)</div>
        <div class="crop m"><img src="data:image/jpeg;base64,${b64}"></div></div>
    </div>
    <div class="lbl">full 1700x540 asset, desktop band marked</div>
    <div class="full"><img src="data:image/jpeg;base64,${b64}">
      <div class="band" style="top:${(D.top / H * 100).toFixed(2)}%;height:${(D.vis / H * 100).toFixed(2)}%"></div></div>`;
  }).join('\n');
  fs.writeFileSync(SHEET, `<!doctype html><meta charset=utf-8><style>
   body{margin:0;padding:18px;background:#111;color:#eee;font:13px -apple-system,Segoe UI,sans-serif}
   h2{font-size:13px;margin:22px 0 8px;color:#ffd21e}
   .lbl{font-size:11px;color:#9aa;margin:6px 0 4px}
   .row{display:flex;gap:18px;align-items:flex-start}
   .crop{overflow:hidden;position:relative}
   .crop img{position:absolute;top:50%;transform:translateY(-50%)}
   .d{width:1100px;aspect-ratio:6/1}   .d img{width:1100px}
   .m{width:390px;aspect-ratio:13/4}   .m img{width:390px}
   .full{position:relative;width:850px}.full img{width:850px;display:block}
   .band{position:absolute;left:0;width:850px;border-top:2px solid #ffd21e;border-bottom:2px solid #ffd21e;background:rgba(255,210,30,.12)}
  </style>${cells}`);
  console.log(`\nsheet -> ${SHEET}`);
}
