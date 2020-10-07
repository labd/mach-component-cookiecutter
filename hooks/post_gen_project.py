#!/usr/bin/env python
import os
import shutil

PROJECT_DIRECTORY = os.path.realpath(os.path.curdir)
MANIFEST = os.path.join(PROJECT_DIRECTORY, "MANIFEST")

def delete_resource(resource):
    if os.path.isfile(resource):
        print(f"removing file: {resource}")
        os.remove(resource)
    elif os.path.isdir(resource):
        print(f"removing directory: {resource}")
        shutil.rmtree(resource)


def use_resources(directory: str):
    if not os.path.isdir(directory):
        raise ValueError(f"{directory} is not a directory")

    target_dir = os.path.dirname(directory)

    print("-----------------------------")
    print(f"{directory} to {target_dir}")


    for file_name in os.listdir(directory):
        if file_name.startswith("."):
            continue

        source = os.path.join(directory, file_name)
        # if os.path.isfile(source):
        shutil.move(source, target_dir)
        # else:
        #     shutil.copytree(source, target_dir)

    delete_resource(directory)

with open(MANIFEST) as manifest_file:
    directories = [
        d.strip() for d in
        manifest_file.readlines()
        if d.strip()
    ]

for directory in directories:
    if directory.startswith("!"):
        delete_resource(directory[1:])
    else:
        use_resources(os.path.join(PROJECT_DIRECTORY, directory))

print("cleanup complete, removing manifest...")
delete_resource(MANIFEST)
