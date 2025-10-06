export const Dialog = {
  mounted() {
    this.isOpen = this.el.hasAttribute('open');
    this.closeOnClickOutside = this.el.hasAttribute('data-close-on-click-outside');

    window.addEventListener('show-dialog', this.show.bind(this));
    window.addEventListener('hide-dialog', this.hide.bind(this));
    window.addEventListener('toggle-dialog', this.toggle.bind(this));

    // Close on click outside
    this.el.addEventListener('click', this.handleClickOutside.bind(this));

    // Close events
    this.el.addEventListener('close', this.handleClose.bind(this));
    this.el.addEventListener('cancel', this.handleClose.bind(this));

    // Oberve open attribute changes (since there's no open event)
    this.openObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === 'open') {
          this.handleOpenMutation(mutation);
        }
      });
    });

    this.openObserver.observe(this.el, { attributes: true });
  },

  destroy() {
    // Remove event listeners
    window.removeEventListener('show-dialog', this.show.bind(this));
    window.removeEventListener('hide-dialog', this.hide.bind(this));
    window.removeEventListener('toggle-dialog', this.toggle.bind(this));
    this.el.removeEventListener('click', this.handleClickOutside.bind(this));
    this.el.removeEventListener('close', this.handleClose.bind(this));
    this.el.removeEventListener('cancel', this.handleClose.bind(this));
  },

  show(event) {
    event.target?.showModal();
  },

  hide(event) {
    event.target?.close();
  },

  toggle() {
    if (this.isOpen) {
      this.el.close();
    } else {
      this.el.showModal();
    }
  },

  handleClose() {
    // Remove the attribute that marks a dialog is open
    document.documentElement.removeAttribute('data-dialog-open');
  },

  handleOpenMutation() {
    this.isOpen = this.el.hasAttribute('open');

    // Add an attribute to mark the dialog is open for browsers that don't support :has()
    document.documentElement.setAttribute('data-dialog-open', '');
  },

  handleClickOutside(event) {
    if (this.closeOnClickOutside && event.target.getAttribute('data-part') === 'dialog-container') {
      this.el.close('dismiss');
    }
  },
};
