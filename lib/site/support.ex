defmodule Site.Support do
  @moduledoc """
  General utilities and helper functions.
  """

  ## Numbers

  @doc """
  Format number shortening big numbers into shorter versions
  """
  def format_number(number) when is_integer(number) or is_float(number) do
    cond do
      number >= 10_000 -> "#{Float.ceil(number / 1000, 1)}k"
      true -> number
    end
  end

  def format_number(number), do: number

  @doc """
  Create URL-friendly slugs.
  """
  def slugify(string, options \\ []) do
    separator = Keyword.get(options, :separator, "-")
    lowercase? = Keyword.get(options, :lowercase, true)

    string
    |> maybe_downcase(lowercase?)
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, separator)
    |> String.trim(separator)
  end

  defp maybe_downcase(string, true), do: String.downcase(string)
  defp maybe_downcase(string, false), do: string
end
