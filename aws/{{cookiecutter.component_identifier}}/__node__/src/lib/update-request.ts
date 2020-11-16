import { CartUpdateAction, OrderUpdateAction } from '@commercetools/platform-sdk'

type UpdateAction = OrderUpdateAction | CartUpdateAction | undefined

export type UpdateRequest<T extends UpdateAction> = { responseType: string; actions: T[] }

export const createUpdateRequest = <T extends UpdateAction>(...actions: T[]): UpdateRequest<T> => ({
  responseType: 'UpdateRequest',
  actions: actions.filter(Boolean),
})

export const onlyIf = <T>(check: any, i: T) => (Boolean(check) ? i : undefined)
