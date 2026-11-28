import { describe, expect, it } from 'vitest';
import { sponsorSentencesFromDocument, itemSponsorSentencesFromSynopsis, sponsorSentencesFromSynopsis, sponsorSentencesWithItems } from './sponsors.js';

describe('sponsor sentence finder', () => {
  it('reads "sponsored by Councilmember X"', () =>
    expect(
      sponsorSentencesFromSynopsis('This Ordinance, sponsored by Councilmember Stosberg, amends Section 14.40.060.')[0].names,
    ).toEqual([{ printed: 'Stosberg', role: 'sponsor' }]));
  it('reads "Cm." and an amendment heading', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: This amendment, sponsored by Cm. Piedmont-Smith, would delay the effective date.',
      ),
    ).toEqual([expect.objectContaining({ label: 'Amendment 01', names: [{ printed: 'Piedmont-Smith', role: 'sponsor' }] })]));
  it('reads two sponsors joined by "and"', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 04 Synopsis: This Amendment is sponsored by Councilmember Sandberg and Councilmember Rollo. The Amendment changes',
      )[0].names.map((n) => n.printed),
    ).toEqual(['Sandberg', 'Rollo']));
  it('reads "Councilmembers X and Y"', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: This amendment is sponsored by Councilmembers Smith and Rollo to remove a provision',
      )[0].names.map((n) => n.printed),
    ).toEqual(['Smith', 'Rollo']));
  it('skips a heading caught inside the name list', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: This amendment is sponsored by Councilmembers Amendment 01 Flaherty and Volan. It replaces',
      )[0].names.map((n) => n.printed),
    ).toEqual(['Flaherty', 'Volan']));
  it('marks co-sponsors', () =>
    expect(
      sponsorSentencesFromSynopsis('This resolution is sponsored by Councilmember Sims and co-sponsored by Councilmember Volan.')[0]
        .names,
    ).toEqual([
      { printed: 'Sims', role: 'sponsor' },
      { printed: 'Volan', role: 'cosponsor' },
    ]));
  it('reads a Reasonable Condition', () =>
    expect(
      sponsorSentencesFromDocument(
        'RC 16 Synopsis: This Reasonable Condition 16 is sponsored by Councilmember Piedmont-Smith. It offers',
      )[0].label,
    ).toBe('Reasonable Condition 16'));
  it('reads "O2" as 02', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment O2 to Ordinance 23-11 Amendment 02 Synopsis: This amendment is sponsored by Councilmember Sgambelluri and replaces',
      )[0].label,
    ).toBe('Amendment 02'));
  it('treats a bracketed placeholder as no sponsor', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: This amendment is sponsored by [CM sponsor needed] [sic] and is being brought forward',
      )[0],
    ).toEqual(expect.objectContaining({ placeholder: true, names: [] })));
  it('keeps "PiedmontSmith" as printed for the resolver', () =>
    expect(
      sponsorSentencesFromDocument('Amendment 01 Synopsis: This amendment is sponsored by Cm. PiedmontSmith and would add')[0]
        .names[0].printed,
    ).toBe('PiedmontSmith'));
  it('finds nothing in a synopsis with no sponsor', () =>
    expect(sponsorSentencesFromSynopsis('This ordinance amends Title 2.')).toEqual([]));
});

