#!/usr/bin/env python
import os
import shutil
import yaml

PROJECT_DIRECTORY = os.path.realpath(os.path.curdir)
MANIFEST = os.path.join(PROJECT_DIRECTORY, "manifest.yml")
print(MANIFEST)

def delete_resource(resource):
    if os.path.isfile(resource):
        print(f"removing file: {resource}")
        os.remove(resource)
    elif os.path.isdir(resource):
        print(f"removing directory: {resource}")
        shutil.rmtree(resource)


with open(MANIFEST) as manifest_file:
    manifest = yaml.load(manifest_file, Loader=yaml.FullLoader)

    for feature in manifest['features']:
        if not feature['enabled']:
            print(f"removing resources for disabled feature {feature['name']}...")
            for resource in feature['resources']:
                delete_resource(resource)

    print("cleanup complete, removing manifest...")
