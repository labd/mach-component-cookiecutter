import { CartUpdateAction } from "@commercetools/platform-sdk";

export const setDefaultShippingMethodAction = (): CartUpdateAction => ({
  action: "setShippingMethod",
  shippingMethod: {
    typeId: "shipping-method",
    key: process.env.DEFAULT_SHIPPING_METHOD_KEY || "default-shipping",
  },
});
