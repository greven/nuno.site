// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const fs = require("fs");
const path = require("path");

const plugin = require("tailwindcss/plugin");
const defaultTheme = require("tailwindcss/defaultTheme");
const colors = require("tailwindcss/colors");

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  darkMode: "class",
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", ...defaultTheme.fontFamily.sans],
        headings: ["Montserrat", ...defaultTheme.fontFamily.serif],
      },
      colors: {
        primary: {
          DEFAULT: "#DD4C4F",
          50: "#FDF3F3",
          100: "#FBE5E5",
          200: "#F9CFD0",
          300: "#F4ADAE",
          400: "#EB7E80",
          500: "#DD4C4F",
          600: "#CB373A",
          700: "#AA2B2E",
          800: "#8D2729",
          900: "#762628",
          950: "#3A1313",
        },
        secondary: colors.neutral,
        complementary: {
          DEFAULT: "#4CDDDA",
          50: "#F1FCFC",
          100: "#CFF8F5",
          200: "#9EF1EC",
          300: "#4CDDDA",
          400: "#37C8CA",
          500: "#1DABAF",
          600: "#15868C",
          700: "#156B70",
          800: "#15565A",
          900: "#16484B",
          950: "#12383B",
        },
        surface: {
          light: "#FBFBFB",
          dark: "#222222",
        },
        text: {
          light: "#15141A",
          dark: "#FBFBFB",
        },
      },

      animation: {
        "spin-slow": "spin 2s linear infinite",
      },
      typography: ({ theme }) => ({
        DEFAULT: {
          color: theme("colors.red.600"),
          css: {
            h1: {
              "font-weight": 600,
            },
            "h2, h3, h4, h5": {
              "font-weight": 400,
            },
            a: {
              "text-decoration": "underline",
            },
          },
        },

        primary: {
          css: {
            "--tw-prose-headings": "#222222",
            "--tw-prose-links": theme("colors.primary.DEFAULT"),
            "--tw-prose-bullets": theme("colors.primary.DEFAULT"),
          },
        },
      }),
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),

    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //

    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-page-loading", [
        ".phx-page-loading&",
        ".phx-page-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-error", [".phx-error&", ".phx-error &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-form-error", [":not(.phx-no-feedback).show-errors &"])
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              "mask": `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              "display": "inline-block",
              "width": theme("spacing.5"),
              "height": theme("spacing.5")
            };
          },
        },
        { values }
      );
    }),
  ],
};
