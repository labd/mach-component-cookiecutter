import { Context } from 'aws-lambda'
import { ExtensionInput, MessageDelivery } from '@commercetools/platform-sdk'
import { exampleCartAction } from './action/cart'
import { createUpdateRequest } from './update-request'

/**
 * Checks if the input is correct and returns and returns a Commercetools request if so.
 *
 * Throws otherwise.
 */
export const extensionHandler = async ({ action, resource }: ExtensionInput, _context?: Context) => {
  if (action === 'Create' && resource.typeId === 'cart' && resource.obj) {
    return createUpdateRequest(exampleCartAction())
  }

  throw new Error(`Unsupported action: ${action}, Unsupported resource typeid: ${resource.typeId}`)
}


export const subscriptionHandler = async (msg: MessageDelivery, _context?: Context) => {
  // Implement
}
