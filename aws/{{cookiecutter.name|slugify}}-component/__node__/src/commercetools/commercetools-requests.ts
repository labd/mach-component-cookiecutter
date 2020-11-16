/**
 * Please write a function for each Commercetools api call,
 * so these can be mocked in the unit tests.
 */
import { projectKey, apiRoot } from './commercetools-client'

export const getCartExample = () =>
  apiRoot
    .withProjectKey({ projectKey })
    .carts()
    .get({ queryArgs: { limit: 1 } })
    .execute()
    .then((r) => r.body)
