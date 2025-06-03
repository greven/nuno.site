defmodule Site.Support do
  @moduledoc """
  General utilities and helper functions.
  """

  ## Strings

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

  def truncate_text(text, opts \\ []) when is_binary(text) do
    length = Keyword.get(opts, :length, 100)
    terminator = Keyword.get(opts, :terminator, "...")

    if String.length(text) > length do
      String.slice(text, 0, length) <> terminator
    else
      text
    end
  end

  ## Numbers

  @doc """
  Format number in a more human-readable way.
  """
  def format_number(number, precision \\ 2)

  def format_number(number, precision) when is_float(number) do
    integer_part = trunc(number)
    decimal_part = (number - integer_part) |> Float.round(precision)

    cond do
      decimal_part == 0 ->
        format_number(integer_part)

      decimal_part < 1 ->
        "#{format_number(integer_part)}.#{String.slice(Float.to_string(decimal_part), 2..-1//1)}"

      decimal_part >= 1 ->
        decimal_integer_part = trunc(decimal_part)
        decimal_decimal_part = decimal_part - decimal_integer_part
        integer_part = (integer_part + decimal_integer_part) |> format_number()

        if decimal_decimal_part == 0.0,
          do: integer_part,
          else: "#{integer_part}.#{String.slice(Float.to_string(decimal_decimal_part), 2..-1//1)}"
    end
  end

  def format_number(number, _) when is_integer(number) do
    cond do
      number >= 1_000 ->
        number
        |> to_string()
        |> String.replace(~r/(?<=\d)(?=(\d{3})+(?!\d))/, ",")

      true ->
        to_string(number)
    end
  end

  def format_number(number, _), do: number

  @doc """
  Abbreviate a number by converting it to a shortened format with unit suffixes,
  such as converting 1000 to 1K, 1000000 to 1M, etc.
  """
  def abbreviate_number(number) do
    cond do
      number >= 1_000_000 -> "#{div(number, 1_000_000)}M"
      number >= 1_000 -> "#{div(number, 1_000)}K"
      true -> to_string(number)
    end
  end

  ## Calendar, Dates and Time

  @min_in_seconds 60
  @hour_in_seconds 3600
  @day_in_seconds 86400

  @doc """
  Returns the time difference in words between the current time and the given datetime
  in text format, e.g. "5 minutes ago", "1 day ago", "3 hours ago", etc. The cutoff
  is 2 days, so anything older than that will just return the datetime.

  ## Examples

      iex> Site.Support.time_ago(~U[2025-04-12 17:58:46.503610Z])
      "3 minutes ago"

      iex> Site.Support.time_ago(~U[2025-04-11 17:58:46.503610Z])
      "1 day ago"
  """

  def time_ago(%Date{} = date) do
    date
    |> NaiveDateTime.new!(~T[00:00:00])
    |> time_ago()
  end

  def time_ago(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_naive()
    |> time_ago()
  end

  def time_ago(%NaiveDateTime{} = datetime) do
    diff = NaiveDateTime.diff(NaiveDateTime.utc_now(), datetime, :second)

    cond do
      diff < @min_in_seconds -> seconds_ago(diff)
      diff < @hour_in_seconds -> minutes_ago(diff)
      diff < @day_in_seconds -> hours_ago(diff)
      diff < 2 * @day_in_seconds -> days_ago(diff)
      true -> datetime
    end
  end

  defp seconds_ago(seconds) do
    case seconds do
      1 -> "1 second ago"
      _ -> "#{seconds} seconds ago"
    end
  end

  defp minutes_ago(seconds) do
    minutes = div(seconds, @min_in_seconds)

    case minutes do
      1 -> "1 minute ago"
      _ -> "#{minutes} minutes ago"
    end
  end

  defp hours_ago(seconds) do
    hours = div(seconds, @hour_in_seconds)

    case hours do
      1 -> "1 hour ago"
      _ -> "#{hours} hours ago"
    end
  end

  defp days_ago(seconds) do
    days = div(seconds, @day_in_seconds)

    case days do
      1 -> "1 day ago"
      _ -> "#{days} days ago"
    end
  end
end
