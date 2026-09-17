/**
 * Turn local-harvest.json into the candidates file the contact sheet and the importer read.
 *
 * Each row takes the highest-scoring image from the official's OWN page. Four officials needed a
 * hunt and carry their source and its reason with them, so a later reader can see why a portrait
 * did not come from the obvious place.
 */
import fs from 'node:fs';
import path from 'node:path';

const OUT = 'C:/EV-Accounts/backend/data/seed-mn-headshots-2026';
const harvest = JSON.parse(fs.readFileSync(path.join(OUT, 'local-harvest.json'), 'utf8'));

// The four the page could not answer on its own, decided by hand and recorded here.
const HUNTED = {
  'Lynn Marie Nephew': {
    url: 'https://images.squarespace-cdn.com/content/v1/642cd31e73ab9710adf02e4f/c3f74138-3356-45c1-bc36-4dc25ce65080/Nephew-Summer-Portrait-007_1-WEB.png',
    page: 'https://lynnmarienephewforduluth.com/about-me',
    license: 'campaign_use',
    note: 'duluthmn.gov carries no portrait on her councillor page — only the city logo. Campaign portrait. 749x500 LANDSCAPE, so the 4:5 crop ships at 400x500 native.',
  },
  'Kimberly J. Maki': {
    url: 'https://content.govdelivery.com/attachments/fancy_images/MNSTLOUIS/2021/09/4906677/3720668/kim-maki_crop.jpg',
    page: 'https://content.govdelivery.com/accounts/MNSTLOUIS/bulletins/2f02920',
    license: 'press_use',
    note: 'The county attorney page carries only a courthouse photograph. This is the county\'s OWN bulletin announcing her appointment (2021-09). Her campaign site is under construction.',
  },
  'Terese Tomanek': {
    positional: true,
    note: 'Her own councillor page serves /media/12005/headshot.jpg — a generic CMS filename that names nobody. VERIFY THE FACE before approving.',
  },
  'Wendy Durrwachter': {
    positional: true,
    note: 'Her own councillor page serves /media/23afjqmb/i-8wdhrjc-x2.jpg — an opaque CMS filename. VERIFY THE FACE before approving.',
  },
};

const cands = [];
const blanks = [];
for (const o of harvest) {
  const hunted = HUNTED[o.prod_name] ?? {};
  const best = o.images.find((i) => i.names_person) ?? o.images[0];
  const url = hunted.url ?? best?.src ?? null;
  if (!url) { blanks.push(o.prod_name); continue; }
  cands.push({
    politician_id: o.politician_id,
    name: o.prod_name,
    office: o.prod_office,
    cohort: o.cohort,
    url,
    page: hunted.page ?? o.page,
    license: hunted.license ?? 'press_use',
    positional: hunted.positional ?? !(best?.names_person ?? false),
    ...(hunted.note ? { _note: hunted.note } : {}),
  });
}
fs.writeFileSync(path.join(OUT, 'candidates-local.json'), JSON.stringify(cands, null, 1));
console.log(`${cands.length} local/county candidates · ${cands.filter((c) => c.positional).length} flagged positional (verify the face) · ` +
            `${blanks.length} with no candidate: ${blanks.join(', ') || 'none'}`);
for (const c of cands.filter((x) => x.positional)) console.log(`  positional: ${c.name} — ${c.url}`);
