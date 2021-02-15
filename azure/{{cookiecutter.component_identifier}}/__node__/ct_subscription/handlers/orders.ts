import { Message } from '@commercetools/platform-sdk'
import { getApiRoot } from '../../shared/commercetools/client'

export const orderHandle = async function (message: Message) {
  const api = getApiRoot()
  const orderApi = await api.orders().withId({ ID: message.resource.id })
  const order = await orderApi
    .get()
    .execute()
    .then((res) => res.body)

  // Implement logic

  return {
    status: "ok"
  }
}
