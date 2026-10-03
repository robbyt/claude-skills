import type { SessionRateLimit } from 'claude-code'

const LABELS: Record<string, string> = {
  five_hour: 'session',
  seven_day: 'week',
}

const remaining = (limit: SessionRateLimit) =>
  Math.max(0, Math.round(100 - limit.percentUsed))

// "session 77% · week 58% remaining", or undefined when no window has a reading.
export const formatUsage = (limits: readonly SessionRateLimit[]) => {
  const parts = Object.entries(LABELS).flatMap(([kind, label]) => {
    const limit = limits.find(l => l.kind === kind)
    return limit ? [`${label} ${remaining(limit)}%`] : []
  })

  return parts.length > 0
    ? `${parts.join(' · ')} remaining`
    : undefined
}
