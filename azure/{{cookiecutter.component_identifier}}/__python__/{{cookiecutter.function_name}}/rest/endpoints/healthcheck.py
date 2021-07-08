import os

from pydantic.dataclasses import dataclass

from .router import router


class ORMConfig:
    orm_mode = True


@dataclass(config=ORMConfig)
class HealthCheckResponse:
    ok: bool
    version: str


@router.get("/healthchecks/", response_model=HealthCheckResponse)
async def healthchecks():
    return HealthCheckResponse(
        ok=True, version=os.environ.get("COMPONENT_VERSION", "dev")
    )
