export const PulseFeed = {
  mounted() {
    this.list = this.el.querySelector('ul');
    this.scrollContainer = this.el.querySelector('[id$="-scroll"]');
    this.topSpacer = this.el.querySelector('[id$="-top-spacer"]');
    this.bottomSpacer = this.el.querySelector('[id$="-bottom-spacer"]');

    this.scrollSnapshot = null;
    this.estimatedItemHeight = 80;
    this.totalItemsSeen = 0;

    this.setupItemListeners();
  },

  beforeUpdate() {
    this.scrollSnapshot = this.captureScrollAnchor();
  },

  updated() {
    if (this.scrollSnapshot) {
      this.restoreScrollAnchor(this.scrollSnapshot);
      this.scrollSnapshot = null;
    }

    this.setupItemListeners();
    this.updateSpacers();
  },

  destroyed() {
    this.removeItemListeners();
  },

  setupItemListeners() {
    this.removeItemListeners();
    this.items = Array.from(this.list.querySelectorAll('li[id]'));

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

  captureScrollAnchor() {
    if (!this.scrollContainer) return null;

    const containerTop = this.scrollContainer.scrollTop;
    const items = Array.from(this.list.querySelectorAll('li[id]'));

    // Find the first item whose bottom edge is visible in the scroll container
    const anchor = items.find((item) => {
      const rect = item.getBoundingClientRect();
      const containerRect = this.scrollContainer.getBoundingClientRect();
      return rect.bottom > containerRect.top;
    });

    if (!anchor) return null;

    const anchorRect = anchor.getBoundingClientRect();
    const containerRect = this.scrollContainer.getBoundingClientRect();

    return {
      id: anchor.id,
      // Distance from the top of the scroll container to the top of the anchor item
      offset: anchorRect.top - containerRect.top,
    };
  },

  restoreScrollAnchor({ id, offset }) {
    if (!this.scrollContainer) return;

    const anchor = document.getElementById(id);
    if (!anchor) return;

    const anchorRect = anchor.getBoundingClientRect();
    const containerRect = this.scrollContainer.getBoundingClientRect();
    const newOffset = anchorRect.top - containerRect.top;
    const drift = newOffset - offset;

    if (drift !== 0) {
      this.scrollContainer.scrollTop += drift;
    }
  },

  // Update top/bottom spacers to simulate a full-height scroll container.
  updateSpacers() {
    if (!this.topSpacer || !this.bottomSpacer) return;

    const renderedItems = Array.from(this.list.querySelectorAll('li[id]'));
    if (renderedItems.length === 0) return;

    const h = this.estimatedItemHeight;

    // How many real items exist above the current window
    const feedOffset = parseInt(this.el.dataset.feedOffset ?? '0', 10);

    // Track the furthest point we've ever reached to estimate the full list length
    const windowBottom = feedOffset + renderedItems.length;
    this.maxItemsSeen = Math.max(this.maxItemsSeen, windowBottom);

    const itemsBelow = Math.max(0, this.maxItemsSeen - windowBottom);

    this.topSpacer.style.height = `${feedOffset * h}px`;
    this.bottomSpacer.style.height = `${itemsBelow * h}px`;
  },

  selectItem(item) {
    const isSelected = item?.getAttribute('aria-selected') === 'true';
    if (!item && isSelected) return;

    // Deselect all items
    this.items.forEach((i) => {
      this.js().removeAttribute(i, 'aria-selected');
      this.js().setAttribute(i, 'tabindex', '-1');
    });

    // Select the clicked item
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
    const currentIndex = Array.from(this.items).indexOf(currentItem);
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
