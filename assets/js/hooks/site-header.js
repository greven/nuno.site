export const SiteHeader = {
  mounted() {
    this.handleScroll = () => {
      if (window.scrollY > 0) {
        this.el.setAttribute("data-scrolled", "");
      } else {
        this.el.removeAttribute("data-scrolled");
      }
    };

    this.handleScroll();

    window.addEventListener("scroll", this.handleScroll, { passive: true });
  },
  destroyed() {
    window.removeEventListener("scroll", this.handleScroll);
  },
};
