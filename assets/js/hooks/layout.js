export const Layout = {
  mounted() {
    this.pageContent = document.getElementById('page-content');

    this.updateCSSVariablesHandler = this.updateCSSVariables.bind(this);
    this.resizeHandler = this.handleResize.bind(this);
    this.rafId = null;

    // Initial CSS variable update
    this.updateCSSVariablesHandler();

    // Set up ResizeObserver for resize detection.
    if (window.ResizeObserver) {
      this.resizeObserver = new ResizeObserver(() => {
        if (this.rafId == null) {
          this.rafId = requestAnimationFrame(() => {
            this.rafId = null;
            this.updateCSSVariablesHandler();
          });
        }
      });

      // Observe the page content element
      if (this.pageContent) {
        this.resizeObserver.observe(this.pageContent);
      }

      // Also observe the body for general layout changes
      this.resizeObserver.observe(document.body);
    } else {
      // Fallback to window resize event
      window.addEventListener('resize', this.resizeHandler);
    }

    // Also listen for orientation changes on mobile
    window.addEventListener('orientationchange', this.resizeHandler);
  },

  destroyed() {
    // Cancel any pending update
    if (this.rafId != null) {
      cancelAnimationFrame(this.rafId);
    }

    // Clean up observers and event listeners
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    } else if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler);
    }

    if (this.resizeHandler) {
      window.removeEventListener('orientationchange', this.resizeHandler);
    }
  },

  updateCSSVariables() {
    // Scope the custom property to the page content element so resizes only
    // invalidate its subtree instead of the whole document.
    if (!this.pageContent) return;

    const contentRect = this.pageContent.getBoundingClientRect();
    const contentWidth = Math.round(contentRect.width);

    this.pageContent.style.setProperty('--content-width', `${contentWidth}px`);
  },

  handleResize() {
    // Debounce resize events
    clearTimeout(this.resizeTimeout);
    this.resizeTimeout = setTimeout(() => {
      this.updateCSSVariablesHandler();
    }, 100); // Plenty for layout updates
  },
};