describe('sponsor sentence finder: safety rules', () => {
  const names = (t: string) => sponsorSentencesFromSynopsis(t)[0].names.map((n) => n.printed);
  const docNames = (t: string) => sponsorSentencesFromDocument(t).flatMap((s) => s.names.map((n) => n.printed));

  it('does not give a later sentence about another item to the amendment', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: This amendment changes the date. Ordinance 25-09 was sponsored by Councilmember Volan.',
      ),
    ).toEqual([]));
  it('does not read narrative minutes after a heading as the sponsor', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: Lehner stated that the amendment was brought forth by the City Clerk, and was sponsored by a councilmember.',
      ),
    ).toEqual([]));
  it('skips a sponsor sentence not worded as about this item', () =>
    expect(docNames('Amendment 01 Synopsis: This amendment would add a clause. It is sponsored by Councilmember Volan.')).toEqual([]));
  it('reads only the first sponsor sentence under a heading', () =>
    expect(
      docNames(
        'Amendment 01 Synopsis: This amendment is sponsored by Councilmember Volan. This amendment is also sponsored by Councilmember Sims.',
      ),
    ).toEqual(['Volan']));
  it('stops after a comma with no closing "and"', () =>
    expect(names('This amendment is sponsored by Cm. Sims, Cm. Volan moved to table it.')).toEqual(['Sims']));
  it('stops after a semicolon', () => expect(names('This amendment is sponsored by Councilmember Sims; Volan voted no.')).toEqual(['Sims']));
  it('reads a comma list closed by "and"', () =>
    expect(names('This resolution is sponsored by Councilmembers Rollo, Sandberg, and Smith.')).toEqual(['Rollo', 'Sandberg', 'Smith']));
  it('does not end a sentence at "Cm."', () =>
    expect(sponsorSentencesFromSynopsis('This is sponsored by Cm. Volan. It amends Title 2.')[0].sentence).toBe(
      'This is sponsored by Cm. Volan.',
    ));
  it('rejoins a name wrapped at its hyphen', () =>
    expect(names('This amendment is sponsored by Councilmember Piedmont- Smith and would add.')).toEqual(['Piedmont-Smith']));
  it('keeps a first name and surname as one printed name', () =>
    expect(names('This resolution, sponsored by Councilmembers Dave Rollo and Andy Ruff, would endorse it.')).toEqual(['Dave Rollo', 'Andy Ruff']));
  it('drops wrapped heading text before the first title', () =>
    expect(
      names('This amendment is sponsored by Dwelling, Triplex, and Dwelling, Councilmembers Piedmont-Smith and Sims.'),
    ).toEqual(['Piedmont-Smith', 'Sims']));
  it('reads nothing when names come before a title that follows (real wrapped strings)', () => {
    expect(names('This Amendment is sponsored by Fourplex Set Forth in BMC 20.03 Councilmember Sandberg and Councilmember Rollo.')).toEqual([]);
    expect(names('This Amendment is sponsored by Related to Dwelling, Duplex; Councilmembers Rollo and Sandberg.')).toEqual([]);
  });
  it('reads nothing from a heading wrapped into the sentence (real string)', () =>
    expect(
      names(
        "This amendment is sponsored by Amendment 01 to Resolution 22- Councilmember Flaherty and removes provisions that would 02 abolish the Council's Administration Committee.",
      ),
    ).toEqual([]));
  it('stops at a period inside a list', () =>
    expect(names('This amendment is sponsored by Councilmember Sims. and Rollo then spoke.')).toEqual([]));
  it.each([
    ['Dr.', 'This amendment is sponsored by Councilmember Sims and Dr. Volan to add a provision.'],
    ['an initial', 'This amendment is sponsored by Councilmember Sims and J. Rollo to add a provision.'],
    ['Sec.', 'This amendment is sponsored by Councilmember Sims and Sec. Rollo to add a provision.'],
    ['Jr.', 'This amendment is sponsored by Councilmember Sims and Councilmember Rollo Jr. to add a provision.'],
  ])('never reads %s as a name', (_k, text) => expect(names(text)).toEqual(['Sims']));
  it('reads heading variants: "#", "(revised)", lowercase synopsis', () => {
    const one = (t: string) => sponsorSentencesFromDocument(t)[0];
    expect(one('Reasonable Condition #1 Synopsis: This Reasonable Condition 01 is sponsored by Councilmember Stosberg. It requires')).toEqual(
      expect.objectContaining({ label: 'Reasonable Condition 1', names: [{ printed: 'Stosberg', role: 'sponsor' }] }),
    );
    expect(one('Reasonable Condition 04 (revised) Synopsis: This Reasonable Condition (04) is sponsored by Cm. Piedmont-Smith and was recommended by it.').names).toEqual([
      { printed: 'Piedmont-Smith', role: 'sponsor' },
    ]);
    expect(one('Reasonable Condition 07 synopsis: This Reasonable Condition (07) is sponsored by Cm. Stosberg and clarifies that').names).toEqual([
      { printed: 'Stosberg', role: 'sponsor' },
    ]);
  });
});

describe('feed synopsis', () => {
  it('leaves out a sentence about an amendment: it names the amendment\'s sponsor, not the item\'s', () =>
    expect(
      itemSponsorSentencesFromSynopsis(
        'This Resolution sponsored by Councilmember Asare requires a briefing. Note: At the Regular Session, the Council adopted ' +
          'Amendment 01 to this resolution. The amendment, sponsored by Councilmember Piedmont-Smith, added a timeline.',
      ).map((s) => s.names.map((n) => n.printed)),
    ).toEqual([['Asare']]));
});

