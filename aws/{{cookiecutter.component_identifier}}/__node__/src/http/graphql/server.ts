import { resolvers } from './resolvers'
import { typeDefs } from './typedefs'
import { ApolloServer, makeExecutableSchema } from 'apollo-server-koa'
import { transformSchemaFederation } from 'graphql-transform-federation'

export type Context = {
  customerIP: string
  headers: {
    [key: string]: string
  }
}

const schema = transformSchemaFederation(
  makeExecutableSchema({
    typeDefs,
    resolvers,
  }),
  { Query: { extend: true } }
)

export const server = new ApolloServer({
  subscriptions: false,
  schema,
  context: ({ ctx }): Context => {
    return {
      customerIP: ctx.ip,
      headers: ctx.header,
    }
  },
})
