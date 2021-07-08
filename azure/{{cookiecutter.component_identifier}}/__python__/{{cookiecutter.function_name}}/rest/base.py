import logging
import os

from fastapi import FastAPI
from fastapi.encoders import jsonable_encoder
from fastapi.middleware.cors import CORSMiddleware
from sentry_sdk.integrations.asgi import SentryAsgiMiddleware
from starlette import status
from starlette.responses import JSONResponse

from api.conf import URL_PREFIX

from .endpoints import router

__all__ = ["app"]

logger = logging.getLogger(__name__)
env = os.environ.get

fastapi_kwargs = {
    "title": "{{ cookiecutter.name }} API",
    "docs_url": f"{URL_PREFIX}/docs",
    "redoc_url": f"{URL_PREFIX}/redoc",
}

app = FastAPI(**fastapi_kwargs)

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("CORS_ALLOWED_ORIGINS", ["*"]),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.exception_handler(Exception)
async def http_exception_handler(request, exc):
    logger.exception(exc)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=jsonable_encoder(
            {
                "detail": {
                    "message": f"Invalid response from AIS: {exc}",
                    "code": exc.code,
                }
            }
        ),
    )


app = SentryAsgiMiddleware(app)


# @app.before_request
# def validate_frontdoor_header():
#     """Validate requests originated from our Frontdoor instance."""
#     frontdoor_id = env("FRONTDOOR_ID")

#     if not frontdoor_id or request.endpoint == "healthchecks":
#         return

#     if "X-Azure-FDID" not in request.headers:
#         abort(403)

#     if env("FRONTDOOR_ID") != request.headers["X-Azure-FDID"]:
#         abort(403)
