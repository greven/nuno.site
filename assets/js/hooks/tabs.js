export const Tabs = {
  mounted() {
    this.tabs = Array.from(this.el.querySelectorAll('[role="tab"]'));
    this.panels = Array.from(this.el.querySelectorAll('[role="tabpanel"]'));
    this.selectEvent = this.el.getAttribute('data-onselect');

    // Event Handlers
    this.handleTabClick = (event) => this.onTabClick(event);
    this.handleKeydown = (event) => this.onKeydown(event);

    // Event Listeners
    this.tabs.forEach((tab) => {
      tab.addEventListener('click', this.handleTabClick);
      tab.addEventListener('keydown', this.handleKeydown);
    });

    // Default tab selection
    const defaultTabName =
      this.el.getAttribute('data-value') || this.tabs[0]?.getAttribute('data-name');
    const defaultTab = this.getTabByName(defaultTabName) || this.tabs[0];

    this.selectTab(defaultTab, false);
  },

  destroyed() {
    this.tabs.forEach((tab) => {
      tab.removeEventListener('click', this.handleTabClick);
      tab.removeEventListener('keydown', this.handleKeydown);
    });
  },

  getTabByName(name) {
    return this.tabs.find((tab) => tab.getAttribute('data-name') === name);
  },

  getTabPanel(tab) {
    const panelId = tab.getAttribute('aria-controls');
    return panelId ? document.getElementById(panelId) : null;
  },

  deselectAllTabs() {
    this.tabs.forEach((tab) => {
      this.js().removeAttribute(tab, 'aria-selected');
      this.js().setAttribute(tab, 'tabindex', '-1');
    });
  },

  hideAllPanels() {
    this.panels.forEach((panel) => {
      this.js().setAttribute(panel, 'hidden', 'true');
    });
  },

  selectTab(tab, fireEvent = true) {
    if (!tab) return;

    // Clear all selected state
    this.deselectAllTabs();
    this.hideAllPanels();

    // Select the clicked tab
    this.js().setAttribute(tab, 'aria-selected', 'true');
    this.js().setAttribute(tab, 'tabindex', '0');

    const panel = this.getTabPanel(tab);
    this.js().removeAttribute(panel, 'hidden');

    if (fireEvent && this.selectEvent) {
      this.pushEvent(this.selectEvent, { id: this.el?.id, name: tab?.getAttribute('data-name') });
    }
  },

  onTabClick(event) {
    const tab = event.target.closest('[role="tab"]');
    if (tab) this.selectTab(tab);
  },

  onKeydown(event) {
    const key = event.key;
    const current = event.target.closest('[role="tab"]');
    const hasModifier = event.ctrlKey || event.metaKey || event.shiftKey || event.altKey;
    if (!current || !this.tabs.includes(current)) return;

    const idx = this.tabs.indexOf(current);
    const lastIdx = this.tabs.length - 1;

    let target = null;

    if ((key === 'ArrowRight' || key === 'ArrowDown') && !hasModifier) {
      event.preventDefault();
      target = this.tabs[(idx + 1) % this.tabs.length];
    } else if ((key === 'ArrowLeft' || key === 'ArrowUp') && !hasModifier) {
      event.preventDefault();
      target = this.tabs[(idx - 1 + this.tabs.length) % this.tabs.length];
    } else if (key === 'Home') {
      event.preventDefault();
      target = this.tabs[0];
    } else if (key === 'End') {
      event.preventDefault();
      target = this.tabs[lastIdx];
    }

    if (target && target !== current) {
      this.selectTab(target);
      target.focus();
    }
  },
};
