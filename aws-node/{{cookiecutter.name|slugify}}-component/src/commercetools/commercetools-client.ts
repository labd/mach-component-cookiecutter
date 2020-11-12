import { createAuthMiddlewareForClientCredentialsFlow } from '@commercetools/sdk-middleware-auth'
import { createHttpMiddleware } from '@commercetools/sdk-middleware-http'
import { createClient } from '@commercetools/sdk-client'
import fetch from 'node-fetch'
import { createApiBuilderFromCtpClient } from '@commercetools/platform-sdk'

export const projectKey = process.env.CT_PROJECT_KEY

const authMiddleware = createAuthMiddlewareForClientCredentialsFlow({
  host: process.env.CT_AUTH_URL,
  projectKey,
  credentials: {
    clientId: process.env.CT_CLIENT_ID,
    clientSecret: process.env.CT_CLIENT_SECRET,
  },
  fetch,
})

const httpMiddleware = createHttpMiddleware({
  host: process.env.CT_API_URL,
  fetch,
})

const ctpClient = createClient({
  middlewares: [authMiddleware, httpMiddleware],
})

export const apiRoot = createApiBuilderFromCtpClient(ctpClient)
