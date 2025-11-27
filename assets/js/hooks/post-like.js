export const PostLike = {
  mounted() {
    this.isThrottled = false;
    this.throttleDelay = 1000;

    this.likeButton = this.el;
    this.unlikedIcon = this.el.querySelector('[data-unliked-icon]');
    this.likedIcon = this.el.querySelector('[data-liked-icon]');
    this.likeCount = this.el.querySelector('[data-likes-count]');
    this.postSlug = this.el.dataset.postSlug;

    this.isLiked = this.getStoredLikeState();

    // Add click event listener
    this.likeButton.addEventListener('click', this.handleLikeToggle.bind(this));

    // Listen for server responses
    this.handleEvent('likes-updated', this.handleLikesUpdated.bind(this));
    this.handleEvent('likes-error', this.handleLikesError.bind(this));

    this.updateUI();
  },

  updated() {
    this.isLiked = this.getStoredLikeState();
    this.updateUI();
  },

  destroyed() {
    if (this.likeButton) {
      this.likeButton.removeEventListener('click', this.handleLikeToggle.bind(this));
    }
  },

  getStoredLikeState() {
    try {
      const stored = localStorage.getItem(`ns-post-like-${this.postSlug}`);
      return stored === 'true';
    } catch (error) {
      console.warn('localStorage not available:', error);
      return false;
    }
  },

  storeLikeState() {
    try {
      localStorage.setItem(`ns-post-like-${this.postSlug}`, this.isLiked.toString());
    } catch (error) {
      console.warn('Failed to store like state:', error);
    }
  },

  updateUI() {
    if (!this.likedIcon || !this.unlikedIcon) return;

    if (this.isLiked) {
      this.js().setAttribute(this.el, 'data-liked', true);
      this.likedIcon.classList.remove('hidden');
      this.unlikedIcon.classList.add('hidden');
    } else {
      this.js().setAttribute(this.el, 'data-liked', false);
      this.likedIcon.classList.add('hidden');
      this.unlikedIcon.classList.remove('hidden');
    }
  },

  addLikeAnimation() {
    if (!this.likedIcon) return;

    // Add pulse animation
    this.likedIcon.classList.add('animate-pulse');

    setTimeout(() => {
      this.likedIcon.classList.remove('animate-pulse');
    }, 600);
  },

  // Append a floating heart
  appendFloatingElement() {
    const icon = this.likedIcon.cloneNode(true);
    const floatingEl = document.createElement('span');

    floatingEl.appendChild(icon);
    icon.classList.remove('hidden');

    // Set a random x position shift between -8 and +8px
    const shiftX = Math.floor(Math.random() * 17) - 8;
    // Scale between 0.25 and 0.75
    const scale = 0.25 + Math.random() * 0.5;
    // Random distance between 12 and 32;
    const distance = 12 + Math.random() * 20;

    floatingEl.style.cssText = `
      position: absolute;
      top: 4px;
      left: ${12 + shiftX}px;
      opacity: 1;
      transform: scale(${scale}) translateY(0);
      transition: opacity 1s ease-out, transform 1s ease-out;
      pointer-events: none;
      z-index: 10;
    `;

    this.el.appendChild(floatingEl);

    // Animation
    setTimeout(() => {
      floatingEl.style.opacity = '0';
      floatingEl.style.transform = `translateY(-${distance}px)`;
      setTimeout(() => floatingEl.remove(), 1000);
    }, 10);
  },

  showErrorFeedback() {
    this.likeButton.classList.add('animate-pulse');
    setTimeout(() => {
      this.likeButton.classList.remove('animate-pulse');
    }, 1000);
  },

  // Update count from server
  handleLikesUpdated(payload) {
    if (this.likeCount) {
      this.likeCount.textContent = abbreviateNumber(payload.likes);

      if (payload.diff > 0) {
        this.appendFloatingElement();
      }
    }
  },

  handleLikesError() {
    // Revert optimistic update
    this.isLiked = !this.isLiked;
    this.updateUI();
    this.storeLikeState();

    // Show error feedback
    this.showErrorFeedback();
  },

  handleLikeToggle(event) {
    event.preventDefault();

    if (this.isThrottled) {
      return;
    }

    this.isThrottled = true;

    // Optimistic UI update
    this.isLiked = !this.isLiked;
    this.updateUI();
    this.storeLikeState();

    // Send to server
    this.pushEvent('toggle-like', {
      post_slug: this.postSlug,
      action: this.isLiked ? 'like' : 'unlike',
    });

    // Add visual feedback
    this.addLikeAnimation();

    // Reset throttle after delay
    setTimeout(() => {
      this.isThrottled = false;
    }, this.throttleDelay);
  },
};

const abbreviateNumber = (num) => {
  if (num >= 1000000) {
    return `${(num / 1000000).toFixed(1)}M`;
  } else if (num >= 1000) {
    return `${(num / 1000).toFixed(1)}K`;
  }
  return num.toString();
};
