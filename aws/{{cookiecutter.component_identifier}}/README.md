# {{ cookiecutter.name|slugify }}-component

## Installation

{% if cookiecutter.language == "node" -%}
1. Run `yarn install`
{%- endif %}

## Getting started

Run

{% if cookiecutter.language == "node" -%}
```bash
$ yarn start
```
{%- endif %}

And you're ready to go.

## Testing

{% if cookiecutter.language == "node" -%}
```bash
$ yarn test
```
{%- endif %}