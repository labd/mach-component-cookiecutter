import { createUpdateRequest, onlyIf } from '../src/lib/update-request'

test('Return correct json format.', () => {
  expect(createUpdateRequest()).toMatchObject({
    responseType: 'UpdateRequest',
    actions: [],
  })
})
