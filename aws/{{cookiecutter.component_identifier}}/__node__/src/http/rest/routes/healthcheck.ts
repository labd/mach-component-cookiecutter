import Koa from 'koa'

export const healthcheck = (ctx: Koa.Context, next: Koa.Next) => {
  ctx.status = 200

  ctx.body = {
    ok: true,
    version: process.env.VERSION,
    environment: process.env.ENVIRONMENT || 'development',
  }
}
