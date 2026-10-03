import type { Register } from 'claude-code'

import { formatUsage } from './format'

export const register: Register = on => {
  // Redraw the row whenever a rate-limit window or the context fill moves.
  on('session.measure', ($, e, next) => {
    if (e.changed.includes('rateLimits') || e.changed.includes('context')) {
      $.ui.invalidate('ui.render')
    }

    return next(e)
  })

  // Draw the usage as its own row under the engine's hint line.
  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    const hint = await next(e)
    const { rateLimits, context } = await $.session.usage()
    const usage = formatUsage(rateLimits, context)

    if (!usage) {
      return hint
    }

    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box flexDirection="column">
        {hint}
        <Text color={usage.isLow ? 'warning' : undefined}>{usage.text}</Text>
      </Box>
    )
  })
}
