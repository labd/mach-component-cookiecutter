import Koa from 'koa'
import bodyParser from 'koa-bodyparser'
import cors from '@koa/cors';
import { addExtensionMethods } from '@sentry/tracing';
import router from './routes'
import logger from './middleware/logger-middleware'
import Sentry from '../../lib/sentry'

const app = new Koa()
app.use(logger())
app.use(cors())
app.use(bodyParser())

if (process.env.SENTRY_DSN) {
  addExtensionMethods()
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    tracesSampleRate: 1.0,
    enabled: true,
    release: process.env.RELEASE,
    environment: process.env.ENVIRONMENT,
    integrations: [new Sentry.Integrations.Http({ tracing: true })],
  })
  app.on('error', (err, ctx) => {
    Sentry.withScope(function (scope) {
      scope.addEventProcessor(function (event) {
        return Sentry.Handlers.parseRequest(event, ctx.request)
      })
      Sentry.captureException(err)
    })
  })
}

app.use(router.middleware())
export default app
