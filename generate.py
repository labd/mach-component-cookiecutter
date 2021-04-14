"""
Helper script to generate a couple of components to do some quick testing/analysis on.
"""
from cookiecutter.main import cookiecutter
from contextlib import contextmanager
import shutil
import os

output_dir = os.path.join(os.curdir, "generated")


def prompt(q):
    while result := input(f"{q} [y/n]: "):
        if result.lower() == "y":
            return True
        if result.lower() == "n":
            return False


keep_node_modules = prompt("Keep node_modules?")

def move(source_dir, dest_dir, name):
    source = os.path.join(source_dir, name)
    if os.path.exists(source):
        shutil.move(source, os.path.join(dest_dir, name))

@contextmanager
def component_dir(cloud, config, counter):
    dirname = f"{cloud}_{counter}_{config['language']}"
    full_path = os.path.join(output_dir, dirname)

    tmp_path = os.path.join(output_dir, f".tmp-{dirname}")
    if os.path.exists(tmp_path):
        shutil.rmtree(tmp_path)

    restore_files = []
    if keep_node_modules and config["language"] == "node":
        restore_files = [
            "node_modules", "yarn.lock"
        ]

    if os.path.exists(full_path):
        os.mkdir(tmp_path)
        for file in restore_files:
            move(full_path, tmp_path, file)

        shutil.rmtree(full_path)

    yield dirname

    if os.path.exists(tmp_path):
        for file in restore_files:
            move(tmp_path, full_path, file)
        shutil.rmtree(tmp_path)


base = {"name": "unit-test"}
AZURE_CONFIGS = [
    {**base, "language": "node"},
    {**base, "language": "python"},
]

AWS_CONFIGS = [
    {**base, "language": "node"},
    {**base, "language": "python"},
]

for i, config in enumerate(AZURE_CONFIGS, start=1):
    with component_dir("azure", config, i) as dirname:
        config["component_identifier"] = dirname
        cookiecutter(
            template="azure", output_dir=output_dir, extra_context=config, no_input=True
        )

for i, config in enumerate(AWS_CONFIGS, start=1):
    with component_dir("aws", config, i) as dirname:
        config["component_identifier"] = dirname
        cookiecutter(
            template="aws",
            output_dir=output_dir,
            extra_context=config,
            no_input=True,
        )
