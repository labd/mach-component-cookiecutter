import { Context } from '@azure/functions'
import * as orders from './handlers/orders'
import trigger from './index'

const log = jest.fn()

// @ts-ignore
const context = {
  log: log,
  invocationId: 'ID',
  done: () => {},
  res: null,
} as Context

describe('trigger', () => {
  test('can call the trigger', async () => {
    const spy = jest
      .spyOn(orders, 'orderHandle')
      .mockImplementation(async () => ({ status: 'ok' }))

    const request = {
      body: {
        id: '3c64afcc-4f57-461c-9366-71576b5e7f50-u4',
        source: '/my-project/orders',
        specversion: '1.0',
        type: 'com.commercetools.order.change.ResourceUpdated',
        subject: '3c64afcc-4f57-461c-9366-71576b5e7f50',
        time: '2021-02-04T18:17:49.057Z',
        data: {
          notificationType: 'ResourceUpdated',
          projectKey: 'my-project',
          resource: {
            typeId: 'order',
            id: '3c64afcc-4f57-461c-9366-71576b5e7f50',
          },
          resourceUserProvidedIdentifiers: { key: 'USA-2002' },
          version: 4,
          oldVersion: 3,
          modifiedAt: '2021-02-04T18:17:49.057Z',
        },
      },
    }

    await trigger(context, request)
    expect(context.res?.body).toEqual({ status: 'ok' })
    expect(spy).toBeCalledWith({
      notificationType: 'ResourceUpdated',
      projectKey: 'my-project',
      resource: {
        typeId: 'order',
        id: '3c64afcc-4f57-461c-9366-71576b5e7f50',
      },
      resourceUserProvidedIdentifiers: { key: 'USA-2002' },
      version: 4,
      oldVersion: 3,
      modifiedAt: '2021-02-04T18:17:49.057Z',
    })
  })
})
