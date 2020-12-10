import { Integrations, AWSLambda } from '@sentry/serverless'
import { RewriteFrames, Transaction } from '@sentry/integrations'
import { addExtensionMethods } from '@sentry/tracing'

addExtensionMethods()

AWSLambda.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 1.0,
  enabled: process.env.SENTRY_DSN ? true : false,
  environment: process.env.ENVIRONMENT,
  release: process.env.RELEASE,
  integrations: [
    new Integrations.Console(),
    new RewriteFrames(),
    new Transaction(),
    new Integrations.Http({ tracing: true }),
  ],
})

AWSLambda.configureScope(function (scope) {
  scope.setTag('service_name', process.env.COMPONENT_NAME || '')
  scope.setTag('site', process.env.SITE || '')
})

export const Sentry = AWSLambda
