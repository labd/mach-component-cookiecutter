// import OrderCreatedModule from 'services/order/order-created'
import { sqsHandler } from './index'

jest.mock('./handlers.ts', () => ({
  handleOrderCreated: () => {},
}))

describe('handler', () => {
  test('is able to handle notifications about subscriptions', async () => {
    const message = {
      notificationType: 'ResourceCreated',
      projectKey: 'mach-test',
      resource: {
        typeId: 'subscription',
        id: '5e545180-63db-4558-98b2-71e11cfae150',
      },
      resourceUserProvidedIdentifiers: {
        key: 'mach-component-commercetools-subscriptions_ct_subscriptions',
      },
      version: 1,
      modifiedAt: '2020-12-14T08:47:42.381Z',
    }

    const res = await sqsHandler({ Records: [{ body: JSON.stringify(message) } as any] })
    expect(res).toEqual(undefined)
  })

  test('throws an error if it does not have a way to handle the message', async () => {
    const message = {
      notificationType: 'Message',
      resource: {
        typeId: 'TestType',
      },
    }
    expect(async () => {
      await sqsHandler({ Records: [{ body: JSON.stringify(message) } as any] })
    }).rejects.toThrow('no handlers for resource type TestType')
  })

  test('calls the proper sub-handler', async () => {
    const res = await sqsHandler({ Records: [{ body: JSON.stringify(exampleMessage) } as any] })
    expect(res).toEqual(undefined)
  })
})

