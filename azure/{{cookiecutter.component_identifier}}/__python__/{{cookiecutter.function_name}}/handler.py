import azure.functions as func

try:
    from azure.functions import AsgiMiddleware
except ImportError:
    from _future.azure.functions._http_asgi import AsgiMiddleware

from shared.sentry import init_sentry

from .rest import app


# This signature is type checked by Azure, so don't mess with it.
def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    if req.url.strip("/").endswith("healthchecks"):
        enable_tracing = False
    else:
        enable_tracing = True

    init_sentry(
        enable_tracing=enable_tracing,
    )
    return AsgiMiddleware(app).handle(req, context)
