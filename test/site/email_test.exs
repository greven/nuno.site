defmodule Site.EmailTest do
  use ExUnit.Case

  alias Site.Email

  describe "encrypt/1" do
    test "returns a URL-safe, unpadded base64 string" do
      encrypted = Email.encrypt("test@example.com")

      assert is_binary(encrypted)
      assert String.match?(encrypted, ~r/^[A-Za-z0-9_-]+$/)
      refute String.contains?(encrypted, "=")
    end

    test "produces different ciphertext for the same email (random IV)" do
      refute Email.encrypt("test@example.com") == Email.encrypt("test@example.com")
    end

    test "round-trips back to the original email" do
      email = "nuno@example.com"
      encrypted = Email.encrypt(email)

      key = Base.decode64!(Application.fetch_env!(:site, :email_encryption_key))
      <<iv::binary-size(12), rest::binary>> = Base.url_decode64!(encrypted, padding: false)
      ciphertext_size = byte_size(rest) - 16

      <<ciphertext::binary-size(^ciphertext_size), tag::binary-size(16)>> = rest

      decrypted =
        :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, "", tag, false)

      assert decrypted == email
    end
  end
end
