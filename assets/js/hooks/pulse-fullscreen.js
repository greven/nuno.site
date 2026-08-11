export const PulseFullscreen = {
  mounted() {
    this.target = document.getElementById('news-feed');
    this.icon = this.el.querySelector('[data-slot="icon"]');

    this.onClick = (event) => this.toggleMaximize(event);
    this.onExitClick = (event) => this.onExitButtonClick(event);
    this.handleKeydown = (event) => this.onKeydown(event);

    this.el.addEventListener('click', this.onClick);
    document.addEventListener('click', this.onExitClick);
    document.addEventListener('keydown', this.handleKeydown);

    // If the page reconnected while the reader was maximized,
    // release the scroll lock the previous session left behind.
    if (
      !document.documentElement.hasAttribute('data-dialog-open') &&
      !document.documentElement.hasAttribute('data-drawer-open')
    ) {
      this.unlockPageScroll();
      document.documentElement.removeAttribute('data-pulse-reader-maximized');
    }

    this.syncState();
  },

  updated() {
    // The toolbar may have been re-rendered
    this.target = document.getElementById('news-feed');
    this.icon = this.el.querySelector('[data-slot="icon"]');

    // Keep the toolbar in sync after view changes
    this.applyMaximizedState();
    this.syncState();
  },

  destroyed() {
    this.el.removeEventListener('click', this.onClick);
    document.removeEventListener('click', this.onExitClick);
    document.removeEventListener('keydown', this.handleKeydown);

    // Restore the page when the LiveView goes away (e.g. navigating away).
    if (this.isMaximized()) {
      this.applyMaximizedState(false);
    }
  },

  isMaximized() {
    return this.maximized === true;
  },

  maximize() {
    if (!this.target || this.isMaximized()) return;

    this.previouslyFocused = document.activeElement;
    this.maximized = true;

    this.applyMaximizedState();
    this.syncState();

    // Move keyboard focus into the reader (standard modal pattern).
    this.target.querySelector('#news-feed-exit-maximize')?.focus();
  },

  restore() {
    if (!this.isMaximized()) return;

    this.maximized = false;

    this.applyMaximizedState(false);
    this.syncState();

    if (this.previouslyFocused && document.contains(this.previouslyFocused)) {
      this.previouslyFocused.focus();
    }
  },

  toggleMaximize(event) {
    event.preventDefault();

    if (this.isMaximized()) {
      this.restore();
    } else {
      this.maximize();
    }
  },

  onExitButtonClick(event) {
    if (event.target.closest?.('#news-feed-exit-maximize')) {
      this.restore();
    }
  },

  onKeydown(event) {
    if (event.key !== 'Escape' || !this.isMaximized()) return;

    // Don't hijack Escape while a dialog (e.g. the finder) is open.
    if (document.querySelector('dialog[open]')) return;

    this.restore();
  },

  applyMaximizedState(maximized = this.isMaximized()) {
    if (!this.target) return;

    if (maximized) {
      this.lockPageScroll();
      document.documentElement.setAttribute('data-pulse-reader-maximized', '');
    } else {
      this.unlockPageScroll();
      document.documentElement.removeAttribute('data-pulse-reader-maximized');
    }
  },

  lockPageScroll() {
    document.body.style.overflow = 'hidden';
  },

  unlockPageScroll() {
    document.body.style.removeProperty('overflow');
  },

  syncState() {
    if (!this.target) return;

    const isListView = this.el.dataset.view === 'list';
    const isMaximized = this.isMaximized();

    // Only usable from List View
    this.el.disabled = !isListView;

    // If the view changed away from List View while maximized, the reader is
    // hidden, so restore rather than showing a blank screen.
    if (!isListView && isMaximized) {
      this.restore();
      return;
    }

    this.el.setAttribute('title', isMaximized ? 'Exit Maximize' : 'Maximize');

    if (isMaximized) {
      this.el.setAttribute('aria-pressed', 'true');
    } else {
      this.el.removeAttribute('aria-pressed');
    }

    if (this.icon) {
      this.icon.classList.toggle('lucide-maximize', !isMaximized);
      this.icon.classList.toggle('lucide-minimize', isMaximized);
    }
  },
};
