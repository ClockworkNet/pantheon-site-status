import { describe, expect, it } from 'vitest'
import { needsUpgrade } from '../utils/pluginStatus'

describe('needsUpgrade', () => {
  it('treats "0" as up to date', () => {
    expect(needsUpgrade({ needs_update: '0' })).toBe(false)
  })

  it('treats "1" as needing an upgrade', () => {
    expect(needsUpgrade({ needs_update: '1' })).toBe(true)
  })
})
