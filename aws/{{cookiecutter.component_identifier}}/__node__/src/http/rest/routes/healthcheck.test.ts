import request from 'supertest'
import app from '../app'

console.error = jest.fn()
console.info = jest.fn()

describe('Healthcheck endpoint', () => {
  test('if it works', async () => {
    const response = await request(app.callback())
      .get('/{{ cookiecutter.name|slugify }}/healthcheck')

    expect(response.status).toEqual(200)
  })
})
