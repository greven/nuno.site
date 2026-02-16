export const PulseClock = {
  mounted() {
    this.clockEl = this.el.querySelector('[data-clock]');
    this.updateTime();
    this.interval = setInterval(() => this.updateTime(), 1000);
  },

  destroyed() {
    clearInterval(this.interval);
  },

  updateTime() {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    this.clockEl.innerHTML = `${hours}<span class="animate-blink text-content-40/60">:</span>${minutes}`;
  },
};