describe('tying a document sentence to its item', () => {
  const items = (t: string) => sponsorSentencesWithItems(t).map((s) => [s.label, s.itemNumber]);

  it('ties an amendment synopsis to the item its motion names', () =>
    expect(
      items(
        'Piedmont-Smith moved and it was seconded to adopt Amendment 01 to Ordinance 22-13.\n\n' +
          'Amendment 01 Synopsis: This amendment is sponsored by Cm. Piedmont-Smith. It delays the date.',
      ),
    ).toEqual([['Amendment 01', 'Ord 22-13']]));
  it('reads an item number wrapped at the hyphen', () =>
    expect(
      items(
        'Volan moved and it was seconded to adopt Amendment 01 to Resolution 23- 04. He spoke.\n' +
          'Amendment 01 Synopsis: This amendment is sponsored by Cm. Volan. It changes the text.',
      ),
    ).toEqual([['Amendment 01', 'Res 23-04']]));
  it('ties two items in one document to their own motions', () =>
    expect(
      items(
        'Daily moved and it was seconded to adopt Amendment 01 to Ordinance 2025-16. ' +
          'Amendment 01 Synopsis: This amendment is sponsored by Cm. Daily. It fixes a date. ' +
          'Stosberg moved and Rollo seconded that Amendment 01 be adopted to Resolution 2025-18. ' +
          'Amendment 01 Synopsis: This amendment is sponsored by Cm. Stosberg. It replaces Exhibit A.',
      ),
    ).toEqual([
      ['Amendment 01', 'Ord 2025-16'],
      ['Amendment 01', 'Res 2025-18'],
    ]));
  it('uses the motion that opens the item when the label is not named near it', () =>
    expect(
      items(
        'Daily moved and Zulich seconded that Ordinance 2026-06 be adopted. The mayor spoke. ' +
          'Stosberg presented Reasonable Condition 4. Reasonable Condition 4 Synopsis: This reasonable condition is ' +
          'sponsored by Cm. Stosberg. It removes a use.',
      ),
    ).toEqual([['Reasonable Condition 4', 'Ord 2026-06']]));
  it('gives no item when another item is cited between the motion and the heading', () =>
    expect(
      items(
        'Daily moved and Zulich seconded that Ordinance 2026-06 be adopted. Condition text: passed as Ordinance 2026-02 on ' +
          'January 14, 2026. Reasonable Condition 11 Synopsis: This reasonable condition is sponsored by Cm. Flaherty. It lowers rents.',
      ),
    ).toEqual([['Reasonable Condition 11', null]]));
  it('does not take a mention in a synopsis ("amends Ordinance 21-03") for a heading', () =>
    expect(
      items(
        'Volan moved and it was seconded to adopt Amendment 02 to Ordinance 22-14. ' +
          'Amendment 02 Synopsis: This amendment is sponsored by Cm. Volan. It amends Ordinance 21-03 by deleting a clause. ' +
          'Amendment 03 Synopsis: This amendment is sponsored by Cm. Rollo. It adds a clause.',
      ),
    ).toEqual([
      ['Amendment 02', 'Ord 22-14'],
      ['Amendment 03', null], // no motion introduced it: the citation inside Amendment 02's synopsis is not one
    ]));
  it('ties an appropriation ordinance', () =>
    expect(
      items(
        'Ruff moved and it was seconded to adopt Amendment 03 to Appropriation Ordinance 2026-02. ' +
          'Amendment 03 Synopsis: This amendment is sponsored by Cm. Ruff. It moves funds.',
      ),
    ).toEqual([['Amendment 03', 'App Ord 2026-02']]));
  it('gives no item to a sentence before any heading, and never guesses', () =>
    expect(
      items(
        'The clerk noted that Ordinance 21-03 was postponed. Amendment 01 Synopsis: This amendment is sponsored by Cm. Ruff. It moves funds.',
      ),
    ).toEqual([['Amendment 01', null]]));

  const OPEN = 'Daily moved and Zulich seconded that Ordinance 2026-02 be adopted. ';
  const SYN = 'Amendment 01 Synopsis: This amendment is sponsored by Cm. Ruff. It moves funds.';
  it('A: a label mentioned in discussion (no moved/seconded) does not tie to that item', () =>
    expect(
      items(`${OPEN}Daily moved and Zulich seconded that Ordinance 2026-06 be adopted. Rollo said this resembled Amendment 01 to Ordinance 2025-16. ${SYN}`),
    ).toEqual([['Amendment 01', null]]));
  it('B: "as amended" in the opening motion still ties to that item', () =>
    expect(items(`${OPEN}Daily moved and Zulich seconded that Ordinance 2026-06, as amended, be adopted. ${SYN}`)).toEqual([['Amendment 01', 'Ord 2026-06']]));
  it('C: "Ordinance No. 2026-06" ties to that item', () =>
    expect(items(`${OPEN}Daily moved and Zulich seconded that Ordinance No. 2026-06 be adopted. ${SYN}`)).toEqual([['Amendment 01', 'Ord 2026-06']]));
  it('D: "to approve Resolution 2026-06" ties to that item', () =>
    expect(items(`${OPEN}Daily moved and Zulich seconded to approve Resolution 2026-06. ${SYN}`)).toEqual([['Amendment 01', 'Res 2026-06']]));
  it('E: the label\'s motion printed after the synopsis, on another item, gives no item', () =>
    expect(items(`${OPEN}${SYN} Volan moved and it was seconded to adopt Amendment 01 to Ordinance 2026-06.`)).toEqual([['Amendment 01', null]]));

  it('a roll call on another item is not a contradiction when another synopsis of the document is tied to that item', () => {
    const text =
      'Daily moved and Zulich seconded to adopt Amendment 01 to Ordinance 2026-02. Amendment 01 Synopsis: This amendment is sponsored by Cm. Ruff. It moves funds. ' +
      'Daily moved and Zulich seconded to adopt Amendment 01 to Ordinance 2026-09. Amendment 01 Synopsis: This amendment is sponsored by Cm. Rollo. It moves dates.';
    expect(sponsorSentencesWithItems(text, [{ itemNumber: 'Ord 2026-09', question: 'Amendment 01' }]).map((s) => s.itemNumber)).toEqual(['Ord 2026-02', 'Ord 2026-09']);
  });
  it('a roll call carrying the label on another item, and none on the tied item, gives no item', () => {
    const text = `${OPEN}${SYN}`;
    expect(sponsorSentencesWithItems(text, [{ itemNumber: 'Ord 2026-06', question: 'Amendment 01' }]).map((s) => s.itemNumber)).toEqual([null]);
    expect(sponsorSentencesWithItems(text, [{ itemNumber: 'Ord 2026-02', question: 'Amendment 01' }]).map((s) => s.itemNumber)).toEqual(['Ord 2026-02']);
    expect(sponsorSentencesWithItems(text, []).map((s) => s.itemNumber)).toEqual(['Ord 2026-02']);
  });
});

