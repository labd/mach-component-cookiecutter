import pytest
import os
from tests import utils


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

    assert result.exception is None
    assert result.exit_code == 0
    assert result.project.basename == "unit-test-component"
    assert result.project.isdir()

    files = list(list_files(str(result.project)))
    assert "terraform/variables.tf" in files

    if language != "python":
        for file in files:
            assert not file.endswith("py"), f"{file} not expected"

    if language != "node":
        assert "tsconfig.json" not in files


@pytest.mark.parametrize("template", ["azure", "aws"])
@pytest.mark.parametrize(
    "function_template", ("api-extension", "subscription", "public-api")
)
def test_terraform_stack(cookies, template, function_template):
    result = cookies.bake(
        template=template,
        extra_context={"function_template": function_template, "name": "unit-test"},
    )
    assert result.exit_code == 0
    assert result.project.isdir()

    files = _list_tf(os.path.join(result.project, "terraform"))

    tf_stack = utils.combine_files(files)

    # utils.write_file(f"terraform_stack_{template}_{function_template}.tf", tf_stack)
    expected = utils.get_file_content(
        f"terraform_stack_{template}_{function_template}.tf"
    )
    assert tf_stack == expected


def _list_tf(dir_):
    files = os.listdir(dir_)

    return sorted([os.path.join(dir_, file) for file in files if file.endswith(".tf")])
