import { ExtensionInput, UpdateAction } from "@commercetools/platform-sdk";
import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import { setDefaultShippingMethodAction } from "./cart";
import { ExtensionError } from "./errors";

const httpTrigger: AzureFunction = async function (
  context: Context,
  req: HttpRequest
): Promise<void> {
  if (!req.body || !req.body.action || !req.body.resource) {
    context.res = {
      status: 400,
      body: "Invalid request",
    };
    return;
  }

  try {
    const result = await handle(req.body);
    context.res = {
      body: result,
    };
  } catch (err) {
    if (err instanceof ExtensionError) {
      context.res = {
        status: err.status,
        body: err.message,
      };
      context.log.error(err);
      return;
    }
    throw err;
  }
};

const handle = async ({ action, resource }: ExtensionInput) => {
  if (action !== "Create") {
    throw new ExtensionError(`Unsupported action '${action}'`);
  }

  if (!resource.obj) {
    throw new ExtensionError("No resource or resource object given");
  }

  console.info(`Receive ${action} action for a ${resource.typeId}`);

  if (resource.typeId === 'cart') {
    return createUpdateRequest(setDefaultShippingMethodAction());
  }

  throw new ExtensionError(`Unsupported resource typeId '${resource.typeId}'`);
};

const createUpdateRequest = (...actions: UpdateAction[]) => ({
  responseType: 'UpdateRequest',
  actions: actions,
});

export default httpTrigger;
