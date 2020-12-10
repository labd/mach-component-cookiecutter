import AWS from 'aws-sdk'
import SQS from 'aws-sdk/clients/sqs'

const sqs = new SQS({
  region: process.env.AWS_REGION,
  apiVersion: '2012-11-05',
  endpoint: process.env.LOCALSTACK_URL ? new AWS.Endpoint(process.env.LOCALSTACK_URL) : undefined,
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

    console.info('--------')
    console.info('messageId:', data.MessageId)
    console.info('data:', resp.data)
    if (resp.error) console.info('error:', resp.error)
    console.info('********')
  } catch (error) {
    console.error(JSON.stringify(error))
  }
}
