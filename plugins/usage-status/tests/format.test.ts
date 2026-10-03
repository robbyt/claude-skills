import { describe, expect, test } from 'claude-code/testing'

import { formatUsage } from '../hooks/format'

describe('formatUsage', () => {
  test('shows session and week remaining', async () => {
    const text = formatUsage([
      { kind: 'seven_day', percentUsed: 42.4 },
      { kind: 'five_hour', percentUsed: 23.5 },
    ])
    expect(text).toBe('session 77% · week 58% remaining')
  })

  test('shows only the windows that have a reading', async () => {
    expect(formatUsage([{ kind: 'seven_day', percentUsed: 10 }])).toBe('week 90% remaining')
  })

  test('clamps an exceeded window at 0%', async () => {
    expect(formatUsage([{ kind: 'five_hour', percentUsed: 104 }])).toBe('session 0% remaining')
  })

  test('clears the status off a subscription', async () => {
    expect(formatUsage([])).toBeUndefined()
    expect(formatUsage([{ kind: 'spend_limit', percentUsed: 50 }])).toBeUndefined()
  })
})
