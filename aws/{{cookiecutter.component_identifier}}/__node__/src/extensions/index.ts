/**
 * The entry point for Lambda.
 */
import { inputHandler } from 'extensions/handler'
import Sentry from 'lib/sentry'

export const handler = Sentry.wrapHandler(inputHandler)
