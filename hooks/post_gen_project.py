#!/usr/bin/env python
import os
import shutil

PROJECT_DIRECTORY = os.path.realpath(os.path.curdir)
MANIFEST = os.path.join(PROJECT_DIRECTORY, "MANIFEST")
SUPPORTED_LANGUAGES = [
    "python", "node"
]

def delete_resource(resource):
    if os.path.isfile(resource):
        os.remove(resource)
    elif os.path.isdir(resource):
        shutil.rmtree(resource)


def use_resources(directory: str):
    if not os.path.isdir(directory):
        raise ValueError(f"{directory} is not a directory")

    target_dir = os.path.dirname(directory)

    for file_name in os.listdir(directory):
        source = os.path.join(directory, file_name)
        _check_path = os.path.join(target_dir, file_name)
        if os.path.exists(_check_path):
            os.remove(_check_path)

        shutil.move(source, target_dir)

    delete_resource(directory)


def unpack(directory_pattern: str):
    """Unpacks a directory pattern to several directories"""
    unpacked = [
        directory_pattern
    ]

    if "*" in directory_pattern:
        parent_dir = os.path.dirname(directory_pattern)

        # Very simple matching on start and end string, no regex here
        start, end = os.path.basename(directory_pattern).split("*")

        subdirs = os.listdir(parent_dir)
        unpacked = [
            os.path.join(parent_dir, dir_) for dir_ in os.listdir(parent_dir)
            if dir_.startswith(start) and dir_.endswith(end)
        ]

    return unpacked

if os.path.exists("gitignore"):
    shutil.move("gitignore", ".gitignore")

with open(MANIFEST) as manifest_file:
    directories = [
        d.strip() for d in
        manifest_file.readlines()
        if d.strip()
    ]

for directory in directories:
    if directory.startswith("!"):
        for dir_ in unpack(directory[1:]):
            delete_resource(os.path.join(PROJECT_DIRECTORY, dir_))
    else:
        for dir_ in unpack(directory):
            use_resources(os.path.join(PROJECT_DIRECTORY, dir_))

# Cleanup all language-specific sub dirs here, so we don't have to define all the excludes
# in the MANIFEST files
for lang in SUPPORTED_LANGUAGES:
    delete_resource(os.path.join(PROJECT_DIRECTORY, f"__{lang}__"))

delete_resource(MANIFEST)
