export const ProfileSlideshow = {
  mounted() {
    // Get the duration from the data attribute (default: 5000ms)
    this.duration = parseInt(this.el.dataset.duration || 5000);
    this.slides = Array.from(this.el.querySelectorAll('.slide'));
    this.currentSlideIndex = 0;

    // Don't start slideshow if there's only one slide
    if (this.slides.length <= 1) return;

    this.startProgress();
    this.startSlideshow();

    // Pause slideshow when tab is not visible
    document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this));
  },

  destroyed() {
    this.stopSlideshow();
    document.removeEventListener('visibilitychange', this.handleVisibilityChange);
  },

  handleVisibilityChange() {
    if (document.hidden) {
      this.pauseSlideshow();
    } else {
      this.resumeSlideshow();
    }
  },

  startProgress() {
    // Reset progress
    this.el.style.setProperty('--progress', '0%');

    // Start progress animation (~60fps)
    this.progressStartTime = Date.now();
    this.progressInterval = setInterval(() => {
      const elapsed = Date.now() - this.progressStartTime;
      const progress = Math.min(100, (elapsed / this.duration) * 100);
      this.el.style.setProperty('--progress', `${progress}%`);
    }, 16);
  },

  resetProgress() {
    clearInterval(this.progressInterval);
    this.el.style.setProperty('--progress', '0%');
  },

  startSlideshow() {
    // Only start if not already running
    if (this.slideshowTimer) return;

    this.slideshowTimer = setInterval(() => {
      this.nextSlide();
    }, this.duration);
  },

  pauseSlideshow() {
    // Store the remaining time
    if (this.progressStartTime) {
      this.remainingTime = this.duration - (Date.now() - this.progressStartTime);
    }

    // Clear all timers
    this.resetProgress();
    clearInterval(this.slideshowTimer);
    this.slideshowTimer = null;
  },

  resumeSlideshow() {
    // If we have remaining time, use that instead of full duration
    if (this.remainingTime) {
      // Start progress from where we left off
      const progress = 100 - (this.remainingTime / this.duration) * 100;
      this.el.style.setProperty('--progress', `${progress}%`);

      this.progressStartTime = Date.now() - (this.duration - this.remainingTime);
      this.progressInterval = setInterval(() => {
        const elapsed = Date.now() - this.progressStartTime;
        const progress = Math.min(100, (elapsed / this.duration) * 100);
        this.el.style.setProperty('--progress', `${progress}%`);
      }, 16);

      // Set up the next slide after remaining time
      this.slideshowTimer = setTimeout(() => {
        this.nextSlide();
        // Resume normal interval after this
        this.startSlideshow();
      }, this.remainingTime);

      this.remainingTime = null;
    } else {
      // Just restart normally
      this.startProgress();
      this.startSlideshow();
    }
  },

  stopSlideshow() {
    clearInterval(this.progressInterval);
    clearInterval(this.slideshowTimer);
    this.slideshowTimer = null;
  },

  nextSlide() {
    // Remove the attribute data-active class from current slide
    this.slides[this.currentSlideIndex].removeAttribute('data-active');

    // Update slide index
    this.currentSlideIndex = (this.currentSlideIndex + 1) % this.slides.length;

    // Add data-active attribute to new slide
    this.slides[this.currentSlideIndex].setAttribute('data-active', '');

    // Restart progress animation
    this.resetProgress();
    this.startProgress();
  },
};
