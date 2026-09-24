import { describe, expect, it } from 'vitest';
import { splitPersonName } from './split-person-name';

describe('splitPersonName', () => {
  it('moves a middle initial out of the surname (CA_0267)', () => {
    expect(splitPersonName('Jeffrey S. Gray')).toEqual({
      first: 'Jeffrey', middle_initial: 'S.', last: 'Gray', suffix: null, preferred: null,
    });
  });

  it('accepts an initial without a period', () => {
    expect(splitPersonName('Julie J Hewetson')).toMatchObject({ first: 'Julie', middle_initial: 'J', last: 'Hewetson' });
  });

  it('splits a generational suffix, with or without a comma', () => {
    expect(splitPersonName('David S. Kerr, Jr.')).toEqual({
      first: 'David', middle_initial: 'S.', last: 'Kerr', suffix: 'Jr.', preferred: null,
    });
    expect(splitPersonName('John A. Beccia III')).toMatchObject({ last: 'Beccia', suffix: 'III' });
    expect(splitPersonName('Henry J. Ward, III')).toMatchObject({ last: 'Ward', suffix: 'III' });
  });

  it('takes a quoted nickname as the preferred name', () => {
    expect(splitPersonName('James C. "Jim" McDermott')).toEqual({
      first: 'James', middle_initial: 'C.', last: 'McDermott', suffix: null, preferred: 'Jim',
    });
  });

  it('keeps a leading initial with the given name', () => {
    expect(splitPersonName('J. Lowry Snow')).toMatchObject({ first: 'J. Lowry', middle_initial: null, last: 'Snow' });
  });

  it('keeps a multi-word remainder whole, as before', () => {
    expect(splitPersonName('Mary Jo Van Pelt')).toMatchObject({ first: 'Mary', middle_initial: null, last: 'Jo Van Pelt' });
  });

  it('never leaves the surname empty', () => {
    expect(splitPersonName('Cher')).toMatchObject({ first: 'Cher', last: 'Cher' });
    expect(splitPersonName('Tom Jr.')).toMatchObject({ first: 'Tom', last: 'Jr.', suffix: null });
    expect(splitPersonName('Ann B.')).toMatchObject({ first: 'Ann', middle_initial: null, last: 'B.' });
  });
});
