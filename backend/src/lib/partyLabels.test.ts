import { describe, expect, it } from 'vitest';
import { bracketEditProblem, namesParty } from './partyLabels.js';

describe('namesParty', () => {
  it('finds party names, cased names, minor parties and colours', () => {
    for (const t of ['The Republicans in this chamber blocked it.', 'the GOP plan', 'Democratic lawmakers blocked it.',
      'the Dems want this', 'the DFL caucus', 'Tea Party members', 'red states do this', 'a blue district']) {
      expect(namesParty(t), t).toBe(true);
    }
  });
  it('finds party-state tags and party letters', () => {
    for (const t of ['Sen. Jim Risch (R-Idaho) wrote', 'Rep. Lucy McBath (D-GA)', 'Sen. Chuck Schumer, D-N.Y.,',
      'Rep. Smith (R-Ill.)', 'Sen. Cruz (R–Texas)', 'Rep. Pallone (D-NJ)', 'Mayor Jones (D)', 'Sen. Lee (R.)',
      'Noes (Democrat): Smith, Jones', 'Jane Doe Democratic Ohio']) {
      expect(namesParty(t), t).toBe(true);
    }
  });
  it('finds party-and-town tags and party-district numbers (Michigan press, 2026-10-30)', () => {
    for (const t of ['said state Rep. Stephen Wooden (D-Grand Rapids), vice chair', 'said Lindsey, R-Allen.',
      'Rep. Jane Doe (D-Warren) said', 'said Bollin, R-Brighton Township.', 'Sen. Smith (D-Detroit)',
      'Rep. Pauline Wendzel (R-79)', 'Rep. Gonzales (D-Tucson)']) {
      expect(namesParty(t), t).toBe(true);
    }
  });
  it('leaves plain words alone', () => {
    for (const t of ['Every eligible voter should be able to vote.', 'a democratic process', 'D-Day landings',
      'an R-rated film', 'a red light camera', 'Section D-1 of the act', 'the R&D budget', 'Plan D-Day was set',
      'W3-R2 applies', 'HB 2492 (R-1 form)']) {
      expect(namesParty(t), t).toBe(false);
    }
  });
});

describe('bracketEditProblem', () => {
  it('accepts a label bracketed out with a listed word', () => {
    expect(bracketEditProblem('Sen. Jim Risch (R-Idaho) wrote that voters deserve it.', 'Sen. Jim Risch […] wrote that voters deserve it.')).toBeNull();
    expect(bracketEditProblem('Democrats want you to believe the rolls are clean.', '[Some lawmakers] want you to believe the rolls are clean.')).toBeNull();
    expect(bracketEditProblem('My Republican colleagues and I support ID.', '[some lawmakers] and I support ID.')).toBeNull();
    expect(bracketEditProblem('said state Rep. Mai Xiong (D-Warren). Mothers should not pay.', 'said state Rep. Mai Xiong […]. Mothers should not pay.')).toBeNull();
    expect(bracketEditProblem('said Lindsey, R-Allen. This session matters.', 'said Lindsey, […]. This session matters.')).toBeNull();
    expect(bracketEditProblem('said Rep. Stephen Wooden (D-Grand Rapids), vice chair.', 'said Rep. Stephen Wooden […], vice chair.')).toBeNull();
    expect(bracketEditProblem('Red states have cut early voting.', '[Some states] have cut early voting.')).toBeNull();
    expect(bracketEditProblem('Republicans and Democrats agree.', '[Others] and [others] agree.')).toBeNull();
  });
  it('treats "..." as "…" and compares quotes, dashes and spaces as the page check does', () => {
    expect(bracketEditProblem('Rep. Smith (D-GA)  said “no” — twice.', 'Rep. Smith [...] said "no" - twice.')).toBeNull();
  });
  it('keeps the speaker’s own brackets as words to match', () => {
    expect(bracketEditProblem('The GOP [sic] plan fails.', 'The [others] [sic] plan fails.')).toBeNull();
  });
  it('refuses a bracket word that is not on the list', () => {
    expect(bracketEditProblem('Democrats want this.', '[conservatives] want this.')).toMatch(/no bracket from the list/);
    expect(bracketEditProblem('Democrats want this.', '[the majority] want this.')).toMatch(/no bracket from the list/);
  });
  it('refuses a bracket over words that are not a party label', () => {
    expect(bracketEditProblem('Voters want this badly.', '[some voters] want this badly.')).toMatch(/not a party label/);
    expect(bracketEditProblem('Democrats who hate voters want this.', '[some lawmakers] want this.')).toMatch(/says more than a party label|changes more/);
  });
  it('refuses any other change, and a label left behind', () => {
    expect(bracketEditProblem('Democrats want this now.', '[some lawmakers] want this.')).toMatch(/changes more/);
    expect(bracketEditProblem('Democrats and the GOP want this.', '[some lawmakers] and the GOP want this.')).toMatch(/still in the shown text/);
    expect(bracketEditProblem('Plain words here.', 'Plain words here.')).toMatch(/same as the original/);
  });
});
