.PHONY: all version

ifdef GIT_VERSION
VERSION := $(GIT_VERSION)
else
VERSION := $(shell git rev-parse --short HEAD 2>/dev/null || echo "dev" )
endif
# shorter name because of azure
NAME := {{ cookiecutter.short_name }}-$(VERSION)
ARTIFACT_NAME := $(NAME).zip
WORKSPACE := $(shell pwd)
BASENAME := $(shell basename $(CURDIR))
LANGUAGE := "en"

version:
	@echo "Version: '${VERSION}'"
	@echo "Name: '${NAME}'"
	@echo "Artifect name: '${ARTIFACT_NAME}'"

install:
	pip install -r requirements_dev.txt

pack:
	# note this function is currently undocumented in core tools (will be added some day)
	func pack --build-native-deps --python
	mv $(BASENAME).zip $(ARTIFACT_NAME)

upload:
	./azure-upload.sh $(ARTIFACT_NAME)

clean: clean-lambda-package
	rm -rf $(WORKSPACE)/.python_packages
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -delete
	find . -name '*.egg-info' | xargs rm -rf

requirements:
	pip install pip-tools
	pip-compile requirements.in

#
# Testing
#
test:
	py.test tests/

retest:
	py.test --lf -vvs tests/

coverage:
	py.test tests/ --cov-report=term-missing

mypy:
	mypy --config-file=mypy.ini .

#
# Lint targets
#
format:
	isort .
	black . 
	terraform fmt terraform

lint: flake8 isort mypy


isort:
	isort . --check-only

flake8:
	flake8

#
# Docker
#
docker-check:
	@rm -rf reports || true
	mkdir reports
	docker rm -f $(NAME) || true
	docker build --tag $(NAME) .
	docker run -e FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT=1 -e TX_TOKEN=${TX_TOKEN} -e GIT_VERSION=$(VERSION) --name=$(NAME) $(NAME) make coverage
	docker rm -f $(NAME)

docker-package: docker-check pack
