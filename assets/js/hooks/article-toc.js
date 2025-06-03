const DESKTOP_OFFSET_X = 999;
const MOBILE_OFFSET_Y = 999;

export const TableOfContents = {
  mounted() {
    // TOC list items
    this.tocItems = Array.from(this.el.querySelectorAll('ol li a'));
    if (this.tocItems.length === 0) return;

    // TOC List and Navigator
    this.container = document.getElementById('toc-container');
    this.navigator = document.getElementById('toc-navigator');

    this.isVisible = false;
    this.currentActive = null;
    this.lastScrollTop = window.scrollY;
    this.hideTimeout = null;

    // Document Header links
    this.headings = this.tocItems
      .map((item) => {
        const id = item.getAttribute('href').replace('#', '');
        return document.getElementById(id);
      })
      .filter(Boolean);

    // Progressive enhancement: If JS is enable, show the mobile navigator
    const mobileNavigator = document.getElementById('toc-navigator-mobile');
    mobileNavigator.classList.remove('hidden');
    mobileNavigator.classList.add('flex');

    this.positionNavigator();
    this.checkPosition();

    this.setupIntersectionObserver();

    // Setup event listeners
    window.addEventListener('scroll', this.handleScroll.bind(this), { passive: true });
    window.addEventListener('resize', this.handleResize.bind(this));

    document.addEventListener('pointerdown', this.handleOutsideClick.bind(this));
    document.addEventListener('keydown', this.handleKeydown.bind(this));

    this.el.addEventListener('hide-toc', this.hideToc.bind(this));

    this.container.addEventListener('mouseenter', this.handleDesktopTocMouseEnter.bind(this));
    this.container.addEventListener('mouseleave', this.handleDesktopTocMouseLeave.bind(this));

    this.navigator.addEventListener('mouseenter', this.handleNavigatgorMouseEnter.bind(this));
    this.navigator.addEventListener('pointerdown', this.handleNavigatorClick.bind(this));
  },

  destroyed() {
    // Clean up the observer
    if (this.observer) {
      this.headings.forEach((heading) => {
        if (heading) this.observer.unobserve(heading);
      });
      this.observer.disconnect();
    }

    // Clear timeouts
    if (this.hideTimeout) clearTimeout(this.hideTimeout);

    // Remove all event listeners
    window.removeEventListener('scroll', this.handleScroll.bind(this));
    window.removeEventListener('resize', this.handleResize.bind(this));

    document.removeEventListener('pointerdown', this.handleOutsideClick.bind(this));
    document.removeEventListener('keydown', this.handleKeydown.bind(this));

    this.el.removeEventListener('hide-toc', this.hideToc.bind(this));

    this.container?.removeEventListener('mouseenter', this.handleDesktopTocMouseEnter.bind(this));
    this.container?.removeEventListener('mouseleave', this.handleDesktopTocMouseLeave.bind(this));

    this.navigator?.removeEventListener('mouseenter', this.handleNavigatgorMouseEnter.bind(this));
    this.navigator?.removeEventListener('pointerdown', this.handleNavigatorClick.bind(this));
  },

  setupIntersectionObserver() {
    this.observer = new IntersectionObserver(this.handleIntersection.bind(this), {
      root: null,
      threshold: [0, 0.1, 0.5, 0.9, 1],
      rootMargin: '-20px 0px -80% 0px',
    });

    // Observe all headings
    this.headings.forEach((heading) => {
      this.observer.observe(heading);
    });
  },

  checkPosition() {
    const viewportHeight = window.innerHeight;

    // Define a stable activation zone (top 30% of viewport)
    const activationThreshold = viewportHeight * 0.3;

    let targetHeading = null;

    // Strategy 1: Find headings currently in the activation zone
    const headingsInZone = this.headings.filter((heading) => {
      const rect = heading.getBoundingClientRect();
      return rect.top >= 0 && rect.top <= activationThreshold;
    });

    if (headingsInZone.length > 0) {
      // Use the first heading in the activation zone
      targetHeading = headingsInZone[0];
    } else {
      // Strategy 2: Find the last heading that has passed the activation threshold
      const passedHeadings = this.headings.filter((heading) => {
        const rect = heading.getBoundingClientRect();
        return rect.top < activationThreshold;
      });

      if (passedHeadings.length > 0) {
        // Get the last heading that passed the threshold
        targetHeading = passedHeadings[passedHeadings.length - 1];

        // Add hysteresis: only switch if we're significantly past the current heading
        if (this.currentActive) {
          const currentActiveElement = this.headings.find((h) => h.id === this.currentActive);
          if (currentActiveElement) {
            const currentRect = currentActiveElement.getBoundingClientRect();
            const targetRect = targetHeading.getBoundingClientRect();

            // If current heading is still close to the top and target is below it,
            // stick with current (prevents jumping when current is just below threshold)
            if (currentRect.top > -100 && targetRect.top < currentRect.top) {
              const currentIndex = this.headings.indexOf(currentActiveElement);
              const targetIndex = this.headings.indexOf(targetHeading);

              // Only switch if we're moving significantly forward or backward
              if (Math.abs(targetIndex - currentIndex) === 1) {
                // Add extra buffer for adjacent headings
                if (this.isScrollingDown && targetRect.top > -50) {
                  targetHeading = currentActiveElement;
                } else if (!this.isScrollingDown && currentRect.top < 50) {
                  targetHeading = currentActiveElement;
                }
              }
            }
          }
        }
      } else {
        // Strategy 3: Default to first heading if nothing has passed
        targetHeading = this.headings.length > 0 ? this.headings[0] : null;
      }
    }

    if (targetHeading && targetHeading.id !== this.currentActive) {
      this.activateHeading(targetHeading.id);
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

  // Check if we're on mobile (smaller than Tailwind's `sm` breakpoint)
  isMobile() {
    return window.innerWidth < 640;
  },

  positionNavigator() {
    this.container.style.opacity = '0';

    if (this.isMobile()) {
      // Mobile: initially hidden below viewport
      this.container.style.transform = `translateY(${MOBILE_OFFSET_Y}px)`;
    } else {
      // Desktop: initially hidden to the right
      this.container.style.transform = `translateX(${DESKTOP_OFFSET_X}px)`;
    }
  },

  showToc() {
    if (this.isVisible) return;

    this.isVisible = true;
    this.navigator.style.opacity = '0';
    this.container.style.opacity = '1';
    this.container.removeAttribute('inert');

    this.checkPosition();

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
      this.container.style.transform = `translateY(${MOBILE_OFFSET_Y}px)`;
    } else {
      // Desktop: slide out to right
      this.container.style.transform = `translateX(${DESKTOP_OFFSET_X}px)`;
    }
  },

  showNavigator() {
    if (this.isMobile()) {
      this.navigator.style.transform = 'translateY(0)';
    } else {
      this.navigator.style.transform = 'translateX(0)';
    }
  },

  hideNavigator() {
    if (this.isMobile()) {
      this.navigator.style.transform = 'translateY(100px)';
    } else {
      this.navigator.style.transform = 'translateX(100px)';
    }
  },

  handleIntersection(entries) {
    this.checkPosition();
  },

  handleScroll() {
    const scrollTop = window.scrollY;
    this.isScrollingDown = scrollTop > this.lastScrollTop;
    this.lastScrollTop = scrollTop;

    // On mobile, if we are scrolling down, hide the toc and navigator
    if (this.isScrollingDown) {
      if (this.isMobile()) {
        this.hideToc();
        this.hideNavigator();
      }
    } else {
      // If scrolling up, show the navigator
      if (this.isMobile()) {
        this.showNavigator();
      }
    }
  },

  handleResize() {
    // Reset position when switching between mobile/desktop
    if (!this.isVisible) {
      this.positionNavigator();
    }
  },

  // Desktop event handlers
  handleNavigatgorMouseEnter() {
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
  handleNavigatorClick(event) {
    event.preventDefault();
    event.stopPropagation();

    if (this.isVisible) {
      this.hideToc();
    } else {
      this.showToc();
    }
  },

  handleOutsideClick(event) {
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
