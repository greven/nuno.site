export const SharePost = {
  mounted() {
    this.button = this.el.querySelector('button');

    if (!this.button) return;

    // Check if Web Share API is supported
    this.supportsNativeShare = navigator.share && navigator.canShare;

    if (!this.supportsNativeShare) {
      this.button.setAttribute('disabled', true);
      return;
    }

    this.handleShare = async (event) => {
      event.preventDefault();
      event.stopPropagation();

      const shareData = this.getShareData();

      // Check if the data can be shared before attempting
      if (navigator.canShare && !navigator.canShare(shareData)) {
        console.warn('Data cannot be shared');
        return;
      }

      try {
        await navigator.share(shareData);
      } catch (error) {
        if (error.name !== 'AbortError') {
          console.error('Share failed:', error);
        }
      }
    };

    this.button.addEventListener('click', this.handleShare);
  },

  destroyed() {
    if (this.button && this.handleShare) {
      this.button.removeEventListener('click', this.handleShare);
    }
  },

  getShareData() {
    const title = this.el.dataset.title || document.title;
    const text = this.el.dataset.text || '';
    const url = this.el.dataset.url || window.location.href;

    return { title, text, url };
  },
};
