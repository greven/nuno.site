defmodule Site.BlueskyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Site.Bluesky` context.
  """

  def valid_bsky_post_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      did: "did:plc:1234567890abcdef",
      rkey: "1234567890abcdef",
      cid: "bafyreigh2akiscaildc3n5u5t6g7h4g5h7g4h5g4h5g4h5g4h5g4h5g4h5g4h5g4",
      uri: "at://did:plc:1234567890abcdef/posts/1234567890abcdef",
      url: "https://bsky.app/profile/user/posts/1234567890abcdef",
      text: "This is a sample Bluesky post content.",
      created_at: ~U[2024-01-01 12:00:00Z],
      like_count: 10,
      repost_count: 2,
      reply_count: 5,
      author_handle: "user.bsky.app",
      author_name: "Sample User",
      avatar_url: "https://bsky.app/avatar/user.png",
      embed: %{}
    })
  end

  def bsky_post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> valid_bsky_post_attributes()
      |> Site.Services.Bluesky.create_post()

    post
  end
end
