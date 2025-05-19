export const TravelMap = {
  mounted() {
    this.baseRadius = 4; // Base map pin point radius
    this.baseStrokeWidth = 1; // Base stroke width for pins
    this.currentTransform = { k: 1 }; // Default zoom level

    Promise.all([import('../../vendor/d3'), import('../../vendor/topojson')])
      .then(([d3Module, topojsonModule]) => {
        this.d3 = d3Module.default;
        this.topojson = topojsonModule.default;

        this.data = JSON.parse(this.el.getAttribute('data-trips'));

        this.initMap();
      })
      .catch((error) => {
        console.error('Error loading modules:', error);
      });
  },

  initMap() {
    const { d3, topojson } = this;

    // Dimensions
    const width = this.el.offsetWidth;
    const height = parseInt(this.el.getAttribute('data-height')) || 500;

    // SVG map
    const svg = d3
      .select(this.el)
      .append('svg')
      .attr('width', width)
      .attr('height', height)
      .attr('viewBox', [0, 0, width, height])
      .attr('style', 'max-width: 100%; height: auto;');

    // Background rectangle for pointer events
    svg
      .append('rect')
      .attr('width', width)
      .attr('height', height)
      .attr('fill', 'none')
      .attr('pointer-events', 'all');

    // Create zoomable group element / container for map features
    const g = svg.append('g');

    // Define base projection (fits most of the world)
    const projection = d3
      .geoMercator()
      .scale(width / (2 * Math.PI)) // Base scale to fit world width
      .center([0, 28]) // Initial center (can be adjusted by zoom transform)
      .translate([width / 2, height / 2]);

    // Path generator
    const path = d3.geoPath().projection(projection);

    // Setup zoom behavior
    const zoom = d3
      .zoom()
      .scaleExtent([1, 8]) // Zoom range relative to base projection
      .on('zoom', (event) => {
        this.currentTransform = event.transform;
        g.attr('transform', event.transform);

        // Adjust pin size and stroke width based on zoom level
        if (this.pins) {
          const scaledRadius = this.baseRadius / this.currentTransform.k;
          const newRadius = Math.max(scaledRadius, this.baseRadius / 2);
          this.pins.attr('r', newRadius);

          const scaledStrokeWidth = this.baseStrokeWidth / this.currentTransform.k;
          const newStrokeWidth = Math.max(scaledStrokeWidth, 0.5);
          this.pins.attr('stroke-width', newStrokeWidth);
        }
      });

    svg.call(zoom); // Attach zoom listener

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
      zoom.translateExtent(worldBounds); // Set translateExtent based on actual world projection

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
        });

      // Set initial map position and zoom to focus on Europe/US
      const targetLonLat = [-25, 45]; // Approx center for Europe/East US
      const initialScaleK = 2.0; // Zoom level

      const [mapX, mapY] = projection(targetLonLat); // Projected center of target

      // Calculate translation to center targetLonLat
      const tx = width / 2 - mapX * initialScaleK;
      const ty = height / 2 - mapY * initialScaleK;

      const initialTransform = d3.zoomIdentity.translate(tx, ty).scale(initialScaleK);

      svg.call(zoom.transform, initialTransform); // Apply initial transform
      this.currentTransform = initialTransform; // Update internal transform state

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
};

// ------------------- Helper Functions -------------------

// Helper method to extract location name from string (e.g., "Lisbon, Portugal" -> "Lisbon")
function extractCityName(str) {
  if (!str) return '';
  const parts = str.split(', ');
  return parts[0] || '';
}

// Helper method to extract country name from string (e.g., "Lisbon, Portugal" -> "Portugal")
function extractCountryName(str) {
  if (!str) return '';
  const parts = str.split(', '); // Corrected typo: removed "are"
  return parts.length > 1 ? parts[parts.length - 1] : '';
}

// Helper method to get coordinates from point object
function getPointCoordinates(point) {
  if (!point) return null;
  if (point.lat !== undefined && point.long !== undefined) {
    return [point.lat, point.long];
  }
  return null;
}
