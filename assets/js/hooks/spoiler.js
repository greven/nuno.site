export const Spoiler = {
  mounted() {
    const trigger = this.el.querySelector("[data-part='spoiler-trigger']");
    const content = this.el.querySelector("[data-part='spoiler-content']");
    const overlay = this.el.querySelector("[data-part='spoiler-overlay']");

    this.isOpen = this.el.dataset.open === 'true';

    trigger.addEventListener('click', () => {
      const isExpanded = trigger.getAttribute('aria-expanded') === 'true';

      this.js().setAttribute(this.el, 'data-open', !isExpanded);
      this.js().setAttribute(content, 'aria-expanded', !isExpanded);
      this.js().setAttribute(trigger, 'aria-expanded', !isExpanded);

      if (isExpanded) {
        this.js().removeClass(overlay, 'hidden opacity-0');
      } else {
        this.js().addClass(overlay, 'hidden opacity-0');
      }
    });
  },
};