describe('final review fixes: wrong-tie paths', () => {
  const OPEN = 'Daily moved and Zulich seconded that Ordinance 2026-02 be adopted. ';

  it('N1: two same-label synopses tied to one item, with a roll call of that label on an unclaimed item, both give no item', () => {
    // The first synopsis belongs to Ord 2026-09 and is a placeholder; the second is Ord 2026-02's. Both tie to 2026-02.
    const text =
      `${OPEN}Amendment 01 Synopsis: This amendment is sponsored by [CM sponsor needed]. It moves funds. ` +
      'Amendment 01 Synopsis: This amendment is sponsored by Cm. Rollo. It moves dates.';
    const rolls = [
      { itemNumber: 'Ord 2026-02', question: 'Amendment 01' },
      { itemNumber: 'Ord 2026-09', question: 'Amendment 01' },
    ];
    expect(sponsorSentencesWithItems(text, rolls).map((s) => s.itemNumber)).toEqual([null, null]);
    // Without the unclaimed roll call there is nothing to say one belongs elsewhere: they stay tied (and the resolver
    // compares them).
    expect(sponsorSentencesWithItems(text, rolls.slice(0, 1)).map((s) => s.itemNumber)).toEqual(['Ord 2026-02', 'Ord 2026-02']);
  });

  it('N2: the label\'s motion on another item counts when printed after a run of synopsis headings (no roll call)', () => {
    const text =
      `${OPEN}Amendment 01 Synopsis: This amendment is sponsored by Cm. Ruff. It moves funds. ` +
      'Amendment 02 Synopsis: This amendment is sponsored by Cm. Rollo. It moves dates. ' +
      'Volan moved and it was seconded to adopt Amendment 01 to Ordinance 2026-09. The motion passed by voice vote.';
    expect(sponsorSentencesWithItems(text).map((s) => [s.label, s.itemNumber])).toEqual([
      ['Amendment 01', null],
      ['Amendment 02', 'Ord 2026-02'],
    ]);
  });

  it('N2: past the next heading, the search stops at the next item-opening motion', () => {
    const text =
      `${OPEN}Amendment 01 Synopsis: This amendment is sponsored by Cm. Ruff. It moves funds. ` +
      'Amendment 02 Synopsis: This amendment is sponsored by Cm. Rollo. It moves dates. ' +
      'Daily moved and Zulich seconded that Ordinance 2026-09 be adopted. ' +
      'Volan moved and it was seconded to adopt Amendment 01 to Ordinance 2026-09. ' +
      'Amendment 01 Synopsis: This amendment is sponsored by Cm. Volan. It adds a clause.';
    expect(sponsorSentencesWithItems(text).map((s) => [s.label, s.itemNumber])).toEqual([
      ['Amendment 01', 'Ord 2026-02'],
      ['Amendment 02', 'Ord 2026-02'],
      ['Amendment 01', 'Ord 2026-09'],
    ]);
  });

  it('N2: the last synopsis still searches to the end of the document (never narrower than before)', () => {
    const text =
      `${OPEN}Amendment 01 Synopsis: This amendment is sponsored by Cm. Ruff. It moves funds. ` +
      'Daily moved and Zulich seconded that Ordinance 2026-09 be adopted. ' +
      'Volan moved and it was seconded to adopt Amendment 01 to Ordinance 2026-09.';
    expect(sponsorSentencesWithItems(text).map((s) => s.itemNumber)).toEqual([null]);
  });

  it('a sub-amendment heading ("Amendment A to Amendment 01 Synopsis:") is never read as Amendment 01', () => {
    const text =
      'Piedmont-Smith moved and it was seconded to adopt Amendment 01 to Ordinance 2026-02. ' +
      'Amendment A to Amendment 01 Synopsis: This amendment is sponsored by Cm. Rollo. It changes a date.';
    const out = sponsorSentencesWithItems(text);
    // Its names come back with no item, so the caller raises sponsor_unresolved (no_item) and writes no row.
    expect(out).toEqual([expect.objectContaining({ label: 'Amendment A to Amendment 01', itemNumber: null, names: [{ printed: 'Rollo', role: 'sponsor' }] })]);
    expect(sponsorSentencesFromDocument(text)).toEqual([]);
    expect(sponsorSentencesWithItems(text.replace('Amendment A to', 'Sub-amendment A to')).map((s) => s.itemNumber)).toEqual([null]);
  });

  it('a sub-amendment heading ends the parent synopsis: its sentence is never taken as the parent\'s sponsor', () => {
    const text =
      'Piedmont-Smith moved and it was seconded to adopt Amendment 01 to Ordinance 2026-02. ' +
      'Amendment 01 Synopsis: It delays the date. ' +
      'Amendment A to Amendment 01 Synopsis: This amendment is sponsored by Cm. Rollo. It changes a date.';
    expect(sponsorSentencesWithItems(text).map((s) => [s.label, s.itemNumber])).toEqual([['Amendment A to Amendment 01', null]]);
  });
});

