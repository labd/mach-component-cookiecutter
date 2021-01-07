import { Message } from '@commercetools/platform-sdk'
import { Sentry } from 'lib/sentry'
import { SQSEvent, SQSRecord } from 'aws-lambda'
import { handleOrderCreated } from './handlers'

const handlers = {
  order: {
    OrderCreated: handleOrderCreated,
  },
}

export const sqsHandler = async ({ Records }: SQSEvent) => {
  if (!Records) throw Error('No Records found')
  
  const promises = Records.map((record) => handleRecord(record))
  await Promise.all(promises)
}

const handleRecord = async (record: SQSRecord) => {
  console.info('subscription received: ', record.body)

  const notificationOfUnknownType = JSON.parse(record.body)
  if (notificationOfUnknownType.notificationType !== 'Message') {
    return
  }
  const message: Message = notificationOfUnknownType

  const resource = message.resource.typeId
  if (!(resource in handlers)) {
    throw new Error(`no handlers for resource type ${message.resource.typeId}`)
  }

  const notificationType = message.type
  // @ts-ignore
  const resourceHandlers = handlers[resource]

  if (!(notificationType in resourceHandlers)) {
    throw new Error(`no handlers for message type ${message.type}`)
  }
  // @ts-ignore
  const typeHandler = resourceHandlers[notificationType]
  return typeHandler(message)
}

export const handler = Sentry.wrapHandler(sqsHandler)
