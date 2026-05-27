export const Dialog = {
  mounted() {
    this.isOpen = this.el.hasAttribute('open');
    this.closeOnClickOutside = this.el.hasAttribute('data-close-on-click-outside');

    this.showHandler = this.show.bind(this);
    this.hideHandler = this.hide.bind(this);
    this.toggleHandler = this.toggle.bind(this);
    this.closeHandler = this.handleClose.bind(this);
    this.cancelHandler = this.handleCancel.bind(this);
    this.clickOutsideHandler = this.handleClickOutside.bind(this);

    window.addEventListener('show-dialog', this.showHandler);
    window.addEventListener('hide-dialog', this.hideHandler);
    window.addEventListener('toggle-dialog', this.toggleHandler);

    this.el.addEventListener('click', this.clickOutsideHandler);
    this.el.addEventListener('close', this.closeHandler);
    this.el.addEventListener('cancel', this.cancelHandler);

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
    if (this.showHandler) window.removeEventListener('show-dialog', this.showHandler);
    if (this.hideHandler) window.removeEventListener('hide-dialog', this.hideHandler);
    if (this.toggleHandler) window.removeEventListener('toggle-dialog', this.toggleHandler);
    if (this.clickOutsideHandler) this.el.removeEventListener('click', this.clickOutsideHandler);
    if (this.closeHandler) this.el.removeEventListener('close', this.closeHandler);
    if (this.cancelHandler) this.el.removeEventListener('cancel', this.cancelHandler);

    if (this.openObserver) this.openObserver.disconnect();
    document.documentElement.removeAttribute('data-dialog-open');
    document.body.style.removeProperty('overflow');
  },

  show(event) {
    if (event.target === this.el || event.target?.id === this.el.id) {
      delete this.el.dataset.closing;
      clearTimeout(this._closeFallbackTimer);
      this.el.showModal();
    }
  },

  hide(event) {
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
    document.documentElement.removeAttribute('data-dialog-open');
    document.body.style.removeProperty('overflow');
    delete this.el.dataset.closing;
  },

  handleOpenMutation() {
    this.isOpen = this.el.hasAttribute('open');
    if (this.isOpen) {
      document.documentElement.setAttribute('data-dialog-open', '');
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

    this._closeFallbackTimer = setTimeout(finishClose, 300);
    this.el.dataset.closing = '';

    const panel = this.el.querySelector('[data-part="dialog-panel"]');
    if (panel) {
      if (this._onAnimEnd) {
        panel.removeEventListener('animationend', this._onAnimEnd);
      }

      // Only respond to the panel's OWN animationend ignore bubbled events
      const onAnimEnd = (event) => {
        if (event.target !== panel) return; // ← KEY FIX
        panel.removeEventListener('animationend', onAnimEnd);
        this._onAnimEnd = null;
        finishClose();
      };
      panel.addEventListener('animationend', onAnimEnd);
      this._onAnimEnd = onAnimEnd;
    } else {
      setTimeout(finishClose, 200);
    }
  },
};
