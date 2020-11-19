#!/bin/bash

STORAGE_ACCOUNT_KEY=`az storage account keys list -g {{ cookiecutter.shared_resource_group }} -n {{ cookiecutter.function_storage_account }} --query [0].value -o tsv`
az storage blob upload --account-name {{ cookiecutter.function_storage_account }} --account-key ${STORAGE_ACCOUNT_KEY} -c {{ cookiecutter.function_container_name }} -f build/$1 -n $1
