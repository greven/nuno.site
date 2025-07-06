export const Hello = {
  mounted() {
    this.helloRootEl = document.getElementById('hello-text')
    this.helloTextEl = document.querySelector('[data-text]')
    this.itemsListEl = document.getElementById('intro-list')

    this.isReduced =
      window.matchMedia(`(prefers-reduced-motion: reduce)`) === true ||
      window.matchMedia(`(prefers-reduced-motion: reduce)`).matches === true

    this.maybeRevealText()
  },

  maybeRevealText() {
    const textContent = this.helloTextEl.getAttribute('data-text')

    // Check if reduced motion is enabled
    if (this.isReduced) {
      this.js().toggleClass(this.helloRootEl, 'opacity-100')
      this.helloTextEl.textContent = textContent
    } else {
      this.js().addClass(this.helloRootEl, 'top-4 transform scale-85 duration-300 transition')
      this.js().toggleClass(this.helloRootEl, 'opacity-100 scale-100 -translate-y-4')

      setTimeout(this.revealText.bind(this), 700)
    }
  },

  revealText() {
    this.helloTextEl.textContent = ''
    const textContent = this.helloTextEl.getAttribute('data-text')

    let currentIndex = 0
    const revealNextChar = () => {
      if (currentIndex < textContent.length) {
        this.helloTextEl.textContent = textContent.substring(0, currentIndex + 1)
        currentIndex++
        setTimeout(revealNextChar, 125)
      }
    }

    revealNextChar()
  },
}
