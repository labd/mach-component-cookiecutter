# {{ cookiecutter.component_identifier }}

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
  source: ...
  {% if cookiecutter.use_public_api|int -%}
  endpoints:
    main: ...
  {% endif -%}
  version: <git hash of version you want to release>
```
{% if cookiecutter.use_public_api|int %}
## Required endpoints

- **`main`**<br>
  Description
{% endif %}

# Getting started

{% if cookiecutter.language == "node" -%}
Run 

```bash
$ yarn install
```{% endif %}

## Getting started

Run

{% if cookiecutter.language == "node" -%}
```bash
$ yarn start
```{% endif %}

And you're ready to go.

## Testing

{% if cookiecutter.language == "node" -%}
```bash
$ yarn test
```{% endif %}