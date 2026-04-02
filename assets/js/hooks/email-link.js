/**
 * EmailLink Hook
 *
 * Protects email addresses from spam bots using AES-256-GCM encryption.
 * The email is encrypted server-side (Elixir) and decrypted here using
 * the browser's built-in SubtleCrypto API, which bots typically cannot access,
 * so the security of the encryption relies on obscurity rather than a secret key.
 *
 * SubtleCrypto is only available in secure contexts (https or localhost).
 *
 * The key below must match `config :site, :email_encryption_key` in the server config.
 * Generate a new key pair with:
 *   mix run --no-start -e ':crypto.strong_rand_bytes(32) |> Base.encode64() |> IO.puts()'
 */

// AES-256-GCM key — must match config :site, :email_encryption_key
const EMAIL_KEY = '4rXTFAJnDzhMEqdaF269tV/5I3Omd7oKXK063qMiAYI=';

async function decryptEmail(encryptedBase64url) {
  // Import raw key bytes
  const keyBytes = Uint8Array.from(atob(EMAIL_KEY), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('raw', keyBytes, { name: 'AES-GCM' }, false, [
    'decrypt',
  ]);

  // Decode base64url → bytes (iv ++ ciphertext ++ tag)
  const b64 = encryptedBase64url.replace(/-/g, '+').replace(/_/g, '/');
  const data = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));

  // Split: first 12 bytes are the IV; the rest is ciphertext+tag (SubtleCrypto expects them concatenated)
  const iv = data.slice(0, 12);
  const ciphertextAndTag = data.slice(12);

  const decrypted = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, ciphertextAndTag);
  return new TextDecoder().decode(decrypted);
}

export const EmailLink = {
  async mounted() {
    this.revealed = false;
    this.originalText = this.el.textContent;

    if (!window.crypto?.subtle) {
      console.warn('EmailLink: SubtleCrypto unavailable (requires a secure context)');
      return;
    }

    try {
      this.email = await decryptEmail(this.el.dataset.email);
    } catch {
      console.warn('EmailLink: failed to decrypt email');
      return;
    }

    this.el.addEventListener('click', (e) => {
      e.preventDefault();

      if (!this.revealed) {
        this.el.textContent = this.email;
        this.el.href = `mailto:${this.email}`;
        this.el.classList.add('revealed');
        this.revealed = true;

        if (this.el.dataset.emailCopy === 'true') {
          this.copyToClipboard(this.email);
        }
      } else {
        window.location.href = this.el.href;
      }
    });
  },

  copyToClipboard(text) {
    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(text).then(() => {
        this.el.setAttribute('data-copied', 'true');
        setTimeout(() => this.el.removeAttribute('data-copied'), 2000);
      });
    }
  },
};
