const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  future: {
    removeDeprecatedGapUtilities: true,
    purgeLayersByDefault: true,
  },
  purge: ["_site/**/*.html"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
      colors: {
        primary: {
          50: "#fafafa",
          100: "#f3f3f3",
          200: "#e3e3e3",
          300: "#c6c6c6",
          400: "#9e9e9e",
          500: "#6e6e6e",
          600: "#434343",
          700: "#242424",
          800: "#121212",
          900: "#0d0d0d",
        },
        secondary: {
          50: "#fafafa",
          100: "#f3f3f3",
          200: "#e3e3e3",
          300: "#c6c6c6",
          400: "#9e9e9e",
          500: "#6e6e6e",
          600: "#434343",
          700: "#242424",
          800: "#121212",
          900: "#0d0d0d",
        },
        dark: {
          50: "#fafafa",
          100: "#f3f3f3",
          200: "#e3e3e3",
          300: "#c6c6c6",
          400: "#9e9e9e",
          500: "#6e6e6e",
          600: "#434343",
          700: "#242424",
          800: "#121212",
          900: "#0d0d0d",
        },
      },
    },
  },
  variants: {},
  plugins: [require("@tailwindcss/ui")],
};
