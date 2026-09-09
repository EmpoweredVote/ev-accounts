import { describe, it, expect } from 'vitest';
import { classifyLead, classifyPair, measureType } from './lead-axis.mjs';

// Every title below is REAL, taken from the 2026-09-05 Senate sweep. The senator
// counts quoted in the test names are that file's, and they are the reason this
// stage exists: the largest leads on two of the three topics cannot separate a
// single rung from any other.

const lead = (topic_key: string, bill: string, title: string) => ({ topic_key, bill, title });

describe('measureType', () => {
  it('separates the measures that bind from the ones that do not', () => {
    expect(measureType('S. 1332')).toBe('bill');
    expect(measureType('HR. 3469')).toBe('bill');
    expect(measureType('SJRES. 200')).toBe('joint');
    expect(measureType('SRES. 417')).toBe('simple');
    expect(measureType('HCONRES. 202')).toBe('concurrent');
  });

  it('reads SCONRES as concurrent and not as a Senate bill', () => {
    // "S" is a prefix of "SCONRES" and "SJRES" and "SRES", so order matters here.
    expect(measureType('SCONRES. 30')).toBe('concurrent');
    expect(measureType('SJRES. 20')).toBe('joint');
    expect(measureType('SRES. 504')).toBe('simple');
  });
});

describe('classifyLead — gun-policy', () => {
  it('seats the three marquee bills on the axis', () => {
    expect(classifyLead(lead('gun-policy', 'S. 25', 'Assault Weapons Ban of 2025'))).toBe('on-axis');
    expect(classifyLead(lead('gun-policy', 'S. 494', 'Background Check Expansion Act'))).toBe('on-axis');
    expect(classifyLead(lead('gun-policy', 'S. 65', 'Constitutional Concealed Carry Reciprocity Act of 2025'))).toBe('on-axis');
  });

  it('keeps a CRA disapproval of an ATF rule, which is a joint resolution and binds', () => {
    expect(classifyLead(lead('gun-policy', 'SJRES. 20',
      'A joint resolution providing for congressional disapproval under chapter 8 of title 5, United States Code, of the rule submitted by the Bureau of Alcohol, Tobacco, Firearms, and Explosives relating to Definition of Engaged in the Business as a Dealer in Firearms.'))).toBe('on-axis');
  });

  it('puts research funding and liability off the axis, real as they are', () => {
    // Both are genuine gun-policy positions. Neither says which firearms should be
    // legal, who may buy one, or who may carry one — so neither seats a rung.
    expect(classifyLead(lead('gun-policy', 'S. 1123', 'Gun Violence Prevention Research Act of 2025'))).toBe('off-axis');
    expect(classifyLead(lead('gun-policy', 'S. 2129', 'Equal Access to Justice for Victims of Gun Violence Act'))).toBe('off-axis');
  });

  it('discards a commemoration — 42 senators, no rung', () => {
    expect(classifyLead(lead('gun-policy', 'SCONRES. 30',
      'A concurrent resolution recognizing the 15th anniversary of the January 8, 2011, Tucson, Arizona, shooting and honoring the victims.'))).toBe('non-operative');
  });
});

