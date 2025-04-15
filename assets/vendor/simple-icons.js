const plugin = require('tailwindcss/plugin');
const fs = require('fs');
const path = require('path');

module.exports = plugin(function ({ matchComponents, theme }) {
  let iconsDir = path.join(__dirname, '../../deps/simple_icons/icons');
  let values = {};

  fs.readdirSync(iconsDir).forEach((file) => {
    if (file.endsWith('.svg')) {
      let name = path.basename(file, '.svg');
      values[name] = { name, fullPath: path.join(iconsDir, file) };
    }
  });

  matchComponents(
    {
      si: ({ name, fullPath }) => {
        let content = fs
          .readFileSync(fullPath)
          .toString()
          .replace(/\r?\n|\r/g, '');

        content = content.replace(/fill="[^"]+"/g, 'fill="currentColor"');
        content = encodeURIComponent(content);

        let size = theme('spacing.5');

        return {
          [`--si-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          '-webkit-mask': `var(--si-${name})`,
          mask: `var(--si-${name})`,
          'mask-repeat': 'no-repeat',
          'background-color': 'currentColor',
          'vertical-align': 'middle',
          'mask-size': 'contain',
          'mask-position': 'center',
          display: 'inline-block',
          width: size,
          height: size,
        };
      },
    },
    { values }
  );
});
