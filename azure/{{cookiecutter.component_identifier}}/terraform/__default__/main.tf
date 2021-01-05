{% if cookiecutter.use_commercetools|int -%}
terraform {
  required_providers {
    commercetools = {
      source = "labd/commercetools"
    }
  }
}{% endif %}