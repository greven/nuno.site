export const SiteHeader = {
  mounted() {
    this.lastScrollY = window.scrollY;
    this.scrollThreshold = 800;

    // Events Handlers
    this.handleScroll = () => this.onScroll();

    this.handleScroll();

    // Event Listeners
    window.addEventListener('scroll', this.handleScroll, { passive: true });
  },

  destroyed() {
    window.removeEventListener('scroll', this.handleScroll);
  },

  onScroll() {
    const currentScrollY = window.scrollY;
    const scrollingDown = currentScrollY > this.lastScrollY;

    // Add/remove data-scrolled attribute
    if (currentScrollY > 0) {
      this.el.setAttribute('data-scrolled', '');
    } else {
      this.el.removeAttribute('data-scrolled');
    }

    // Hide header when scrolling down past threshold
    if (scrollingDown && currentScrollY > this.scrollThreshold) {
      this.el.classList.add('opacity-0');
      this.el.classList.add('pointer-events-none');
    }

    // Show header when scrolling up above threshold
    else if (!scrollingDown && currentScrollY < this.scrollThreshold) {
      this.el.classList.remove('pointer-events-none');
      this.el.classList.remove('opacity-0');
    }

    this.lastScrollY = currentScrollY;
  },
};
