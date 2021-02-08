import {
  generateOrderNumber,
  setOrderNumberAction,
} from './order'
import ctActions from '../../lib/commercetools/commercetools-actions'
console.error = jest.fn() // remove the console logs for mocked failing commercetools requests

afterEach(() => {
  jest.resetAllMocks()
})

describe('setOrderNumberAction', () => {
  test('Return correct json format.', () => {
    expect(setOrderNumberAction(1)).toMatchObject({
      action: 'setOrderNumber',
      orderNumber: `unittest-1`,
    })
  })
})

describe('generateOrderNumber', () => {
  test('Order create sets order number.', async () => {
    for (let value = 0; value < 3; value++) {
      jest.spyOn(ctActions.customObjects, 'getOrderNumber').mockResolvedValue({ version: 1, value })
      jest
        .spyOn(ctActions.customObjects, 'increaseOrderNumber')
        .mockImplementation(async (v) => ({ version: 1, value: v + 1 }))

      const orderNumber = await generateOrderNumber()

      expect(orderNumber).toBe(value + 1)
    }
  })

  test('Initiate an order number with 2_000_001 if getOrderNumber throws an error. ', async () => {
    jest.spyOn(ctActions.customObjects, 'getOrderNumber').mockRejectedValue(new Error())
    jest
      .spyOn(ctActions.customObjects, 'increaseOrderNumber')
      .mockImplementation(async (v) => ({ version: 1, value: v + 1 }))

    const orderNumber = await generateOrderNumber()

    expect(orderNumber).toBe(2_000_001)
  })

  test('Try again if CT api call fails.', async () => {
    jest
      .spyOn(ctActions.customObjects, 'getOrderNumber')
      .mockResolvedValue({ version: 1, value: 1 })
    const mockError = jest
      .spyOn(ctActions.customObjects, 'increaseOrderNumber')
      .mockRejectedValueOnce(new Error())
    const mockResolved = jest
      .spyOn(ctActions.customObjects, 'increaseOrderNumber')
      .mockImplementation(async (v) => ({ version: 1, value: v + 1 }))

    const orderNumber = await generateOrderNumber()

    expect(mockError).toBeCalled()
    expect(mockResolved).toBeCalled()
    expect(orderNumber).toBe(2)
  })

  test('Try at most 20 times to update the order number.', async () => {
    jest.spyOn(ctActions.customObjects, 'getOrderNumber').mockRejectedValue(new Error())
    const mock = jest
      .spyOn(ctActions.customObjects, 'increaseOrderNumber')
      .mockRejectedValue(new Error())

    await expect(() => generateOrderNumber()).rejects.toBeInstanceOf(Error)

    expect(mock).toBeCalledTimes(20)
  })
})
