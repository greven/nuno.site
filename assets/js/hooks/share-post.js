export const SharePost = {
  mounted() {
    this.button = this.el.querySelector('button');

    if (this.button) {
      this.button.addEventListener('click', this.handleShare.bind(this));
    }

    // Check if Web Share API is supported
    this.supportsNativeShare = navigator.share && navigator.canShare;
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

  handleShare() {
    event.preventDefault();

    console.log(this.getShareData());
  },
};
