defmodule Site.Blog.SyntaxTheme do
  @moduledoc """
  Custom Lumis syntax theme.
  """

  # https://hexdocs.pm/mdex/custom_theme.html

  @doc """
  Re-use Github Themes but change the background color to match our surface colors
  """
  def light do
    Lumis.Theme.get("github_light")
    |> put_in([Access.key!(:name)], "umbra_light")
    |> put_in(
      [Access.key!(:highlights), Access.key!("normal"), Access.key!(:bg)],
      "var(--color-surface-20)"
    )
  end

  @doc """
  Re-use Github Themes but change the background color to match our surface colors
  """
  def dark do
    Lumis.Theme.get("github_dark")
    |> put_in([Access.key!(:name)], "umbra_dark")
    |> put_in(
      [Access.key!(:highlights), Access.key!("normal"), Access.key!(:bg)],
      "var(--color-surface-20)"
    )
  end
end
