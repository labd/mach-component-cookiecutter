import path from 'path'
import slsw from 'serverless-webpack'
import ForkTsCheckerWebpackPlugin from 'fork-ts-checker-webpack-plugin'
import SentryWebpackPlugin from '@sentry/webpack-plugin'
// eslint-disable-next-line
import { Configuration, DefinePlugin, WebpackPluginInstance } from 'webpack'

const config: Configuration = {
  mode: slsw.lib.webpack.isLocal ? 'development' : 'production',
  entry: {
    index: './src/index.ts',
  },
  devtool: slsw.lib.webpack.isLocal ? 'cheap-module-eval-source-map' : 'source-map',
  resolve: {
    extensions: ['.js', '.jsx', '.json', '.ts', '.tsx'],
    symlinks: false,
    cacheWithContext: false,
  },
  output: {
    libraryTarget: 'commonjs2',
    path: path.join(__dirname, '.webpack'),
    filename: '[name].js',
  },
  target: 'node',
  module: {
    rules: [
      {
        // Include ts, tsx, js, and jsx files.
        test: /\.(ts|js)x?$/,
        exclude: /node_modules/,
        use: [
          {
            loader: 'cache-loader',
            options: {
              cacheDirectory: path.resolve('.webpackCache'),
            },
          },
          'babel-loader',
        ],
      },
    ],
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
