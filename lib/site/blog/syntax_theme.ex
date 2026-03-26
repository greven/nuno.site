defmodule Site.Blog.SyntaxTheme do
  @moduledoc """
  Custom Lumis syntax theme.
  """

  # https://hexdocs.pm/mdex/custom_theme.html

  # Re-use Github Dark but change the background color to match our surface colors
  def umbra_theme do
    Lumis.Theme.get("github_dark")
    |> put_in([Access.key!(:highlights), Access.key!("normal"), Access.key!(:bg)], "#0E0E0E")
  end
end
