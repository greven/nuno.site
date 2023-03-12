defmodule App.Helpers do
  @moduledoc """
  Small utilities and helper functions.
  """

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
end
