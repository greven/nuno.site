export const Layout = {
  mounted() {
    this.updateCSSVariables = this.updateCSSVariables.bind(this)
    this.handleResize = this.handleResize.bind(this)

    // Initial CSS variables update
    this.updateCSSVariables()

    // Set up ResizeObserver for more efficient resize detection
    if (window.ResizeObserver) {
      this.resizeObserver = new ResizeObserver(() => {
        this.updateCSSVariables()
      })

      // Observe the page content element
      const pageContent = document.getElementById('page-content')
      if (pageContent) {
        this.resizeObserver.observe(pageContent)
      }

      // Also observe the body for general layout changes
      this.resizeObserver.observe(document.body)
    } else {
      // Fallback to window resize event
      window.addEventListener('resize', this.handleResize)
    }

    // Also listen for orientation changes on mobile
    window.addEventListener('orientationchange', this.handleResize)
  },

  destroyed() {
    // Clean up observers and event listeners
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    } else {
      window.removeEventListener('resize', this.handleResize)
    }

    window.removeEventListener('orientationchange', this.handleResize)
  },

  updateCSSVariables() {
    const root = document.documentElement

    // Set viewport dimensions
    const viewportWidth = Math.round(window.innerWidth)
    const viewportHeight = Math.round(window.innerHeight)

    root.style.setProperty('--viewport-width', `${viewportWidth}px`)
    root.style.setProperty('--viewport-height', `${viewportHeight}px`)

    // Get page content element
    const pageContent = document.getElementById('page-content')

    if (pageContent) {
      const contentRect = pageContent.getBoundingClientRect()
      const contentWidth = Math.round(contentRect.width)
      const contentHeight = Math.round(contentRect.height)
      const marginWidth = Math.round((viewportWidth - contentWidth) / 2)

      // Set CSS variables for page content dimensions
      root.style.setProperty('--content-width', `${contentWidth}px`)
      root.style.setProperty('--content-height', `${contentHeight}px`)
      root.style.setProperty('--content-margin', `${marginWidth}px`)
    }
  },

  handleResize() {
    // Debounce resize events
    clearTimeout(this.resizeTimeout)
    this.resizeTimeout = setTimeout(() => {
      this.updateCSSVariables()
    }, 16) // ~60fps
  },
}
