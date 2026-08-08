export const PulseFullscreen = {
  mounted() {
    this.target = document.getElementById('news-feed');
    this.icon = this.el.querySelector('[data-slot="icon"]');

    this.onClick = (event) => this.toggleFullscreen(event);
    this.onFullscreenChange = () => this.syncState();

    this.el.addEventListener('click', this.onClick);
    document.addEventListener('fullscreenchange', this.onFullscreenChange);

    this.syncState();
  },

  updated() {
    // The toolbar may have been re-rendered
    this.target = document.getElementById('news-feed');
    this.icon = this.el.querySelector('[data-slot="icon"]');
    this.syncState();
  },

  destroyed() {
    this.el.removeEventListener('click', this.onClick);
    document.removeEventListener('fullscreenchange', this.onFullscreenChange);

    // Leave fullscreen when the LiveView goes away (e.g. navigating away).
    if (this.isFullscreen()) {
      this.exitFullscreen();
    }
  },

  isFullscreen() {
    return (document.fullscreenElement || document.webkitFullscreenElement) === this.target;
  },

  requestFullscreen() {
    if (!this.target) return;

    const request = this.target.requestFullscreen || this.target.webkitRequestFullscreen;
    if (request) {
      // Safari's webkit variant doesn't return a promise.
      request.call(this.target)?.catch?.(() => {});
    }
  },

  exitFullscreen() {
    const exit = document.exitFullscreen || document.webkitExitFullscreen;
    if (exit) {
      exit.call(document);
    }
  },

  toggleFullscreen(event) {
    event.preventDefault();

    if (this.isFullscreen()) {
      this.exitFullscreen();
    } else {
      this.requestFullscreen();
    }
  },

  syncState() {
    if (!this.target) return;

    const isListView = this.el.dataset.view === 'list';
    const isFullscreen = this.isFullscreen();

    // Only usable from List View. LiveView keeps `data-view` up to date on
    // ignored elements, so this stays in sync when the view changes.
    this.el.disabled = !isListView;

    // If the view changed away from List View while fullscreen, the reader is
    // hidden, so leave fullscreen rather than showing a blank screen.
    if (!isListView && isFullscreen) {
      this.exitFullscreen();
      return;
    }

    this.el.setAttribute('title', isFullscreen ? 'Exit Fullscreen' : 'Fullscreen');

    // The button theme styles `aria-[pressed]` on attribute presence, so only
    // keep the attribute while the reader is actually fullscreen.
    if (isFullscreen) {
      this.el.setAttribute('aria-pressed', 'true');
    } else {
      this.el.removeAttribute('aria-pressed');
    }

    if (this.icon) {
      this.icon.classList.toggle('lucide-maximize', !isFullscreen);
      this.icon.classList.toggle('lucide-minimize', isFullscreen);
    }
  },
};
