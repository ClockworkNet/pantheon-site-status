import { describe, expect, it } from 'vitest'
import { formatGeneratedAt, parseSitesPayload } from '../utils/sitesPayload'

describe('parseSitesPayload', () => {
  it('keeps a legacy array payload working', () => {
    const sites = [{ name: 'alpha' }]
    expect(parseSitesPayload(sites)).toEqual({
      list: sites,
      generatedAt: null
    })
  })

  it('reads generated_at and sites from the envelope', () => {
    const sites = [{ name: 'alpha' }]
    expect(parseSitesPayload({
      generated_at: '2026-08-20T06:00:00.000Z',
      sites
    })).toEqual({
      list: sites,
      generatedAt: '2026-08-20T06:00:00.000Z'
    })
  })

  it('returns an empty list when the envelope is missing sites', () => {
    expect(parseSitesPayload({})).toEqual({
      list: [],
      generatedAt: null
    })
  })
})

describe('formatGeneratedAt', () => {
  it('formats a UTC timestamp in Chicago time', () => {
    expect(formatGeneratedAt('2026-08-20T06:00:00.000Z')).toBe('August 20, 2026 at 1:00 AM CDT')
  })

  it('returns an empty string when the timestamp is missing', () => {
    expect(formatGeneratedAt(null)).toBe('')
  })
})
