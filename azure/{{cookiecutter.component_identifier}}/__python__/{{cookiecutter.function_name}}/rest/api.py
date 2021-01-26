import os

from flask import jsonify
from flask_restx import Resource, reqparse

from .base import api, app, ns


@app.route("/healthchecks")
def healthchecks() -> str:
    return jsonify({"status": "ok", "version": os.environ.get("COMPONENT_VERSION")})


some_parser = reqparse.RequestParser()

some_parser.add_argument(
    "order_number", type=str, help="The commercetools order number", required=True
)
some_parser.add_argument(
    "message",
    type=str,
    help="Some message",
    required=True,
)


@api.route("/some-endpoint")
class SomeEndpoint(Resource):
    @ns.expect(some_parser)
    def post(self):
        args = some_parser.parse_args()
        app.logger.info("Received input: %s", str(args))
        return args
