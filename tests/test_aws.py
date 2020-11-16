def test_generate(cookies):
    result = cookies.bake(template="aws")

    assert result.exit_code == 0
    assert result.exception is None
    assert result.project.basename == "example-component"
    assert result.project.isdir()
