import { Integrations, AWSLambda } from '@sentry/serverless'
import { RewriteFrames, Transaction, CaptureConsole } from '@sentry/integrations'

AWSLambda.init({
  dsn: process.env.SENTRY_DSN,
  enabled: !!process.env.SENTRY_DSN && process.env.NODE_ENV === 'production',
  release: process.env.RELEASE,
  environment: process.env.ENVIRONMENT,
  integrations: [
    new Integrations.Console(),
    new RewriteFrames(),
    new Transaction(),
    new Integrations.Http({ tracing: true }),
    new CaptureConsole({
      levels: ['warning', 'error'],
    }),
    new Integrations.OnUnhandledRejection(),
  ],
})

AWSLambda.configureScope(function (scope) {
  scope.setTag('service_name', process.env.COMPONENT_NAME || '')
  scope.setTag('site', process.env.SITE || '')
})

export default AWSLambda