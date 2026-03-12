export const PulseFeed = {
  mounted() {
    this.itemsList = this.el.querySelector(`#${this.el.id}-list-container`);
    this.detailsList = this.el.querySelector(`#${this.el.id}-details-container`);
    this.placeholder = this.detailsList.querySelector(`#${this.detailsList.id}-placeholder`);

    this.setupItemListeners();
  },

  updated() {
    this.setupItemListeners();
  },

  destroyed() {
    this.removeItemListeners();
  },

  setupItemListeners() {
    this.removeItemListeners();
    this.items = Array.from(this.itemsList?.querySelectorAll('li[id]') ?? []);

    this.itemClick = (event) => this.onItemClick(event);
    this.itemFocus = (event) => this.onItemFocus(event);
    this.handleKeydown = (event) => this.onKeydown(event);

    this.items.forEach((item) => {
      item.addEventListener('click', this.itemClick);
      item.addEventListener('keydown', this.handleKeydown);
      item.addEventListener('focus', this.itemFocus);
    });
  },

  removeItemListeners() {
    if (!this.items) return;
    this.items.forEach((item) => {
      item.removeEventListener('click', this.itemClick);
      item.removeEventListener('keydown', this.handleKeydown);
      item.removeEventListener('focus', this.itemFocus);
    });
  },

  selectItem(item) {
    if (!item) return;

    // Hide placeholder when an item is selected
    this.js().addClass(this.placeholder, 'hidden');

    this.items.forEach((i) => {
      this.js().removeAttribute(i, 'aria-selected');
      this.js().setAttribute(i, 'tabindex', '-1');
    });

    this.js().setAttribute(item, 'aria-selected', 'true');
    this.js().setAttribute(item, 'tabindex', '0');
    this.showItemDetails(item);
  },

  showItemDetails(item) {
    if (!item) return;

    const detailsId = item.getAttribute('aria-controls');
    const details = document.querySelector(`#${detailsId}`);
    const itemsDetails = this.detailsList.querySelectorAll('[id$="-item-detail"]');

    if (details) {
      itemsDetails.forEach((itemDetail) => {
        this.js().addClass(itemDetail, 'hidden');
        this.js().setAttribute(itemDetail, 'aria-selected', 'false');
      });
      this.js().removeClass(details, 'hidden');
      this.js().setAttribute(details, 'aria-selected', 'true');
      details.focus();
    }
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
      case 'Enter':
        event.preventDefault();
        this.selectItem(currentItem);
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
