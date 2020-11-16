# MACH component cookiecutter template

Provides a template to bootstrap your [MACH](https://machcomposer.io) component.

Supports various implementations running on **AWS** or **Azure** and using various runtimes.

# Usage

```bash
$ cookiecutter https://github.com/labd/mach-component-cookiecutter --directory="aws"
```

or 

```bash
$ cookiecutter https://github.com/labd/mach-component-cookiecutter --directory="azure"
```

# Supported configurations

## Cloud integrations

A cloud integration is selected by defining a directory.

- AWS
- Azure

## Language

- Python
- Node

## Component types

- commercetools API extension
- commercetools Subscription