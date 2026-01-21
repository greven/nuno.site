export const TravelMap = {
  mounted() {
    this.initialScaleK = 1;
    this.hoverZoomScaleK = 4;
    this.initialLonLat = [0, 20];

    this.baseRadius = 4;
    this.baseStrokeWidth = 1;
    this.currentTransform = { k: this.initialScaleK }; // Default zoom level

    this.locationsMap = new Map(); // Processed location data
    this.projection = null;
    this.highlightedPin = { key: null, selection: null };

    this.showLoadingIndicator();
    this.scheduleMapInitialization();
  },

  scheduleMapInitialization() {
    // Use requestIdleCallback if available, otherwise setTimeout
    const scheduler = window.requestIdleCallback || ((cb) => setTimeout(cb, 1));

    scheduler(() => {
      this.loadMapDependencies()
        .then(() => {
          this.initializeMap();
        })
        .catch((error) => {
          console.error('Error loading map dependencies:', error);
          this.handleLoadError(error);
        });
    });
  },

  showLoadingIndicator() {
    const loader = document.createElement('div');
    loader.className = 'map-loading';
    loader.style.cssText = `
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      text-align: center;
      color: var(--color-content-40);
    `;
    loader.innerHTML = `
      <div class="animate-pulse">
        <svg class="inline-block w-8 h-8 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <p class="text-sm">Loading map...</p>
      </div>
    `;
    this.loadingIndicator = loader;
    this.el.appendChild(loader);
  },

  hideLoadingIndicator() {
    if (this.loadingIndicator) {
      this.loadingIndicator.remove();
      this.loadingIndicator = null;
    }
  },

  async loadMapDependencies() {
    try {
      const [d3Module, topojsonModule] = await Promise.all([
        import('d3'),
        import('topojson-client'),
      ]);

      this.d3 = d3Module;
      this.topojson = topojsonModule;

      return { d3: d3Module, topojson: topojsonModule };
    } catch (error) {
      throw new Error(`Failed to load map dependencies: ${error.message}`);
    }
  },

  initializeMap() {
    this.createTooltip();
    this.setupEventListeners();
    this.initMap();
  },

  createTooltip() {
    this.tooltip = this.d3
      .select(this.el)
      .append('div')
      .attr('class', 'map-tooltip')
      .style('opacity', 0)
      .style('position', 'absolute')
      .style('pointer-events', 'none');
  },

  setupEventListeners() {
    this.data = JSON.parse(this.el.getAttribute('data-trips'));
    this.listItems = document.querySelectorAll('[data-item="trip"]');

    // Event handlers
    this.listItemHoverHandler = this.onListItemHover.bind(this);
    this.listItemLeaveHandler = this.onListItemLeave.bind(this);
    this.resetHandler = this.onReset.bind(this);

    // List items hover events
    this.listItems.forEach((item) => {
      item.addEventListener('mouseenter', this.listItemHoverHandler);
      item.addEventListener('mouseleave', this.listItemLeaveHandler);
    });

    // Map reset click event
    window.addEventListener('phx:map-reset', this.resetHandler);
  },

  handleLoadError() {
    this.hideLoadingIndicator();

    // Graceful fallback when dependencies fail to load
    const errorMessage = document.createElement('div');
    errorMessage.className = 'map-error p-4 text-center text-content-40';
    errorMessage.innerHTML = `
      <p class="mb-2">Unable to load map components.</p>
      <p class="text-sm">Please refresh the page to try again.</p>
    `;
    this.el.appendChild(errorMessage);
  },

  destroyed() {
    // Remove event listeners
    if (this.listItems && this.listItemHoverHandler && this.listItemLeaveHandler) {
      this.listItems.forEach((item) => {
        item.removeEventListener('mouseenter', this.listItemHoverHandler);
        item.removeEventListener('mouseleave', this.listItemLeaveHandler);
      });
    }

    if (this.resetHandler) {
      window.removeEventListener('phx:map-reset', this.resetHandler);
    }
  },

  async initMap() {
    const { d3, topojson } = this;

    // ViewBox Dimensions
    const viewBoxWidth = this.el.offsetWidth;
    const viewBoxHeight = this.el.offsetHeight;

    // SVG map
    const svg = d3
      .select(this.el)
      .append('svg')
      .attr('viewBox', [0, 0, viewBoxWidth, viewBoxHeight])
      .attr('preserveAspectRatio', 'xMidYMid meet'); // Ensures aspect ratio is maintained

    // Background rectangle for pointer events, sized to the viewBox
    svg
      .append('rect')
      .attr('width', viewBoxWidth)
      .attr('height', viewBoxHeight)
      .attr('fill', 'none')
      .attr('pointer-events', 'all');

    this.svg = svg; // Store SVG reference

    // Create zoomable group element / container for map features
    const g = svg.append('g');

    // Define base projection (fits most of the world)
    const projection = d3
      .geoMercator()
      .scale(viewBoxWidth / (2 * Math.PI)) // Scale based on viewBox width
      .center([0, 28]) // Initial center
      .translate([viewBoxWidth / 2, viewBoxHeight / 2]); // Translate to center of viewBox
    this.projection = projection; // Store projection

    // Path generator
    const path = d3.geoPath().projection(projection);

    // Setup zoom behavior
    this.zoom = d3
      .zoom()
      .scaleExtent([1, 16]) // Zoom range relative to base projection
      .filter((event) => {
        // Allows wheel events (even with Ctrl) and mouse drag without Ctrl (typically left button).
        // Disallows zoom start with other mouse buttons (e.g., right/middle click).
        const allowEvent = (!event.ctrlKey || event.type === 'wheel') && !event.button;

        // If the event is a wheel event and it's allowed by the filter,
        // prevent the default browser scroll action.
        if (event.type === 'wheel' && allowEvent) {
          event.preventDefault();
        }

        return allowEvent;
      })
      .on('zoom', (event) => {
        this.currentTransform = event.transform;
        g.attr('transform', event.transform);

        // Adjust pin size and stroke width based on zoom level
        if (this.pins) {
          const scaledRadius = this.baseRadius / this.currentTransform.k;
          const newRadius = Math.max(scaledRadius, this.baseRadius / 7);
          this.pins.attr('r', newRadius);

          const scaledStrokeWidth = this.baseStrokeWidth / this.currentTransform.k;
          const newStrokeWidth = Math.max(scaledStrokeWidth, 0.25);
          this.pins.attr('stroke-width', newStrokeWidth);
        }
      });

    svg.call(this.zoom); // Attach zoom listener

    // Process trip data
    const processedLocations = this.processData();
    this.locationsMap = processedLocations;

    const visitedCountries = new Set();

    for (const loc of processedLocations.values()) {
      if (loc.visits > 0 && loc.country) {
        visitedCountries.add(loc.country);
      }
    }

    try {
      // Load world data asynchronously
      const worldData = await d3.json('data/world-110m.json');

      if (!worldData) {
        throw new Error('Failed to load world map data!');
      }

      const worldFeature = topojson.feature(worldData, worldData.objects.countries);
      const worldBounds = path.bounds(worldFeature);
      this.zoom.translateExtent(worldBounds);

      this.hideLoadingIndicator();

      requestAnimationFrame(() => {
        this.renderMap(g, path, worldFeature, visitedCountries, projection);
      });
    } catch (error) {
      console.error('Error loading world map:', error);
      this.handleLoadError(error);
    }
  },

  renderMap(g, path, worldFeature, visitedCountries, projection) {
    const { d3 } = this;

    // Draw world map
    g.append('g')
      .selectAll('path')
      .data(worldFeature.features)
      .enter()
      .append('path')
      .attr('d', path)
      .attr('class', (d_country) => {
        const geoCountryName = d_country.properties.name;
        return visitedCountries.has(geoCountryName) ? 'country visited' : 'country';
      })
      .attr('stroke', 'var(--color-surface-40)')
      .attr('stroke-width', 0.5)
      .attr('cursor', 'pointer');

    // Draw map pins
    this.pins = g
      .selectAll('.city')
      .data(Array.from(this.locationsMap.values()))
      .enter()
      .append('circle')
      .attr('class', 'map-pin')
      .attr('cx', (d_pin) => {
        const pin = projection([d_pin.coordinates[1], d_pin.coordinates[0]]);
        return pin ? pin[0] : null;
      })
      .attr('cy', (d_pin) => {
        const pin = projection([d_pin.coordinates[1], d_pin.coordinates[0]]);
        return pin ? pin[1] : null;
      })
      .attr('r', this.baseRadius)
      .attr('fill', 'var(--color-primary)')
      .attr('stroke', 'var(--color-surface-20)')
      .attr('stroke-width', this.baseStrokeWidth)
      .attr('cursor', 'pointer')
      .on('mouseover', (event, d_pin) => {
        const [mouseX, mouseY] = d3.pointer(event, this.el);
        this.tooltip.transition().duration(200).style('opacity', 0.9);
        this.tooltip
          .html(
            `<span class="tooltip-title">${d_pin.name}</span><br/>` +
              `<span class="tooltip-subtitle">${d_pin.country}</span><br/>` +
              `<span class="tooltip-info">${d_pin.visits} ${pluralize(
                'visit',
                'visits',
                d_pin.visits
              )}</span>`
          )
          .style('left', `${mouseX + 15}px`)
          .style('top', `${mouseY - 28}px`);
      })
      .on('mousemove', (event) => {
        const [mouseX, mouseY] = d3.pointer(event, this.el);
        this.tooltip.style('left', `${mouseX + 15}px`).style('top', `${mouseY - 28}px`);
      })
      .on('mouseout', () => {
        this.tooltip.transition().duration(500).style('opacity', 0);
      });

    // Set initial position in next frame to avoid blocking
    requestAnimationFrame(() => {
      const viewBoxWidth = this.el.offsetWidth;
      const viewBoxHeight = this.el.offsetHeight;
      this.setMapPositionAndZoom(this.svg, projection, viewBoxWidth, viewBoxHeight);

      if (this.pins) {
        const scaledRadius = this.baseRadius / this.currentTransform.k;
        const newRadius = Math.max(scaledRadius, this.baseRadius / 2);
        this.pins.attr('r', newRadius);

        const scaledStrokeWidth = this.baseStrokeWidth / this.currentTransform.k;
        const newStrokeWidth = Math.max(scaledStrokeWidth, 0.5);
        this.pins.attr('stroke-width', newStrokeWidth);
      }
    });
  },

  resetMap() {
    if (this.svg && this.zoom && this.initialTransform) {
      this.svg.transition().duration(750).call(this.zoom.transform, this.initialTransform);
    }
  },

  setMapPositionAndZoom(svg, projection, width, height) {
    const { d3 } = this;

    const targetLonLat = this.initialLonLat || [0, 20];
    const [mapX, mapY] = projection(targetLonLat);

    // Calculate translation to center targetLonLat
    const tx = width / 2 - mapX * this.initialScaleK;
    const ty = height / 2 - mapY * this.initialScaleK;

    const initialTransform = d3.zoomIdentity.translate(tx, ty).scale(this.initialScaleK);

    this.initialTransform = initialTransform; // Store initial transform
    this.currentTransform = initialTransform; // Update internal transform state

    svg.call(this.zoom.transform, this.currentTransform); // Apply initial transform
  },

  processData() {
    // Extract locations (cities, etc.) from trip data
    const locations = new Map();

    this.data.forEach((trip) => {
      if (trip.from && trip.to) {
        const fromCoords = getPointCoordinates(trip.from);
        const toCoords = getPointCoordinates(trip.to);

        if (fromCoords && toCoords) {
          // Add origin city to unique locations
          const fromKey = `${trip.origin}`;
          if (!locations.has(fromKey)) {
            locations.set(fromKey, {
              name: extractCityName(trip.origin),
              country: extractCountryName(trip.origin),
              coordinates: fromCoords,
              visits: 0, // Don't count origin as a visit
            });
          }

          // Add destination city to unique locations
          const toKey = `${trip.destination}`;
          if (!locations.has(toKey)) {
            locations.set(toKey, {
              name: extractCityName(trip.destination),
              country: extractCountryName(trip.destination),
              coordinates: toCoords,
              visits: 1,
            });
          } else {
            const city = locations.get(toKey);
            locations.set(toKey, {
              ...city,
              visits: city.visits + 1, // Increment visit count
            });
          }
        }
      }
    });

    return locations; // This is the local variable in processData, not this.locationsMap
  },

  // Helper to parse "City, Country" string into {name, country} object
  parseLocationKey(locationKey) {
    if (!locationKey || typeof locationKey !== 'string') return { name: null, country: null };
    const name = extractCityName(locationKey); // Uses existing global helper
    const country = extractCountryName(locationKey); // Uses existing global helper
    return { name, country: country || null }; // Ensure country is null if not present
  },

  // Helper to highlight or de-highlight a pin
  highlightPin(locationKeyToActOn, doHighlight) {
    if (!this.pins) return;

    // De-highlight current pin if necessary
    if (this.highlightedPin.selection) {
      const mustDehighlightCurrent =
        (doHighlight && this.highlightedPin.key !== locationKeyToActOn) ||
        (!doHighlight && this.highlightedPin.key === locationKeyToActOn);

      if (mustDehighlightCurrent) {
        const currentPinRadius = this.baseRadius / this.currentTransform.k;
        this.highlightedPin.selection
          .transition()
          .duration(150)
          .attr('r', Math.max(currentPinRadius, this.baseRadius / 8)) // Apply min radius rule
          .style('fill', 'var(--color-primary)');
        this.highlightedPin = { key: null, selection: null };
      }
    }

    // Highlight new pin if requested and not already de-highlighted
    if (doHighlight && !this.highlightedPin.selection) {
      // Ensure we only highlight if nothing is highlighted or it's a new pin
      const { name: targetName, country: targetCountry } =
        this.parseLocationKey(locationKeyToActOn);
      if (!targetName) return;

      const targetPinSelection = this.pins.filter(
        (d_pin) =>
          d_pin.name === targetName && (targetCountry ? d_pin.country === targetCountry : true)
      );

      if (!targetPinSelection.empty()) {
        const highlightedPinRadius = (this.baseRadius * 1.5) / this.currentTransform.k;
        targetPinSelection
          .raise()
          .transition()
          .duration(150)
          .attr('r', Math.max(highlightedPinRadius, this.baseRadius / 6))
          .style('fill', 'var(--color-info)');
        this.highlightedPin = { key: locationKeyToActOn, selection: targetPinSelection };
      }
    }
  },

  showTooltipForLocation(locationKey) {
    if (!this.tooltip || !this.locationsMap || !this.projection || !this.currentTransform) return;

    const locationData = this.locationsMap.get(locationKey);
    if (!locationData || !locationData.coordinates) {
      console.warn('Tooltip: Location data or coordinates not found for:', locationKey);
      return;
    }

    const [geoLat, geoLon] = locationData.coordinates;
    const [projectedX, projectedY] = this.projection([geoLon, geoLat]);
    const [screenX, screenY] = this.currentTransform.apply([projectedX, projectedY]);

    this.tooltip.transition().duration(200).style('opacity', 0.9);
    this.tooltip
      .html(
        `<span class="tooltip-title">${locationData.name}</span><br/>` +
          `<span class="tooltip-subtitle">${locationData.country}</span><br/>` +
          `<span class="tooltip-info">${locationData.visits} ${pluralize(
            'visit',
            'visits',
            locationData.visits
          )}</span>`
      )
      .style('left', `${screenX + 15}px`)
      .style('top', `${screenY - 28}px`);
  },

  hideTooltip() {
    if (this.tooltip) {
      this.tooltip.transition().duration(200).style('opacity', 0);
    }
  },

  onListItemHover(event) {
    const locationKey = event.currentTarget.dataset.destination;
    if (!locationKey || !this.locationsMap || !this.projection || !this.svg || !this.zoom) return;

    const locationData = this.locationsMap.get(locationKey);

    if (locationData?.coordinates) {
      const [geoLat, geoLon] = locationData.coordinates;
      const [mapX, mapY] = this.projection([geoLon, geoLat]);

      const viewBoxWidth = this.el.offsetWidth;
      const viewBoxHeight = this.el.offsetHeight;

      const tx = viewBoxWidth / 2 - mapX * this.hoverZoomScaleK;
      const ty = viewBoxHeight / 2 - mapY * this.hoverZoomScaleK;
      const hoverTransform = this.d3.zoomIdentity.translate(tx, ty).scale(this.hoverZoomScaleK);

      this.svg
        .transition()
        .duration(750)
        .call(this.zoom.transform, hoverTransform)
        .on('end.highlight', () => {
          this.highlightPin(locationKey, true);
          this.showTooltipForLocation(locationKey); // Show tooltip for the highlighted pin
        });
    } else {
      console.warn('Location data or coordinates not found for:', locationKey);
    }
  },

  onListItemLeave(event) {
    const locationKey = event.currentTarget.dataset.destination;
    if (!locationKey) return;

    this.hideTooltip();
    this.highlightPin(locationKey, false);
    this.resetMap();
  },

  onReset() {
    this.hideTooltip();
    if (this?.highlightedPin.key) {
      this.highlightPin(this.highlightedPin.key, false);
    }
    this.resetMap();
  },
};

// ------------------- Helper Functions -------------------

// Helper method to extract location name from string
function extractCityName(str) {
  if (!str || typeof str !== 'string') {
    return '';
  }
  const parts = str.split(', ');
  return parts[0] || '';
}

// Helper method to extract country name from string
function extractCountryName(str) {
  if (!str || typeof str !== 'string') {
    return '';
  }
  const parts = str.split(', ');
  return parts.length > 1 ? parts[parts.length - 1] : parts[0];
}

// Helper method to get coordinates from point object
function getPointCoordinates(point) {
  if (!point) return null;
  if (point.lat !== undefined && point.long !== undefined) {
    return [point.lat, point.long];
  }
  return null;
}

function pluralize(singular, plural, count) {
  return count === 1 ? singular : plural;
}
