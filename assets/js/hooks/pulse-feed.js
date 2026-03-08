export const PulseFeed = {
  mounted() {
    this.list = this.el.querySelector('ul');
    this.scrollContainer = this.el.querySelector('[id$="-scroll"]');
    this.lastAnchor = null;

    this.setupScrollAnchor();
    this.setupItemListeners();
  },

  updated() {
    this.setupItemListeners();
  },

  destroyed() {
    this.teardownScrollAnchor();
    this.removeItemListeners();
  },

  setupScrollAnchor() {
    if (!this.scrollContainer || !this.list) return;

    // Keep a fresh anchor on every scroll event
    this._onScroll = () => {
      this.lastAnchor = this.captureScrollAnchor();
    };
    this.scrollContainer.addEventListener('scroll', this._onScroll, { passive: true });

    // Restore scroll position whenever the <ul>'s children change
    this._mutationObserver = new MutationObserver(() => {
      if (this.lastAnchor) {
        this.restoreScrollAnchor(this.lastAnchor);
      }
    });

    this._mutationObserver.observe(this.list, { childList: true });
  },

  teardownScrollAnchor() {
    if (this._onScroll && this.scrollContainer) {
      this.scrollContainer.removeEventListener('scroll', this._onScroll);
    }
    if (this._mutationObserver) {
      this._mutationObserver.disconnect();
    }
  },

  captureScrollAnchor() {
    if (!this.scrollContainer || !this.list) return null;

    const containerRect = this.scrollContainer.getBoundingClientRect();
    const items = Array.from(this.list.querySelectorAll('li[id]'));

    const anchor = items.find((item) => {
      return item.getBoundingClientRect().bottom > containerRect.top;
    });

    if (!anchor) return null;

    return {
      id: anchor.id,
      offset: anchor.getBoundingClientRect().top - containerRect.top,
    };
  },

  restoreScrollAnchor({ id, offset }) {
    if (!this.scrollContainer) return;

    const anchor = document.getElementById(id);
    if (!anchor) return;

    const containerRect = this.scrollContainer.getBoundingClientRect();
    const drift = anchor.getBoundingClientRect().top - containerRect.top - offset;

    if (drift !== 0) {
      this.scrollContainer.scrollTop += drift;
    }
  },

  setupItemListeners() {
    this.removeItemListeners();
    this.items = Array.from(this.list?.querySelectorAll('li[id]') ?? []);

    this.itemClick = (event) => this.onItemClick(event);
    this.itemFocus = (event) => this.onItemFocus(event);
    this.handleKeydown = (event) => this.onKeydown(event);

    this.items.forEach((item) => {
      const article = item.querySelector('article');
      item.addEventListener('click', this.itemClick);
      item.addEventListener('keydown', this.handleKeydown);
      if (article) article.addEventListener('focus', this.itemFocus);
    });
  },

  removeItemListeners() {
    if (!this.items) return;
    this.items.forEach((item) => {
      const article = item.querySelector('article');
      item.removeEventListener('click', this.itemClick);
      item.removeEventListener('keydown', this.handleKeydown);
      if (article) article.removeEventListener('focus', this.itemFocus);
    });
  },

  selectItem(item) {
    const isSelected = item?.getAttribute('aria-selected') === 'true';
    if (!item && isSelected) return;

    this.items.forEach((i) => {
      this.js().removeAttribute(i, 'aria-selected');
      this.js().setAttribute(i, 'tabindex', '-1');
    });

    this.js().setAttribute(item, 'aria-selected', 'true');
    this.js().setAttribute(item, 'tabindex', '0');
  },

  onItemClick(event) {
    this.selectItem(event.currentTarget);
  },

  onItemFocus(event) {
    this.selectItem(event.currentTarget);
  },

  onKeydown(event) {
    const currentItem = event.currentTarget;
    const currentIndex = this.items.indexOf(currentItem);
    if (currentIndex === -1) return;

    let newIndex = null;

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        newIndex = Math.min(currentIndex + 1, this.items.length - 1);
        break;
      case 'ArrowUp':
        event.preventDefault();
        newIndex = Math.max(currentIndex - 1, 0);
        break;
      default:
        return;
    }

    if (newIndex !== null && newIndex !== currentIndex) {
      const targetItem = this.items[newIndex];
      this.selectItem(targetItem);
      targetItem.focus();
    }
  },
};
