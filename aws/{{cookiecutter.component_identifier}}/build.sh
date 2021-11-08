#!/bin/bash

VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "dev" )
TAGS=$(git tag)
BASENAME={{ cookiecutter.name|slugify }}
AWS_BUCKET_NAME="{{ cookiecutter.lambda_s3_repository }}"

artifact () {
    echo "${BASENAME}-$1.zip"
}

ARTIFACT_NAME=$(artifact $VERSION)

package () {
    {% if cookiecutter.language == "node" -%}
    yarn package:prod{% elif cookiecutter.language == "python" -%}
    python3 setup.py sdist bdist_wheel
    python3 -m pip install dist/*.whl -t ./build
    cp handler.py ./build
    clean
    cd build && zip -9 -r $ARTIFACT_NAME .
    {% endif %}
}

upload () {
    {% if cookiecutter.language == "node" -%}
    src=".serverless/{{ cookiecutter.name|slugify }}.zip"{% elif cookiecutter.language == "python" -%}
    src="build/${ARTIFACT_NAME}"
    {% endif %}
    aws s3 cp $src s3://$AWS_BUCKET_NAME/$ARTIFACT_NAME
    for TAG in $TAGS
    do
        echo "Uploading tagged ${TAG}"
        aws s3 cp $src s3://$AWS_BUCKET_NAME/$(artifact $TAG)
    done
}

version () {
    echo "Version: '${VERSION}'"
    echo "Artifact name: '${ARTIFACT_NAME}'"
    for TAG in $TAGS
    do
        echo " - $(artifact $TAG)"
    done
}

clean () {
    {% if cookiecutter.language == "python" -%}
    find . -name '*.pyc' -delete
    find . -name '__pycache__' -delete
    find . -name '*.egg-info' | xargs rm -rf{% else %}
    echo "Not implemented yet"{% endif %}
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
    clean)
        clean
    ;;
esac
