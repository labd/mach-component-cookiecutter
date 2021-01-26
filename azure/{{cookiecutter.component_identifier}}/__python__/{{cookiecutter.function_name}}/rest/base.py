import logging
import os

from flask import Flask, abort, request
from flask_cors import CORS
from flask_restx import Api
from werkzeug.middleware.dispatcher import DispatcherMiddleware

logger = logging.getLogger(__name__)
env = os.environ.get
app = Flask(__name__)

CORS(app)

api = Api(app)
ns = api.namespace("{{ cookiecutter.function_name }}", description="REST operations")

# Just listen to all the possible paths (easier local debugging).
# On Azure it will run behind Frontdoor, which will be /{{ cookiecutter.name }}/{{ cookiecutter.function_name }}
application = DispatcherMiddleware(
    api.app, {"/{{ cookiecutter.name }}/{{ cookiecutter.function_name }}": api.app, "/{{ cookiecutter.function_name }}": api.app}
)


@app.before_request
def validate_frontdoor_header():
    """Validate requests originated from our Frontdoor instance."""
    if request.endpoint == "healthchecks":
        return

    if "X-Azure-FDID" not in request.headers:
        abort(403)

    if env("FRONTDOOR_ID") != request.headers["X-Azure-FDID"]:
        abort(403)
