import AWS from 'aws-sdk'
import SQS from 'aws-sdk/clients/sqs'
import logger from 'lib/logging'

const sqs = new SQS({
  region: process.env.AWS_REGION,
  apiVersion: '2012-11-05',
  endpoint:
    process.env.NODE_ENV !== 'production' ? new AWS.Endpoint('http://localhost:4566') : undefined,
})

export const sendMessage = async (data: any) => {
  if (!process.env.SQS_QUEUE_URL) {
    throw Error('No SQS_QUEUE_URL defined')
  }

  const queue_url = process.env.SQS_QUEUE_URL

  var params = {
    DelaySeconds: 10,
    MessageAttributes: {},
    MessageBody: JSON.stringify(data),
    QueueUrl: queue_url,
  }

  try {
    const data = await sqs.sendMessage(params).promise()
    const resp = data.$response

    logger.info('--------')
    logger.info('messageId:', data.MessageId)
    logger.info('data:', resp.data)
    if (resp.error) logger.info('error:', resp.error)
    logger.info('********')
  } catch (error) {
    logger.error(JSON.stringify(error))
  }
}
