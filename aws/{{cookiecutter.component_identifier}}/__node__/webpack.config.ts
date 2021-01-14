import ForkTsCheckerWebpackPlugin from 'fork-ts-checker-webpack-plugin';
import nodeExternals from 'webpack-node-externals';
import serverlessWebpack from 'serverless-webpack';
import TsconfigPathsPlugin from 'tsconfig-paths-webpack-plugin';
import { Configuration, DefinePlugin, WebpackPluginInstance } from 'webpack';

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
  resolve: {
    plugins: [new TsconfigPathsPlugin()],
    extensions: ['.ts', '.js'],
  },
  plugins: [
    new ForkTsCheckerWebpackPlugin(),
    
    new DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
    }),
  ].filter(Boolean) as WebpackPluginInstance[],
}
module.exports = config