describe('feed synopsis allow-list', () => {
  it('keeps only sentences that open "This Ordinance/Resolution"', () => {
    const names = (t: string) => itemSponsorSentencesFromSynopsis(t).map((s) => s.names.map((n) => n.printed));
    expect(names('This Ordinance, sponsored by Councilmember Ruff, changes rents.')).toEqual([['Ruff']]);
    expect(names('This Appropriation Ordinance, sponsored by Councilmember Ruff, moves funds.')).toEqual([['Ruff']]);
    expect(names('Councilmember Daily, sponsored by Councilmember Ruff, spoke.')).toEqual([]);
    expect(names('The amendment, sponsored by Councilmember Ruff, added a date.')).toEqual([]);
  });
});

describe('"Council Sponsor:" agenda headings', () => {
  const heads = (t: string) => sponsorSentencesWithItems(t).filter((s) => s.label === null);

  it('reads one name, tied to the heading block item (not the motion)', () => {
    const r = heads([
      'Resolution 2026-15', '',
      'Approval of Collective Bargaining Agreement with Don Owens Memorial Lodge 88, Fraternal',
      'Order of Police Council Sponsor: CM Rollo',
      'Daily moved and Asare seconded that Resolution 2026-15 be introduced.',
    ].join('\n'));
    expect(r).toHaveLength(1);
    expect(r[0]).toMatchObject({ itemNumber: 'Res 2026-15', label: null, sentence: 'Council Sponsor: CM Rollo', names: [{ printed: 'Rollo', role: 'sponsor' }] });
  });

  it('keeps the heading item when the motion below names another item', () => {
    const r = heads(['Resolution 2026-22', 'To Approve an Update to the ADA Transition Plan Council Sponsor - CM Daily', 'Daily moved and Piedmont-Smith seconded that Ordinance 2026-22 be introduced.'].join('\n'));
    expect(r[0].itemNumber).toBe('Res 2026-22');
  });

  it('reads two and three names, with the zero-width space and the numbered heading of real files', () => {
    const r = heads(['6.2.​ Ordinance 2026-22', 'Prohibiting Use of ALPR Technology Council Sponsor - CMs Zulich, Piedmont-Smith, Asare', 'x'].join('\n'));
    expect(r[0].itemNumber).toBe('Ord 2026-22');
    expect(r[0].names.map((n) => n.printed)).toEqual(['Zulich', 'Piedmont-Smith', 'Asare']);
    const two = heads(['7.3.​ Ordinance 2026-12', 'To Provide a Carless Kirkwood Council Sponsor - CM Daily and Rosenbarger'].join('\n'));
    expect(two[0].names.map((n) => n.printed)).toEqual(['Daily', 'Rosenbarger']);
  });

  it('reads "N/A", "None" and a blank as no sponsor: no row and no exception', () => {
    expect(heads(['Appropriation Ordinance 2026-01', 'Approval of Additional Appropriation Council Sponsor N/A (B.M.C. 2.04.070)'].join('\n'))).toEqual([]);
    expect(heads(['Resolution 2026-20', 'Budget for the Board Council Sponsor: N/A - Budget-related per B.M.C.', '2.04.270'].join('\n'))).toEqual([]);
    expect(heads(['Resolution 2026-21', 'Something Council Sponsor: None'].join('\n'))).toEqual([]);
    expect(heads(['Resolution 2026-21', 'Something Council Sponsor:'].join('\n'))).toEqual([]);
  });

  it('joins a wrapped name only when the next line is only a name', () => {
    const wrapped = heads(['Ordinance 2026-20', 'Amending Title 20 pursuant to Council Resolution 2026-05 Council Sponsor - CM', 'Flaherty', 'Daily moved and Zulich seconded that Ordinance 2026-20 be introduced'].join('\n'));
    expect(wrapped[0].names).toEqual([{ printed: 'Flaherty', role: 'sponsor' }]);
    expect(wrapped[0].sentence).toBe('Council Sponsor - CM Flaherty');
    const notAName = heads(['Ordinance 2026-20', 'Amending Title 20 Council Sponsor - CM', 'Daily moved and Zulich seconded that it be introduced'].join('\n'));
    expect(notAName[0].names).toEqual([]);
    expect(notAName[0].placeholder).toBe(false);
  });

  it('gives item null when the heading item cannot be read', () => {
    const r = heads(['Amending Title 20 of the Code Council Sponsor - CM Rollo', 'Daily moved and Zulich seconded that Ordinance 2026-20 be introduced'].join('\n'));
    expect(r[0].itemNumber).toBeNull();
    expect(r[0].names).toEqual([{ printed: 'Rollo', role: 'sponsor' }]);
    // A motion between the heading and the sponsor line also breaks the tie.
    const motion = heads(['Ordinance 2026-20', 'Daily moved and Zulich seconded that it be adopted.', 'Council Sponsor - CM Rollo'].join('\n'));
    expect(motion[0].itemNumber).toBeNull();
  });

  it('joins a marker that wraps between "Council" and "Sponsor:"', () => {
    const r = sponsorSentencesWithItems(['Ordinance 2026-23', 'UDO Amendments Related to Limited Compliance and Change in Use Standards Council', 'Sponsor: CM Stosberg', 'Daily moved and Zulich seconded that Ordinance 2026-23 be introduced'].join('\n'));
    expect(r).toHaveLength(1);
    expect(r[0]).toMatchObject({ itemNumber: 'Ord 2026-23', sentence: 'Council Sponsor: CM Stosberg', names: [{ printed: 'Stosberg', role: 'sponsor' }] });
  });

  it('a co-sponsor line gives the cosponsor role', () => {
    const r = heads(['Ordinance 2026-30', 'Title Council Co-Sponsor: CM Rollo'].join('\n'));
    expect(r[0].names).toEqual([{ printed: 'Rollo', role: 'cosponsor' }]);
  });
});

