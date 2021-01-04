import { getApiRoot } from 'lib/commercetools/client'

const orders = {
  getOrderByOrderNumber: async ({ orderNumber }: { orderNumber: string }) => {
    const root = await getApiRoot()
    return root
      .orders()
      .withOrderNumber({ orderNumber })
      .get()
      .execute()
      .then((res) => res.body)
  },
}

export default {
  orders,
}
