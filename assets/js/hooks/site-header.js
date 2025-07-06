export const SiteHeader = {
  mounted() {
    this.lastScrollY = window.scrollY
    this.scrollThreshold = 1200

    // Events Handlers
    this.handleScroll = () => this.onScroll()

    this.handleScroll()

    // Event Listeners
    window.addEventListener('scroll', this.handleScroll, { passive: true })
  },

  destroyed() {
    window.removeEventListener('scroll', this.handleScroll)
  },

  onScroll() {
    const currentScrollY = window.scrollY

    // Add/remove data-scrolled attribute
    if (currentScrollY > 0) {
      this.el.setAttribute('data-scrolled', '')
    } else {
      this.el.removeAttribute('data-scrolled')
    }

    this.lastScrollY = currentScrollY
  },
}
