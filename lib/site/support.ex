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
