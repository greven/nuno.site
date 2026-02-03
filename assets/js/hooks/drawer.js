export const Drawer = {
  mounted() {
    this.isOpen = this.el.hasAttribute('open');
    this.closeOnClickOutside = this.el.hasAttribute('data-close-on-click-outside');

    // Event handlers
    this.showHandler = this.show.bind(this);
    this.hideHandler = this.hide.bind(this);
    this.toggleHandler = this.toggle.bind(this);
    this.clickOutsideHandler = this.handleClickOutside.bind(this);
    this.closeHandler = this.handleClose.bind(this);

    // Register event listeners
    window.addEventListener('show-drawer', this.showHandler);
    window.addEventListener('hide-drawer', this.hideHandler);
    window.addEventListener('toggle-drawer', this.toggleHandler);

    // Close on click outside
    this.el.addEventListener('click', this.clickOutsideHandler);

    // Close events
    this.el.addEventListener('close', this.closeHandler);
    this.el.addEventListener('cancel', this.closeHandler);

    // Observe open attribute changes
    this.openObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === 'open') {
          this.handleOpenMutation();
        }
      });
    });

    this.openObserver.observe(this.el, { attributes: true });
  },

  destroyed() {
    // Cleanup event listeners
    if (this.showHandler) {
      window.removeEventListener('show-drawer', this.showHandler);
    }
    if (this.hideHandler) {
      window.removeEventListener('hide-drawer', this.hideHandler);
    }
    if (this.toggleHandler) {
      window.removeEventListener('toggle-drawer', this.toggleHandler);
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
    document.documentElement.removeAttribute('data-drawer-open');
    document.body.style.removeProperty('overflow');
  },

  show(event) {
    // Check if the event is targeting this specific drawer
    if (event.target === this.el || event.target?.id === this.el.id) {
      this.el.showModal();
    }
  },

  hide(event) {
    // Check if the event is targeting this specific drawer
    if (event.target === this.el || event.target?.id === this.el.id) {
      this.el.close();
    }
  },

  toggle() {
    if (this.isOpen) {
      this.el.close();
    } else {
      this.el.showModal();
    }
  },

  handleClose() {
    // Remove the attribute that marks a drawer is open
    document.documentElement.removeAttribute('data-drawer-open');
    document.body.style.removeProperty('overflow');
  },

  handleOpenMutation() {
    this.isOpen = this.el.hasAttribute('open');

    if (this.isOpen) {
      // Add an attribute to mark the drawer is open
      document.documentElement.setAttribute('data-drawer-open', '');
      // Prevent body scroll when drawer is open
      document.body.style.overflow = 'hidden';
    } else {
      document.documentElement.removeAttribute('data-drawer-open');
      document.body.style.removeProperty('overflow');
    }
  },

  handleClickOutside(event) {
    // Only close if clicking directly on the dialog element (the backdrop area)
    if (this.closeOnClickOutside && event.target === this.el) {
      this.el.close('dismiss');
    }
  },
};
