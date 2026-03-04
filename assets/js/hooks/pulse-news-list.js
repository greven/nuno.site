export const PulseNewsList = {
  mounted() {
    this.list = this.el.querySelector('ul');
    this.items = this.list.querySelectorAll('li');

    // Event Handlers
    this.itemClick = (event) => this.onItemClick(event);
    this.itemFocus = (event) => this.onItemFocus(event);
    this.handleKeydown = (event) => this.onKeydown(event);

    // Event Listeners
    this.items.forEach((item) => {
      const article = item.querySelector('article');

      item.addEventListener('click', this.itemClick);
      item.addEventListener('keydown', this.handleKeydown);
      article.addEventListener('focus', this.itemFocus);
    });
  },

  destroyed() {
    this.items.forEach((item) => {
      const article = item.querySelector('article');

      item.removeEventListener('click', this.itemClick);
      item.removeEventListener('keydown', this.handleKeydown);
      article.removeEventListener('focus', this.itemFocus);
    });
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

    if (!currentItem) return;

    let newIndex = null;

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        newIndex = (currentIndex + 1) % this.items.length;
        break;
      case 'ArrowUp':
        event.preventDefault();
        newIndex = (currentIndex - 1 + this.items.length) % this.items.length;
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
