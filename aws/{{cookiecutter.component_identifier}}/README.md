# {{ cookiecutter.name|slugify }}-component

{{ cookiecutter.description }}

# Usage

Use the following attributes to configure this component in MACH:

```yaml
sites:
  - identifier: some site
    components:
    - name: {{ cookiecutter.name }}
      variables:
        ...

...

components:
- name: {{ cookiecutter.name }}
  {% if cookiecutter.name != cookiecutter.short_name %}short_name: apiexts{% endif %}
  source: ...
  version: <git hash of version you want to release>
```

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