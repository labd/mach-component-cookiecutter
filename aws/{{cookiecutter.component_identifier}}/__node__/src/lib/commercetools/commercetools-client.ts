import { ApiRoot, createApiBuilderFromCtpClient } from '@commercetools/platform-sdk'
import { createClient } from '@commercetools/sdk-client'
import {
  createAuthMiddlewareForClientCredentialsFlow,
  createAuthMiddlewareWithExistingToken,
} from '@commercetools/sdk-middleware-auth'
import { createHttpMiddleware } from '@commercetools/sdk-middleware-http'
import fetch from 'node-fetch'
import assert from 'assert'

assert(process.env.CT_SCOPES, 'CT_SCOPES missing')

const authMiddleware = createAuthMiddlewareForClientCredentialsFlow({
  host: process.env.CT_AUTH_URL,
  projectKey: process.env.CT_PROJECT_KEY,
  credentials: {
    clientId: process.env.CT_CLIENT_ID,
    clientSecret: process.env.CT_CLIENT_SECRET,
  },
  scopes: process.env.CT_SCOPES.split(','),
  fetch,
})

const httpMiddleware = createHttpMiddleware({
  host: process.env.CT_API_URL,
  enableRetry: true,
  retryConfig: {
    maxRetries: 2,
    retryDelay: 300,
    maxDelay: 5000,
  },
  fetch,
})

export const ctClientServer = createClient({
  middlewares: [authMiddleware, httpMiddleware],
})

export const ctClientCustomer = createClient({
  middlewares: [httpMiddleware],
})

export const apiRootServer: ApiRoot = createApiBuilderFromCtpClient(ctClientServer)

export const getApiRootForCustomer = (authorization: string): ApiRoot => {
  const customerAuthMiddleware = createAuthMiddlewareWithExistingToken(authorization)
  const client = createClient({ middlewares: [customerAuthMiddleware, httpMiddleware] })
  return createApiBuilderFromCtpClient(client)
}
