.PHONY: all

WORKSPACE := $(shell pwd)

install:
	pip install -r requirements_dev.txt

version:
	./build version

start:
	func start --python

pack:
	./build.sh package

upload:
	./build.sh upload

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
