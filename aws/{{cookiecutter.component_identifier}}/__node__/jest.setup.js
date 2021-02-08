process.env.BABEL_ENV = 'test' // Make sure to load the appropriate babel plugins
process.env.NODE_ENV = 'test' // set the proper node env
global.__DEV__ = false

// For async tests, catch all errors here so we don't have to try / catch
// everywhere for safety
process.on('unhandledRejection', (error) => {
  console.error(error)
})

process.env.ENVIRONMENT = 'test'
process.env.RELEASE = 'v1'
process.env.CT_PROJECT_KEY = 'nl-unittest'
process.env.CT_CLIENT_ID = 'foo'
process.env.CT_CLIENT_SECRET = 'foo'
process.env.CT_SCOPES = 'foo'
process.env.CT_API_URL = 'https://localhost'
process.env.CT_AUTH_URL = 'https://localhost'
process.env.AWS_REGION = 'eu-central-1'
process.env.COMPONENT_NAME = '{{ cookiecutter.name|slugify }}'
{% if cookiecutter.use_commercetools_api_extension|int -%}
process.env.ORDER_PREFIX = 'unittest-'
process.env.INITIAL_ORDER_NUMBER = '2000000'{% endif %}
