import { describe, it, expect, vi } from 'vitest'
import {
  firstNonBlank,
  deterministicAutoName,
  generateUniqueAutoName,
  type Queryable,
} from './displayName.js'

describe('firstNonBlank', () => {
  it('returns the first non-whitespace string, trimmed', () => {
    expect(firstNonBlank(null, undefined, '  ', '  Explorer  ')).toBe('Explorer')
  })
  it('returns undefined when everything is blank', () => {
    expect(firstNonBlank(null, undefined, '', '   ')).toBeUndefined()
  })
})

describe('deterministicAutoName', () => {
  it('is stable for a given seed', () => {
    expect(deterministicAutoName('user-abc')).toBe(deterministicAutoName('user-abc'))
  })
  it('is a non-empty CamelCase AdjectiveAnimal', () => {
    expect(deterministicAutoName('user-abc')).toMatch(/^[A-Z][a-z]+[A-Z][a-z]+$/)
  })
})

describe('generateUniqueAutoName', () => {
  it('returns the base name when it is free (one DB check)', async () => {
    const db = { query: vi.fn().mockResolvedValue({ rows: [] }) } as unknown as Queryable
    const name = await generateUniqueAutoName(db)
    expect(name).toMatch(/^[A-Z][a-z]+[A-Z][a-z]+$/)
    expect((db.query as ReturnType<typeof vi.fn>)).toHaveBeenCalledTimes(1)
  })
  it('appends a number when the base name is taken', async () => {
    const query = vi.fn()
      .mockResolvedValueOnce({ rows: [{ one: 1 }] }) // base taken
      .mockResolvedValueOnce({ rows: [] })            // base+2 free
    const db = { query } as unknown as Queryable
    const name = await generateUniqueAutoName(db)
    expect(name).toMatch(/2$/)
    expect(query).toHaveBeenCalledTimes(2)
  })
})
