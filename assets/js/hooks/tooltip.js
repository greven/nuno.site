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

    this.anchor.addEventListener('mouseenter', this.handleEnter.bind(this));
    this.anchor.addEventListener('mouseleave', this.handleLeave.bind(this));

    // DEBUG: REMOVE
    // this.tooltip.showPopover();
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
