import { Cart } from '@commercetools/platform-sdk'
import { extensionHandler } from '../src/lib/handler'

describe('extensionHandler', () => {
  test('Return a result for cart create events', async () => {
    expect(
      extensionHandler({ action: 'Create', resource: { id: '1', typeId: 'cart', obj: {} as Cart } })
    ).resolves.toBeTruthy()
  })
})