describe('classifyLead — israel-military-aid', () => {
  it('discards the solidarity resolutions, which is the whole point of the stage', () => {
    // 84 of 100 senators cosponsored the first. A lead 84 senators share cannot
    // tell rung 1 from rung 5; it tells you the text was written to be agreed to.
    expect(classifyLead(lead('israel-military-aid', 'SRES. 417',
      'A resolution standing with Israel against terrorism.'))).toBe('non-operative');
    expect(classifyLead(lead('israel-military-aid', 'SRES. 90',
      'A resolution celebrating the 75th anniversary of the founding of the State of Israel, and for other purposes.'))).toBe('non-operative');
  });

  it('keeps a resolution whose SUBJECT is the flow of arms, though it enacts nothing', () => {
    // The case that inverted the axis test and the instrument test. This enacts
    // nothing and is a signed objection to withholding arms — exactly the line
    // rung 1 draws against rungs 3 and 4.
    expect(classifyLead(lead('israel-military-aid', 'SRES. 715',
      'A resolution condemning the decision by the Biden Administration to halt the shipment of United States made ammunition and weapons to the State of Israel.'))).toBe('on-axis');
  });

  it('keeps the 502B(c) request, this topic\'s most on-point instrument', () => {
    expect(classifyLead(lead('israel-military-aid', 'SRES. 504',
      "A resolution requesting information on Israel's human rights practices pursuant to section 502B(c) of the Foreign Assistance Act of 1961."))).toBe('on-axis');
  });

  it('keeps arms-sale disapprovals', () => {
    expect(classifyLead(lead('israel-military-aid', 'SJRES. 111',
      'A joint resolution providing for congressional disapproval of the proposed foreign military sale to the Government of Israel of certain defense articles and services.'))).toBe('on-axis');
  });

  it('rejects the four bills whose short titles fooled an earlier draft', () => {
    // Each was in NAMED_ON_AXIS until somebody read it. The first carried 40 of
    // 100 senators, so a rung-1 extension off it would have published 40 claims
    // sourced to a bill about United Nations dues.
    expect(classifyLead(lead('israel-military-aid', 'S. 1521', 'Stand with Israel Act'))).toBe('off-axis');
    expect(classifyLead(lead('israel-military-aid', 'S. 2216', 'Weapons Resupply, Stockpile, and Alliance-Israel Act'))).toBe('off-axis');
    expect(classifyLead(lead('israel-military-aid', 'S. 1504', 'Ensuring Peace Through Strength in Israel Act'))).toBe('off-axis');
    expect(classifyLead(lead('israel-military-aid', 'S. 510', 'Expediting Israeli Aerial Refueling Act of 2023'))).toBe('off-axis');
  });

  it('keeps the three named bills whose purpose was actually read', () => {
    expect(classifyLead(lead('israel-military-aid', 'S. 4337', 'Israel Security Assistance Support Act'))).toBe('on-axis');
    expect(classifyLead(lead('israel-military-aid', 'S. 4537', "Maintaining Our Ironclad Commitment to Israel's Security Act"))).toBe('on-axis');
    expect(classifyLead(lead('israel-military-aid', 'S. 3081', 'Fortify Israel Act'))).toBe('on-axis');
  });

  it('keeps a specific arms-sale disapproval, the rung 3 instrument', () => {
    // S.J.Res. 138 prohibits a named FMS: 12,000 BLU-110A/B 1,000-pound bomb
    // bodies. Offensive ordnance, not missile defense.
    expect(classifyLead(lead('israel-military-aid', 'SJRES. 138',
      'A joint resolution providing for congressional disapproval of the proposed foreign military sale to the Government of Israel of certain defense articles and services.'))).toBe('on-axis');
  });

  it('puts joint R&D off the axis — cooperation is not an aid level', () => {
    expect(classifyLead(lead('israel-military-aid', 'S. 1004', 'United States-Israel Anti-Tunnel Cooperation Act'))).toBe('off-axis');
    expect(classifyLead(lead('israel-military-aid', 'S. 3775', 'United States-Israel PTSD Collaborative Research Act'))).toBe('off-axis');
  });
});

