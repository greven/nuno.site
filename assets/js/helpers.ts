const THEME_KEY = 'phx:theme';

type Theme = 'light' | 'dark';

export const getSystemTheme = (): Theme => {
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
};

export const getTheme = (): Theme => {
  return document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light';
};

export const setTheme = (theme: Theme | 'system') => {
  if (theme === 'system') {
    localStorage.removeItem(THEME_KEY);
    document.documentElement.setAttribute('data-theme', getSystemTheme());
    document.documentElement.setAttribute('data-theme-mode', 'system');
  } else {
    localStorage.setItem(THEME_KEY, theme);
    document.documentElement.setAttribute('data-theme', theme);
    document.documentElement.setAttribute('data-theme-mode', 'user');
  }
};

export const observeThemeChanges = (callback: (theme: Theme) => void) => {
  const observer = new MutationObserver(() => {
    const theme = getTheme();
    callback(theme);
  });

  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['data-theme'],
  });

  return () => observer.disconnect();
};
