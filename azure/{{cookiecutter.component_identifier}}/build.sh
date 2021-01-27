#!/bin/bash

VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "dev" )
BASENAME={{ cookiecutter.short_name|slugify }}
NAME=$BASENAME-$VERSION
BUILD_NAME=$NAME
ARTIFACT_NAME="${NAME}.zip"

package () {
    {% if cookiecutter.language == "node" -%}
    yarn build:production
    mkdir -p build
    func pack -o build/$NAME
    {% else -%}
    mkdir -p build
	func pack --build-native-deps --python
	mv $(BASENAME).zip build/$(ARTIFACT_NAME){% endif %}
}

upload () {
    src="build/${NAME}.zip"
    dest=$ARTIFACT_NAME
    STORAGE_ACCOUNT_KEY=`az storage account keys list -g {{ cookiecutter.shared_resource_group }} -n { cookiecutter.function_storage_account }} --query [0].value -o tsv`
    az storage blob upload --account-name {{ cookiecutter.function_storage_account }} --account-key ${STORAGE_ACCOUNT_KEY} -c {{ cookiecutter.function_container_name }} -f ${src} -n ${dest}
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
