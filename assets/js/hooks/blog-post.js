export const BlogPost = {
  mounted() {
    // Code Blocks
    this.codeBlocks = this.el.querySelectorAll('.code-block');
    this.codeBlocks.forEach((codeBlock) => this.setCopyButton(codeBlock));
  },

  setCopyButton(codeBlock) {
    const copyButton = codeBlock.querySelector('.code-block-copy-button');
    if (!copyButton) return;

    const copyButtonIcon = copyButton.querySelector('span.lucide-copy');
    const copyButtonCheckIcon = copyButton.querySelector('span.lucide-check');

    copyButton.addEventListener('click', () => {
      const code = codeBlock.querySelector('pre').textContent.trim();
      navigator.clipboard.writeText(code).then(() => {
        copyButtonIcon.style.display = 'none';
        copyButtonCheckIcon.style.display = 'inline-block';
        setTimeout(() => {
          copyButtonIcon.style.display = 'inline-block';
          copyButtonCheckIcon.style.display = 'none';
        }, 2000);
      });
    });
  },
};