const exampleMessage = {
  notificationType: 'Message',
  projectKey: 'mach-test',
  id: '4b5d3bb8-3b65-4c01-8108-db1b5f172eeb',
  version: 1,
  sequenceNumber: 1,
  resource: {
    typeId: 'order',
    id: 'b3aa2abe-f2dc-4363-9981-8c50ecbd3f26',
  },
  resourceVersion: 1,
  resourceUserProvidedIdentifiers: {
    orderNumber: '5000096',
  },
  type: 'OrderCreated',
  order: {
    type: 'Order',
    id: 'b3aa2abe-f2dc-4363-9981-8c50ecbd3f26',
    version: 1,
    lastMessageSequenceNumber: 1,
    createdAt: '2020-12-14T10:02:54.175Z',
    lastModifiedAt: '2020-12-14T10:02:54.175Z',
    lastModifiedBy: {
      clientId: '1qGcTSsoGLHvmiRUnMOut5__',
      isPlatformClient: false,
      anonymousId: '9b01b7bf-f2e3-413d-b317-eab2018e431d',
    },
    createdBy: {
      clientId: '1qGcTSsoGLHvmiRUnMOut5__',
      isPlatformClient: false,
      anonymousId: '9b01b7bf-f2e3-413d-b317-eab2018e431d',
    },
    orderNumber: '5000096',
    customerEmail: 'bramkaashoek@gmail.com',
    anonymousId: '9b01b7bf-f2e3-413d-b317-eab2018e431d',
    locale: 'nl-NL',
    totalPrice: {
      type: 'centPrecision',
      currencyCode: 'EUR',
      centAmount: 5716,
      fractionDigits: 2,
    },
    taxedPrice: {
      totalNet: {
        type: 'centPrecision',
        currencyCode: 'EUR',
        centAmount: 4724,
        fractionDigits: 2,
      },
      totalGross: {
        type: 'centPrecision',
        currencyCode: 'EUR',
        centAmount: 5716,
        fractionDigits: 2,
      },
      taxPortions: [
        {
          rate: 0.21,
          amount: {
            type: 'centPrecision',
            currencyCode: 'EUR',
            centAmount: 992,
            fractionDigits: 2,
          },
          name: '21% BTW',
        },
      ],
    },
    country: 'NL',
    orderState: 'Open',
    syncInfo: [],
    returnInfo: [],
    shippingInfo: {
      shippingMethodName: 'Standard shipping method',
      price: {
        type: 'centPrecision',
        currencyCode: 'EUR',
        centAmount: 5000,
        fractionDigits: 2,
      },
      shippingRate: {
        price: {
          type: 'centPrecision',
          currencyCode: 'EUR',
          centAmount: 5000,
          fractionDigits: 2,
        },
        freeAbove: {
          type: 'centPrecision',
          currencyCode: 'EUR',
          centAmount: 50000,
          fractionDigits: 2,
        },
        tiers: [],
      },
      taxRate: {
        name: '21% BTW',
        amount: 0.21,
        includedInPrice: true,
        country: 'NL',
        id: 'Z0wLUuYw',
        subRates: [],
      },
      taxCategory: {
        typeId: 'tax-category',
        id: 'ac8b6c6c-424f-4cbb-aec5-d3754fb8dd78',
      },
      deliveries: [],
      shippingMethod: {
        typeId: 'shipping-method',
        id: 'fdf53457-487f-4b0e-bfbb-3124e44686e7',
      },
      taxedPrice: {
        totalNet: {
          type: 'centPrecision',
          currencyCode: 'EUR',
          centAmount: 4132,
          fractionDigits: 2,
        },
        totalGross: {
          type: 'centPrecision',
          currencyCode: 'EUR',
          centAmount: 5000,
          fractionDigits: 2,
        },
      },
      shippingMethodState: 'MatchesCart',
    },
    taxMode: 'Platform',
    inventoryMode: 'ReserveOnOrder',
    taxRoundingMode: 'HalfEven',
    taxCalculationMode: 'LineItemLevel',
    origin: 'Customer',
    lineItems: [
      {
        id: '5d2da9a6-4ef5-4a59-bab2-270433139c8c',
        productId: '02e00188-0f19-4b43-9c35-55ae702fd1be',
        name: {
          'nl-NL': 'Some product',
          'en-GB': 'Some product',
        },
        productType: {
          typeId: 'product-type',
          id: '109caecb-abe6-4900-ab03-7af5af985ff3',
          version: 1,
        },
        variant: {
          id: 1,
          sku: '00000001',
          key: '00000001',
          prices: [
            {
              value: {
                type: 'centPrecision',
                currencyCode: 'EUR',
                centAmount: 895,
                fractionDigits: 2,
              },
              id: '36506ccc-e770-4937-a027-3e4ff0e7e70e',
              channel: {
                typeId: 'channel',
                id: 'd75c2a23-fb85-4916-bd9c-9862dca9138c',
              },
              discounted: {
                value: {
                  type: 'centPrecision',
                  currencyCode: 'EUR',
                  centAmount: 716,
                  fractionDigits: 2,
                },
                discount: {
                  typeId: 'product-discount',
                  id: '57b26c6e-ebea-4197-ac24-ed602d1a0c04',
                },
              },
            },
            {
              value: {
                type: 'centPrecision',
                currencyCode: 'EUR',
                centAmount: 895,
                fractionDigits: 2,
              },
              id: '4ff26188-cb30-44c8-8aec-46e909378056',
              channel: {
                typeId: 'channel',
                id: 'cf084626-613e-451a-971b-12cf68473ad2',
              },
              discounted: {
                value: {
                  type: 'centPrecision',
                  currencyCode: 'EUR',
                  centAmount: 716,
                  fractionDigits: 2,
                },
                discount: {
                  typeId: 'product-discount',
                  id: '57b26c6e-ebea-4197-ac24-ed602d1a0c04',
                },
              },
            },
            {
              value: {
                type: 'centPrecision',
                currencyCode: 'GBP',
                centAmount: 740,
                fractionDigits: 2,
              },
              id: '680e9511-64e1-417c-9154-4a7fdbf21750',
              channel: {
                typeId: 'channel',
                id: 'a085f4e3-bbb4-41b7-8cd7-1c66cd20af26',
              },
              discounted: {
                value: {
                  type: 'centPrecision',
                  currencyCode: 'GBP',
                  centAmount: 592,
                  fractionDigits: 2,
                },
                discount: {
                  typeId: 'product-discount',
                  id: '57b26c6e-ebea-4197-ac24-ed602d1a0c04',
                },
              },
            },
            {
              value: {
                type: 'centPrecision',
                currencyCode: 'EUR',
                centAmount: 895,
                fractionDigits: 2,
              },
              id: '025805e1-f71b-4353-9298-dcad0807a957',
              channel: {
                typeId: 'channel',
                id: '10ea8562-45c2-47f5-91d9-92cf968d92b4',
              },
              discounted: {
                value: {
                  type: 'centPrecision',
                  currencyCode: 'EUR',
                  centAmount: 716,
                  fractionDigits: 2,
                },
                discount: {
                  typeId: 'product-discount',
                  id: '57b26c6e-ebea-4197-ac24-ed602d1a0c04',
                },
              },
            },
            {
              value: {
                type: 'centPrecision',
                currencyCode: 'EUR',
                centAmount: 895,
                fractionDigits: 2,
              },
              id: 'a4e741c1-d41e-4868-bbc2-f7ee16a185df',
              channel: {
                typeId: 'channel',
                id: '8f813d70-9bf5-4420-8a8c-686026263126',
              },
              discounted: {
                value: {
                  type: 'centPrecision',
                  currencyCode: 'EUR',
                  centAmount: 716,
                  fractionDigits: 2,
                },
                discount: {
                  typeId: 'product-discount',
                  id: '57b26c6e-ebea-4197-ac24-ed602d1a0c04',
                },
              },
            },
          ],
          images: [],
          attributes: [],
          assets: [],
          availability: {
            channels: {
              'd75c2a23-fb85-4916-bd9c-9862dca9138c': {
                isOnStock: true,
                availableQuantity: 99904,
              },
            },
          },
        },
        price: {
          value: {
            type: 'centPrecision',
            currencyCode: 'EUR',
            centAmount: 895,
            fractionDigits: 2,
          },
          id: '36506ccc-e770-4937-a027-3e4ff0e7e70e',
          channel: {
            typeId: 'channel',
            id: 'd75c2a23-fb85-4916-bd9c-9862dca9138c',
          },
          discounted: {
            value: {
              type: 'centPrecision',
              currencyCode: 'EUR',
              centAmount: 716,
              fractionDigits: 2,
            },
            discount: {
              typeId: 'product-discount',
              id: '57b26c6e-ebea-4197-ac24-ed602d1a0c04',
            },
          },
        },
        quantity: 1,
        discountedPricePerQuantity: [],
        supplyChannel: {
          typeId: 'channel',
          id: 'd75c2a23-fb85-4916-bd9c-9862dca9138c',
        },
        distributionChannel: {
          typeId: 'channel',
          id: 'd75c2a23-fb85-4916-bd9c-9862dca9138c',
        },
        taxRate: {
          name: '21% BTW',
          amount: 0.21,
          includedInPrice: true,
          country: 'NL',
          id: 'Z0wLUuYw',
          subRates: [],
        },
        addedAt: '2020-12-14T10:02:11.686Z',
        lastModifiedAt: '2020-12-14T10:02:11.686Z',
        state: [
          {
            quantity: 1,
            state: {
              typeId: 'state',
              id: 'f1d9531d-41f0-46a7-82f2-c4b0748aa9f5',
            },
          },
        ],
        priceMode: 'Platform',
        totalPrice: {
          type: 'centPrecision',
          currencyCode: 'EUR',
          centAmount: 716,
          fractionDigits: 2,
        },
        taxedPrice: {
          totalNet: {
            type: 'centPrecision',
            currencyCode: 'EUR',
            centAmount: 592,
            fractionDigits: 2,
          },
          totalGross: {
            type: 'centPrecision',
            currencyCode: 'EUR',
            centAmount: 716,
            fractionDigits: 2,
          },
        },
        lineItemMode: 'Standard',
      },
    ],
    customLineItems: [],
    transactionFee: true,
    discountCodes: [],
    cart: {
      typeId: 'cart',
      id: '4f2a6203-678b-4170-a6d9-510332f8e556',
    },
    shippingAddress: {
      country: 'NL',
    },
    billingAddress: {
      firstName: 'John',
      lastName: 'Doe',
      streetName: '',
      streetNumber: '',
      postalCode: '',
      city: '',
      country: '',
      company: '',
      building: '',
      phone: '',
    },
    itemShippingAddresses: [],
    refusedGifts: [],
  },
  createdAt: '2020-12-14T10:02:54.978Z',
  lastModifiedAt: '2020-12-14T10:02:54.978Z',
}
