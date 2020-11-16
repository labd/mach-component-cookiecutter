import pytest
import os


def list_files(path, *, root=""):
    for file in os.listdir(path):
        full_path = os.path.join(path, file)
        if os.path.isdir(full_path):
            subroot = os.path.join(root, file)
            yield from list_files(full_path, root=subroot)
        else:
            yield os.path.join(root, file)


@pytest.mark.parametrize("template", ["aws", "azure"])
@pytest.mark.parametrize("language", ["node", "python"])
def test_generate(cookies, template, language):
    result = cookies.bake(
        template=template, extra_context={"language": language, "name": "unit-test"}
    )

    assert result.exit_code == 0
    assert result.exception is None
    assert result.project.basename == "unit-test-component"
    assert result.project.isdir()

    files = list(list_files(str(result.project)))
    assert "terraform/variables.tf" in files

    if language != "python":
        for file in files:
            assert not file.endswith("py"), f"{file} not expected"

    if language != "node":
        assert "tsconfig.json" not in files