describe('"Council Sponsor:" line in the right margin column', () => {
  it('is read from the unmargined text when given', () => {
    const raw = ['7.2. Resolution 2026-13', '', 'Authorizing Issuance of Bonds   Council Sponsor - CM Zulich', 'Daily moved'].join('\n');
    const stripped = ['7.2. Resolution 2026-13', '', 'Authorizing Issuance of Bonds', 'Daily moved'].join('\n');
    expect(sponsorSentencesWithItems(stripped)).toEqual([]);
    const r = sponsorSentencesWithItems(stripped, [], raw);
    expect(r).toHaveLength(1);
    expect(r[0]).toMatchObject({ itemNumber: 'Res 2026-13', names: [{ printed: 'Zulich', role: 'sponsor' }] });
  });
});

describe('heading block stays inside its own block', () => {
  const run = (second: string) => sponsorSentencesWithItems(
    ['7.1. Ordinance 2026-20', 'Title A Council Sponsor - N/A', second, 'Title B Council Sponsor - CM Daily'].join('\n'),
  ).map((s) => [s.itemNumber, s.names.map((n) => n.printed)]);

  it('an unreadable own item line gives null, never the earlier item', () => {
    expect(run('7.2. Ordinance 2026-21        Ayes: 9')).toEqual([[null, ['Daily']]]);
    expect(run('7.2. Ordinance 26-21')).toEqual([[null, ['Daily']]]);
  });
  it('a trailing parenthetical is accepted and still ties to its own item', () => {
    expect(run('7.2. Ordinance 2026-21 (Second Reading)')).toEqual([['Ord 2026-21', ['Daily']]]);
  });
  it('a readable own item still ties correctly', () => {
    expect(run('7.2. Ordinance 2026-21')).toEqual([['Ord 2026-21', ['Daily']]]);
  });
});

