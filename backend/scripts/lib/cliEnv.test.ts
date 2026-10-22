import { describe, it, expect } from 'vitest';
import { flag, flags, hasFlag, CliFlagError } from './cliEnv.js';

const A = ['node', 'x.ts', '--topic', 'taxes', '--json', '--forbid', '/a', '--forbid', '/b'];

describe('flag', () => {
  it('returns the value, or undefined when absent', () => {
    expect(flag(A, '--topic')).toBe('taxes');
    expect(flag(A, '--season')).toBeUndefined();
  });
  it('a flag with no value is an error: at the end, or followed by another flag', () => {
    expect(() => flag(['--topic'], '--topic')).toThrow(CliFlagError);
    expect(() => flag(['--research', '--json'], '--research')).toThrow('--research needs a value');
    expect(() => flag(['--root', ''], '--root')).toThrow(CliFlagError);
  });
  it('accepts a value that starts with a single dash or a slash', () => {
    expect(flag(['--x', '-1'], '--x')).toBe('-1');
    expect(flag(['--root', '/abs'], '--root')).toBe('/abs');
  });
});

describe('flags', () => {
  it('collects every use in order', () => {
    expect(flags(A, '--forbid')).toEqual(['/a', '/b']);
    expect(flags(A, '--none')).toEqual([]);
  });
  it('throws when any use has no value', () => {
    expect(() => flags(['--forbid', '/a', '--forbid'], '--forbid')).toThrow(CliFlagError);
    expect(() => flags(['--forbid', '--out', 'o'], '--forbid')).toThrow(CliFlagError);
  });
});

describe('hasFlag', () => {
  it('detects a boolean flag', () => {
    expect(hasFlag(A, '--json')).toBe(true);
    expect(hasFlag(A, '--dry-run')).toBe(false);
  });
});
