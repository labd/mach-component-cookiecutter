/**
 * The entry point for Lambda.
 *
 * This file is ignored by the unit tests should not contain any code that needs unit testing.
 */
import { init, Integrations, AWSLambda } from '@sentry/serverless'
import { addExtensionMethods } from '@sentry/tracing'
import { inputHandler } from './lib/handler'

addExtensionMethods()

init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 1.0,
  enabled: process.env.NODE_ENV === 'production',
  environment: process.env.ENVIRONMENT,
  release: process.env.RELEASE,
  integrations: [new Integrations.Http({ tracing: true })],
})

export const handler = AWSLambda.wrapHandler(inputHandler)