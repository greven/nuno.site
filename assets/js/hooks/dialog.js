export const Dialog = {
  mounted() {
    window.addEventListener('show-dialog', this.show.bind(this))
    window.addEventListener('hide-dialog', this.hide.bind(this))
  },

  destroy() {
    // Remove event listeners
    window.removeEventListener('show-dialog', this.show.bind(this))
    window.removeEventListener('hide-dialog', this.hide.bind(this))
  },

  show(event) {
    event.target?.showModal()
  },

  hide(event) {
    event.target?.close()
  },
}
