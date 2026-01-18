import plugin from 'tailwindcss/plugin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default plugin(function ({ matchComponents, theme }) {
  let iconsDir = path.join(__dirname, '../../deps/lucide_icons/icons');
  let values = {};

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

        // Clean up SVG
        content = content
          .replace(/width="24"/g, '')
          .replace(/height="24"/g, '')
          .replace(/stroke-width="2"/g, 'stroke-width="1.5"')
          .replace(/stroke="[^"]+"/g, 'stroke="currentColor"');
        content = encodeURIComponent(content);

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
