export const ProfileSlideshow = {
  mounted() {
    // Get the duration from the data attribute (default: 5000ms)
    this.duration = parseInt(this.el.dataset.duration || 5000)
    this.slides = Array.from(this.el.querySelectorAll('.slide'))
    this.currentSlideIndex = 0

    // Don't start slideshow if there's only one slide
    if (this.slides.length <= 1) return

    this.startProgress()
    this.startSlideshow()

    // Add hover events to pause/resume slideshow
    this.el.addEventListener('mouseenter', this.handleMouseEnter.bind(this))
    this.el.addEventListener('mouseleave', this.handleMouseLeave.bind(this))

    // Add navigation button event listeners
    const prevButton = this.el.querySelector('.slideshow-nav-prev')
    const nextButton = this.el.querySelector('.slideshow-nav-next')

    if (prevButton) {
      prevButton.addEventListener('click', this.handlePreviousClick.bind(this))
    }

    if (nextButton) {
      nextButton.addEventListener('click', this.handleNextClick.bind(this))
    }

    // Pause slideshow when tab is not visible
    document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this))

    // Clean up on destroy
    this.onDestroy = () => {
      this.stopSlideshow()
      document.removeEventListener('visibilitychange', this.handleVisibilityChange)
      this.el.removeEventListener('mouseenter', this.handleMouseEnter)
      this.el.removeEventListener('mouseleave', this.handleMouseLeave)

      if (prevButton) {
        prevButton.removeEventListener('click', this.handlePreviousClick)
      }

      if (nextButton) {
        nextButton.removeEventListener('click', this.handleNextClick)
      }
    }
  },

  destroyed() {
    if (this.onDestroy) {
      this.onDestroy()
    }
  },

  handleMouseEnter() {
    // Pause the slideshow when mouse enters
    this.pauseSlideshow()
  },

  handleMouseLeave() {
    // Resume the slideshow when mouse leaves
    this.resumeSlideshow()
  },

  handlePreviousClick() {
    this.previousSlide()
    this.resetAndRestartSlideshow()
  },

  handleNextClick() {
    this.nextSlide()
    this.resetAndRestartSlideshow()
  },

  handleVisibilityChange() {
    if (document.hidden) {
      this.pauseSlideshow()
    } else {
      // Only resume if not currently being hovered
      if (!this.el.matches(':hover')) {
        this.resumeSlideshow()
      }
    }
  },

  startProgress() {
    this.el.style.setProperty('--progress', '0%')

    // Start progress animation (~60fps)
    this.progressStartTime = Date.now()
    this.progressInterval = setInterval(() => {
      const elapsed = Date.now() - this.progressStartTime
      const progress = Math.min(100, (elapsed / this.duration) * 100)
      this.el.style.setProperty('--progress', `${progress}%`)
    }, 16)
  },

  resetProgress() {
    clearInterval(this.progressInterval)
    this.el.style.setProperty('--progress', '0%')
  },

  startSlideshow() {
    // Only start if not already running
    if (this.slideshowTimer) return

    this.slideshowTimer = setInterval(() => {
      this.nextSlide()
    }, this.duration)
  },

  pauseSlideshow() {
    // Store the remaining time
    if (this.progressStartTime) {
      this.remainingTime = this.duration - (Date.now() - this.progressStartTime)
    }

    clearInterval(this.progressInterval)
    clearInterval(this.slideshowTimer)
    this.slideshowTimer = null
  },

  resumeSlideshow() {
    // If we have remaining time, use that instead of full duration
    if (this.remainingTime && this.remainingTime > 0) {
      // Start progress from where we left off
      const progress = 100 - (this.remainingTime / this.duration) * 100
      this.el.style.setProperty('--progress', `${progress}%`)

      this.progressStartTime = Date.now() - (this.duration - this.remainingTime)
      this.progressInterval = setInterval(() => {
        const elapsed = Date.now() - this.progressStartTime
        const currentProgress = Math.min(100, (elapsed / this.duration) * 100)
        this.el.style.setProperty('--progress', `${currentProgress}%`)
      }, 16)

      // Set up the next slide after remaining time
      this.slideshowTimer = setTimeout(() => {
        this.nextSlide()
        this.slideshowTimer = null
        this.startSlideshow()
      }, this.remainingTime)

      this.remainingTime = null
    } else {
      this.startProgress()
      this.startSlideshow()
    }
  },

  stopSlideshow() {
    clearInterval(this.progressInterval)
    clearTimeout(this.slideshowTimer)
    this.slideshowTimer = null
  },

  nextSlide() {
    // Remove the attribute data-active class from current slide
    this.slides[this.currentSlideIndex].removeAttribute('data-active')

    // Update slide index
    this.currentSlideIndex = (this.currentSlideIndex + 1) % this.slides.length

    // Add data-active attribute to new slide
    this.slides[this.currentSlideIndex].setAttribute('data-active', '')

    // Restart progress animation
    this.resetProgress()
    this.startProgress()
  },

  previousSlide() {
    // Remove the attribute data-active class from current slide
    this.slides[this.currentSlideIndex].removeAttribute('data-active')

    // Update slide index (go backwards, with wraparound)
    this.currentSlideIndex = (this.currentSlideIndex - 1 + this.slides.length) % this.slides.length

    // Add data-active attribute to new slide
    this.slides[this.currentSlideIndex].setAttribute('data-active', '')

    // Restart progress animation
    this.resetProgress()
    this.startProgress()
  },

  resetAndRestartSlideshow() {
    // Clear existing timers
    this.stopSlideshow()
    this.remainingTime = null

    // Restart the slideshow with full duration
    this.resetProgress()
    this.startProgress()
    this.startSlideshow()
  },
}
