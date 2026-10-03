import type { Register } from 'claude-code'

import { formatUsage } from './format'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    const { rateLimits } = await $.session.usage()
    $.ui.status(formatUsage(rateLimits))

    return result
  })

  on('session.measure', ($, e, next) => {
    if (e.changed.includes('rateLimits')) {
      $.ui.status(formatUsage(e.rateLimits))
    }

    return next(e)
  })
}
