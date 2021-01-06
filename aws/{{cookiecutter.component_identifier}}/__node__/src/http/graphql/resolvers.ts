import { Context } from './server'

export const resolvers = {
  Mutation: {
    sample: async (
      _parent: undefined,
      { body }: { body: string },
      context: Context
    ) => {
      console.log(body)
      const result = "ok"
      return { result }
    },
  },
}
