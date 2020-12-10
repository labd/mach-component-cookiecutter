import { apiRootServer } from 'lib/commercetools/client'
import assert from 'assert'

const projectKey = process.env.CT_PROJECT_KEY
assert(projectKey)

const orders = {
  getOrderByOrderNumber: async ({ orderNumber }: { orderNumber: string }) => {
    return apiRootServer
      .withProjectKey({ projectKey })
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
