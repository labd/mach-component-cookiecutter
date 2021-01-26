import pytest

@pytest.fixture
def order_create_data():
    return {
        "action": "Create",
        "resource": {
            "typeId": "order",
            "id": "22ce48b3-0156-47fc-b566-5dd513749e32",
            "obj": {
                "type": "Order",
                "id": "22ce48b3-0156-47fc-b566-5dd513749e32",
                "version": 1,
                "lastMessageSequenceNumber": 1,
                "createdAt": "2018-12-03T16:27:47.197Z",
                "lastModifiedAt": "2018-12-03T16:27:47.197Z",
                "lastModifiedBy": {"clientId": "jHLbJnEwycibBMB5SnxaYpAf"},
                "createdBy": {"clientId": "jHLbJnEwycibBMB5SnxaYpAf"},
                "customerEmail": "d.weterings@labdigital.nl",
                "anonymousId": "9338846",
                "locale": "en",
                "totalPrice": {
                    "type": "centPrecision",
                    "currencyCode": "GBP",
                    "centAmount": 12100,
                    "fractionDigits": 2,
                },
                "taxedPrice": {
                    "totalNet": {
                        "type": "centPrecision",
                        "currencyCode": "GBP",
                        "centAmount": 12100,
                        "fractionDigits": 2,
                    },
                    "totalGross": {
                        "type": "centPrecision",
                        "currencyCode": "GBP",
                        "centAmount": 12705,
                        "fractionDigits": 2,
                    },
                    "taxPortions": [
                        {
                            "rate": 0.05,
                            "amount": {
                                "type": "centPrecision",
                                "currencyCode": "GBP",
                                "centAmount": 605,
                                "fractionDigits": 2,
                            },
                            "name": "5% US",
                        }
                    ],
                },
                "country": "US",
                "orderState": "Open",
                "syncInfo": [],
                "returnInfo": [],
                "shippingInfo": {
                    "shippingMethodName": "DHL",
                    "price": {
                        "type": "centPrecision",
                        "currencyCode": "GBP",
                        "centAmount": 1000,
                        "fractionDigits": 2,
                    },
                    "shippingRate": {
                        "price": {
                            "type": "centPrecision",
                            "currencyCode": "GBP",
                            "centAmount": 1000,
                            "fractionDigits": 2,
                        },
                        "tiers": [],
                    },
                    "taxRate": {
                        "name": "5% US",
                        "amount": 0.05,
                        "includedInPrice": False,
                        "country": "US",
                        "state": "Tennessee",
                        "id": "6pzaYIlQ",
                        "subRates": [],
                    },
                    "taxCategory": {
                        "typeId": "tax-category",
                        "id": "b293d1c4-8623-4941-a9e5-2ab7e63bd056",
                    },
                    "deliveries": [],
                    "shippingMethod": {
                        "typeId": "shipping-method",
                        "id": "10c135bf-d00e-447a-84c0-f1ba1f438561",
                    },
                    "taxedPrice": {
                        "totalNet": {
                            "type": "centPrecision",
                            "currencyCode": "GBP",
                            "centAmount": 1000,
                            "fractionDigits": 2,
                        },
                        "totalGross": {
                            "type": "centPrecision",
                            "currencyCode": "GBP",
                            "centAmount": 1050,
                            "fractionDigits": 2,
                        },
                    },
                    "shippingMethodState": "MatchesCart",
                },
                "taxMode": "Platform",
                "inventoryMode": "TrackOnly",
                "taxRoundingMode": "HalfEven",
                "taxCalculationMode": "LineItemLevel",
                "origin": "Customer",
                "lineItems": [
                    {
                        "id": "423663ef-6abf-4a59-816f-f2a1d6540a6e",
                        "productId": "f8457f5f-b4a8-4b6c-a9b7-7f502307a959",
                        "name": {"en": "APPLE BLUEBERRY & YOGHURT JAR STAGE 2"},
                        "productType": {
                            "typeId": "product-type",
                            "id": "c5fab78f-f715-41a6-bd52-e65381a1723b",
                            "version": 10,
                        },
                        "productSlug": {"en": "apple-blueberry-yoghurt-jar-stage-2"},
                        "variant": {
                            "id": 1,
                            "sku": "851855622033274",
                            "prices": [
                                {
                                    "value": {
                                        "type": "centPrecision",
                                        "currencyCode": "GBP",
                                        "centAmount": 11100,
                                        "fractionDigits": 2,
                                    },
                                    "id": "25c3a500-6a8d-4dcd-a088-70bc0e2fdaaa",
                                },
                                {
                                    "value": {
                                        "type": "centPrecision",
                                        "currencyCode": "GBP",
                                        "centAmount": 1100,
                                        "fractionDigits": 2,
                                    },
                                    "id": "c7bd3a72-41f1-4d65-ad27-8816b67b7935",
                                    "country": "US",
                                    "channel": {
                                        "typeId": "channel",
                                        "id": "2e11c979-5b6b-4b5d-a3eb-b744816210bb",
                                    },
                                },
                            ],
                            "images": [],
                            "attributes": [
                                {"name": "brand", "value": "Cow & Gate"},
                            ],
                            "assets": [],
                            "availability": {
                                "channels": {
                                    "2e11c979-5b6b-4b5d-a3eb-b744816210bb": {
                                        "isOnStock": True,
                                        "availableQuantity": 1304,
                                    }
                                }
                            },
                        },
                        "price": {
                            "value": {
                                "type": "centPrecision",
                                "currencyCode": "GBP",
                                "centAmount": 11100,
                                "fractionDigits": 2,
                            },
                            "id": "25c3a500-6a8d-4dcd-a088-70bc0e2fdaaa",
                        },
                        "quantity": 1,
                        "discountedPricePerQuantity": [],
                        "supplyChannel": {
                            "typeId": "channel",
                            "id": "2e11c979-5b6b-4b5d-a3eb-b744816210bb",
                        },
                        "taxRate": {
                            "name": "5% US",
                            "amount": 0.05,
                            "includedInPrice": False,
                            "country": "US",
                            "state": "Tennessee",
                            "id": "6pzaYIlQ",
                            "subRates": [],
                        },
                        "state": [
                            {
                                "quantity": 1,
                                "state": {
                                    "typeId": "state",
                                    "id": "cb84e45d-1d15-4f9b-979d-0b3a95fa6229",
                                },
                            }
                        ],
                        "priceMode": "Platform",
                        "totalPrice": {
                            "type": "centPrecision",
                            "currencyCode": "GBP",
                            "centAmount": 11100,
                            "fractionDigits": 2,
                        },
                        "taxedPrice": {
                            "totalNet": {
                                "type": "centPrecision",
                                "currencyCode": "GBP",
                                "centAmount": 11100,
                                "fractionDigits": 2,
                            },
                            "totalGross": {
                                "type": "centPrecision",
                                "currencyCode": "GBP",
                                "centAmount": 11655,
                                "fractionDigits": 2,
                            },
                        },
                        "lineItemMode": "Standard",
                    }
                ],
                "customLineItems": [],
                "transactionFee": True,
                "discountCodes": [],
                "cart": {
                    "typeId": "cart",
                    "id": "f1ab0dbe-9390-4e38-b73b-fd914d250e67",
                },
                "custom": {
                    "type": {
                        "typeId": "type",
                        "id": "e633c4f3-3f95-49a6-9eac-330612ee17fb",
                    },
                    "fields": {},
                },
                "shippingAddress": {
                    "firstName": "Max",
                    "lastName": "Mustermann",
                    "streetName": "Aviation Way",
                    "streetNumber": "1026",
                    "postalCode": "37501",
                    "city": "MEMPHIS",
                    "state": "Tennessee",
                    "country": "US",
                },
                "itemShippingAddresses": [],
                "refusedGifts": [],
            },
        },
    }
