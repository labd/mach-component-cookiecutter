import pytest


class ProjectGenerator:
    def __init__(self, cookies):
        self.cookies = cookies

    def create(self, template: str, extra_context: dict) -> str:
        result = self.cookies.bake(template=template, extra_context=extra_context)
        assert result.exit_code == 0
        return result.project


@pytest.fixture
def project(cookies):
    return ProjectGenerator(cookies)
