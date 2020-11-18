import hcl2
from typing import Any


class HclWrapper:
    def __init__(self, source: dict, level=0):
        self._level = 0
        self._source = source

    def __getitem__(self, key):
        return self._wrap(self._source[key])

    def __getattr__(self, key):
        return self[key]

    def _wrap(self, value: Any) -> Any:
        if isinstance(value, dict):
            return HclWrapper(value, level=self._level + 1)

        if isinstance(value, list) and len(value) == 1:
            # Very bold assumption: the HCL package also wraps
            # single values in lists. We'll unwrap it here.
            # In case we need to test an actual list
            # which could also contain 1 item, we need to fine-tune this.
            # At the moment, this suffies.
            return self._wrap(value[0])

        if isinstance(value, list) and self._level == 0:
            # On the root-level, all items are wrapped in a list
            # where all items are dicts with 1 key.
            # We'll unwrap this to access the elements in a more
            # elegant way.
            result = {}
            for item in value:
                for k, v in item.items():
                    if k in result and isinstance(result[k], dict):
                        result[k].update(v)
                    else:
                        result[k] = v
            return self._wrap(result)

        return value


def load_hcl(path: str):
    with open(path) as f:
        return HclWrapper(hcl2.load(f))
