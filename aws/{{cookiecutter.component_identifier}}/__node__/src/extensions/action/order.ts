import { OrderUpdateAction } from '@commercetools/platform-sdk'
import ctActions from '../../lib/commercetools/commercetools-actions'

export const setOrderNumberAction = (orderNumber: number): OrderUpdateAction => ({
  action: 'setOrderNumber',
  orderNumber: `${process.env.ORDER_PREFIX ?? ''}${orderNumber}`,
})

const initialOrderNumber = Number(process.env.INITIAL_ORDER_NUMBER ?? 0)

/**
 * Returns an unique order number using CommerceTools custom objects.
 *
 * We use a custom object to store the current value and increment it for
 * every call. If a conflict occurs (race condition) then we retry it with
 * a max of 20 times. (this number is arbitrary).
 */
export const generateOrderNumber = async () => {
  const maxTries = 20

  for (let i = 0; i < maxTries; i++) {
    try {
      const { version, value: currentValue } = await ctActions.customObjects
        .getOrderNumber()
        .catch(() => ({
          version: undefined,
          value: initialOrderNumber,
        }))

      const { value: orderNumber } = await ctActions.customObjects.increaseOrderNumber(
        currentValue,
        version
      )

      return orderNumber
    } catch (e) {
      console.error(e?.message)
    }
  }
  throw new Error(`Could not get order number in ${maxTries} tries`)
}