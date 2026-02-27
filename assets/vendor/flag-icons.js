import plugin from 'tailwindcss/plugin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let iconsDir = path.join(__dirname, '../../deps/flag_icons/flags');
const svgCache = new Map();

let icons = [
  ['', '/4x3'],
  ['-square', '/1x1'],
];

let values = {};

icons.forEach(([suffix, dir]) => {
  fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
    let name = path.basename(file, '.svg') + suffix;
    values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
  });
});

export default plugin(function ({ matchComponents, theme }) {
  matchComponents(
    {
      flag: ({ name, fullPath }) => {
        if (!svgCache.has(fullPath)) {
          const content = encodeURIComponent(
            fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, '')
          );

          svgCache.set(fullPath, content);
        }

        const content = svgCache.get(fullPath);

        let aspect = '4 / 3';
        let size = theme('spacing.6');
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
