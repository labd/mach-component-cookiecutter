#!/bin/bash

VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "dev" )
BASENAME={{ cookiecutter.name|slugify }}
NAME=$BASENAME-$VERSION
BUILD_NAME=$NAME
ARTIFACT_NAME="${NAME}.zip"

package () {
    {% if cookiecutter.language == "node" -%}
    yarn package:prod{% else -%}
    # TODO{% endif %}
}

upload () {
    {% if cookiecutter.language == "node" -%}
    src=".serverless/{{ cookiecutter.name|slugify }}.zip"
    dest=$ARTIFACT_NAME
    aws s3 cp $src s3://{{ cookiecutter.lambda_s3_repository }}/$dest{% else -%}
    # TODO{% endif %}
}

version () {
    echo "Version: '${VERSION}'"
    echo "Name: '${NAME}'"
    echo "Artifect name: '${ARTIFACT_NAME}'"
}

case $1 in
    package)
        package $2 $3
    ;;
    upload)
        upload $2
    ;;
    version)
        version
    ;;
esac
