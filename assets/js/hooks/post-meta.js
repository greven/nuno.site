// Create and style the floating element
const appendFloatingElement = (el, diff) => {
  const floatingNumber = document.createElement('span');
  floatingNumber.textContent = diff > 0 ? `+${diff}` : diff;
  floatingNumber.style.cssText = `
      position: absolute;
      font-size: 0.85rem;
      opacity: 1;
      transform: translateY(0);
      transition: opacity 1s ease-out, transform 1s ease-out;
      color: ${diff > 0 ? 'var(--color-success)' : 'var(--color-danger)'};
      pointer-events: none;
    `;

  // Animation
  setTimeout(() => {
    floatingNumber.style.opacity = '0';
    floatingNumber.style.transform = 'translateY(-20px)';
    setTimeout(() => floatingNumber.remove(), 1000);
  }, 10);

  el.style.position = 'relative';
  el.appendChild(floatingNumber);
};

export const PostMeta = {
  mounted() {
    this.viewsEl = this.el.querySelector('[data-views-count]');
    this.readersEl = this.el.querySelector('[data-readers-count]');

    // Event handling
    this.handleEvent('presence', this.handleReadersRender.bind(this));
    this.handleEvent(`page-views:${window.location.pathname}`, this.handleMetricsRender.bind(this));
  },

  handleReadersRender({ diff }) {
    if (!diff || diff === 0) return;

    appendFloatingElement(this.readersEl, diff);
  },

  handleMetricsRender({ diff }) {
    if (!diff || diff === 0) return;

    appendFloatingElement(this.viewsEl, diff);
  },
};
