import { describe, it, expect } from 'vitest';
import { parseStancesCsv, parseEvidenceCsv, writeStancesCsv, writeEvidenceCsv } from './stanceResearchCsv.js';

describe('parseStancesCsv', () => {
  it('parses header + rows, coerces value to number, leaves null when blank', () => {
    const csv = `full_name,politician_id,topic_key,value,reasoning
"Brad Sherman",,healthcare,2,"Cosponsored public option bill"
"Maxine Waters",,abortion,,"Insufficient recent record"
`;
    const rows = parseStancesCsv(csv);
    expect(rows).toEqual([
      { full_name: 'Brad Sherman', politician_id: '', topic_key: 'healthcare', value: 2, reasoning: 'Cosponsored public option bill' },
      { full_name: 'Maxine Waters', politician_id: '', topic_key: 'abortion', value: null, reasoning: 'Insufficient recent record' },
    ]);
  });
});

describe('parseEvidenceCsv', () => {
  it('parses header + rows with snippet_index as integer', () => {
    const csv = `full_name,topic_key,source_url,snippet,snippet_index
"Brad Sherman",healthcare,https://a.example,"Some long snippet text here",0
"Brad Sherman",healthcare,https://a.example,"Another snippet from same source",1
`;
    const rows = parseEvidenceCsv(csv);
    expect(rows).toHaveLength(2);
    expect(rows[0].snippet_index).toBe(0);
    expect(rows[1].snippet_index).toBe(1);
    expect(rows[0].source_url).toBe('https://a.example');
  });
});

describe('writeStancesCsv', () => {
  it('produces a parseable CSV with quoted fields', () => {
    const csv = writeStancesCsv([
      { full_name: 'Brad, Sherman', politician_id: '', topic_key: 'healthcare', value: 2, reasoning: 'has "quotes" inside' },
    ]);
    const reparsed = parseStancesCsv(csv);
    expect(reparsed[0].full_name).toBe('Brad, Sherman');
    expect(reparsed[0].reasoning).toBe('has "quotes" inside');
  });

  it('I1: round-trips the row sources and evidence_type; an old CSV without the columns leaves them undefined', () => {
    const csv = writeStancesCsv([
      { full_name: 'A', politician_id: '', topic_key: 't', value: 2, reasoning: 'r',
        evidence_type: 'record', source_urls: ['https://a.example/x', 'https://b.example/y'] },
      { full_name: 'B', politician_id: '', topic_key: 't', value: null, reasoning: '' },
    ]);
    const [a, b] = parseStancesCsv(csv);
    expect(a.source_urls).toEqual(['https://a.example/x', 'https://b.example/y']);
    expect(a.evidence_type).toBe('record');
    expect(b.source_urls).toEqual([]);
    const old = parseStancesCsv('full_name,politician_id,topic_key,value,reasoning\nA,,t,2,r\n');
    expect(old[0].source_urls).toBeUndefined();
    expect(old[0].evidence_type).toBeUndefined();
  });
});

describe('writeEvidenceCsv', () => {
  it('round-trips through parseEvidenceCsv', () => {
    const csv = writeEvidenceCsv([
      { full_name: 'X', topic_key: 't', source_url: 'https://u', snippet: 'a, b, c', snippet_index: 0 },
    ]);
    expect(parseEvidenceCsv(csv)[0].snippet).toBe('a, b, c');
  });
});
