import type { SessionRateLimit } from 'claude-code'

const LABELS: Record<string, string> = {
  five_hour: 'session',
  seven_day: 'week',
}

// Below this much remaining in any window, the line turns yellow.
export const LOW_PERCENT = 10

export type UsageLine = { text: string; isLow: boolean }

const remaining = (limit: SessionRateLimit) =>
  Math.max(0, Math.round(100 - limit.percentUsed))

// { text: "Claude Usage Remaining: session 77% · week 58%", isLow }, or undefined when no
// window has a reading.
export const formatUsage = (
  limits: readonly SessionRateLimit[],
): UsageLine | undefined => {
  const left = Object.entries(LABELS).flatMap(([kind, label]) => {
    const limit = limits.find(l => l.kind === kind)
    return limit ? [{ label, percent: remaining(limit) }] : []
  })

  if (left.length === 0) {
    return undefined
  }

  return {
    text: `Claude Usage Remaining: ${left.map(l => `${l.label} ${l.percent}%`).join(' · ')}`,
    isLow: left.some(l => l.percent < LOW_PERCENT),
  }
}
