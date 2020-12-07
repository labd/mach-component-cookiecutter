import Koa from 'koa'
import router from 'koa-joi-router'
const Joi = router.Joi

export const healthCheckValidator = {
  output: {
    200: {
      body: {
        ok: Joi.boolean().equal(true),
        version: Joi.string(),
      },
    },
  },
  failure: 400,
  continueOnError: false,
}

export const healthcheck = (ctx: Koa.Context, next: Koa.Next) => {
  ctx.status = 200

  ctx.body = {
    ok: true,
    version: process.env.NODE_ENV || 'development',
  }
}
