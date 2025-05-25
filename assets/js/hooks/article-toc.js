export const TableOfContents = {
  mounted() {
    // TOC list items
    this.tocItems = Array.from(this.el.querySelectorAll('ol li a'));
    if (this.tocItems.length === 0) return;

    // TOC List and Navigator
    this.container = document.getElementById('toc-container');
    this.navigator = document.getElementById('toc-navigator');

    // Set initial position based on screen size
    this.setInitialPosition();

    // Document Header links
    this.headings = this.tocItems
      .map((item) => {
        const id = item.getAttribute('href').replace('#', '');
        return document.getElementById(id);
      })
      .filter(Boolean);

    this.observer = new IntersectionObserver(this.handleIntersection.bind(this), {
      root: null,
      threshold: [0, 0.5, 1],
    });

    // Observe all headings
    this.headings.forEach((heading) => {
      this.observer.observe(heading);
    });

    this.currentActive = null;
    this.lastScrollTop = window.scrollY;
    this.hideTimeout = null;
    this.isVisible = false;

    this.checkPosition();
    this.setupEventListeners();
  },

  destroyed() {
    // Clean up the observer when the hook is destroyed
    if (this.observer) {
      this.headings.forEach((heading) => {
        if (heading) this.observer.unobserve(heading);
      });
      this.observer.disconnect();
    }

    // Remove all event listeners
    window.removeEventListener('scroll', this.handleScroll.bind(this));
    window.removeEventListener('resize', this.handleResize.bind(this));
    this.navigator.removeEventListener('mouseenter', this.handleDesktopMouseEnter.bind(this));
    this.container.removeEventListener('mouseenter', this.handleDesktopTocMouseEnter.bind(this));
    this.container.removeEventListener('mouseleave', this.handleDesktopTocMouseLeave.bind(this));
    this.navigator.removeEventListener('click', this.handleMobileClick.bind(this));
    document.removeEventListener('click', this.handleOutsideClick.bind(this));
    document.removeEventListener('keydown', this.handleKeydown.bind(this));
  },

  setupEventListeners() {
    // Add event listener to hide ToC
    this.el.addEventListener('hide_toc', this.hideToc.bind(this));

    // Add scroll event listener to detect direction
    window.addEventListener('scroll', this.handleScroll.bind(this), { passive: true });

    // Handle window resize to adjust initial position
    window.addEventListener('resize', this.handleResize.bind(this));

    // Desktop: hover events for larger screens
    this.navigator.addEventListener('mouseenter', this.handleDesktopMouseEnter.bind(this));
    this.container.addEventListener('mouseenter', this.handleDesktopTocMouseEnter.bind(this));
    this.container.addEventListener('mouseleave', this.handleDesktopTocMouseLeave.bind(this));

    // Mobile: click events for smaller screens
    this.navigator.addEventListener('click', this.handleMobileClick.bind(this));

    // Close TOC when clicking outside on mobile
    document.addEventListener('click', this.handleOutsideClick.bind(this));

    // Handle escape key to close TOC
    document.addEventListener('keydown', this.handleKeydown.bind(this));
  },

  checkPosition() {
    // Find the topmost visible heading
    const visibleHeadings = this.headings.filter((heading) => {
      const rect = heading.getBoundingClientRect();
      return rect.top >= 0 && rect.top <= window.innerHeight / 2;
    });

    if (visibleHeadings.length > 0) {
      // Activate the first visible heading
      const firstVisible = visibleHeadings[0];
      this.activateHeading(firstVisible.id);
    } else if (this.headings.length > 0) {
      // If no visible headings, check if we're already past some headings
      const pastHeadings = this.headings.filter((heading) => {
        return heading.getBoundingClientRect().top < 0;
      });

      if (pastHeadings.length > 0) {
        // Activate the last heading we've scrolled past
        this.activateHeading(pastHeadings[pastHeadings.length - 1].id);
      } else {
        // We're before all headings, activate the first one
        this.activateHeading(this.headings[0].id);
      }
    }
  },

  activateHeading(headingId) {
    // Skip if already active
    if (this.currentActive === headingId) return;

    this.currentActive = headingId;

    this.tocItems.forEach((item) => {
      const href = item.getAttribute('href').replace('#', '');
      const li = item.closest('li');

      if (href === headingId) {
        li.setAttribute('data-active', '');
      } else {
        li.removeAttribute('data-active');
      }
    });
  },

  handleIntersection(entries) {
    this.checkPosition();
  },

  handleScroll() {
    const scrollTop = window.scrollY;
    this.isScrollingDown = scrollTop > this.lastScrollTop;
    this.lastScrollTop = scrollTop;
  },

  // Check if we're on mobile (smaller than Tailwind's `sm` breakpoint)
  isMobile() {
    return window.innerWidth < 640;
  },

  setInitialPosition() {
    this.container.style.opacity = '0';

    if (this.isMobile()) {
      // Mobile: initially hidden below viewport
      this.container.style.transform = 'translateY(400px)';
    } else {
      // Desktop: initially hidden to the right
      this.container.style.transform = 'translateX(500px)';
    }
  },

  handleResize() {
    // Reset position when switching between mobile/desktop
    if (!this.isVisible) {
      this.setInitialPosition();
    }
  },

  showToc() {
    if (this.isVisible) return;

    this.isVisible = true;
    this.navigator.style.opacity = '0';
    this.container.style.opacity = '1';
    this.container.removeAttribute('inert');

    if (this.isMobile()) {
      // Mobile: slide up from bottom
      this.container.style.transform = 'translateY(0)';
    } else {
      // Desktop: slide in from right
      this.container.style.transform = 'translateX(0)';
    }
  },

  hideToc() {
    if (!this.isVisible) return;

    this.isVisible = false;
    this.navigator.style.opacity = '1';
    this.container.setAttribute('inert', '');

    if (this.isMobile()) {
      // Mobile: slide down to bottom
      this.container.style.transform = 'translateY(400px)';
    } else {
      // Desktop: slide out to right
      this.container.style.transform = 'translateX(500px)';
    }
  },

  // Desktop event handlers
  handleDesktopMouseEnter() {
    if (this.isMobile()) return; // Don't handle on mobile
    this.showToc();
  },

  handleDesktopTocMouseEnter() {
    if (this.isMobile()) return; // Don't handle on mobile

    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout);
      this.hideTimeout = null;
    }
  },

  handleDesktopTocMouseLeave() {
    if (this.isMobile()) return; // Don't handle on mobile

    // Clear any existing timeout to prevent multiple triggers
    if (this.hideTimeout) clearTimeout(this.hideTimeout);

    this.hideTimeout = setTimeout(() => {
      this.hideToc();
    }, 750);
  },

  // Mobile event handlers
  handleMobileClick(event) {
    if (!this.isMobile()) return; // Don't handle on desktop

    event.preventDefault();
    event.stopPropagation();

    if (this.isVisible) {
      this.hideToc();
    } else {
      this.showToc();
    }
  },

  handleOutsideClick(event) {
    if (!this.isMobile() || !this.isVisible) return;

    // Check if click is outside the TOC container and navigator
    if (!this.container.contains(event.target) && !this.navigator.contains(event.target)) {
      this.hideToc();
    }
  },

  handleKeydown(event) {
    if (!this.isMobile() || !this.isVisible) return;

    // Close TOC on Escape key
    if (event.key === 'Escape') {
      this.hideToc();
    }
  },
};
