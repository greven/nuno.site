export const TravelMap = {
  mounted() {
    this.initialScaleK = 1; // Default zoom level for the whole map
    this.hoverZoomScaleK = 4; // Zoom level when hovering a list item
    this.initialLonLat = [0, 20]; // Initial longitude and latitude

    this.baseRadius = 4; // Base map pin point radius
    this.baseStrokeWidth = 1; // Base stroke width for pins
    this.currentTransform = { k: this.initialScaleK }; // Default zoom level

    this.locationsMap = new Map(); // Processed location data
    this.projection = null; // Map projection
    this.highlightedPin = { key: null, selection: null }; // { key, selection } of highlighted pin

    Promise.all([import('../../vendor/d3'), import('../../vendor/topojson')])
      .then(([d3Module, topojsonModule]) => {
        this.d3 = d3Module.default;
        this.topojson = topojsonModule.default;

        this.tooltip = this.d3
          .select(this.el)
          .append('div')
          .attr('class', 'map-tooltip')
          .style('opacity', 0)
          .style('position', 'absolute')
          .style('pointer-events', 'none');

        this.data = JSON.parse(this.el.getAttribute('data-trips'));
        this.listItems = document.querySelectorAll('[data-item="trip"]');

        // List items hover events
        this.listItems.forEach((item) => {
          item.addEventListener('mouseover', this.onListItemHover.bind(this));
          item.addEventListener('mouseout', this.onListItemLeave.bind(this));
        });

        // Map reset click event
        window.addEventListener('phx:map-reset', this.onReset.bind(this));

        // Let the party begin!
        this.initMap();
      })
      .catch((error) => {
        console.error('Error loading modules:', error);
      });
  },

  destroyed() {
    // Remove event listeners
    this.listItems.forEach((item) => {
      item.removeEventListener('mouseover', this.onListItemHover.bind(this));
      item.removeEventListener('mouseout', this.onListItemLeave.bind(this));
    });

    this.el.removeEventListener('phx:map-reset', this.onReset.bind(this));
  },

  initMap() {
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

    // Load World map data
    d3.json('data/world-110m.json').then((worldData) => {
      if (!worldData) {
        throw new Error('Failed to load world map data!');
      }

      const worldFeature = topojson.feature(worldData, worldData.objects.countries);
      const worldBounds = path.bounds(worldFeature);
      this.zoom.translateExtent(worldBounds);

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
          const [mouseX, mouseY] = this.d3.pointer(event, this.el);
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
          const [mouseX, mouseY] = this.d3.pointer(event, this.el);
          this.tooltip.style('left', `${mouseX + 15}px`).style('top', `${mouseY - 28}px`);
        })
        .on('mouseout', () => {
          this.tooltip.transition().duration(500).style('opacity', 0);
        });

      // Set initial map position and zoom using viewBox dimensions
      this.setMapPositionAndZoom(svg, projection, viewBoxWidth, viewBoxHeight);

      // Apply pin scaling
      if (this.pins) {
        const scaledRadius = this.baseRadius / this.currentTransform.k;
        const newRadius = Math.max(scaledRadius, this.baseRadius / 2); // Ensure min radius
        this.pins.attr('r', newRadius);

        const scaledStrokeWidth = this.baseStrokeWidth / this.currentTransform.k;
        const newStrokeWidth = Math.max(scaledStrokeWidth, 0.5); // Ensure min stroke
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

    if (locationData && locationData.coordinates) {
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

  onReset(event) {
    this.hideTooltip();
    if (this.highlightedPin && this.highlightedPin.key) {
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
