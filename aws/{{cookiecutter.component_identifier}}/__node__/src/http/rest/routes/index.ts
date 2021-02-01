import Router from '@koa/router'
import { DefaultState, Context } from 'koa'
import { healthcheck } from './healthcheck'

const router = new Router<DefaultState, Context>({
  prefix: `/${process.env.COMPONENT_NAME}`,
})

router.get('/healthcheck', healthcheck)

export default router
