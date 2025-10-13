function supportsPopover() {
  return Object.hasOwn(HTMLElement.prototype, 'popover');
}

export const Tooltip = {
  mounted() {
    this.anchor = this.el.querySelector('[data-part="tooltip-anchor"]');
    this.tooltip = document.querySelector(`[data-popover=${this.el.id}]`);

    this.defaultOpened = this.el.hasAttribute('data-default-opened');
    this.openDelay = this.el.dataset.openDelay || 200;
    this.closeDelay = this.el.dataset.closeDelay;

    if (!supportsPopover()) {
      this.js().hide(this.tooltip);
      return;
    }

    this.anchor.addEventListener('mouseenter', this.handleEnter.bind(this));
    this.anchor.addEventListener('mouseleave', this.handleLeave.bind(this));

    if (this.defaultOpened) {
      this.tooltip.showPopover();
    }
  },

  destroyed() {
    this.anchor.removeEventListener('mouseenter', this.handleEnter.bind(this));
    this.anchor.removeEventListener('mouseleave', this.handleLeave.bind(this));
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
