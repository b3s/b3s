module.exports = {
  plugins: [
    require("postcss-import-ext-glob"),
    require("postcss-import"),
    require("postcss-image-inliner")({ assetPaths: ["app/assets/images"] }),
    require("postcss-url")([
      {
        filter: /webfonts\/fa-/,
        url: "copy",
        basePath: "../../../node_modules/@fortawesome/fontawesome-free/css",
        assetsPath: "./fonts",
        useHash: true
      }
    ]),
    require("postcss-mixins"),
    require("postcss-simple-vars"),
    require("postcss-nested"),
    require("autoprefixer")
  ]
};
