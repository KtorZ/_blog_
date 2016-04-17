module.exports = {
    entry: './src/app.js',
    output: {
        path: __dirname + '/dist',
        filename: '[name].js',
    },

    module: {
        loaders: [
            {
                test: /\.html$|\.css$/,
                exclude: /node_modules|elm-stuff/,
                loader: 'file?name=[name].[ext]',
            },
            {
                test: /\.elm$/,
                exclude: /node_modules|elm-stuff/,
                loader: 'elm-webpack',
            },
        ],
        noParse: /\.elm$/,
    },

    devtool: 'source-map',

    devServer: {
        inline: true,
        stats: { colors: true },
    },
}
