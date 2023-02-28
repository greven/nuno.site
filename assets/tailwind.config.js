// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const defaultTheme = require("tailwindcss/defaultTheme");

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
        primary: "#DD4C4F",
        secondary: "#222222",
        complementary: "#4cddda",
        surface: {
          light: "#FBFBFB",
          dark: "#222222",
        },
        text: {
          light: "#15141A",
          dark: "#FBFBFB",
        },
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
            "--tw-prose-links": theme("colors.primary"),
            "--tw-prose-bullets": theme("colors.primary"),
          },
        },
      }),
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/line-clamp"),

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
      addVariant("phx-error", [".phx-error&", ".phx-error &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-form-error", [":not(.phx-no-feedback).show-errors &"])
    ),
  ],
};
