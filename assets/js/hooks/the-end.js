// Enhanced version of the hook
export const TheEnd = {
  mounted() {
    this.setupIntersectionObserver();
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect();
    }
  },

  setupIntersectionObserver() {
    const options = {
      root: null,
      rootMargin: '0px 0px -10% 0px',
      threshold: 0.9,
    };

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        const dots = entry.target.querySelectorAll('.the-end-dot');

        if (entry.isIntersecting) {
          // Animate each dot with staggered timing
          dots.forEach((dot, index) => {
            setTimeout(() => {
              dot.classList.remove('text-content-40');
              dot.classList.add('text-primary');
              dot.classList.add('dot-jump');

              // Remove animation class after completion
              setTimeout(() => {
                dot.classList.remove('dot-jump');
              }, 400);
            }, index * 150);
          });
        } else {
          // Reset all dots immediately when scrolling away
          dots.forEach((dot) => {
            dot.classList.remove('text-primary');
            dot.classList.add('text-content-40');
          });
        }
      });
    }, options);

    this.observer.observe(this.el);
  },
};
