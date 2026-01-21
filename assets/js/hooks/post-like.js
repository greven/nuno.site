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

    // Event handlers
    this.likeToggleHandler = this.handleLikeToggle.bind(this);
    this.likesUpdatedHandler = this.handleLikesUpdated.bind(this);
    this.likesErrorHandler = this.handleLikesError.bind(this);

    // Add click event listener
    this.likeButton.addEventListener('click', this.likeToggleHandler);

    // Listen for server responses
    this.handleEvent('likes-updated', this.likesUpdatedHandler);
    this.handleEvent('likes-error', this.likesErrorHandler);

    this.updateUI();
  },

  updated() {
    this.isLiked = this.getStoredLikeState();
    this.updateUI();
  },

  destroyed() {
    if (this.likeButton && this.likeToggleHandler) {
      this.likeButton.removeEventListener('click', this.likeToggleHandler);
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
    if (!this.likedIcon || !this.unlikedIcon) return;

    // Add pulse animation
    this.likedIcon.classList.add('animate-pulse');

    setTimeout(() => {
      this.likedIcon.classList.remove('animate-pulse');
    }, 600);
  },

  // Create particle effect with multiple floating hearts
  appendFloatingElement() {
    // Bailout if no like icon
    if (!this.likedIcon || !this.el) {
      return;
    }

    // Generate 3-5 particles
    const particleCount = 3 + Math.floor(Math.random() * 3);

    for (let i = 0; i < particleCount; i++) {
      setTimeout(() => {
        this.createParticle(i, particleCount);
      }, i * 50); // Stagger by 50ms
    }
  },

  // Create individual particle
  createParticle(index, total) {
    if (!this.likedIcon || !this.el) {
      return;
    }

    const icon = this.likedIcon.cloneNode(true);
    const floatingEl = document.createElement('span');

    floatingEl.appendChild(icon);
    icon.classList.remove('hidden');

    // Calculate angle for radial distribution
    const baseAngle = -90;
    const spread = 120;
    const angleOffset = (spread / (total - 1)) * index - spread / 2;
    const angle = (baseAngle + angleOffset) * (Math.PI / 180);

    // Add some randomness
    const angleVariation = (Math.random() - 0.5) * 0.3;
    const finalAngle = angle + angleVariation;

    // Smaller scale for particles (0.3 to 0.5)
    const scale = 0.3 + Math.random() * 0.2;

    // Distance particles travel (40-70px)
    const distance = 40 + Math.random() * 30;

    // Calculate x and y movement based on angle
    const moveX = Math.cos(finalAngle) * distance;
    const moveY = Math.sin(finalAngle) * distance;

    // Add slight rotation
    const rotation = (Math.random() - 0.5) * 30;

    floatingEl.style.cssText = `
      position: absolute;
      top: 4px;
      left: 12px;
      opacity: 1;
      transform: scale(${scale}) translate(0, 0) rotate(0deg);
      transition: opacity 1.5s ease-out, transform 1.2s ease-out;
      pointer-events: none;
      z-index: 10;
    `;

    this.el.appendChild(floatingEl);

    // Trigger animation
    setTimeout(() => {
      floatingEl.style.opacity = '0';
      floatingEl.style.transform = `scale(${scale}) translate(${moveX}px, ${moveY}px) rotate(${rotation}deg)`;
      setTimeout(() => floatingEl.remove(), 1500);
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

    // Toggle like state
    this.isLiked = !this.isLiked;

    // Optimistic UI update
    this.updateUI();
    this.storeLikeState();
    this.addLikeAnimation();

    // Send to server
    this.pushEvent('toggle-like', {
      post_slug: this.postSlug,
      action: this.isLiked ? 'like' : 'unlike',
    });

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
