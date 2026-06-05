import 'dotenv/config';

const OFFICIALS = [
  { name: 'Raj Salwan', ext: -670001, url: 'https://www.fremont.gov/home/showpublishedimage/482/638791182509370000' },
  { name: 'Yajing Zhang', ext: -670014, url: 'https://www.fremont.gov/home/showpublishedimage/9838/638767002190270000' },
  { name: 'Teresa Keng', ext: -670010, url: 'https://www.fremont.gov/home/showpublishedimage/6159/637981555727730000' },
  { name: 'Desrie Campbell', ext: -670011, url: 'https://www.fremont.gov/home/showpublishedimage/6771/638072457065130000' },
  { name: 'Kathy Kimberlin', ext: -670012, url: 'https://www.fremont.gov/home/showpublishedimage/9621/638767001732970000' },
  { name: 'Yang Shao', ext: -670013, url: 'https://www.fremont.gov/home/showpublishedimage/10104/638767007145300000' },
  { name: 'Raymond Liu', ext: -670015, url: 'https://www.fremont.gov/home/showpublishedimage/9840/638791182084370000' },
];

async function run() {
  for (const o of OFFICIALS) {
    const resp = await fetch(o.url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://www.fremont.gov/government/mayor-city-council',
      }
    });
    const ct = resp.headers.get('content-type') || '';
    const cl = resp.headers.get('content-length') || '?';
    console.log(`${o.name} (${o.ext}): ${resp.status} ${ct} ${cl}b`);
  }
}
run().catch(console.error);
