import { exampleCartAction } from '../../src/lib/action/cart'

describe('exampleCartAction', () => {
  test('Return correct json format.', () => {
    expect(exampleCartAction()).toMatchObject({
      action: 'exampleAction',
      examplePayload: 0,
    })
  })
})
