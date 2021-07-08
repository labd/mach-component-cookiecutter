from fastapi import APIRouter

from api.conf import URL_PREFIX

router = APIRouter(prefix=URL_PREFIX)