describe('"authored by" as a sponsor marker', () => {
  it('reads a feed synopsis "This Resolution 2026-07, authored by Councilmembers Sydney Zulich and Courtney Daily, supports ..."', () => {
    const r = itemSponsorSentencesFromSynopsis("This Resolution 2026-07, authored by Councilmembers Sydney Zulich and Courtney Daily, supports the Monroe County Council's decision.");
    expect(r).toHaveLength(1);
    expect(r[0].names).toEqual([{ printed: 'Sydney Zulich', role: 'sponsor' }, { printed: 'Courtney Daily', role: 'sponsor' }]);
  });
  it('reads "co-authored by" as cosponsor, and ignores a non-council author', () => {
    expect(sponsorSentencesFromSynopsis('This ordinance, co-authored by Councilmember Rollo, amends Title 2.')[0].names).toEqual([{ printed: 'Rollo', role: 'cosponsor' }]);
    expect(itemSponsorSentencesFromSynopsis('This ordinance, authored by Public Works, updates the sanitation division.')).toEqual([]);
  });
  it('reads it in a document amendment synopsis', () => {
    const r = sponsorSentencesFromDocument('Amendment 01 Synopsis: This amendment, authored by Cm. Piedmont-Smith, would delay the date.');
    expect(r[0].names).toEqual([{ printed: 'Piedmont-Smith', role: 'sponsor' }]);
  });
});

