import serverless from 'serverless-http'
import app from './app'
import { Sentry } from 'lib/sentry'

app.on('error', (err, ctx) => {
  console.error(err)

  Sentry.withScope(function (scope) {
    scope.addEventProcessor(function (event) {
      return Sentry.Handlers.parseRequest(event, ctx.request)
    })
    Sentry.captureException(err)
  })
})

const restHandler = serverless(app)
export const handler = restHandler
