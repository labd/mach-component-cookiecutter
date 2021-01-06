import serverless from 'serverless-http'
import app from './app'

const restHandler = serverless(app)
export const handler = restHandler
