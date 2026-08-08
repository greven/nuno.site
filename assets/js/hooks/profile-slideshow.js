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

    // Event handlers
    this.mouseEnterHandler = this.handleMouseEnter.bind(this);
    this.mouseLeaveHandler = this.handleMouseLeave.bind(this);
    this.visibilityChangeHandler = this.handleVisibilityChange.bind(this);
    this.previousClickHandler = this.handlePreviousClick.bind(this);
    this.nextClickHandler = this.handleNextClick.bind(this);

    // Add hover events to pause/resume slideshow
    this.el.addEventListener('mouseenter', this.mouseEnterHandler);
    this.el.addEventListener('mouseleave', this.mouseLeaveHandler);

    // Add navigation button event listeners
    this.prevButton = this.el.querySelector('.slideshow-nav-prev');
    this.nextButton = this.el.querySelector('.slideshow-nav-next');

    if (this.prevButton) {
      this.prevButton.addEventListener('click', this.previousClickHandler);
    }

    if (this.nextButton) {
      this.nextButton.addEventListener('click', this.nextClickHandler);
    }

    // Pause slideshow when tab is not visible
    document.addEventListener('visibilitychange', this.visibilityChangeHandler);
  },

  destroyed() {
    this.stopSlideshow();

    if (this.visibilityChangeHandler) {
      document.removeEventListener('visibilitychange', this.visibilityChangeHandler);
    }
    if (this.mouseEnterHandler) {
      this.el.removeEventListener('mouseenter', this.mouseEnterHandler);
    }
    if (this.mouseLeaveHandler) {
      this.el.removeEventListener('mouseleave', this.mouseLeaveHandler);
    }
    if (this.prevButton && this.previousClickHandler) {
      this.prevButton.removeEventListener('click', this.previousClickHandler);
    }
    if (this.nextButton && this.nextClickHandler) {
      this.nextButton.removeEventListener('click', this.nextClickHandler);
    }
  },

  handleMouseEnter() {
    // Pause the slideshow when mouse enters
    this.pauseSlideshow();
  },

  handleMouseLeave() {
    // Resume the slideshow when mouse leaves
    this.resumeSlideshow();
  },

  handlePreviousClick() {
    this.previousSlide();
    this.resetAndRestartSlideshow();
  },

  handleNextClick() {
    this.nextSlide();
    this.resetAndRestartSlideshow();
  },

  handleVisibilityChange() {
    if (document.hidden) {
      this.pauseSlideshow();
    } else {
      // Only resume if not currently being hovered
      if (!this.el.matches(':hover')) {
        this.resumeSlideshow();
      }
    }
  },

  startProgress() {
    // (Re)start the progress ring animation from 0.
    this.progressAnimation?.cancel();
    this.progressAnimation = this.el.animate([{ '--progress': '0%' }, { '--progress': '100%' }], {
      duration: this.duration,
      easing: 'linear',
      fill: 'forwards',
    });
  },

  resetProgress() {
    this.progressAnimation?.cancel();
    this.progressAnimation = null;
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
    // Pause the progress animation and keep the slide timer in sync with the
    // animation's current position
    if (this.progressAnimation) {
      this.remainingTime = this.duration - (this.progressAnimation.currentTime || 0);
      this.progressAnimation.pause();
    }

    clearInterval(this.slideshowTimer);
    this.slideshowTimer = null;
  },

  resumeSlideshow() {
    // Resume the progress animation from where it was paused
    this.progressAnimation?.play();

    // If we have remaining time, use that instead of full duration
    if (this.remainingTime && this.remainingTime > 0) {
      // Set up the next slide after remaining time
      this.slideshowTimer = setTimeout(() => {
        this.nextSlide();
        this.slideshowTimer = null;
        this.startSlideshow();
      }, this.remainingTime);

      this.remainingTime = null;
    } else {
      this.startProgress();
      this.startSlideshow();
    }
  },

  stopSlideshow() {
    this.progressAnimation?.cancel();
    this.progressAnimation = null;
    clearTimeout(this.slideshowTimer);
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

  previousSlide() {
    // Remove the attribute data-active class from current slide
    this.slides[this.currentSlideIndex].removeAttribute('data-active');

    // Update slide index (go backwards, with wraparound)
    this.currentSlideIndex = (this.currentSlideIndex - 1 + this.slides.length) % this.slides.length;

    // Add data-active attribute to new slide
    this.slides[this.currentSlideIndex].setAttribute('data-active', '');

    // Restart progress animation
    this.resetProgress();
    this.startProgress();
  },

  resetAndRestartSlideshow() {
    // Clear existing timers
    this.stopSlideshow();
    this.remainingTime = null;

    // Restart the slideshow with full duration
    this.resetProgress();
    this.startProgress();
    this.startSlideshow();
  },
};
