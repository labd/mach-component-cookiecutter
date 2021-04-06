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
@pytest.mark.parametrize("use_public_api", (1, 0))
@pytest.mark.parametrize(
    "use_commercetools, use_commercetools_api_extension, use_commercetools_subscription",
    (
        (0, 0, 0),
        (1, 0, 0),
        (1, 1, 0),
        (1, 1, 1),
        (1, 0, 1),
    ),
)
def test_terraform_stack(
    cookies,
    template,
    use_public_api,
    use_commercetools,
    use_commercetools_api_extension,
    use_commercetools_subscription,
):
    context = {
        "use_public_api": use_public_api,
        "use_commercetools": use_commercetools,
        "use_commercetools_api_extension": use_commercetools_api_extension,
        "use_commercetools_subscription": use_commercetools_subscription,
        "name": "unit-test",
    }
    if template == "aws":
        context["lambda_s3_repository"] = "mach-lambda-repository"

    result = cookies.bake(
        template=template,
        extra_context=context,
    )
    assert result.exit_code == 0
    assert result.project.isdir()

    files = _list_tf(os.path.join(result.project, "terraform"))

    tf_stack = utils.combine_files(files)
    filename = _get_tf_filename(
        template,
        use_public_api,
        use_commercetools,
        use_commercetools_api_extension,
        use_commercetools_subscription,
    )
    # utils.write_file(filename, tf_stack)
    expected = utils.get_file_content(filename)
    assert tf_stack == expected


def _get_tf_filename(
    template: str,
    use_public_api: int,
    use_commercetools: int,
    use_commercetools_api_extension: int,
    use_commercetools_subscription: int,
) -> str:
    parts = []
    if use_public_api:
        parts.append("public")
    if use_commercetools:
        parts.append("ct")
    if use_commercetools_api_extension:
        parts.append("apiext")
    if use_commercetools_subscription:
        parts.append("subscr")
    ext = f"_{'_'.join(parts)}" if parts else ""
    return f"terraform_stack_{template}{ext}.tf"


def _list_tf(dir_):
    files = os.listdir(dir_)

    return sorted([os.path.join(dir_, file) for file in files if file.endswith(".tf")])
