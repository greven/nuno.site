export const TravelMap = {
  mounted() {
    this.trips = JSON.parse(this.el.getAttribute('data-trips'));

    console.log(this.trips);
  },
};
