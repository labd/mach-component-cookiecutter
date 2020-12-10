import { SQSEvent } from 'aws-lambda'
import { Sentry } from 'lib/sentry'

export const sqsHandler = async ({ Records }: SQSEvent) => {
  if (!Records) throw Error('No Records found')
}
export const handler = Sentry.wrapHandler(sqsHandler)
