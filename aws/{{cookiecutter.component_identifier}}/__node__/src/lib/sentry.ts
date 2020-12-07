import { Integrations, AWSLambda } from '@sentry/serverless'
import { addExtensionMethods } from '@sentry/tracing'

addExtensionMethods()

AWSLambda.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 1.0,
  enabled: process.env.NODE_ENV === 'production',
  environment: process.env.ENVIRONMENT,
  release: process.env.RELEASE,
  integrations: [new Integrations.Http({ tracing: true })],
})

export default AWSLambda
