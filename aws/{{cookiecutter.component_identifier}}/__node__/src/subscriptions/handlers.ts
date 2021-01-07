import { OrderCreatedMessage } from '@commercetools/platform-sdk'

export const handleOrderCreated = async (message: OrderCreatedMessage) => {
  const order = message.order
  // Implement logic
}

export default { handleOrderCreated }
