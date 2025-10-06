import { getTheme, observeThemeChanges } from '../helpers';

export const CardStack = {
  mounted() {
    this.container = this.el.querySelector("[data-part='card-container']");
    this.maxStack = this.el.dataset.maxStack ? parseInt(this.el.dataset.maxStack, 10) : 3;
    this.showNav = this.el.hasAttribute('data-show-nav');
    this.autoplay = this.el.hasAttribute('data-autoplay');
    this.duration = parseInt(this.el.dataset.duration || 5000);

    this.cards = Array.from(this.container.children);
    this.totalItems = this.cards.length;
    this.currentIndex = 0;
    this.isAnimating = false;

    this.theme = getTheme();
    observeThemeChanges((theme) => {
      this.theme = theme;
    });

    if (this.showNav) {
      this.navButtons = Array.from(this.el.querySelectorAll("[data-part='nav-button']"));
      this.navButtons.forEach((button) => {
        button.addEventListener('click', this.handleNavClick.bind(this));
      });
    }

    // Add CSS transitions to all cards
    this.cards.forEach((card) => {
      card.style.transition = 'transform 0.4s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.4s ease-out';
    });

    this.updateCards();
    this.updateNavButtons();
  },

  updateCards() {
    this.cards.forEach((card, index) => {
      const offset = index - this.currentIndex;

      // Items above the max stack are hidden
      if (offset >= this.maxStack) {
        card.style.display = 'none';
        card.style.pointerEvents = 'none';
        card.style.transform = 'translateY(0px) scale(0.8)';
        card.style.zIndex = '0';
      }

      // Items after the current card are hidden (circular stack)
      if (offset < 0) {
        card.style.opacity = '0';
        card.style.pointerEvents = 'none';
        card.style.transform = 'translateY(0px) scale(0.8)';
        card.style.zIndex = '0';
        return;
      }

      // Current card (fully visible)
      if (offset === 0) {
        card.style.transform = 'translateY(0px) scale(1)';
        card.style.zIndex = this.totalItems;
        card.style.pointerEvents = 'auto';
        card.style.filter = 'brightness(100%)';
        card.style.opacity = '1';
        card.inert = false;
        return;
      }

      // Cards below progressively smaller and with lower z-index
      const scale = Math.max(0.8, 1 - offset * 0.05);
      const translateY = offset * 14;
      const zIndex = this.totalItems - offset;
      const brightness =
        this.theme === 'light' ? Math.max(90, 100 - offset * 2.5) : Math.max(40, 100 - offset * 5);

      card.style.transform = `translateY(${translateY}px) scale(${scale})`;
      card.style.zIndex = zIndex;
      card.style.pointerEvents = 'none';
      card.style.opacity = '0.9';
      card.style.filter = `brightness(${brightness}%)`;
      card.inert = true;
    });
  },

  updateNavButtons() {
    if (!this.showNav || !this.navButtons) return;

    this.navButtons.forEach((button) => {
      const index = parseInt(button.dataset.index, 10);
      if (index === this.currentIndex) {
        button.setAttribute('aria-current', 'true');
      } else {
        button.removeAttribute('aria-current');
      }
    });
  },

  nextCard() {
    if (this.isAnimating) return;
    this.isAnimating = true;

    setTimeout(() => {
      this.currentIndex = (this.currentIndex + 1) % this.totalItems;

      this.updateCards();
      this.updateNavButtons();

      setTimeout(() => {
        this.isAnimating = false;
      }, 400);
    }, 100);
  },

  previousCard() {
    if (this.isAnimating) return;
    this.isAnimating = true;

    setTimeout(() => {
      this.currentIndex = (this.currentIndex - 1 + this.totalItems) % this.totalItems;

      this.updateCards();
      this.updateNavButtons();

      setTimeout(() => {
        this.isAnimating = false;
      }, 400);
    }, 100);
  },

  handleNavClick(event) {
    const button = event.currentTarget;
    const index = parseInt(button.dataset.index, 10);
    if (!isNaN(index) && index >= 0 && index < this.totalItems) {
      this.currentIndex = index;
      this.updateCards();
      this.updateNavButtons();
    }
  },
};
