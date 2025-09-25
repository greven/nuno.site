export const CardStack = {
  mounted() {
    this.container = this.el.querySelector("[data-part='card-container']");
    this.cards = Array.from(this.container.children);
    this.maxStack = this.el.dataset.maxStack ? parseInt(this.el.dataset.maxStack, 10) : 3;
    this.totalCards = this.cards.length;
    this.currentIndex = 0;

    this.updateCards();
  },

  updateCards() {
    this.cards.forEach((card, index) => {
      const offset = index - this.currentIndex;

      // Only show `this.maxStack` cards
      if (offset < 0 || offset >= this.maxStack) {
        card.style.opacity = '0';
        card.style.pointerEvents = 'none';
        card.style.transform = 'translateY(0px) scale(0.8)';
        card.style.zIndex = '0';
        return;
      }

      // Current card (fully visible)
      if (offset === 0) {
        card.style.transform = 'translateY(0px) scale(1)';
        card.style.zIndex = this.totalCards;
        card.style.opacity = '1';
        card.style.pointerEvents = 'auto';
        return;
      }

      // Cards below progressively smaller and with lower z-index
      const scale = Math.max(0.8, 1 - offset * 0.05);
      const translateY = offset * 12.5;
      const zIndex = this.totalCards - offset;

      card.style.transform = `translateY(${translateY}px) scale(${scale})`;
      card.style.zIndex = zIndex;
      card.style.opacity = '1';
      card.style.pointerEvents = 'none';
    });
  },
};
