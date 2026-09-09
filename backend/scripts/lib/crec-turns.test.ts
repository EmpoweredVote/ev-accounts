import { describe, it, expect } from 'vitest';
import { turns, turnsBy, recordSurname, isSenateGranule, SPEECH_AXIS } from './crec-turns.mjs';

const RECORD = `
  Mr. PADILLA. Mr. President, this bill practically eliminates the right to seek
asylum for people fleeing for their safety.
  Mr. LANKFORD. Mr. President, asylum is very difficult to achieve. Only about 3
percent of the people that actually go through the hearings achieve asylum.
  Mr. Padilla's amendment was subsequently agreed to without objection.
`;

describe('turns', () => {
  it('splits on the speaker attribution and ends a turn at the next speaker', () => {
    const t = turns(RECORD);
    expect(t.map((x) => x.surname)).toEqual(['PADILLA', 'LANKFORD']);
    expect(t[0].body).toContain('right to seek');
    // The turn must STOP at the next member, or every speaker inherits the rest
    // of the page and attribution means nothing.
    expect(t[0].body).not.toContain('difficult to achieve');
  });

  it('does not treat a mixed-case mention as an attribution', () => {
    // "Mr. Padilla's amendment was agreed to" is prose ABOUT him. The Record puts
    // the speaker in capitals and nothing else, which is the only thing separating
    // the two — relaxing the case turns every mention into a quote.
    const t = turns(RECORD);
    expect(t).toHaveLength(2);
    expect(t.some((x) => x.body.includes('subsequently agreed to') && x.surname !== 'LANKFORD')).toBe(false);
  });
});

describe('turnsBy', () => {
  it('returns only the named member and flags the axis', () => {
    const t = turnsBy(RECORD, 'PADILLA');
    expect(t).toHaveLength(1);
    expect(t[0].onAxis).toBe(true);
    expect(t[0].asylumMentions).toBe(1);
  });

  it('is empty for a member who did not speak, however often they are named', () => {
    expect(turnsBy(RECORD, 'SCHUMER')).toHaveLength(0);
  });
});

describe('SPEECH_AXIS', () => {
  it('reaches asylum posture', () => {
    expect(SPEECH_AXIS.test('they are allowed to apply for asylum')).toBe(true);
    expect(SPEECH_AXIS.test('passing the credible fear screen')).toBe(true);
    expect(SPEECH_AXIS.test('return them under Remain in Mexico')).toBe(true);
  });

  it('does NOT fire on the two words that broke the title axis', () => {
    // Both of these are real sentences from the 2026-09-08 sweep, and both were
    // false positives under the bill-title regex.
    expect(SPEECH_AXIS.test('we have seen a refugee population grow in my parish')).toBe(false);
    expect(SPEECH_AXIS.test('the political persecution of Donald Trump’s enemies')).toBe(false);
  });
});

describe('isSenateGranule', () => {
  it('admits the Senate section and rejects House and Extensions', () => {
    expect(isSenateGranule('CREC-2024-05-22-pt1-PgS3844')).toBe(true);
    expect(isSenateGranule('CREC-2024-05-22-pt1-PgH4001')).toBe(false);
    expect(isSenateGranule('CREC-2024-05-22-pt1-PgE500')).toBe(false);
  });
});

describe('recordSurname', () => {
  it('handles the names a last-word split gets wrong', () => {
    expect(recordSurname('Catherine Cortez Masto')).toBe('CORTEZ MASTO');
    expect(recordSurname('Chris Van Hollen')).toBe('VAN HOLLEN');
    expect(recordSurname('Ben Ray Luján')).toBe('LUJAN');
    expect(recordSurname('Angus S. King, Jr.')).toBe('KING');
  });

  it('strips accents and suffixes on names it derives', () => {
    expect(recordSurname('Adam B. Schiff')).toBe('SCHIFF');
    expect(recordSurname('Tina Smith')).toBe('SMITH');
  });
});
