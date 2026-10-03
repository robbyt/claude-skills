import type { SessionContextUsage, SessionRateLimit } from 'claude-code'

const LABELS: Record<string, string> = {
  five_hour: 'session',
  seven_day: 'week',
}

// Below this much remaining, the line turns yellow: a rate-limit window, or
// the context window (higher, since auto-compact fires before it is full).
export const LOW_LIMIT_PERCENT = 10
export const LOW_CONTEXT_PERCENT = 15

export type UsageLine = { text: string; isLow: boolean }

type Remaining = { label: string; percent: number; low: number }

const left = (percentUsed: number) =>
  Math.max(0, Math.round(100 - percentUsed))

// { text: "Claude Usage Remaining: session 77% · week 58% · context 63%", isLow },
// or undefined when nothing has a reading yet.
export const formatUsage = (
  limits: readonly SessionRateLimit[],
  context?: SessionContextUsage,
): UsageLine | undefined => {
  const parts: Remaining[] = Object.entries(LABELS).flatMap(([kind, label]) => {
    const limit = limits.find(l => l.kind === kind)
    return limit
      ? [{ label, percent: left(limit.percentUsed), low: LOW_LIMIT_PERCENT }]
      : []
  })

  if (context?.percent !== undefined) {
    parts.push({ label: 'context', percent: left(context.percent), low: LOW_CONTEXT_PERCENT })
  }

  if (parts.length === 0) {
    return undefined
  }

  return {
    text: `Claude Usage Remaining: ${parts.map(p => `${p.label} ${p.percent}%`).join(' · ')}`,
    isLow: parts.some(p => p.percent < p.low),
  }
}
