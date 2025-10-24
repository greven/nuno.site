export const Image = {
  mounted() {
    this.useBlur = this.el.hasAttribute('data-src-blur');
    this.blurPath = this.el.getAttribute('data-src-blur');

    this.setImageBlur();

    // Load and error events
    this.el.addEventListener('load', this.onLoad.bind(this), { once: true });
    this.el.addEventListener('error', this.onError.bind(this), { once: true });
  },

  // If the image has a blur path, set it as background as a placeholder
  // while the image loads, which will be removed on load event
  setImageBlur() {
    if (this.useBlur && this.blurPath) {
      this.el.style.backgroundImage = `url(${this.blurPath})`;
      this.el.style.backgroundSize = 'cover';
      this.el.style.backgroundRepeat = 'no-repeat';
      this.el.style.backgroundPosition = 'center';
      this.el.style.transition = 'opacity 0.5s ease-out';
    }
  },

  removeImageBlur() {
    this.el.style.backgroundImage = 'none';
  },

  onError() {
    if (this.useBlur) {
      this.removeImageBlur();
    }

    // Fallback placeholder
    this.el.src = 'data:image/gif;base64,R0lGODlhAQABAAAAACwAAAAAAQABAAA=';
    this.el.setAttribute('alt', 'Image not found');
    this.el.setAttribute('data-error', true);
  },

  onLoad() {
    if (this.useBlur) {
      this.removeImageBlur();
    }
  },
};
