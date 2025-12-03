export const CoverImage = {
  // TODO: Instead of extracting just the dominant color, extract a palette of colors of the 3 most dominant colors
  // TODO: Check other implementations / libraries, like Vibrant.js or Color Thief, for better color extraction algorithms
  // TODO: For the cover image, instead of just a shadow, consider generating a gradient background using the extracted colors
  // TODO: In order to improve performance, consider caching the extracted colors based on image URL or a hash of the image data
  // TODO: Add error handling for cases where image loading fails or canvas operations are not supported
  // TODO: Add unit tests for the color extraction logic to ensure accuracy and reliability
  // TODO: Optimize the sampling strategy to balance performance and color accuracy, possibly using adaptive sampling based on image complexity
  // TODO: Consider using Web Workers for offloading the color extraction process to avoid blocking the main thread

  mounted() {
    this.extractDominantColor();
  },

  updated() {
    this.extractDominantColor();
  },

  extractDominantColor() {
    const img = this.el.querySelector('img');
    if (!img) return;

    if (!img.complete) {
      img.addEventListener('load', () => this.processImage(img), { once: true });
    } else {
      this.processImage(img);
    }
  },

  processImage(img) {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');

    canvas.width = 50;
    canvas.height = 50;

    ctx.drawImage(img, 0, 0, 50, 50);

    try {
      const imageData = ctx.getImageData(0, 0, 50, 50);
      const color = this.getDominantColor(imageData.data);

      // Apply shadow with dominant color
      this.el.style.setProperty('--album-shadow-color', `${color.r}, ${color.g}, ${color.b}`);
      this.el.classList.add('album-shadow');
    } catch (e) {
      console.error('Error extracting color:', e);
    }
  },

  getDominantColor(data) {
    const colorScores = [];

    // Sample every 4th pixel for performance
    for (let i = 0; i < data.length; i += 16) {
      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];
      const a = data[i + 3];

      // Skip transparent pixels
      if (a < 125) continue;

      // Calculate luminance (brightness)
      const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

      // Skip very dark (< 15%) or very light (> 85%) colors
      if (luminance < 0.15 || luminance > 0.85) continue;

      // Calculate saturation (how colorful vs grayscale)
      const max = Math.max(r, g, b);
      const min = Math.min(r, g, b);
      const saturation = max === 0 ? 0 : (max - min) / max;

      // Skip low saturation colors (grayscale-ish)
      if (saturation < 0.3) continue;

      // Prefer vibrant colors with good saturation
      const score = saturation * (1 - Math.abs(luminance - 0.5));

      colorScores.push({
        r,
        g,
        b,
        score,
        key: `${r},${g},${b}`,
      });
    }

    if (colorScores.length === 0) {
      // Fallback if no accent colors found
      return { r: 128, g: 128, b: 128 };
    }

    // Group similar colors and sum their scores
    const colorGroups = {};
    const tolerance = 30; // Group colors within this RGB distance

    for (const color of colorScores) {
      let grouped = false;

      for (const [groupKey, group] of Object.entries(colorGroups)) {
        const [gr, gg, gb] = groupKey.split(',').map(Number);
        const distance = Math.sqrt(
          Math.pow(color.r - gr, 2) + Math.pow(color.g - gg, 2) + Math.pow(color.b - gb, 2)
        );

        if (distance < tolerance) {
          group.score += color.score;
          group.count += 1;
          grouped = true;
          break;
        }
      }

      if (!grouped) {
        colorGroups[color.key] = {
          r: color.r,
          g: color.g,
          b: color.b,
          score: color.score,
          count: 1,
        };
      }
    }

    // Find the color group with highest combined score
    let bestColor = { r: 128, g: 128, b: 128 };
    let maxScore = 0;

    for (const group of Object.values(colorGroups)) {
      if (group.score > maxScore) {
        maxScore = group.score;
        bestColor = { r: group.r, g: group.g, b: group.b };
      }
    }

    return bestColor;
  },
};
