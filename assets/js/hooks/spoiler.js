export const Spoiler = {
  mounted() {
    // Elements
    const trigger = this.el.querySelector("[data-part='spoiler-trigger']");
    const content = this.el.querySelector("[data-part='spoiler-content']");
    const overlay = this.el.querySelector("[data-part='spoiler-overlay']");

    // Check if content exceeds max height
    this.checkOverflow(content, trigger, overlay);

    trigger.addEventListener('click', () => {
      const isExpanded = trigger.getAttribute('aria-expanded') === 'true';

      this.js().setAttribute(this.el, 'data-open', !isExpanded);
      this.js().setAttribute(content, 'aria-expanded', !isExpanded);
      this.js().setAttribute(trigger, 'aria-expanded', !isExpanded);
      this.js().exec(trigger.getAttribute('data-on-click'));

      if (isExpanded) {
        this.js().removeClass(overlay, 'hidden opacity-0');
      } else {
        this.js().addClass(overlay, 'hidden opacity-0');
      }
    });
  },

  checkOverflow(content, trigger, overlay) {
    const contentHeight = content.scrollHeight;

    // Get max height from CSS variable
    const computedStyle = window.getComputedStyle(content);
    const maxHeight = parseFloat(computedStyle.maxHeight) || 0;

    if (contentHeight > maxHeight) {
      this.js().removeClass(trigger, 'hidden');
      this.js().removeClass(overlay, 'hidden opacity-0');
    } else {
      this.js().addClass(trigger, 'hidden');
      this.js().addClass(overlay, 'hidden opacity-0');
    }
  },
};
