import serverless from 'serverless-http'
import app from './app'
import assert from 'assert'
import AWSLambda from 'lib/sentry'

assert(process.env.CT_PROJECT_KEY)
assert(process.env.CT_API_URL)
assert(process.env.CT_AUTH_URL)
assert(process.env.CT_CLIENT_ID)
assert(process.env.CT_CLIENT_SECRET)
assert(process.env.CT_SCOPES)
assert(process.env.BUCKAROO_SITE_KEY)
assert(process.env.BUCKAROO_SITE_SECRET_SECRET_NAME)
assert(process.env.BUCKAROO_API_URL)
assert(process.env.AWS_REGION)
assert(process.env.SQS_QUEUE_URL)
assert(process.env.COMPONENT_NAME)
assert(process.env.PRIVATE_API_URL)

const restHandler = serverless(app)

export const handler = AWSLambda.wrapHandler(restHandler)
