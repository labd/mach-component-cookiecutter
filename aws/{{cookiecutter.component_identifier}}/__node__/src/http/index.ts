import serverless from 'serverless-http'
import app from './rest/app'
{% if cookiecutter.include_graphql_server|int -%}
import { server } from './graphql/server'

// @ts-ignore: Combine GraphQL server with Koa routing
server.applyMiddleware({ app, path: `/${process.env.COMPONENT_NAME}/graphql` }){% endif %}

export const handler = serverless(app)
