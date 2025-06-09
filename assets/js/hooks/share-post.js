export const SharePost = {
  mounted() {
    this.button = this.el.querySelector('button');

    if (this.button) {
      this.button.addEventListener('click', this.handleShare.bind(this));
    }

    // Check if Web Share API is supported, if not bail out
    this.supportsNativeShare = navigator.share && navigator.canShare;
    if (!this.supportsNativeShare) {
      this.button.setAttribute('disabled', true);
      this.button.removeEventListener('click', this.handleShare.bind(this));
      return;
    }
  },

  destroyed() {
    if (this.button) {
      this.button.removeEventListener('click', this.handleShare.bind(this));
    }
  },

  getShareData() {
    const title = this.el.dataset.title || document.title;
    const text = this.el.dataset.text || '';
    const url = this.el.dataset.url || window.location.href;

    return { title, text, url };
  },

  async handleShare(event) {
    event.preventDefault();
    event.stopPropagation();

    try {
      await navigator.share(this.getShareData());
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Share failed:', error);
      }
    }
  },
};
