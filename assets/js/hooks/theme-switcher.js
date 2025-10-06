import { setTheme, getSystemTheme } from '../helpers';

const THEME_KEY = 'phx:theme';

export const ThemeSwitcher = {
  mounted() {
    this.el.addEventListener('click', this.handleClick.bind(this));
    this.svg = this.el.querySelector('svg');
  },

  destroyed() {
    this.el.removeEventListener('click', this.handleClick.bind(this));
  },

  toggleTheme() {
    const currentTheme = localStorage.getItem(THEME_KEY) || 'system';
    if (currentTheme === 'light') {
      setTheme('dark');
    } else if (currentTheme === 'dark') {
      setTheme('light');
    } else {
      setTheme(getSystemTheme() === 'dark' ? 'light' : 'dark');
    }
  },

  async handleClick() {
    if (!document.startViewTransition) {
      this.toggleTheme();
      return;
    }

    // Mark that we're doing a theme transition
    document.documentElement.setAttribute('data-theme-transitioning', '');

    const transition = document.startViewTransition(() => {
      this.toggleTheme();
    });

    await transition.ready;

    const { top, left, width, height } = this.svg.getBoundingClientRect();
    const x = left + width / 2;
    const y = top + height / 2;

    const maxRadius = Math.hypot(
      Math.max(left, window.innerWidth - left),
      Math.max(top, window.innerHeight - top)
    );

    const animation = document.documentElement.animate(
      {
        clipPath: [`circle(0px at ${x}px ${y}px)`, `circle(${maxRadius}px at ${x}px ${y}px)`],
      },
      {
        duration: 600,
        easing: 'ease-in-out',
        pseudoElement: '::view-transition-new(root)',
      }
    );

    await animation.finished;

    // Clean up after the animation
    setTimeout(() => {
      document.documentElement.removeAttribute('data-theme-transitioning');
    }, 50);
  },
};
