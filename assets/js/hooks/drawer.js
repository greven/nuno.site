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
    this.cancelHandler = this.handleCancel.bind(this);

    // Register event listeners
    window.addEventListener('show-drawer', this.showHandler);
    window.addEventListener('hide-drawer', this.hideHandler);
    window.addEventListener('toggle-drawer', this.toggleHandler);

    // Close on click outside
    this.el.addEventListener('click', this.clickOutsideHandler);

    // Close events
    this.el.addEventListener('close', this.closeHandler);
    // Intercept cancel (Escape) to animate before closing
    this.el.addEventListener('cancel', this.cancelHandler);

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
    }
    if (this.cancelHandler) {
      this.el.removeEventListener('cancel', this.cancelHandler);
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
      // Cancel any in-progress close animation
      delete this.el.dataset.closing;
      clearTimeout(this._closeFallbackTimer);

      const container = this.el.querySelector('[data-part="drawer-container"]');
      const position = this.el.dataset.position;

      if (container) {
        // Force the container to its closed (offscreen) transform before opening
        const closedTransforms = {
          left: 'translateX(-100%)',
          right: 'translateX(100%)',
          top: 'translateY(-100%)',
          bottom: 'translateY(100%)',
        };
        container.style.transform = closedTransforms[position] || '';
        // Force a reflow so the transform is painted before the transition starts
        container.getBoundingClientRect();
      }

      this.el.showModal();

      // Remove the forced inline style in the next frame so the CSS transition
      // animates from the closed position to the open (translated-to-zero) position
      requestAnimationFrame(() => {
        if (container) {
          container.style.transform = '';
        }
      });
    }
  },

  hide(event) {
    // Check if the event is targeting this specific drawer
    if (event.target === this.el || event.target?.id === this.el.id) {
      if (!this.isOpen) return;
      this.animateClose();
    }
  },

  toggle() {
    if (this.isOpen) {
      this.animateClose();
    } else {
      this.el.showModal();
    }
  },

  handleCancel(event) {
    event.preventDefault();
    this.animateClose();
  },

  handleClose() {
    // Cleanup when drawer actually closes
    document.documentElement.removeAttribute('data-drawer-open');
    document.body.style.removeProperty('overflow');
    delete this.el.dataset.closing;
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
      this.animateClose();
    }
  },

  animateClose() {
    let closed = false;

    const finishClose = () => {
      if (closed) return;
      closed = true;

      clearTimeout(this._closeFallbackTimer);
      this.el.close();
    };

    // Fallback: if transitionend never fires, close after a short delay
    this._closeFallbackTimer = setTimeout(finishClose, 300);

    const container = this.el.querySelector('[data-part="drawer-container"]');
    const position = this.el.dataset.position;

    if (container) {
      // Set the exit transform direction
      const exitTransforms = {
        left: 'translateX(-100%)',
        right: 'translateX(100%)',
        top: 'translateY(-100%)',
        bottom: 'translateY(100%)',
      };
      container.style.transform = exitTransforms[position] || '';

      container.addEventListener('transitionend', finishClose, { once: true });
    } else {
      setTimeout(finishClose, 200);
    }
  },
};
