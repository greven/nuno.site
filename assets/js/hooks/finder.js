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

    this.addMountedEventListeners();
    this.warmUpSearch();
  },

  destroyed() {
    this.removeMountedEventListeners();
  },

  addMountedEventListeners() {
    // Window keydown event listener
    this.handleWindowKeydown = this.handleWindowKeydown.bind(this);
    window.addEventListener('keydown', this.handleWindowKeydown);

    // Open custom event listener
    this.handleFinderOpen = this.handleFinderOpen.bind(this);
    this.el.addEventListener('phx:finder-open', this.handleFinderOpen);

    // Close custom event listener
    this.handleFinderClose = this.handleFinderClose.bind(this);
    this.el.addEventListener('phx:finder-close', this.handleFinderClose);

    // Toggle custom event listener
    this.handleFinderToggle = this.handleFinderToggle.bind(this);
    this.el.addEventListener('phx:finder-toggle', this.handleFinderToggle);

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
  },

  removeMountedEventListeners() {
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

    // Reset default items sections visibility
    this.finderSections.forEach((section) => {
      section.hidden = false;
    });

    this.finderItems.forEach((item) => {
      item.hidden = false;
    });

    this.clearCurrentItems();
  },

  getCurrentOptions() {
    return this.el.querySelectorAll('ul > li[role="option"]:not([hidden])');
  },

  setCurrentItem(item) {
    this.clearCurrentItems();

    // If no item is provided, set the first one as current
    if (!item) {
      const currentItems = this.getCurrentOptions();
      item = currentItems[0];
    }

    item.current = true;
    item.setAttribute('aria-selected', 'true');
    item.tabIndex = 0;
  },

  // Deselect all items
  clearCurrentItems() {
    const currentItems = this.getCurrentOptions();
    currentItems?.forEach((item) => {
      item.current = false;
      item.setAttribute('aria-selected', 'false');
      item.tabIndex = -1;
    });
  },

  updateSectionVisibility(activeItems) {
    this.finderSections.forEach((section) => {
      const sectionItems = Array.from(section.querySelectorAll('[role="option"]'));
      const hasActiveItems = sectionItems.some((item) => activeItems.includes(item.id));
      section.hidden = hasActiveItems ? false : true;
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

  // Search items by query, items to search depend on the current mode,
  // by `default` we search the default items (navigation / commands), if the
  // query starts with ">" we search content/articles (`search` mode).
  searchItems(query) {
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
        item.hidden = matchingItems.includes(item.id) ? false : true;
      });
    } else {
      this.finderEmpty.hidden = false;
    }

    this.setCurrentItem();
  },

  // Given the finderItems and a query string we filter items returning only
  // those that match the query. The result is an array of the item ids.
  filterItemsByQuery(query) {
    const matchingItems = [];
    const q = query?.toLowerCase();

    this.finderItems.forEach((item) => {
      if (
        item.textContent.toLowerCase().includes(q) ||
        item.dataset.description?.toLowerCase().includes(q) ||
        matchStringInitials(item.textContent, q)
      ) {
        matchingItems.push(item.id);
      }
    });

    return matchingItems;
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
      item.addEventListener('mouseenter', this.handleItemMouseEnter.bind(this));
      item.addEventListener('mouseleave', this.handleItemMouseLeave.bind(this));
    });

    this.finderResultsContainer.hidden = false;
  },

  // Event handlers

  handleInput(event) {
    const query = event.target.value;

    // If the query is empty, show all items
    if (!query) {
      this.reset();
      return;
    }

    this.searchItems(query);
  },

  handleWindowKeydown(event) {
    // Intercept ESC to clear the input if there is content
    if (event.key === 'Escape') {
      if (this.finderInput.value) {
        event.preventDefault();
        this.reset();
      }
    }

    // Intercept CMD/CTRL + K to toggle the finder
    if (event.key.toLowerCase() === 'k' && (event.ctrlKey || event.metaKey)) {
      event.preventDefault();
      this.toggle();
    }
  },

  handleInputKeydown(event) {
    // Navigation
    if (['ArrowUp', 'ArrowDown', 'Home', 'End'].includes(event.key)) {
      event.preventDefault();

      const currentItems = this.getCurrentOptions();
      const currentIndex = Array.from(currentItems).findIndex((item) => item.current);

      let newIndex = Math.max(0, currentIndex);

      // Navigation;
      if (event.key === 'ArrowDown') {
        newIndex = currentIndex + 1;
        if (newIndex >= currentItems.length) newIndex = 0;
      } else if (event.key === 'ArrowUp') {
        newIndex = currentIndex - 1;
        if (newIndex < 0) newIndex = currentItems.length - 1;
      } else if (event.key === 'Home') {
        newIndex = 0;
      } else if (event.key === 'End') {
        newIndex = currentItems.length - 1;
      }

      this.setCurrentItem(currentItems[newIndex]);
    }

    // Activate current item
    if (event.key === 'Enter') {
      const currentItems = this.getCurrentOptions();
      const currentIndex = Array.from(currentItems).findIndex((item) => item.current);
      const currentItem = currentItems[currentIndex];

      if (currentItem) {
        event.preventDefault();
        currentItem.click();
      }
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
    this.setCurrentItem(event.currentTarget);
  },

  handleItemMouseLeave(event) {
    this.clearCurrentItems();
  },
};

// HELPERS

// Check if the initials of the text match the query string
// E.g. the string "New Project" matches "NP", "np", "Np" or "nP"
function matchStringInitials(text, query) {
  const textInitials = text.match(/\b\w/g)?.join('').toLowerCase() || '';
  return textInitials === query.toLowerCase();
}
