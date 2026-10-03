import { describe, expect, test } from 'claude-code/testing'

import { formatUsage } from '../hooks/format'

describe('formatUsage', () => {
  test('shows session and week remaining', async () => {
    const usage = formatUsage([
      { kind: 'seven_day', percentUsed: 42.4 },
      { kind: 'five_hour', percentUsed: 23.5 },
    ])
    expect(usage).toEqual({ text: 'Claude Usage Remaining: session 77% · week 58%', isLow: false })
  })

  test('shows only the windows that have a reading', async () => {
    expect(formatUsage([{ kind: 'seven_day', percentUsed: 10 }])?.text).toBe('Claude Usage Remaining: week 90%')
  })

  test('is low when any window is under 10% remaining', async () => {
    expect(formatUsage([{ kind: 'five_hour', percentUsed: 50 }, { kind: 'seven_day', percentUsed: 91 }])?.isLow).toBe(true)
    expect(formatUsage([{ kind: 'five_hour', percentUsed: 90 }])?.isLow).toBe(false)
  })

  test('clamps an exceeded window at 0%', async () => {
    expect(formatUsage([{ kind: 'five_hour', percentUsed: 104 }])).toEqual({ text: 'Claude Usage Remaining: session 0%', isLow: true })
  })

  test('draws nothing off a subscription', async () => {
    expect(formatUsage([])).toBeUndefined()
    expect(formatUsage([{ kind: 'spend_limit', percentUsed: 50 }])).toBeUndefined()
  })
})
