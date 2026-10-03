import type { On, SessionRateLimit } from 'claude-code'
import { expect, test } from 'claude-code/testing'
import type { TestBody } from 'claude-code/testing'

const USAGE = { type: 'Text', text: /^Claude Usage Remaining: / }
const ENGINE = { type: 'Text', text: '? for shortcuts' }
const SURFACES = ['terminal', 'desktop'] as const
const HINT = { isDraft: false, isWorking: false, hint: '? for shortcuts' }

// Stand in for the engine: report these windows, draw the hint line as text.
const engine = (on: On, rateLimits: SessionRateLimit[]) => {
  on('session.usage', () => ({
    value: { startedAt: 0, context: { window: 200000 }, rateLimits },
  }))
  on('ui.render', { component: 'PromptHint' }, ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>{e.props.hint}</Text>
  })
}

for (const surface of SURFACES) {
  const mount = ($: Parameters<TestBody>[0]) =>
    $.ui.mount({ plugin: 'usage-status', surface, component: 'PromptHint', props: HINT })

  test(`${surface}: plain usage after the engine's hint`, async ($, on) => {
    engine(on, [{ kind: 'five_hour', percentUsed: 6 }, { kind: 'seven_day', percentUsed: 24 }])
    const drawn = await mount($)
    const line = await drawn.find(USAGE)

    expect(line?.text).toBe('Claude Usage Remaining: session 94% · week 76%')
    expect(line?.props.color).toBeUndefined()
    expect((await drawn.find(ENGINE))?.text).toBe('? for shortcuts')
  })

  test(`${surface}: yellow under 10% remaining`, async ($, on) => {
    engine(on, [{ kind: 'five_hour', percentUsed: 95 }])
    const drawn = await mount($)

    expect((await drawn.find(USAGE))?.props.color).toBe('warning')
  })

  test(`${surface}: engine's hint alone off a subscription`, async ($, on) => {
    engine(on, [])
    const drawn = await mount($)

    expect(await drawn.find(USAGE)).toBeUndefined()
    expect((await drawn.find(ENGINE))?.text).toBe('? for shortcuts')
  })
}
