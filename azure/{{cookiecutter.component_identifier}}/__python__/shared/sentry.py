import logging
import os
from typing import Callable, List, Optional, Dict, Any

import sentry_sdk
from sentry_sdk.integrations import Integration
from sentry_sdk.integrations.logging import LoggingIntegration

env = os.environ.get
logger = logging.getLogger(__name__)

def init_sentry(
    event_level=logging.WARNING,
    extra_integrations: Optional[List[Integration]] = None,
    attach_stacktrace: bool = True,
    before_send: Optional[Callable] = None,
    debug: bool = False,
    enable_tracing: bool = True,
):
    sentry_dsn = env("SENTRY_DSN")
    if not sentry_dsn:
        logging.info("Not initializing Sentry: no SENTRY_DSN environment variable set")
        return

    integrations: List[Integration] = [
        LoggingIntegration(level=logging.INFO, event_level=event_level),
    ]
    if extra_integrations:
        for e in extra_integrations:
            integrations.append(e)

    init_kwargs: Dict[str, Any] = {
        "dsn": sentry_dsn,
        "integrations": integrations,
        "debug": debug,
        "release": env("SENTRY_RELEASE"),
        "environment": env("SENTRY_ENVIRONMENT"),
        "send_default_pii": True,
        "_experiments": {"auto_enabling_integrations": True},
        "attach_stacktrace": attach_stacktrace,
    }

    if enable_tracing:
        init_kwargs["traces_sample_rate"] = float(env("SENTRY_SAMPLE_RATE", 0.25))

    if before_send:
        init_kwargs["before_send"] = before_send  # type: ignore

    sentry_sdk.init(**init_kwargs)  # type: ignore
    set_sentry_scope()


def set_sentry_scope():
    with sentry_sdk.configure_scope() as scope:
        scope.set_tag("service_name", os.environ.get("NAME"))
        scope.set_tag("stage", os.environ.get("ENVIRONMENT"))
        scope.set_tag("alias", os.environ.get("SITE"))
        scope.set_tag("region", os.environ.get("REGION"))
