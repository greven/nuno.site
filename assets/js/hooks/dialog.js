export const Dialog = {
  mounted() {
    this.closeOnClickOutside = this.el.hasAttribute('data-close-on-click-outside');

    window.addEventListener('show-dialog', this.show.bind(this));
    window.addEventListener('hide-dialog', this.hide.bind(this));

    // Close on click outside
    this.el.addEventListener('click', this.handleClickOutside.bind(this));
  },

  destroy() {
    // Remove event listeners
    window.removeEventListener('show-dialog', this.show.bind(this));
    window.removeEventListener('hide-dialog', this.hide.bind(this));
    this.el.removeEventListener('click', this.handleClickOutside.bind(this));
  },

  show(event) {
    event.target?.showModal();
  },

  hide(event) {
    event.target?.close();
  },

  handleClickOutside(event) {
    if (this.closeOnClickOutside && event.target.getAttribute('data-part') === 'dialog-container') {
      this.el.close('dismiss');
    }
  },
};
