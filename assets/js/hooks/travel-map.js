export const TravelMap = {
  mounted() {
    this.initialScaleK = 1; // Zoom level
    this.initialLonLat = [0, 20]; // Initial longitude and latitude

    this.baseRadius = 4; // Base map pin point radius
    this.baseStrokeWidth = 1; // Base stroke width for pins
    this.currentTransform = { k: this.initialScaleK }; // Default zoom level

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
          .style('pointer-events', 'none'); // So it doesn't interfere with mouse events on the map

        this.data = JSON.parse(this.el.getAttribute('data-trips'));
        this.listItems = this.el.querySelectorAll('[data-item="trip"]');

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

    // Path generator
    const path = d3.geoPath().projection(projection);

    // Setup zoom behavior
    this.zoom = d3
      .zoom()
      .scaleExtent([1, 12]) // Zoom range relative to base projection
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

    // Process trip data to determine visited countries
    const locations = this.processData();
    const visitedCountries = new Set();

    for (const loc of locations.values()) {
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
        .data(Array.from(locations.values()))
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
        .on('click', (event, { country, name }) => {
          this.pushEvent('map-point-click', { country, name });
        })
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
    this.currentTransform = this.initialTransform;
    this.svg.call(this.zoom.transform, this.currentTransform);
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

    return locations;
  },

  onListItemHover(event) {
    // TODO: !
    console.log('mouseover', event);
  },

  onListItemLeave(event) {
    // TODO: !
    console.log('mouseout', event);
  },

  onReset(event) {
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
