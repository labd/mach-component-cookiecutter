import chalk from 'chalk'
import Koa from 'koa'

let defaultOptions = {
  dateFormat(date: number) {
    return new Date(date).toISOString()
  },

  color(status: number) {
    if (status < 400) {
      return 'green'
    } else if (status < 500) {
      return 'yellow'
    }
    return 'red'
  },

  async fillInfo(ctx: Koa.Context) {
    ctx.__logInfo = ctx.state.__logInfo = {}
  },

  async fillError(ctx: Koa.Context) {
    ctx.__infoError = ctx.state.__infoError = Object.assign({}, ctx.__logInfo, {
      query: ctx.request.query,
      method: ctx.request.method,
      url: ctx.request.url,
      DeviceId: ctx.request.get('DeviceId'),
      path: ctx.request.path,
      ip: ctx.request.ip,
      host: ctx.request.host,
      protocol: ctx.request.protocol,
    })
  },

  onStartFormat(ctx: Koa.Context) {
    const start = ctx.__logger.start
    return `--> ${chalk.blue(this.dateFormat(start))} - ${chalk.bold(ctx.method)} ${chalk.blue.bold(
      ctx.url
    )}`
  },

  async onStart(ctx: Koa.Context) {
    const info = Object.assign({}, ctx.__logInfo, { logType: 'routeStart' })
    this.logger.info(this.onStartFormat(ctx), info)
  },

  onErrorFormat(ctx: Koa.Context) {
    return `${chalk.red('[ERROR]')} ${chalk.red.bold(ctx.method)} ${ctx.url}`
  },

  async onError(ctx: Koa.Context, err: Error) {
    // @ts-ignore
    err.expose = process.env.NODE_ENV !== 'production'

    const info = Object.assign({}, ctx.state.__infoError, {
      error: err,
      logType: 'routeError',
    })
    this.logger.error(this.onErrorFormat(ctx), info)

    throw err
  },

  onEndFormat(ctx: Koa.Context, timeTaken: number) {
    const status = ctx.__logger.status
    const fColor = chalk[this.color(status)]
    const now = this.dateFormat(new Date().getTime())

    return `<-- ${fColor(now)} - ${fColor.bold(status)} ${chalk.bold(ctx.method)} ${
      ctx.url
    } - ${fColor(timeTaken + ' ms')}`
  },

  async onEnd(ctx: Koa.Context) {
    const timeTaken = Date.now() - ctx.__logger.start
    const info = Object.assign({}, ctx.__logInfo, { logType: 'routeEnd' })
    this.logger.info(this.onEndFormat(ctx, timeTaken), info)
  },

  logger: console, // eslint-disable-line
}

export default (options = {}) => {
  const opt = Object.assign({}, defaultOptions, options)
  const logger = async (ctx: Koa.Context, next: Koa.Next) => {
    ctx.__logger = { status: 500, start: Date.now() }
    try {
      await opt.fillInfo(ctx)
      await opt.fillError(ctx)
      await opt.onStart(ctx)
      await next()
      ctx.__logger.status = ctx.status
    } catch (err) {
      await opt.onError(ctx, err)
    } finally {
      await opt.onEnd(ctx)
    }
  }
  return logger
}
