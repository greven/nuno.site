// Adds swipe-to-navigate gestures for the fullscreen photo gallery.
export const PhotoSwipe = {
  mounted() {
    this.startX = null;
    this.startY = null;

    this.onTouchStart = (event) => {
      const touch = event.touches[0];
      if (!touch) return;
      this.startX = touch.clientX;
      this.startY = touch.clientY;
    };

    this.onTouchEnd = (event) => {
      if (this.startX === null) return;

      const touch = event.changedTouches[0];
      const deltaX = touch ? touch.clientX - this.startX : 0;
      const deltaY = touch ? touch.clientY - this.startY : 0;
      this.startX = null;
      this.startY = null;

      // Ignore short and vertical (scroll-like) swipes.
      const threshold = 50;
      if (Math.abs(deltaX) < threshold || Math.abs(deltaY) >= Math.abs(deltaX)) return;

      const direction = deltaX < 0 ? 'next' : 'prev';
      const available =
        direction === 'next'
          ? this.el.dataset.hasNext === 'true'
          : this.el.dataset.hasPrev === 'true';
      if (!available) return;

      this.pushEvent('navigate', { direction });
    };

    this.el.addEventListener('touchstart', this.onTouchStart, { passive: true });
    this.el.addEventListener('touchend', this.onTouchEnd, { passive: true });
  },

  destroyed() {
    if (this.onTouchStart) this.el.removeEventListener('touchstart', this.onTouchStart);
    if (this.onTouchEnd) this.el.removeEventListener('touchend', this.onTouchEnd);
  },
};
