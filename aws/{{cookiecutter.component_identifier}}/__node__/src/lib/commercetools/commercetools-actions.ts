/**
 * Please write a function for each Commercetools api call,
 * so these can be mocked in the unit tests.
 */
import { getApiRoot } from './commercetools-client'

const ORDER_CONTAINER = 'order-numbers'
const ORDER_KEY = 'order-number'
type OrderNumber = { version?: number; value: number }

const customObjects = {
  getOrderNumber: async () => {
    const root = await getApiRoot()
    return root
      .customObjects()
      .withContainerAndKey({ container: ORDER_CONTAINER, key: ORDER_KEY })
      .get()
      .execute()
      .then<OrderNumber>((res) => res.body)
  },
  increaseOrderNumber: async (currentValue: number, version?: number) => {
    const root = await getApiRoot()
    return root
      .customObjects()
      .post({ body: { container: ORDER_CONTAINER, key: ORDER_KEY, value: (currentValue ?? 0) + 1, version } })
      .execute()
      .then<OrderNumber>((res) => res.body)
  },
}

export default { customObjects }
