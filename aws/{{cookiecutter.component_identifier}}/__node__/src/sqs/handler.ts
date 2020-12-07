import AWSLambda from 'lib/sentry'
import { SQSEvent } from 'aws-lambda'

export const sqsHandler = async ({ Records }: SQSEvent) => {
  if (!Records) throw Error('No Records found')
}

export const handler = AWSLambda.wrapHandler(sqsHandler)
