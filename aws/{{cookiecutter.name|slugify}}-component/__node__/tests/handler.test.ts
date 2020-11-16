import { Cart } from '@commercetools/platform-sdk'
import { inputHandler } from '../src/lib/handler'

describe('inputHandler', () => {
  test('Return a result for cart create events', async () => {
    expect(
      inputHandler({ action: 'Create', resource: { id: '1', typeId: 'cart', obj: {} as Cart } })
    ).resolves.toBeTruthy()
  })
})
