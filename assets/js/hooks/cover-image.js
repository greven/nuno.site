import { getDominantColor } from '../helpers/color-utils.js';

const CACHE_PREFIX = 'ns-album-color';
const CACHE_TTL = 30 * 24 * 60 * 60 * 1000; // 30 days

export const CoverImage = {
  mounted() {
    this.initWorker();
    this.extractDominantColor();
  },

  updated() {
    this.extractDominantColor();
  },

  destroyed() {
    if (this.worker) {
      this.worker.terminate();
    }
  },

  initWorker() {
    if (typeof Worker !== 'undefined' && !this.worker) {
      try {
        this.worker = new Worker(new URL('/assets/js/workers/color.worker.js', import.meta.url), {
          type: 'module',
        });

        this.worker.onmessage = (e) => {
          const { color, error } = e.data;
          if (error) {
            console.error('Worker processing error:', error);
            this.useMainThread = true;
            return;
          }

          const imgSrc = this.el.querySelector('img')?.src;
          if (imgSrc) {
            this.cacheColorExtraction(imgSrc, color);
          }

          this.applyColor(color);
        };

        this.worker.onerror = (error) => {
          console.error('Worker error:', error);
          this.useMainThread = true;
        };
      } catch (error) {
        console.error('Failed to initialize worker:', error);
        this.useMainThread = true;
      }
    } else {
      this.useMainThread = true;
    }
  },

  extractDominantColor() {
    const img = this.el.querySelector('img');
    if (!img) return;

    // Check cache first
    const cachedColor = this.getCachedColor(img.src);
    if (cachedColor) {
      this.applyColor(cachedColor);
      return;
    }

    // If not cached and once loaded, process the image
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

      if (this.worker && !this.useMainThread) {
        this.worker.postMessage({
          data: imageData.data,
          width: imageData.width,
          height: imageData.height,
        });
      } else {
        const color = getDominantColor(imageData.data);
        this.applyColor(color);
      }
    } catch (e) {
      console.error('Error extracting color:', e);
    }
  },

  applyColor(color) {
    this.el.style.setProperty('--album-shadow-color', `${color.r}, ${color.g}, ${color.b}`);
    this.el.classList.add('album-shadow');
  },

  // Cache

  getCachedColor(imageUrl) {
    try {
      const cacheKey = `${CACHE_PREFIX}:${imageUrl}`;
      const cached = localStorage.getItem(cacheKey);

      if (!cached) return null;

      const entry = JSON.parse(cached);

      // Check if expired
      const now = Date.now();
      if (now - entry.timestamp > CACHE_TTL) {
        localStorage.removeItem(cacheKey);
        return null;
      }

      return entry.color;
    } catch (e) {
      console.error('Error reading color cache:', e);
      return null;
    }
  },

  cacheColorExtraction(imageUrl, color) {
    try {
      const cacheKey = `${CACHE_PREFIX}:${imageUrl}`;
      const entry = { color: color, timestamp: Date.now() };

      localStorage.setItem(cacheKey, JSON.stringify(entry));
      this.cleanupCache();
    } catch (e) {
      if (e.name === 'QuotaExceededError') {
        this.cleanupCache();
      } else {
        console.error('Error setting color cache:', e);
      }
    }
  },

  cleanupCache(force = false) {
    try {
      const keys = Object.keys(localStorage);
      const colorCacheKeys = keys.filter((key) => key.startsWith(CACHE_PREFIX));

      // Only cleanup if we have many entries or forced
      if (!force && colorCacheKeys.length < 100) return;

      const now = Date.now();
      const entries = colorCacheKeys.map((key) => {
        try {
          const entry = JSON.parse(localStorage.getItem(key));
          return { key, timestamp: entry.timestamp };
        } catch {
          return { key, timestamp: 0 };
        }
      });

      // Sort by timestamp (oldest first)
      entries.sort((a, b) => a.timestamp - b.timestamp);

      // Remove oldest 20% or expired entries
      const removeCount = force ? Math.ceil(entries.length * 0.5) : Math.ceil(entries.length * 0.2);

      entries.slice(0, removeCount).forEach(({ key, timestamp }) => {
        if (force || now - timestamp > CACHE_TTL) {
          localStorage.removeItem(key);
        }
      });
    } catch (e) {
      console.error('Error cleaning up color cache:', e);
    }
  },
};
