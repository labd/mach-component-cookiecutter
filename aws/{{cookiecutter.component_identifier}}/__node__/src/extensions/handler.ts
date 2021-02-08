import { ExtensionInput , OrderUpdateAction } from '@commercetools/platform-sdk'
import {
  setOrderNumberAction,
  generateOrderNumber,
} from './action/order'


type UpdateAction = OrderUpdateAction

export type UpdateRequest<T extends UpdateAction> = { responseType: string; actions: T[] }
/**
 * Checks if the input is correct and returns and returns a Commercetools request if so.
 *
 * Throws otherwise.
 */
export const inputHandler = async ({ action, resource }: ExtensionInput) => {
  // The lambda warmer invokes the action without any arguments. So let's not
  // throw an error but just return if action is missing
  if (!action) {
    return {}
  }

  console.info(`invoked for action ${action} on resource ${resource?.typeId}`)

  if (action !== 'Create') {
    throw new Error(`Unsupported action '${action}'`)
  }
  if (!resource || !resource.obj) {
    throw new Error(`No resource or resource object given`)
  }

  if (resource.typeId === 'order') {
    return createUpdateRequest(
      setOrderNumberAction(await generateOrderNumber()),
    )
  }

  throw new Error(`Unsupported resource typeId '${resource.typeId}'`)
}


const createUpdateRequest = <T extends UpdateAction>(...actions: T[]): UpdateRequest<T> => ({
  responseType: 'UpdateRequest',
  actions: actions,
})