export const Tooltip = {
  mounted() {
    this.anchor = document.getElementById(`${this.el.id}-anchor`);
    this.tooltip = document.querySelector(`[data-popover=${this.el.id}]`);

    this.openDelay = this.el.dataset.openDelay || 200;
    this.closeDelay = this.el.dataset.closeDelay;

    const supportsPopover = Object.hasOwn(HTMLElement.prototype, 'popover');

    if (!supportsPopover) {
      this.js().hide(this.tooltip);
      return;
    }

    // Event handlers
    this.enterHandler = this.handleEnter.bind(this);
    this.leaveHandler = this.handleLeave.bind(this);

    this.anchor.addEventListener('mouseenter', this.enterHandler);
    this.anchor.addEventListener('mouseleave', this.leaveHandler);

    // DEBUG: REMOVE
    // this.tooltip.showPopover();
  },

  destroyed() {
    if (this.anchor && this.enterHandler) {
      this.anchor.removeEventListener('mouseenter', this.enterHandler);
    }
    if (this.anchor && this.leaveHandler) {
      this.anchor.removeEventListener('mouseleave', this.leaveHandler);
    }
  },

  handleEnter() {
    setTimeout(() => {
      if (this.anchor.matches(':hover')) {
        this.tooltip.showPopover();
      }
    }, this.openDelay);
  },

  handleLeave() {
    setTimeout(() => {
      if (!this.anchor.matches(':hover')) {
        this.tooltip.hidePopover();
      }
    }, this.closeDelay);
  },
};