// A synopsis that ends without a full stop (a numbered list, a code section) is not split from the next line, so the
// stored sentence ran on into the next motion. Live case: Ord 2026-22 Amendment 03, meeting file 17809.
describe('a sponsor sentence stops before the next motion or heading', () => {
  const MEETING_17809 = [
    'Daily moved and Zulich seconded that Ordinance 2026-22 be adopted.',
    '',
    'Piedmont-Smith moved and Zulich seconded Amendment 03 to Ordinance 2026-22. The',
    'motion to adopt Amendment 03 received a roll call vote of Ayes: 7, Nays: 0, Abstain: 0.',
    '',
    'Amendment 03 Synopsis: This amendment, sponsored by Cm. Piedmont-Smith, does the',
    'following:',
    '1) Aligns prohibited uses with the expanded definition of surveillance camera proposed by',
    'Am. 02 and allows limited technical access to internal systems for repairs - 2.87.035',
    '2) Clarifies that acquisition of ALPR systems, as well as their use, is banned - 2.87.030(a)',
    '4) Adds a requirement for surveillance cameras that ARE allowed under this ordinance to',
    'not by used for facial recognition, biometric identification, or automated tracking of',
    'persons without prior city council authorization - 2.87.040',
    '',
    'Piedmont-Smith moved and Zulich seconded Amendment 05 to Ordinance 2026-22. The',
    'motion to adopt Amendment 05 received a roll call vote of Ayes: 5, Nays: 2 (Zulich, Asare),',
    'Abstain: 0.',
  ].join('\n');

  it('live case: Ord 2026-22 Amendment 03 ends at its own last line, not at the Amendment 05 motion', () => {
    const [s] = sponsorSentencesWithItems(MEETING_17809);
    expect(s.label).toBe('Amendment 03');
    expect(s.itemNumber).toBe('Ord 2026-22');
    expect(s.names).toEqual([{ printed: 'Piedmont-Smith', role: 'sponsor' }]);
    expect(s.sentence.endsWith('without prior city council authorization - 2.87.040')).toBe(true);
    expect(s.sentence).not.toMatch(/moved|seconded|Amendment 05/);
  });

  const cases: [string, string, string][] = [
    ['"<Name> moved and <Name> seconded" after a code section',
      'Amendment 02 Synopsis: This amendment, sponsored by Cm. Rollo, changes the fee - 15.48.030 Rollo moved and Sims seconded to adopt Amendment 02.',
      'This amendment, sponsored by Cm. Rollo, changes the fee - 15.48.030'],
    ['"Cm. <Name> moved" after a numbered list',
      'Amendment 04 Synopsis: This amendment is sponsored by Councilmember Stosberg and does the following: 1) sets hours 2) sets fees Cm. Volan moved and Cm. Sims seconded Amendment 06 to Ordinance 2025-11.',
      'This amendment is sponsored by Councilmember Stosberg and does the following: 1) sets hours 2) sets fees'],
    ['"Councilmember <Name> moved"',
      'Amendment 01 Synopsis: This amendment, sponsored by Councilmember Flaherty, corrects the map - Exhibit A Councilmember Flaherty moved to adopt Amendment 01.',
      'This amendment, sponsored by Councilmember Flaherty, corrects the map - Exhibit A'],
    ['"It was moved and seconded"',
      'Amendment 01 Synopsis: This amendment, sponsored by Cm. Zulich, fixes a typo in Section 3 It was moved and seconded to adopt Amendment 01.',
      'This amendment, sponsored by Cm. Zulich, fixes a typo in Section 3'],
    ['"The motion to adopt" line',
      'Amendment 02 Synopsis: This amendment, sponsored by Cm. Asare, adds a whereas clause The motion to adopt Amendment 02 received a roll call vote of Ayes: 9.',
      'This amendment, sponsored by Cm. Asare, adds a whereas clause'],
    ['a numbered item heading',
      'Amendment 05 Synopsis: This amendment, sponsored by Cm. Daily, changes the date - 2.87.050 7.2. Appropriation Ordinance 2026-02 An Ordinance for Appropriations.',
      'This amendment, sponsored by Cm. Daily, changes the date - 2.87.050'],
    ['a Roman-numeral agenda heading',
      'Amendment 03 Synopsis: This amendment, sponsored by Cm. Stosberg, removes Section 4 VIII. LEGISLATION FOR FIRST READING Ordinance 2025-30.',
      'This amendment, sponsored by Cm. Stosberg, removes Section 4'],
  ];
  it.each(cases)('cuts at %s', (_shape, text, want) => {
    const [s] = sponsorSentencesFromDocument(text);
    expect(s.sentence).toBe(want);
  });

  it('keeps every sponsor name when the cut follows a two-name list', () => {
    const [s] = sponsorSentencesFromDocument(
      'Amendment 01 Synopsis: This amendment, sponsored by Councilmembers Flaherty and Volan, changes Table 2 - 20.04.020 Flaherty moved and Volan seconded Amendment 01 to Ordinance 2024-10.',
    );
    expect(s.names.map((n) => n.printed)).toEqual(['Flaherty', 'Volan']);
    expect(s.sentence).toBe('This amendment, sponsored by Councilmembers Flaherty and Volan, changes Table 2 - 20.04.020');
  });

  it('a motion right after the names no longer glues onto the last name', () => {
    const [s] = sponsorSentencesFromDocument(
      'Amendment 01 Synopsis: This amendment is sponsored by Cm. Rollo\n\nRollo moved and Sims seconded Amendment 01 to Ordinance 2024-10.',
    );
    expect(s.names).toEqual([{ printed: 'Rollo', role: 'sponsor' }]);
    expect(s.sentence).toBe('This amendment is sponsored by Cm. Rollo');
  });

  it('never cuts when the cut would drop a name the whole sentence reads', () => {
    const text = 'Amendment 01 Synopsis: This amendment is sponsored by Cm. Sims and Cm. Volan moved and Rollo seconded it.';
    const [s] = sponsorSentencesFromDocument(text);
    expect(s.names.map((n) => n.printed)).toEqual(['Sims', 'Volan']);
    expect(s.sentence).toBe(text.replace('Amendment 01 Synopsis: ', ''));
  });

  it('does not cut synopsis prose that only mentions a move or another amendment', () => {
    const text =
      'Amendment 02 Synopsis: This amendment, sponsored by Cm. Piedmont-Smith, moves the text regarding the surcharge to 15.52.060 and aligns it with the definition proposed by Amendment 01 to Ordinance 2026-22 and the motion to table.';
    const [s] = sponsorSentencesFromDocument(text);
    expect(s.sentence).toBe(text.replace('Amendment 02 Synopsis: ', ''));
  });

  it('leaves a feed synopsis that is one clean sentence alone', () => {
    const text = 'This ordinance, sponsored by Councilmember Piedmont-Smith, moves Title 2 provisions into a single chapter.';
    expect(sponsorSentencesFromSynopsis(text)[0].sentence).toBe(text);
  });
});
