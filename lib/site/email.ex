defmodule Site.Email do
  @moduledoc """
  Email related utilities, such as encryption for email obfuscation in the frontend.
  """

  @doc """
  AES-256-GCM encryption for email address obfuscation.

  Encrypts email addresses server-side so they can be safely embedded in HTML
  and decrypted client-side via the browser's SubtleCrypto API. This prevents
  email harvesting by bots that cannot execute JavaScript.

  The encrypted payload format is: `iv (12 bytes) || ciphertext || tag (16 bytes)`,
  encoded as URL-safe Base64 without padding.

  The encryption key must match the `EMAIL_KEY` constant in `assets/js/hooks/email-link.js`.
  Configure via `config :site, :email_encryption_key, "<base64-key>"` or the
  `EMAIL_ENCRYPTION_KEY` environment variable in production.

  Returns a URL-safe Base64 string containing the random IV, ciphertext,
  and GCM authentication tag concatenated together.
  """
  @spec encrypt(String.t()) :: String.t()
  def encrypt(email) when is_binary(email) do
    key = get_key()
    iv = :crypto.strong_rand_bytes(12)

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, email, "", true)

    Base.url_encode64(iv <> ciphertext <> tag, padding: false)
  end

  defp get_key do
    Application.fetch_env!(:site, :email_encryption_key)
    |> Base.decode64!()
  end
end
