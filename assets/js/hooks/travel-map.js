export const TravelMap = {
  mounted() {
    this.baseRadius = 4; // Base map pin point radius
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

    // Define projection
    const projection = d3
      .geoMercator()
      .scale(width / 2 / Math.PI)
      .center([0, 28]) // Slightly north-shifted center
      .translate([width / 2, height / 2]);

    // Path generator
    const path = d3.geoPath().projection(projection);

    // Setup zoom behavior
    const zoom = d3
      .zoom()
      .scaleExtent([1, 4])
      .translateExtent([
        [0, 0],
        [width, height],
      ])
      .on('zoom', (event) => {
        this.currentTransform = event.transform;
        g.attr('transform', event.transform);
      });

    svg.call(zoom);

    // Load World map data
    d3.json('data/world-110m.json').then((data) => {
      if (!data) {
        throw new Error('Failed to load world map data!');
      }

      // Draw world map
      g.append('g')
        .selectAll('path')
        .data(topojson.feature(data, data.objects.countries).features)
        .enter()
        .append('path')
        .attr('d', path)
        .attr('class', 'country')
        .attr('fill', 'var(--color-surface-30)')
        .attr('stroke', 'var(--color-surface-40)')
        .attr('stroke-width', 0.5)
        .attr('cursor', 'pointer');

      // Process trip data
      const locations = this.processData();

      this.pins = g
        .selectAll('.city')
        .data(Array.from(locations.values()))
        .enter()
        .append('circle')
        .attr('class', 'map-pin')
        .attr('cx', (d) => {
          const pin = projection([d.coordinates[1], d.coordinates[0]]);
          return pin ? pin[0] : null;
        })
        .attr('cy', (d) => {
          const pin = projection([d.coordinates[1], d.coordinates[0]]);
          return pin ? pin[1] : null;
        })
        .attr('r', this.baseRadius)
        .attr('fill', 'var(--color-primary)')
        .attr('stroke', 'var(--color-surface-20)')
        .attr('stroke-width', 1)
        .attr('cursor', 'pointer');
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
  const parts = str.split(', ');
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
