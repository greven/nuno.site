export const TableOfContents = {
  // TODO: It breaks when using HOME or END
  // TODO: It doesn't work very well for multi level as it never triggers headings close to the end of the document!

  mounted() {
    this.toc = document.getElementById('toc-list');
    this.navigator = document.getElementById('toc-navigator');

    // TOC list items
    this.tocItems = Array.from(this.el.querySelectorAll('ol li a'));
    if (this.tocItems.length === 0) return;

    // Document Header links
    this.headings = this.tocItems
      .map((item) => {
        const id = item.getAttribute('href').replace('#', '');
        return document.getElementById(id);
      })
      .filter(Boolean);

    this.observer = new IntersectionObserver(this.handleIntersection.bind(this), {
      root: null,
      rootMargin: '-10% 0px -70% 0px', // Adjust this to create a detection zone near the top
      threshold: [0, 0.1, 0.5, 1], // Multiple thresholds to detect partial visibility
    });

    // Observe all headings
    this.headings.forEach((heading) => {
      this.observer.observe(heading);
    });

    this.currentActive = null;
    this.lastScrollTop = window.scrollY;

    this.checkInitialPosition();

    // Store the timeout id so we can clear it if needed
    this.hideTimeout = null;

    // When hovering on the navigator, show the TOC list
    this.navigator.addEventListener('mouseenter', this.handleNavigatorMouseEnter.bind(this));
    this.toc.addEventListener('mouseenter', this.handleTocMouseEnter.bind(this));
    this.toc.addEventListener('mouseleave', this.handleTocMouseLeave.bind(this));

    // Add scroll event listener to detect direction
    window.addEventListener('scroll', this.handleScroll.bind(this), { passive: true });
  },

  destroyed() {
    // Clean up the observer when the hook is destroyed
    if (this.observer) {
      this.headings.forEach((heading) => {
        if (heading) this.observer.unobserve(heading);
      });
      this.observer.disconnect();
    }

    window.removeEventListener('scroll', this.handleScroll.bind(this));
    this.navigator.removeEventListener('mouseenter', this.handleMouseEnter);
    this.toc.removeEventListener('mouseenter', this.handleMouseEnter);
    this.toc.removeEventListener('mouseleave', this.handleMouseLeave);
  },

  handleScroll() {
    const scrollTop = window.scrollY;
    this.isScrollingDown = scrollTop > this.lastScrollTop;
    this.lastScrollTop = scrollTop;
  },

  handleIntersection(entries) {
    // Filter for entries that are at least partially visible
    const intersectingEntries = entries.filter((entry) => entry.isIntersecting);

    if (intersectingEntries.length === 0) return;

    let targetHeading;

    if (this.isScrollingDown) {
      // When scrolling down, prioritize the first heading entering the viewport from below
      targetHeading = intersectingEntries
        .filter((entry) => entry.boundingClientRect.top > 0)
        .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
    } else {
      // When scrolling up, prioritize the last heading that's at/near the detection zone
      targetHeading = intersectingEntries.sort(
        (a, b) => a.boundingClientRect.top - b.boundingClientRect.top
      )[0];
    }

    // If we couldn't determine by scroll direction, use the most visible heading
    if (!targetHeading) {
      targetHeading = intersectingEntries.sort(
        (a, b) => b.intersectionRatio - a.intersectionRatio
      )[0];
    }

    if (targetHeading) {
      this.activateHeading(targetHeading.target.id);
    }
  },

  handleNavigatorMouseEnter() {
    this.navigator.style.opacity = '0';
    this.toc.style.transform = 'translateX(0px)';
    this.toc.classList.remove('invisible');
  },

  handleTocMouseEnter() {
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout);
      this.hideTimeout = null;
    }
  },

  handleTocMouseLeave() {
    // Clear any existing timeout to prevent multiple triggers
    if (this.hideTimeout) clearTimeout(this.hideTimeout);

    this.hideTimeout = setTimeout(() => {
      this.navigator.style.opacity = '100%';
      this.toc.style.transform = 'translateX(100vw)';
      this.toc.classList.add('invisible');
    }, 750);
  },

  checkInitialPosition() {
    // Find the topmost visible heading on initial load
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
};
