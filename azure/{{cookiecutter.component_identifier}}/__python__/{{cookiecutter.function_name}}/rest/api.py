import logging
import os

from commercetools import CommercetoolsError
from flask import Flask, abort, jsonify, request
from flask.json import JSONEncoder
from flask_cors import CORS
from flask_restx import Api, Resource
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


@app.route("/healthchecks")
def healthchecks() -> str:
    return jsonify({"status": "ok", "version": env("COMPONENT_VERSION")})


@api.errorhandler(CommercetoolsError)
def handle_ct_error(error: CommercetoolsError):
    app.logger.info("Handling CT error: %s", str(error))

    conf = errors.get_ct_error_config(error)
    if conf.propagate:
        app.logger.exception(str(error))

    msg = "There was a problem with commercetools"
    return (
        {"message": msg, "details": str(error), "code": conf.code},
        conf.status_code or error.response.status_code,
    )
