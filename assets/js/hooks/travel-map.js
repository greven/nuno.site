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

    // Create a container for zoomable content
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
        g.attr('transform', event.transform);
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
          .attr('fill', 'var(--surface-70, #e1e3e6)')
          .attr('stroke', 'var(--surface-20, #fbfcfd)')
          .attr('stroke-width', 0.5);

        // Add ocean fill
        g.append('path')
          .datum(topojson.mesh(world, world.objects.countries, (a, b) => a !== b))
          .attr('d', path)
          .attr('class', 'country-boundary')
          .attr('fill', 'none')
          .attr('stroke', 'var(--surface-60, #e1e3e6)')
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
          // Add origin city to unique cities map
          const fromKey = `${trip.origin}`;
          if (!cities.has(fromKey)) {
            cities.set(fromKey, {
              name: this.extractCityName(trip.origin),
              country: this.extractCountryName(trip.origin),
              coordinates: fromCoords,
              visits: 1,
            });
          } else {
            const city = cities.get(fromKey);
            cities.set(fromKey, {
              ...city,
              visits: city.visits + 1,
            });
          }

          // Add destination city to unique cities map
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
    g.selectAll('.trip-arc')
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
      .attr('stroke', 'var(--primary, #3b82f6)')
      .attr('stroke-width', 1.5)
      .attr('stroke-opacity', 0.6)
      .attr('stroke-linecap', 'round');

    // Draw city points
    g.selectAll('.city')
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
      .attr('r', (d) => Math.min(3 + Math.sqrt(d.visits), 7)) // Size based on visits
      .attr('fill', 'var(--primary, #3b82f6)')
      .attr('stroke', 'var(--surface-20, #fbfcfd)')
      .attr('stroke-width', 1)
      .attr('cursor', 'pointer')
      .on('mouseover', (event, d) => this.showTooltip(event, d))
      .on('mouseout', () => this.hideTooltip());

    // Add tooltip container
    this.tooltip = d3
      .select(this.el)
      .append('div')
      .attr('class', 'tooltip')
      .style('position', 'absolute')
      .style('background', 'var(--surface-10, #ffffff)')
      .style('border', '1px solid var(--surface-90, #d1d5db)')
      .style('border-radius', '4px')
      .style('padding', '8px')
      .style('box-shadow', '0 2px 8px rgba(0, 0, 0, 0.1)')
      .style('pointer-events', 'none')
      .style('opacity', 0)
      .style('transition', 'opacity 0.2s');
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
    const { d3 } = this;

    this.tooltip
      .style('opacity', 1)
      .style('left', `${event.pageX + 10}px`)
      .style('top', `${event.pageY + 10}px`).html(`
        <div class="font-medium">${d.name}</div>
        <div class="text-content-40 text-sm">${d.country}</div>
        <div class="text-content-40 text-sm mt-1">${d.visits} visit${d.visits > 1 ? 's' : ''}</div>
      `);
  },

  hideTooltip() {
    this.tooltip.style('opacity', 0);
  },
};
