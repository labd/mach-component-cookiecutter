import { orderHandle } from './orders'
import { ctNock, ctAuthNock } from '../../tests/fixtures/commercetools'
import * as orderDetail from '../../tests/files/order-detail.json'

describe('orders handler', () => {
  test('handles a order update/create', async () => {
    ctAuthNock()
    const getOrderNock = ctNock()
      .filteringRequestBody(() => '*')
      .get(`/nl-unittest/orders/${orderDetail.id}`)
      .reply(200, orderDetail)

    const message = {
      notificationType: 'ResourceUpdated',
      projectKey: 'my-project',
      resource: {
        typeId: 'order',
        id: orderDetail.id,
      },
    }

    // @ts-ignore
    const resp = await orderHandle(message)
    expect(resp).toEqual({
      status: 'ok',
    })

    expect(getOrderNock.done())
  })
})
