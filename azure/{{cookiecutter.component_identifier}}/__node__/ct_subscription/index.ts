import { AzureFunction, Context, HttpRequest } from '@azure/functions'
import { Message } from '@commercetools/platform-sdk'
import { orderHandle } from './handlers/orders'
import intercept from '../shared/intercept'
import { Sentry } from '../shared/sentry'

const httpTrigger: AzureFunction = async function (
  context: Context,
  req: HttpRequest
): Promise<void> {
  if (req.method === 'OPTIONS') {
    context.res = {
      headers: {
        'Webhook-Allowed-Origin': 'eventgrid.azure.net',
      },
    }
    return
  }

  context.log('HTTP trigger function processed a request.')
  context.log(req.body)

  intercept(context)

  try {
    const result = await handle(req.body.data)
    context.res = {
      body: result,
    }
  } catch (err) {
    Sentry.captureException(err)
    await Sentry.flush(2000);
    throw err
  }
}

const handle = async function (message: Message) {
  if (message.resource.typeId === 'order') {
    return orderHandle(message)
  } 
  
  return { status: 'skipped' }
}

export default httpTrigger
