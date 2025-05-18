export const TravelMap = {
  mounted() {
    Promise.all([import('../../vendor/d3'), import('../../vendor/topojson')])
      .then(([d3Module, topojsonModule]) => {
        this.d3 = d3Module.default || d3Module;
        this.topojson = topojsonModule.default || topojsonModule;

        this.data = JSON.parse(this.el.getAttribute('data-trips'));

        this.initMap();
      })
      .catch((error) => {
        console.error('Error loading modules:', error);
      });
  },

  initMap() {
    const { d3, topojson } = this;

    // Map dimensions
    const width = this.el.offsetWidth;
    const height = 500;

    // Store base radius for city points and default transform
    this.baseRadius = 4;
    this.currentTransform = { k: 1 }; // Default zoom level

    // Create SVG map
    const svg = d3
      .select(this.el)
      .append('svg')
      .attr('width', width)
      .attr('height', height)
      .attr('viewBox', [0, 0, width, height])
      .attr('style', 'max-width: 100%; height: auto;');

    svg
      .append('rect')
      .attr('width', width)
      .attr('height', height)
      .attr('fill', 'none')
      .attr('pointer-events', 'all');

    // Create zoomable container
    const g = svg.append('g');

    // Define projection
    const projection = d3
      .geoMercator()
      .scale(width / 2 / Math.PI)
      .center([0, 20]) // Slightly north-shifted center
      .translate([width / 2, height / 2]);

    // Path generator
    const path = d3.geoPath().projection(projection);

    // Setup zoom behavior
    const zoom = d3
      .zoom()
      .scaleExtent([1, 8])
      .on('zoom', (event) => {
        // Update transform and container
        this.currentTransform = event.transform;
        g.attr('transform', event.transform);

        // Adjust city point sizes based on zoom level
        this.updateCityPointSizes();

        // Adjust any visible arcs
        this.updateArcThickness();
      });

    svg.call(zoom);

    // Load world map data
    d3.json('data/world-110m.json')
      .then((world) => {
        if (!world) {
          throw new Error('Failed to load world map data');
        }

        // Draw world map
        g.append('g')
          .selectAll('path')
          .data(topojson.feature(world, world.objects.countries).features)
          .enter()
          .append('path')
          .attr('d', path)
          .attr('class', 'country')
          .attr('fill', 'var(--color-surface-30, #e1e3e6)')
          .attr('stroke', 'var(--color-surface-40, #fbfcfd)')
          .attr('stroke-width', 0.5)
          .attr('cursor', 'pointer')
          // .on('mouseover', (event, d) => {
          // this.showCountryTooltip(d);
          // })
          .on('mouseout', () => {
            this.hideTooltip();
          });

        // Add country boundaries
        g.append('path')
          .datum(topojson.mesh(world, world.objects.countries, (a, b) => a !== b))
          .attr('d', path)
          .attr('class', 'country-boundary')
          .attr('fill', 'none')
          .attr('stroke', 'var(--color-surface-40, #e1e3e6)')
          .attr('stroke-width', 0.5);

        // Process trip data
        this.processTrips(g, projection);

        // Initial zoom to fit content
        const initialTransform = d3.zoomIdentity
          .translate(width / 2, height / 2)
          .scale(0.9)
          .translate(-width / 2, -height / 2);

        svg.call(zoom.transform, initialTransform);
      })
      .catch((error) => {
        console.error('Error loading world map data:', error);
      });
  },

  processTrips(g, projection) {
    const { d3 } = this;

    // Extract unique cities from trips
    const cities = new Map();

    this.data.forEach((trip) => {
      // Check if from and to coordinates exist
      if (trip.from && trip.to) {
        // Get coordinates
        const fromCoords = this.getPointCoordinates(trip.from);
        const toCoords = this.getPointCoordinates(trip.to);

        if (fromCoords && toCoords) {
          // Add origin city to unique cities map (without incrementing visit count)
          const fromKey = `${trip.origin}`;
          if (!cities.has(fromKey)) {
            cities.set(fromKey, {
              name: this.extractCityName(trip.origin),
              country: this.extractCountryName(trip.origin),
              coordinates: fromCoords,
              visits: 0, // Don't count as a visit (it's an origin)
            });
          }

          // Add destination city to unique cities map and increment visit count
          const toKey = `${trip.destination}`;
          if (!cities.has(toKey)) {
            cities.set(toKey, {
              name: this.extractCityName(trip.destination),
              country: this.extractCountryName(trip.destination),
              coordinates: toCoords,
              visits: 1,
            });
          } else {
            const city = cities.get(toKey);
            cities.set(toKey, {
              ...city,
              visits: city.visits + 1,
            });
          }
        }
      }
    });

    // Draw arcs for trips
    this.tripArcs = g
      .selectAll('.trip-arc')
      .data(this.data.filter((trip) => trip.from && trip.to))
      .enter()
      .append('path')
      .attr('class', 'trip-arc')
      .attr('d', (trip) => {
        const fromCoords = this.getPointCoordinates(trip.from);
        const toCoords = this.getPointCoordinates(trip.to);

        if (!fromCoords || !toCoords) return null;

        // Create an arc between the two points
        const source = projection([fromCoords[1], fromCoords[0]]);
        const target = projection([toCoords[1], toCoords[0]]);

        if (!source || !target) return null;

        // Calculate the arc
        const dx = target[0] - source[0];
        const dy = target[1] - source[1];
        const dr = Math.sqrt(dx * dx + dy * dy) * 1.2; // Adjust curve

        return `M${source[0]},${source[1]}A${dr},${dr} 0 0,1 ${target[0]},${target[1]}`;
      })
      .attr('fill', 'none')
      .attr('stroke', 'var(--color-content-40, #3b82f6)')
      .attr('stroke-width', 1.5)
      .attr('stroke-opacity', 0.6)
      .attr('stroke-linecap', 'round')
      .style('opacity', 0) // Initially hide all arcs
      .style('pointer-events', 'none'); // Prevent hidden arcs from capturing mouse events

    // Draw city points
    this.cityPoints = g
      .selectAll('.city')
      .data(Array.from(cities.values()))
      .enter()
      .append('circle')
      .attr('class', 'city')
      .attr('cx', (d) => {
        const point = projection([d.coordinates[1], d.coordinates[0]]);
        return point ? point[0] : null;
      })
      .attr('cy', (d) => {
        const point = projection([d.coordinates[1], d.coordinates[0]]);
        return point ? point[1] : null;
      })
      .attr('r', this.baseRadius)
      .attr('fill', 'var(--color-primary, #3b82f6)')
      .attr('stroke', 'var(--color-surface-20, #fbfcfd)')
      .attr('stroke-width', 1)
      .attr('cursor', 'pointer')
      .on('mouseover', (event, d) => {
        this.showTooltip(event, d);

        // Highlight the city point on hover
        d3.select(event.target)
          .attr('fill', 'var(--primary-focus, #2563eb)')
          .attr('r', (this.baseRadius * 2 * 1.25) / (this.currentTransform.k || 1))
          .attr('stroke-width', 1.5 / (this.currentTransform.k || 1));

        // Show arcs connected to this city
        this.showConnectedArcs(d);
      })
      .on('mouseout', (event) => {
        this.hideTooltip();

        // Restore normal appearance
        d3.select(event.target)
          .attr('fill', 'var(--color-primary, #3b82f6)')
          .attr('r', (this.baseRadius * 1.25) / (this.currentTransform.k || 1))
          .attr('stroke-width', 1 / (this.currentTransform.k || 1));

        // Hide all arcs
        this.hideAllArcs();
      });

    // Add tooltip container
    this.tooltip = d3
      .select(this.el)
      .append('div')
      .attr('class', 'tooltip')
      .style('position', 'absolute')
      .style('bottom', '20px')
      .style('right', '20px')
      .style('opacity', 0);
  },

  // Helper method to extract city name from location string (e.g., "Lisbon, Portugal" -> "Lisbon")
  extractCityName(location) {
    if (!location) return '';
    const parts = location.split(', ');
    return parts[0] || '';
  },

  // Helper method to extract country name from location string (e.g., "Lisbon, Portugal" -> "Portugal")
  extractCountryName(location) {
    if (!location) return '';
    const parts = location.split(', ');
    return parts.length > 1 ? parts[parts.length - 1] : '';
  },

  // Helper method to get coordinates from point object
  getPointCoordinates(point) {
    if (!point) return null;
    if (point.lat !== undefined && point.long !== undefined) {
      return [point.lat, point.long];
    }
    return null;
  },

  showTooltip(event, d) {
    // Create visit text based on visit count
    let visitText = '';
    if (d.visits > 0) {
      visitText = `<div class="text-content-40 text-sm mt-1">${d.visits} visit${
        d.visits > 1 ? 's' : ''
      }</div>`;
    } else {
      visitText = `<div class="text-content-40 text-sm mt-1">Departure city</div>`;
    }

    this.tooltip.style('opacity', 1).html(`
        <div class="font-medium">${d.name}</div>
        <div class="text-content-40 text-sm">${d.country}</div>
        ${visitText}
      `);
  },

  hideTooltip() {
    this.tooltip.style('opacity', 0);
  },

  // Show trip arcs that are connected to a specific city
  showConnectedArcs(city) {
    if (!this.tripArcs) return;

    const cityName = city.name;
    const countryName = city.country;
    const locationString = `${cityName}, ${countryName}`;

    // Calculate the adjusted stroke width based on zoom level
    const adjustedStrokeWidth = 1.5 / (this.currentTransform.k || 1);

    // Calculate adjusted dash pattern
    const dashLength = 1 / (this.currentTransform.k || 1);
    const gapLength = 2 / (this.currentTransform.k || 1);
    const adjustedDashPattern = `${dashLength},${gapLength}`;

    this.tripArcs
      .style('pointer-events', (trip) => {
        // Enable pointer events only for visible arcs
        if (trip.origin === locationString || trip.destination === locationString) {
          return 'auto';
        }
        return 'none';
      })
      .style('opacity', (trip) => {
        // Show arcs where this city is either origin or destination
        if (trip.origin === locationString || trip.destination === locationString) {
          return 1;
        }
        return 0;
      })
      .attr('stroke-width', adjustedStrokeWidth) // Adjust stroke width based on zoom
      .attr('stroke-dasharray', adjustedDashPattern); // Adjust dash pattern based on zoom
  },

  // Dynamically adjust city point sizes based on zoom level
  updateCityPointSizes() {
    if (!this.cityPoints) return;

    // Calculate the adjusted radius based on zoom level
    const adjustedRadius = (this.baseRadius * 1.25) / (this.currentTransform.k || 1);

    // Update all city points with the new radius
    this.cityPoints.attr('r', adjustedRadius);

    // Also adjust the stroke-width based on zoom to keep proportions
    const adjustedStrokeWidth = 1 / (this.currentTransform.k || 1);
    this.cityPoints.attr('stroke-width', adjustedStrokeWidth);
  },

  // Update arc thickness based on zoom level
  updateArcThickness() {
    const { d3 } = this;

    if (!this.tripArcs) return;

    // Only update arcs that are currently visible (opacity > 0)
    this.tripArcs
      .filter(function () {
        return d3.select(this).style('opacity') > 0;
      })
      .attr('stroke-width', 1.5 / (this.currentTransform.k || 1))
      .attr('stroke-dasharray', () => {
        // Adjust dash pattern based on zoom level
        const dashLength = 1 / (this.currentTransform.k || 1);
        const gapLength = 2 / (this.currentTransform.k || 1);
        return `${dashLength},${gapLength}`;
      });
  },

  // Hide all trip arcs
  hideAllArcs() {
    if (!this.tripArcs) return;
    this.tripArcs.style('opacity', 0).style('pointer-events', 'none');
  },
};
