import assert from 'assert';
import fetch from 'node-fetch';

import { ByProjectKeyRequestBuilder } from '@commercetools/platform-sdk/dist/generated/client/by-project-key-request-builder';
import { createApiBuilderFromCtpClient } from '@commercetools/platform-sdk';
import { createClient } from '@commercetools/sdk-client';
import { createHttpMiddleware } from '@commercetools/sdk-middleware-http';
import {
  createAuthMiddlewareWithExistingToken,
  createAuthMiddlewareForClientCredentialsFlow,
} from '@commercetools/sdk-middleware-auth'
import { getSecret } from 'lib/secrets';

const projectKey = process.env.CT_PROJECT_KEY
assert(process.env.CT_API_URL, 'CT_API_URL missing')
assert(projectKey)

const getAccessToken = async () => {
  /**
   * Retrieve commercetools access token from the AWS Secrets Manager.
   * This token is auto-rotated the by the commercetools token refresher component:
   * https://github.com/labd/mach-component-aws-commercetools-token-refresher
   */
  assert(process.env.CT_ACCESS_TOKEN_SECRET_NAME, 'CT_ACCESS_TOKEN_SECRET_NAME missing')
  try {
    const accessToken = await getSecret(process.env.CT_ACCESS_TOKEN_SECRET_NAME)
    return JSON.parse(accessToken).access_token
  } catch (err) {
    console.error(err)
    throw new Error(
      `Could not create commercetools client because access token could not be retreived`
    )
  }
}

const getAuthMiddleware = async () => {
  if (process.env.CT_CLIENT_ID && process.env.CT_CLIENT_SECRET && process.env.CT_SCOPES) {
    {% if cookiecutter.use_commercetools_token_rotator|int -%}
    console.warn("CT_CLIENT_ID and CT_CLIENT_SECRET for local dev only; make sure this is not used in production")
    {% endif %}
    assert(process.env.CT_AUTH_URL, 'CT_AUTH_URL missing')
    return createAuthMiddlewareForClientCredentialsFlow({
      host: process.env.CT_AUTH_URL,
      projectKey: projectKey,
      credentials: {
        clientId: process.env.CT_CLIENT_ID,
        clientSecret: process.env.CT_CLIENT_SECRET,
      },
      scopes: process.env.CT_SCOPES.split(','),
      fetch,
    })
  }

  const token = await getAccessToken()
  return createAuthMiddlewareWithExistingToken(`Bearer ${token}`, {
    force: true,
  })
}

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

export const getApiRoot = async (): Promise<ByProjectKeyRequestBuilder> => {
  const authMiddleware = await getAuthMiddleware()
  const server = await createClient({
    middlewares: [authMiddleware, httpMiddleware],
  })
  /**
   * Create commercetools API request builder configured for the project configured with the 
   * CT_PROJECT_KEY environment variable.
   */
  return createApiBuilderFromCtpClient(server).withProjectKey({ projectKey })
}

export const getApiRootForCustomer = (authorization: string): ByProjectKeyRequestBuilder => {
  /**
   * Create commercetools API request builder configured for the me-endpoints for the project configured with the
   * CT_PROJECT_KEY environment variable.
   */
  const customerAuthMiddleware = createAuthMiddlewareWithExistingToken(authorization)
  const client = createClient({ middlewares: [customerAuthMiddleware, httpMiddleware] })
  return createApiBuilderFromCtpClient(client).withProjectKey({ projectKey })
}