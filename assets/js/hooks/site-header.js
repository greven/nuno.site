export const SiteHeader = {
  mounted() {
    this.lastScrollY = window.scrollY;
    this.scrollThreshold = 1200;
    this.showProgress = this.el.getAttribute('data-progress') === 'true';
    this.progressIcon = this.el.querySelector('#page-progress-icon');

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

    // Add/remove data-scrolled attribute
    if (currentScrollY > 0) {
      this.el.setAttribute('data-scrolled', '');
    } else {
      this.el.removeAttribute('data-scrolled');
    }

    this.updateProgress(currentScrollY);
    this.lastScrollY = currentScrollY;
  },

  updateProgress(currentScrollY) {
    if (this.showProgress) {
      const scrollPercentage = this.calculateScrollPercentage(currentScrollY);
      this.el.style.setProperty('--page-progress', `${scrollPercentage}%`);

      if (scrollPercentage > 0 && this.progressIcon) {
        this.progressIcon.classList.remove('hidden');
      } else if (this.progressIcon) {
        this.progressIcon.classList.add('hidden');
      }
    }
  },

  calculateScrollPercentage(currentScrollY) {
    const documentHeight = document.documentElement.scrollHeight;
    const windowHeight = window.innerHeight;
    const maxScrollDistance = documentHeight - windowHeight;

    if (maxScrollDistance <= 0) {
      return 0;
    }

    const percentage = (currentScrollY / maxScrollDistance) * 100;
    return Math.min(Math.max(percentage, 0), 100);
  },
};
