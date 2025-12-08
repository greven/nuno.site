import { getDominantColor } from '../helpers/color-utils.js';

self.onmessage = function (e) {
  const { data } = e.data;

  try {
    const color = getDominantColor(data);
    self.postMessage({ color });
  } catch (error) {
    self.postMessage({ error: error.message });
  }
};
