import { gql } from 'apollo-server-koa'

export const typeDefs = gql`
  type Query {
    _empty: String
  }

  type SampleResult {
    result: String!
  }

  type Mutation {
    sample(body: String!): SampleResult!
  }
`
