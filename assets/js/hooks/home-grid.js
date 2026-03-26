export const HomeGrid = {
  mounted() {
    this.items = this.el.querySelectorAll('[data-part="card"]');
    this.gridLabel = this.el.querySelector('#grid-label');

    // Events Handlers
    this.handleMouseEnter = (event) => this.onMouseEnter(event);
    this.handleMouseLeave = (event) => this.onMouseLeave(event);

    // Event Listeners
    this.items.forEach((item) => {
      item.addEventListener('mouseenter', this.handleMouseEnter);
      item.addEventListener('mouseleave', this.handleMouseLeave);
    });
  },

  destroyed() {
    this.items.forEach((item) => {
      item.removeEventListener('mouseenter', this.handleMouseEnter);
      item.removeEventListener('mouseleave', this.handleMouseLeave);
    });
  },

  onMouseEnter(event) {
    const card = event.currentTarget;
    const description = card?.getAttribute('data-description');
    if (!description) return;

    this.gridLabel.textContent = description;
  },

  onMouseLeave(event) {
    this.gridLabel.textContent = '';
  },
};
