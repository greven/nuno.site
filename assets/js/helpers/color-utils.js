/**
 * Extract dominant color from image pixel data
 * @param {Uint8ClampedArray} data - Image pixel data from canvas.getImageData()
 * @returns {Object} Color object with r, g, b properties
 */
export function getDominantColor(data) {
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
}

/**
 * Extract a palette of dominant colors from image pixel data
 * @param {Uint8ClampedArray} data - Image pixel data from canvas.getImageData()
 * @param {number} count - Number of colors to extract (default: 3)
 * @returns {Array} Array of color objects with r, g, b, saturation, luminance properties
 */
export function extractColorPalette(data, count = 3) {
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
      saturation,
      luminance,
      key: `${r},${g},${b}`,
    });
  }

  if (colorScores.length === 0) {
    // Fallback if no accent colors found
    return [{ r: 128, g: 128, b: 128 }];
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
        // Keep the most vibrant color in the group
        if (color.saturation > group.saturation) {
          group.r = color.r;
          group.g = color.g;
          group.b = color.b;
          group.saturation = color.saturation;
          group.luminance = color.luminance;
        }
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
        saturation: color.saturation,
        luminance: color.luminance,
        count: 1,
      };
    }
  }

  // Sort color groups by score and return top N
  const sortedColors = Object.values(colorGroups)
    .sort((a, b) => b.score - a.score)
    .slice(0, count)
    .map(({ r, g, b, saturation, luminance }) => ({
      r,
      g,
      b,
      saturation,
      luminance,
    }));

  // Ensure we have distinct colors by checking minimum distance between selected colors
  const distinctColors = [sortedColors[0]];
  const minDistinctDistance = 50;

  for (let i = 1; i < sortedColors.length; i++) {
    const candidate = sortedColors[i];
    let isDistinct = true;

    for (const existing of distinctColors) {
      const distance = Math.sqrt(
        Math.pow(candidate.r - existing.r, 2) +
          Math.pow(candidate.g - existing.g, 2) +
          Math.pow(candidate.b - existing.b, 2)
      );

      if (distance < minDistinctDistance) {
        isDistinct = false;
        break;
      }
    }

    if (isDistinct) {
      distinctColors.push(candidate);
      if (distinctColors.length >= count) break;
    }
  }

  return distinctColors;
}
