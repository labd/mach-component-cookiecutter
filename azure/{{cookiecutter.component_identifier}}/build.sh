#!/bin/bash

VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "dev" )
TAGS=$(git tag)
BASENAME=$(basename $PWD)
NAME={{ cookiecutter.name|slugify }}-$VERSION

artifact () {
    echo "${BASENAME}-$1.zip"
}

ARTIFACT_NAME=$(artifact $VERSION)

package () {
    {% if cookiecutter.language == "node" -%}
    yarn build:production
    mkdir -p build
    func pack -o build/$NAME
    # For some reason; func pack doesnt do this for us;
    find . -name function.json | xargs zip -ur build/$ARTIFACT_NAME
    zip -ur build/$ARTIFACT_NAME dist
    zip -ur build/$ARTIFACT_NAME node_modules
    {% else -%}
    mkdir -p build
	func pack --build-native-deps --python
	mv ${BASENAME}.zip build/${ARTIFACT_NAME}{% endif %}
}

upload () {
    src="build/${ARTIFACT_NAME}"
    STORAGE_ACCOUNT_KEY=`az storage account keys list -g {{ cookiecutter.shared_resource_group }} -n {{ cookiecutter.function_storage_account }} --query [0].value -o tsv`
    az storage blob upload --account-name {{ cookiecutter.function_storage_account }} --account-key ${STORAGE_ACCOUNT_KEY} -c {{ cookiecutter.function_container_name }} -f ${src} -n ${ARTIFACT_NAME}
    for TAG in $TAGS
    do
        echo "Uploading tagged ${TAG}"
        az storage blob upload --account-name {{ cookiecutter.function_storage_account }} --account-key ${STORAGE_ACCOUNT_KEY} -c {{ cookiecutter.function_container_name }} -f ${src} -n ${TAG}
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
