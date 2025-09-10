const DAY_IN_MILLISECONDS = 24 * 60 * 60 * 1000;

export const Finder = {
  mounted() {
    this.finderDialog = document.getElementById('finder-dialog');
    this.finderInput = document.getElementById('finder-input');
    this.finderSections = this.el.querySelectorAll('section[id$="-section"]');
    this.finderItems = this.el.querySelectorAll('ul > li[role="option"]');
    this.finderEmpty = this.el.querySelector('#finder-no-results');
    this.finderResultsContainer = this.el.querySelector('#finder-search-results');
    this.finderResultsList = this.el.querySelector('ul#finder-search-items');

    // Search content cache
    this.searchCache = [];

    // Open custom event listener
    this.handleFinderOpen = this.handleFinderOpen.bind(this);
    this.el.addEventListener('phx:finder-open', this.handleFinderOpen);

    // Close custom event listener
    this.handleFinderClose = this.handleFinderClose.bind(this);
    this.el.addEventListener('phx:finder-close', this.handleFinderClose);

    // Toggle custom event listener
    this.handleFinderToggle = this.handleFinderToggle.bind(this);
    this.el.addEventListener('phx:finder-toggle', this.handleFinderToggle);

    // Window keydown event listener
    this.handleWindowKeydown = this.handleWindowKeydown.bind(this);
    window.addEventListener('keydown', this.handleWindowKeydown);

    // Input keydown event listener
    this.handleInputKeydown = this.handleInputKeydown.bind(this);
    this.finderInput.addEventListener('keydown', this.handleInputKeydown);

    // Input event listener
    this.handleInput = this.handleInput.bind(this);
    this.finderInput.addEventListener('input', this.handleInput);

    // Item mouseenter event listener
    this.handleItemMouseEnter = this.handleItemMouseEnter.bind(this);
    this.finderItems.forEach((item) => {
      item.addEventListener('mouseenter', this.handleItemMouseEnter);
    });

    // Item mouseleave event listener
    this.handleItemMouseLeave = this.handleItemMouseLeave.bind(this);
    this.finderItems.forEach((item) => {
      item.addEventListener('mouseleave', this.handleItemMouseLeave);
    });

    this.warmUpSearch();
  },

  destroyed() {
    window.removeEventListener('keydown', this.handleWindowKeydown);

    this.el.removeEventListener('phx:finder-open', this.handleFinderOpen);
    this.el.removeEventListener('phx:finder-close', this.handleFinderClose);
    this.el.removeEventListener('phx:finder-toggle', this.handleFinderToggle);

    this.finderInput.removeEventListener('keydown', this.handleInputKeydown);
    this.finderInput.removeEventListener('input', this.handleInput);
    this.finderItems.forEach((item) => {
      item.removeEventListener('mouseenter', this.handleItemMouseEnter);
    });
    this.finderItems.forEach((item) => {
      item.removeEventListener('mouseleave', this.handleItemMouseLeave);
    });
  },

  open() {
    this.reset();
    this.finderDialog.showModal();
  },

  close() {
    this.finderDialog.close();
  },

  toggle() {
    if (this.finderDialog?.open) {
      this.close();
    } else {
      this.open();
    }
  },

  reset() {
    this.el.setAttribute('data-mode', 'default');
    this.finderEmpty.hidden = true;
    this.finderResultsContainer.hidden = true;

    this.finderInput.value = '';
    this.finderSections.forEach((section) => {
      section.style.display = '';
    });

    this.finderItems.forEach((item) => {
      item.style.display = '';
    });
  },

  selectItem(item) {
    item?.setAttribute('aria-selected', 'true');
  },

  deselectItem(item) {
    item?.setAttribute('aria-selected', 'false');
  },

  focusNextItem() {
    const currentIndex = Array.from(this.finderItems).indexOf(document.activeElement);
    const nextIndex = (currentIndex + 1) % this.finderItems.length;
    this.finderItems[nextIndex].focus();
  },

  focusPreviousItem() {
    const currentIndex = Array.from(this.finderItems).indexOf(document.activeElement);
    const previousIndex = (currentIndex - 1 + this.finderItems.length) % this.finderItems.length;
    this.finderItems[previousIndex].focus();
  },

  // Given the finderItems and a query string we filter items returning only
  // those that match the query. The result is an array of the item ids.
  filterItemsByQuery(query) {
    const matchingItems = [];
    const str = query?.toLowerCase();

    this.finderItems.forEach((item) => {
      if (
        item.textContent.toLowerCase().includes(str) ||
        item.dataset.description?.toLowerCase().includes(str)
      ) {
        matchingItems.push(item.id);
      }
    });

    return matchingItems;
  },

  updateSectionVisibility(activeItems) {
    this.finderSections.forEach((section) => {
      const sectionItems = Array.from(section.querySelectorAll('[role="option"]'));
      const hasActiveItems = sectionItems.some((item) => activeItems.includes(item.id));
      section.style.display = hasActiveItems ? '' : 'none';
    });
  },

  updateSearchCache() {
    // Clear the search cache
    this.searchCache = [];

    // Clear the local storage
    localStorage.removeItem('ns_search');
    localStorage.removeItem('ns_search_timestamp');

    // Send server event to fetch new search data
    this.pushEventTo(this.el, 'finder:update_search', {}, (reply, ref) => {
      if (reply.status === 'ok') {
        localStorage.setItem('ns_search', JSON.stringify(reply.data));
        localStorage.setItem('ns_search_timestamp', Date.now());
        this.searchCache = reply.data;
      } else {
        console.error('NS: Failed to update search cache');
        this.searchCache = [];
      }
    });
  },

  // Warm up the search by preloading any necessary data. Save the server content
  // to local storage if not already cached or if cache is stale (more than 24h old).
  // Content items to search against are articles where each item has an id, title and keywords.
  warmUpSearch() {
    const cachedItems = localStorage.getItem('ns_search');
    const cacheTimestamp = localStorage.getItem('ns_search_timestamp');

    // If cache is fresh, use it
    if (cachedItems && cacheTimestamp) {
      const age = Date.now() - cacheTimestamp;

      if (age < DAY_IN_MILLISECONDS) {
        // Cache is fresh, use it
        this.searchCache = JSON.parse(cachedItems);
      } else {
        // Cache is stale, update it
        this.updateSearchCache();
      }
    } else {
      // Cache is empty, fetch new data
      this.updateSearchCache();
    }
  },

  searchArticles(query) {
    if (query.length > 1 && this.searchCache.length > 0) {
      const searchResults = [];

      this.searchCache.forEach((item) => {
        let title = item?.title.toLowerCase();
        let keywords = item?.keywords.map((k) => k.toLowerCase()).join(' ');

        if (title.includes(query) || keywords.includes(query)) {
          searchResults.push(item);
          return;
        }
      });

      if (searchResults.length > 0) {
        // Show search results
        this.finderEmpty.hidden = true;
        this.finderResultsContainer.hidden = true;
        this.renderSearchArticles(searchResults);
      } else {
        this.finderEmpty.hidden = false;
        this.finderResultsContainer.hidden = true;
      }
    } else {
      this.finderResultsContainer.hidden = true;
    }
  },

  renderSearchArticles(articles) {
    this.finderResultsList.innerHTML = '';

    articles.forEach((article) => {
      const itemTemplate = this.el.querySelector('ul#finder-theme-switcher > li');
      const iconTemplate = itemTemplate.querySelector('span[data-slot="icon"]');
      const textTemplate = itemTemplate.querySelector('span[data-slot="text"]');

      const fragment = document.createElement('li');
      fragment.dataset.id = article.id;
      fragment.dataset.year = article.year;
      fragment.className = itemTemplate.className;
      fragment.setAttribute('aria-selected', 'false');

      // Icon element
      const iconClassName = iconTemplate.className.replace('lucide-sun', 'lucide-file-text');
      fragment.appendChild(document.createElement('span')).className = iconClassName;

      // Text element
      const textElement = document.createElement('span');
      textElement.className = textTemplate.className;
      textElement.textContent = article.title;
      fragment.appendChild(textElement);

      this.finderResultsList.appendChild(fragment);
    });

    // Add mouse events
    this.finderResultsList?.querySelectorAll('li').forEach((item) => {
      item.addEventListener('click', () =>
        this.js().push(this.el, 'finder:navigate', {
          target: this.el,
          value: { year: item.dataset.year, id: item.dataset.id },
        })
      );
      item.addEventListener('mouseenter', this.handleResultsItemMouseEnter.bind(this));
      item.addEventListener('mouseleave', this.handleResultsItemMouseLeave.bind(this));
    });

    this.finderResultsContainer.hidden = false;
  },

  handleInput(event) {
    const query = event.target.value;

    // If the query is empty, show all items
    if (!query) {
      this.reset();
      return;
    }

    // Search the default items to filter results
    const matchingItems = this.filterItemsByQuery(query);
    this.updateSectionVisibility(matchingItems);

    if (query.startsWith('>')) {
      // If query stats with ">" set data-mode to search and trigger a content search
      this.el.setAttribute('data-mode', 'search');
      this.searchArticles(query.slice(1).trim());
    } else if (matchingItems.length > 0) {
      this.finderEmpty.hidden = true;
      // Search the default items to filter results
      this.finderItems.forEach((item) => {
        item.style.display = matchingItems.includes(item.id) ? '' : 'none';
      });
    } else {
      this.finderEmpty.hidden = false;
    }
  },

  // Handle arrow up and down items navigation
  handleInputKeydown(event) {
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      this.focusNextItem();
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      this.focusPreviousItem();
    }
  },

  handleWindowKeydown(event) {
    // Intercept ESC to clear the input if there is content
    if (event.key === 'Escape') {
      if (this.finderInput.value) {
        event.preventDefault();
        this.reset();
      }
    }

    if (event.key.toLowerCase() === 'k' && (event.ctrlKey || event.metaKey)) {
      event.preventDefault();
      this.toggle();
    }
  },

  handleFinderOpen(event) {
    event.preventDefault();
    this.open();
  },

  handleFinderClose(event) {
    event.preventDefault();
    this.close();
  },

  handleFinderToggle(event) {
    event.preventDefault();
    this.toggle();
  },

  handleItemMouseEnter(event) {
    const item = event.currentTarget;
    this.finderItems.forEach((i) => this.deselectItem(i));
    this.selectItem(item);
  },

  handleItemMouseLeave(event) {
    const item = event.currentTarget;
    this.deselectItem(item);
  },

  handleResultsItemMouseEnter(event) {
    const item = event.currentTarget;
    this.finderResultsList?.querySelectorAll('li').forEach((i) => this.deselectItem(i));
    this.selectItem(item);
  },

  handleResultsItemMouseLeave(event) {
    const item = event.currentTarget;
    this.deselectItem(item);
  },
};
