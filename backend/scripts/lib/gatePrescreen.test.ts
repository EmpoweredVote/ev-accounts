import { describe, it, expect } from 'vitest';
import { gateForVote, gateForSponsor } from './gatePrescreen';
import type { Vote } from './sourceStore';

const v = (o: Partial<Vote>): Vote => ({ date: '2026-01-01', body: 'b', motion: 'm', kind: 'action-item', yes: 0, no: 0, members: [], ...o } as Vote);
const base = { ownMotion: true, higherLawDuty: false, multiSubject: false };

describe('gateForVote', () => {
  it('MD HB 1386 House 120-16 is not near-unanimous', () => {
    expect(gateForVote(v({ kind: 'roll-call', yes: 120, no: 16, body_size: 141 }), base)).toBeNull();
  });
  it('a 140-5 chamber is near-unanimous', () => {
    expect(gateForVote(v({ kind: 'roll-call', yes: 140, no: 5, body_size: 145 }), base)).toBe('near-unanimous');
  });
  it('7-member board, 7-0, own action item, own choice', () => {
    expect(gateForVote(v({ yes: 7, no: 0, body_size: 7 }), base)).toBeNull();
  });
  it('7-member board on consent', () => {
    expect(gateForVote(v({ kind: 'consent', yes: 7, no: 0, body_size: 7 }), base)).toBe('consent');
  });
  it('7-member board carrying out a state duty', () => {
    expect(gateForVote(v({ yes: 7, no: 0, body_size: 7 }), { ...base, higherLawDuty: true })).toBe('higher-law-duty');
  });
  it('11-member board 6-5 and 11-0', () => {
    expect(gateForVote(v({ kind: 'roll-call', yes: 6, no: 5, body_size: 11 }), base)).toBeNull();
    expect(gateForVote(v({ kind: 'roll-call', yes: 11, no: 0, body_size: 11 }), base)).toBe('near-unanimous');
  });
  it('multi-subject wins over every other gate', () => {
    expect(gateForVote(v({ kind: 'consent', yes: 7, no: 0, body_size: 7 }), { ownMotion: false, higherLawDuty: true, multiSubject: true })).toBe('multi-subject');
  });
  it('unknown body_size uses yes + no + absent', () => {
    expect(gateForVote(v({ yes: 5, no: 0, absent: 1 }), { ...base, higherLawDuty: true })).toBe('higher-law-duty');
  });
  it('a small body acting on another body\'s motion is gated as consent', () => {
    expect(gateForVote(v({ yes: 5, no: 2, body_size: 7 }), { ...base, ownMotion: false })).toBe('consent');
  });
});

describe('gateForSponsor', () => {
  it('sponsor of an off-topic filed version', () => {
    expect(gateForSponsor(false)).toBe('off-version-sponsor');
    expect(gateForSponsor(true)).toBeNull();
  });
});
