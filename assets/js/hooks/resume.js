export const Resume = {
  mounted() {
    this.arrow = document.getElementById('resume-arrow');

    // Events Handlers
    this.handleScroll = () => this.onScroll();

    this.handleScroll();

    // Event Listeners
    window.addEventListener('scroll', this.handleScroll, { passive: true });
  },

  destroyed() {
    window.removeEventListener('scroll', this.handleScroll);
  },

  onScroll() {
    const currentScrollY = window.scrollY;
    const scrollPercentage = this.scrollPercentage(currentScrollY);

    this.rotateArrow(scrollPercentage);
  },

  // Scroll percentage representing the amount of screen scrolled (0 to 1)
  scrollPercentage(scrollY) {
    const documentHeight = document.body.scrollHeight;
    const windowHeight = window.innerHeight;

    return Math.min((3 * scrollY) / (documentHeight - windowHeight), 1);
  },

  // Let's rotate the arrow based on percentage
  rotateArrow(percent) {
    const rotation = percent * 120;
    this.arrow.style.transform = `rotate(${rotation}deg)`;
  },
};
