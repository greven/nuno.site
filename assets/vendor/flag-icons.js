import plugin from 'tailwindcss/plugin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default plugin(function ({ matchComponents, theme }) {
  let iconsDir = path.join(__dirname, '../../deps/flag_icons/flags');
  let values = {};
  let icons = [
    ['', '/4x3'],
    ['-square', '/1x1'],
  ]

  icons.forEach(([suffix, dir]) => {
    fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
      let name = path.basename(file, '.svg') + suffix;
      values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
    });
  });

  matchComponents(
    {
      flag: ({ name, fullPath }) => {
        let content = fs
          .readFileSync(fullPath)
          .toString()
          .replace(/\r?\n|\r/g, '');
        content = encodeURIComponent(content);
        let size = theme('spacing.6');
        let aspect = '4 / 3';
        if (name.endsWith('-square')) {
          aspect = '1';
        }
        return {
          [`--flag-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          'background-image': `var(--flag-${name})`,
          'background-repeat': 'no-repeat',
          'background-size': 'cover',
          'background-position': 'center',
          'vertical-align': 'middle',
          display: 'inline-block',
          'aspect-ratio': aspect,
          width: size,
        };
      },
    },
    { values }
  );
});
