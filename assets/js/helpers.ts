type Theme = 'light' | 'dark';

export const getTheme = (): Theme => {
  return document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light';
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
