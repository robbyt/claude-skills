import { describe, expect, test } from 'claude-code/testing'

import { formatUsage } from '../hooks/format'

const WINDOW = 200000

describe('formatUsage', () => {
  test('shows session, week and context remaining', async () => {
    const usage = formatUsage(
      [
        { kind: 'seven_day', percentUsed: 42.4 },
        { kind: 'five_hour', percentUsed: 23.5 },
      ],
      { window: WINDOW, tokens: 74000, percent: 37 },
    )
    expect(usage).toEqual({
      text: 'Claude Usage Remaining: session 77% · week 58% · context 63%',
      isLow: false,
    })
  })

  test('shows only what has a reading', async () => {
    expect(formatUsage([{ kind: 'seven_day', percentUsed: 10 }], { window: WINDOW })?.text).toBe(
      'Claude Usage Remaining: week 90%',
    )
    expect(formatUsage([], { window: WINDOW, percent: 20 })?.text).toBe(
      'Claude Usage Remaining: context 80%',
    )
  })

  test('is low when a rate-limit window is under 10% remaining', async () => {
    expect(formatUsage([{ kind: 'five_hour', percentUsed: 50 }, { kind: 'seven_day', percentUsed: 91 }])?.isLow).toBe(true)
    expect(formatUsage([{ kind: 'five_hour', percentUsed: 90 }])?.isLow).toBe(false)
  })

  test('is low when the context is under 15% remaining', async () => {
    expect(formatUsage([], { window: WINDOW, percent: 86 })?.isLow).toBe(true)
    expect(formatUsage([], { window: WINDOW, percent: 85 })?.isLow).toBe(false)
  })

  test('clamps an exceeded window at 0%', async () => {
    expect(formatUsage([{ kind: 'five_hour', percentUsed: 104 }])).toEqual({
      text: 'Claude Usage Remaining: session 0%',
      isLow: true,
    })
  })

  test('draws nothing before any reading', async () => {
    expect(formatUsage([])).toBeUndefined()
    expect(formatUsage([{ kind: 'spend_limit', percentUsed: 50 }], { window: WINDOW })).toBeUndefined()
  })
})
