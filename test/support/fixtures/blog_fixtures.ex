defmodule App.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Blog` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        body: "some body",
        excerpt: "some excerpt",
        slug: "some slug",
        title: "some title"
      })
      |> App.Blog.create_post()

    post
  end
end
