/**
 * EmailProtection Hook
 *
 * Protects email addresses from spam bots by obfuscating
 * them in the HTML and revealing them only when the user
 * clicks on the link.
 *
 */
export const EmailLink = {
  mounted() {
    this.revealed = false;
    this.originalText = this.el.textContent;

    // Decode email from data attributes
    const user = this.el.dataset.emailUser;
    const domain = this.el.dataset.emailDomain;

    if (!user || !domain) {
      console.warn('EmailProtection: missing email-user or email-domain data attributes');
      return;
    }

    this.email = `${user}@${domain}`;

    // Handle click to reveal email
    this.el.addEventListener('click', (e) => {
      e.preventDefault();

      if (!this.revealed) {
        // Reveal the email
        this.el.textContent = this.email;
        this.el.href = `mailto:${this.email}`;
        this.revealed = true;

        // Add visual feedback
        this.el.classList.add('revealed');

        // Optional: Copy to clipboard
        if (this.el.dataset.emailCopy === 'true') {
          this.copyToClipboard(this.email);
        }
      } else {
        // If already revealed, follow the mailto link
        window.location.href = this.el.href;
      }
    });
  },

  copyToClipboard(text) {
    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(text).then(() => {
        // Optional: Show a toast notification
        this.el.setAttribute('data-copied', 'true');
        setTimeout(() => {
          this.el.removeAttribute('data-copied');
        }, 2000);
      });
    }
  },
};
