export const Spoiler = {
  mounted() {
    const trigger = this.el.querySelector("[data-part='spoiler-trigger']");
    const content = this.el.querySelector("[data-part='spoiler-content']");
    const overlay = this.el.querySelector("[data-part='spoiler-overlay']");

    this.isOpen = this.el.dataset.open === 'true';

    trigger.addEventListener('click', () => {
      const isExpanded = trigger.getAttribute('aria-expanded') === 'true';
      trigger.setAttribute('aria-expanded', !isExpanded);

      if (isExpanded) {
        this.js().removeClass(overlay, 'opacity-0');
      } else {
        this.js().addClass(overlay, 'opacity-0');
      }

      content.style.maxHeight = isExpanded
        ? this.el.dataset.maxHeight
        : content.scrollHeight + 'px';
    });
  },
};
