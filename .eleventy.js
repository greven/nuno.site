const fs = require("fs");
const pluginRss = require("@11ty/eleventy-plugin-rss");
const pluginSyntaxHighlight = require("@11ty/eleventy-plugin-syntaxhighlight");
const pluginNavigation = require("@11ty/eleventy-navigation");
const markdownIt = require("markdown-it");
const markdownItAnchor = require("markdown-it-anchor");
const htmlmin = require("html-minifier");
const { DateTime } = require("luxon");
// const Image = require("@11ty/eleventy-img");
// const sharp = require("sharp");

module.exports = function (eleventyConfig) {
  eleventyConfig.addPlugin(pluginRss);
  eleventyConfig.addPlugin(pluginSyntaxHighlight);
  eleventyConfig.addPlugin(pluginNavigation);

  eleventyConfig.setUseGitIgnore(false);

  eleventyConfig.setDataDeepMerge(true);

  eleventyConfig.addLayoutAlias("post", "layouts/post.njk");

  eleventyConfig.addFilter("readableDate", (dateObj) => {
    return DateTime.fromJSDate(dateObj, { zone: "utc" }).toFormat(
      "dd LLL yyyy"
    );
  });

  // https://html.spec.whatwg.org/multipage/common-microsyntaxes.html#valid-date-string
  eleventyConfig.addFilter("htmlDateString", (dateObj) => {
    return DateTime.fromJSDate(dateObj, { zone: "utc" }).toFormat("yyyy-LL-dd");
  });

  // Get the first `n` elements of a collection.
  eleventyConfig.addFilter("head", (array, n) => {
    if (n < 0) {
      return array.slice(n);
    }

    return array.slice(0, n);
  });

  eleventyConfig.addCollection("tagList", function (collection) {
    let tagSet = new Set();
    collection.getAll().forEach(function (item) {
      if ("tags" in item.data) {
        let tags = item.data.tags;

        tags = tags.filter(function (item) {
          switch (item) {
            // this list should match the `filter` list in tags.njk
            case "all":
            case "nav":
            case "post":
            case "posts":
              return false;
          }

          return true;
        });

        for (const tag of tags) {
          tagSet.add(tag);
        }
      }
    });

    // returning an array in addCollection works in Eleventy 0.5.3
    return [...tagSet];
  });

  eleventyConfig.addShortcode("version", function () {
    return String(Date.now());
  });

  // Images optimization
  // Usage: {% Image "/images/00.jpg", "this is an alt description" %}
  // eleventyConfig.addNunjucksAsyncShortcode("Image", async (src, alt) => {
  //   if (!alt) {
  //     throw new Error(`Missing \`alt\` on image from: ${src}`);
  //   }

  //   let stats = await Image(src, {
  //     widths: [25, 320, 640, 960, 1200, 1800, 2400],
  //     formats: ["jpeg", "webp"],
  //     urlPath: "/images/",
  //     outputDir: "./_site/images/",
  //   });

  //   let lowestSrc = stats["jpeg"][0];

  //   const placeholder = await sharp(lowestSrc.outputPath)
  //     .resize({ fit: sharp.fit.inside })
  //     .blur()
  //     .toBuffer();

  //   const base64Placeholder = `data:image/png;base64,${placeholder.toString(
  //     "base64"
  //   )}`;

  //   const srcset = Object.keys(stats).reduce(
  //     (acc, format) => ({
  //       ...acc,
  //       [format]: stats[format].reduce(
  //         (_acc, curr) => `${_acc} ${curr.srcset} ,`,
  //         ""
  //       ),
  //     }),
  //     {}
  //   );

  //   const source = `<source type="image/webp" data-srcset="${srcset["webp"]}" >`;

  //   const img = `<img
  //     class="lazy"
  //     alt="${alt}"
  //     src="${base64Placeholder}"
  //     data-src="${lowestSrc.url}"
  //     data-sizes='(min-width: 1024px) 1024px, 100vw'
  //     data-srcset="${srcset["jpeg"]}"
  //     width="${lowestSrc.width}"
  //     height="${lowestSrc.height}">`;

  //   return `<div class="image-wrapper"><picture> ${source} ${img} </picture></div>`;
  // });

  // Build
  eleventyConfig.addWatchTarget("./_tmp/style.css");

  eleventyConfig.addPassthroughCopy("images");
  eleventyConfig.addPassthroughCopy({ "./_tmp/style.css": "./style.css" });
  eleventyConfig.addPassthroughCopy({
    "./node_modules/alpinejs/dist/alpine.js": "./js/alpine.js",
  });

  /* Markdown Overrides */
  let markdownLibrary = markdownIt({
    html: true,
    breaks: true,
    linkify: true,
  }).use(markdownItAnchor, {
    permalink: true,
    permalinkClass: "direct-link",
    permalinkSymbol: "#",
  });
  eleventyConfig.setLibrary("md", markdownLibrary);

  // Browsersync Overrides
  eleventyConfig.setBrowserSyncConfig({
    callbacks: {
      ready: function (err, browserSync) {
        const content_404 = fs.readFileSync("_site/404.html");

        browserSync.addMiddleware("*", (req, res) => {
          // Provides the 404 content without redirect.
          res.write(content_404);
          res.end();
        });
      },
    },
    ui: false,
    ghostMode: false,
  });

  eleventyConfig.addTransform("htmlmin", function (content, outputPath) {
    if (
      process.env.ELEVENTY_PRODUCTION &&
      outputPath &&
      outputPath.endsWith(".html")
    ) {
      let minified = htmlmin.minify(content, {
        useShortDoctype: true,
        removeComments: true,
        collapseWhitespace: true,
      });
      return minified;
    }
    return content;
  });

  return {
    templateFormats: ["md", "njk", "html", "liquid"],

    markdownTemplateEngine: "liquid",
    htmlTemplateEngine: "njk",
    dataTemplateEngine: "njk",

    dir: {
      input: ".",
      includes: "_includes",
      data: "_data",
      output: "_site",
    },
  };
};
