import router from 'koa-joi-router'
import { healthCheckValidator, healthcheck } from './healthcheck'

const privateRouter = router()

privateRouter.route({
  method: 'get',
  path: `/${process.env.COMPONENT_NAME}/healthcheck`,
  validate: healthCheckValidator,
  handler: healthcheck,
})

export default privateRouter