describe('classifyLead — border-security', () => {
  it('keeps the asylum bills, including ones no pattern could name', () => {
    // "Secure the Border Act" carries no word an asylum pattern matches, which is
    // why NAMED_ON_AXIS exists and why every entry in it has to be read by a person.
    expect(classifyLead(lead('border-security', 'S. 2824', 'Secure the Border Act of 2023'))).toBe('on-axis');
    expect(classifyLead(lead('border-security', 'S. 1473', 'Asylum Abuse Reduction Act'))).toBe('on-axis');
    expect(classifyLead(lead('border-security', 'S. 5371', 'Stopping Border Surges Act'))).toBe('on-axis');
    // These reach the axis on their own words rather than through the named list.
    expect(classifyLead(lead('border-security', 'S. 112', 'Make the Migrant Protection Protocols Mandatory Act of 2025'))).toBe('on-axis');
    expect(classifyLead(lead('border-security', 'S. 3488', 'Asylum Reform and Loophole Closure Act'))).toBe('on-axis');
  });

  it('puts interdiction and reporting off the axis', () => {
    // Both are about the border. The ladder is about the people who cross it.
    expect(classifyLead(lead('border-security', 'S. 987', 'Stop Fentanyl Border Crossings Act'))).toBe('off-axis');
    expect(classifyLead(lead('border-security', 'S. 2409', 'Southern Border Transparency Act of 2023'))).toBe('off-axis');
  });

  it('puts the immigration bills that take no asylum posture off the axis', () => {
    // The two named entries removed on 2026-09-08. Both are real immigration
    // bills; neither says anything about who may claim asylum, which is the only
    // thing this ladder's five rungs measure. Together they carried 45 senator-rows.
    expect(classifyLead(lead('border-security', 'S. 1965', 'Protect Vulnerable Immigrant Youth Act'))).toBe('off-axis');
    expect(classifyLead(lead('border-security', 'S. 1885', 'Protect Vulnerable Immigrant Youth Act'))).toBe('off-axis');
    expect(classifyLead(lead('border-security', 'S. 3702', 'Dignity for Detained Immigrants Act'))).toBe('off-axis');
    expect(classifyLead(lead('border-security', 'S. 1208', 'Dignity for Detained Immigrants Act of 2023'))).toBe('off-axis');
    // And the sponsor-vetting bills the bare word `unaccompanied` used to reach.
    expect(classifyLead(lead('border-security', 'S. 286', 'Stop Human Trafficking of Unaccompanied Migrant Children Act of 2025'))).toBe('off-axis');
    expect(classifyLead(lead('border-security', 'S. 1461', 'Stop Human Trafficking of Unaccompanied Migrant Children Act of 2023'))).toBe('off-axis');
  });

  it('still reaches a detention measure that changes asylum itself', () => {
    // Dropping `detention` cost nothing the axis needs: a measure that detains
    // ASYLUM SEEKERS still matches, on the word that carries the posture.
    expect(classifyLead(lead('border-security', 'S. 0000', 'A bill to require the detention of asylum seekers pending a credible fear determination.'))).toBe('on-axis');
  });

  it('discards anniversaries and heritage months', () => {
    expect(classifyLead(lead('border-security', 'SRES. 662',
      'A resolution recognizing May 28, 2024, as the 100th anniversary of the U.S. Border Patrol and commending the service of its agents.'))).toBe('non-operative');
  });
});

describe('classifyPair', () => {
  it('is settleable on one on-axis lead, however much noise surrounds it', () => {
    const { verdict, counts } = classifyPair([
      lead('israel-military-aid', 'SRES. 417', 'A resolution standing with Israel against terrorism.'),
      lead('israel-military-aid', 'SRES. 90', 'A resolution celebrating the 75th anniversary of the founding of the State of Israel, and for other purposes.'),
      lead('israel-military-aid', 'S. 4337', 'Israel Security Assistance Support Act'),
    ]);
    expect(verdict).toBe('settleable');
    expect(counts).toEqual({ 'on-axis': 1, 'off-axis': 0, 'non-operative': 2 });
  });

  it('separates "has real bills, wrong axis" from "has only commemorations"', () => {
    // The two need different next instruments — a roll call or a floor statement
    // for the first, and something other than the legislative record for the second.
    expect(classifyPair([lead('border-security', 'S. 987', 'Stop Fentanyl Border Crossings Act')]).verdict)
      .toBe('off-axis-only');
    expect(classifyPair([lead('israel-military-aid', 'SRES. 417', 'A resolution standing with Israel against terrorism.')]).verdict)
      .toBe('non-operative-only');
  });
});
