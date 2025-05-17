export const TravelMap = {
  mounted() {
    import('../../vendor/d3').then((d3) => {
      this.trips = JSON.parse(this.el.getAttribute('data-trips'));
      this.container = this.el.querySelector('#travel-map');
    });
  },
};
