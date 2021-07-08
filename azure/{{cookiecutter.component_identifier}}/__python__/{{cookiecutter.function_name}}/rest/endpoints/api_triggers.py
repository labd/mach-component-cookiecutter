from enum import Enum

from pydantic import BaseModel
from pydantic.dataclasses import dataclass

from .router import router


class ORMConfig:
    orm_mode = True


@dataclass(config=ORMConfig)
class TriggerResponse:
    ok: bool


class Action(str, Enum):
    new = "new"
    update = "update"


class TriggerData(BaseModel):
    order_id: str
    action: Action


@router.post("/api-trigger/", response_model=TriggerResponse)
async def trigger(data: TriggerData):
    print(data)
    return TriggerResponse(ok=True)
