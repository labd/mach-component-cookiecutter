import path from 'path'
import slsw from 'serverless-webpack'
import ForkTsCheckerWebpackPlugin from 'fork-ts-checker-webpack-plugin'
import SentryWebpackPlugin from '@sentry/webpack-plugin'
import { Configuration, DefinePlugin, WebpackPluginInstance } from 'webpack'
import nodeExternals from 'webpack-node-externals'

const config: Configuration = {
 mode: serverlessWebpack.lib.webpack.isLocal ? 'development' : 'production',
  entry: serverlessWebpack.lib.entries,
  externals: [nodeExternals()],
  devtool: serverlessWebpack.lib.webpack.isLocal ? 'inline-cheap-module-source-map' : 'source-map',
  target: 'node',
  node: false,
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
    ],
  },
  optimization: {
    minimize: false,
  },
  plugins: [
    new ForkTsCheckerWebpackPlugin(),
    {% if cookiecutter.sentry_project -%}
    process.env.SENTRY_AUTH_TOKEN &&
      process.env.RELEASE &&
      new SentryWebpackPlugin({
        // sentry-cli configuration
        release: process.env.RELEASE,
        authToken: process.env.SENTRY_AUTH_TOKEN,
        org: '{{ cookiecutter.sentry_organization }}',
        project: '{{ cookiecutter.sentry_project }}',
        // webpack specific configuration
        include: '.webpack/service',
        stripCommonPrefix: true,
        urlPrefix: 'app:///',
      }),
    {%- endif %}
    new DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
    }),
  ].filter(Boolean) as WebpackPluginInstance[],
}
module.exports = config

