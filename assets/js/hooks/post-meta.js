export const PostMeta = {
  mounted() {
    this.countEl = this.el.querySelector('[data-readers-count]');
    this.handleEvent('presence', this.handleRender.bind(this));
  },

  handleRender({ diff }) {
    if (!diff || diff === 0) return;

    // Create the floating element
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

    this.countEl.style.position = 'relative';
    this.countEl.appendChild(floatingNumber);

    // Animate
    setTimeout(() => {
      floatingNumber.style.opacity = '0';
      floatingNumber.style.transform = 'translateY(-20px)';
      setTimeout(() => floatingNumber.remove(), 1000);
    }, 10);
  },
};
