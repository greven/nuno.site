export const Dialog = {
  mounted() {
    this.isOpen = this.el.hasAttribute('open');
    this.closeOnClickOutside = this.el.hasAttribute('data-close-on-click-outside');

    // Event handlers
    this.showHandler = this.show.bind(this);
    this.hideHandler = this.hide.bind(this);
    this.toggleHandler = this.toggle.bind(this);
    this.closeHandler = this.handleClose.bind(this);
    this.clickOutsideHandler = this.handleClickOutside.bind(this);

    window.addEventListener('show-dialog', this.showHandler);
    window.addEventListener('hide-dialog', this.hideHandler);
    window.addEventListener('toggle-dialog', this.toggleHandler);

    // Close on click outside
    this.el.addEventListener('click', this.clickOutsideHandler);

    // Close events
    this.el.addEventListener('close', this.closeHandler);
    this.el.addEventListener('cancel', this.closeHandler);

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

  destroyed() {
    // Remove event listeners
    if (this.showHandler) {
      window.removeEventListener('show-dialog', this.showHandler);
    }
    if (this.hideHandler) {
      window.removeEventListener('hide-dialog', this.hideHandler);
    }
    if (this.toggleHandler) {
      window.removeEventListener('toggle-dialog', this.toggleHandler);
    }
    if (this.clickOutsideHandler) {
      this.el.removeEventListener('click', this.clickOutsideHandler);
    }
    if (this.closeHandler) {
      this.el.removeEventListener('close', this.closeHandler);
      this.el.removeEventListener('cancel', this.closeHandler);
    }

    // Disconnect observer
    if (this.openObserver) {
      this.openObserver.disconnect();
    }

    // Cleanup body overflow
    document.documentElement.removeAttribute('data-dialog-open');
    document.body.style.removeProperty('overflow');
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
    document.body.style.removeProperty('overflow');
  },

  handleOpenMutation() {
    this.isOpen = this.el.hasAttribute('open');

    if (this.isOpen) {
      // Add an attribute to mark the drawer is open
      document.documentElement.setAttribute('data-dialog-open', '');
      // Prevent body scroll when drawer is open
      document.body.style.overflow = 'hidden';
    } else {
      document.documentElement.removeAttribute('data-dialog-open');
      document.body.style.removeProperty('overflow');
    }
  },

  handleClickOutside(event) {
    if (
      (this.closeOnClickOutside && event.target === this.el) ||
      event.target.getAttribute('data-part') === 'dialog-container'
    ) {
      this.el.close('dismiss');
    }
  },
};
