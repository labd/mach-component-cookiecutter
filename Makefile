test: unit integration

unit:
	pytest tests/unit

integration:
	pytest tests/integration

format:
	black tests

generate:
	python generate.py

clean:
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -delete
	find . -name '*.egg-info' | xargs rm -rf
	find . -name '.DS_Store' -delete
