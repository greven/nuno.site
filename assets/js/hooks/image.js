export const Image = {
  mounted() {
    const image = this.el;
    const imageId = this.el.getAttribute('id');
    const imageHash = document.getElementById(`${imageId}-hash`);

    console.log({image, imageHash})

    if(imageHash) {
      image.onload = () => {
        imageHash.classList.add('hidden');
        image.classList.remove('hidden');
      }
    }
  },
};
