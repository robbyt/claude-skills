import type { Register } from 'claude-code'

import { formatUsage } from './format'

export const register: Register = on => {
  // Redraw the hint line whenever a rate-limit window moves a whole point.
  on('session.measure', ($, e, next) => {
    if (e.changed.includes('rateLimits')) {
      $.ui.invalidate('ui.render')
    }

    return next(e)
  })

  // Draw the usage as its own row under the engine's hint line.
  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    const hint = await next(e)
    const usage = formatUsage((await $.session.usage()).rateLimits)

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
