const plugin = require('tailwindcss/plugin');
const fs = require('fs');
const path = require('path');

module.exports = plugin(function ({ matchComponents, theme }) {
  let iconsDir = path.join(__dirname, '../../deps/lucide_icons/icons');
  let values = {};

  // Read all SVG files in the icons directory
  fs.readdirSync(iconsDir).forEach((file) => {
    if (file.endsWith('.svg')) {
      let name = path.basename(file, '.svg');
      values[name] = { name, fullPath: path.join(iconsDir, file) };
    }
  });

  matchComponents(
    {
      lucide: ({ name, fullPath }) => {
        let content = fs
          .readFileSync(fullPath)
          .toString()
          .replace(/\r?\n|\r/g, '');

        // Clean up SVG: remove width/height/stroke-width and set stroke to currentColor
        content = content
          .replace(/width="24"/g, '')
          .replace(/height="24"/g, '')
          .replace(/stroke-width="2"/g, 'stroke-width="1.5"')
          .replace(/stroke="[^"]+"/g, 'stroke="currentColor"');
        console.log(content);
        content = encodeURIComponent(content);

        // Default size for Lucide icons
        let size = theme('spacing.6'); // 1.5rem / 24px by default

        return {
          [`--lucide-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          '-webkit-mask': `var(--lucide-${name})`,
          mask: `var(--lucide-${name})`,
          'mask-repeat': 'no-repeat',
          'background-color': 'currentColor',
          'vertical-align': 'middle',
          display: 'inline-block',
          width: size,
          height: size,
        };
      },
    },
    { values }
  );
});
