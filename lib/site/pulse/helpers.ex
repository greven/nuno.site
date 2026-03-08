defmodule Site.Pulse.Helpers do
  @moduledoc false

  def strip_text(text) do
    text
    |> Site.Support.strip_tags()
    |> String.replace(~r/^\s*"\s*/, "")
    |> String.replace(~r/\s*"\s*$/, "")
    |> String.replace(~r/\s+/, " ")
  end

  def maybe_parse_date(maybe_date) do
    parse_unix_timestamp(maybe_date) ||
      parse_rfc2822_date(maybe_date) ||
      parse_iso8601_date(maybe_date) ||
      parse_rfc822_date(maybe_date) ||
      parse_custom_date(maybe_date) ||
      DateTime.utc_now()
  end

  @doc """
  Parses a Unix timestamp (integer) into a `DateTime`.
  """
  def parse_unix_timestamp(timestamp) when is_float(timestamp) do
    parse_unix_timestamp(trunc(timestamp))
  end

  def parse_unix_timestamp(timestamp) when is_integer(timestamp) do
    case DateTime.from_unix(timestamp) do
      {:ok, dt} -> dt
      _ -> nil
    end
  end

  def parse_unix_timestamp(_), do: nil

  @doc """
  Parses an RFC 2822 date string (used in RSS feeds) into a `DateTime`.
  Returns `nil` if parsing fails.

  Example: "Tue, 03 Mar 2026 22:54:21 +0000"
  """
  def parse_rfc2822_date(""), do: nil

  def parse_rfc2822_date(date_str) when is_binary(date_str) do
    {{y, m, d}, {h, min, s}} = :httpd_util.convert_request_date(String.to_charlist(date_str))
    DateTime.new!(Date.new!(y, m, d), Time.new!(h, min, s), "Etc/UTC")
  rescue
    _ -> nil
  catch
    _, _ -> nil
  end

  def parse_rfc2822_date(_), do: nil

  @doc """
  Parses an ISO 8601 date string into a `DateTime`.
  Returns `nil` if parsing fails.
  """
  def parse_iso8601_date(""), do: nil

  def parse_iso8601_date(date_str) when is_binary(date_str) do
    case DateTime.from_iso8601(date_str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  def parse_iso8601_date(_), do: nil

  # Parse RFC822 date format used in RSS feeds
  # Example: "Thu, 5 Jan 2017 00:00:00 +0000"
  defp parse_rfc822_date(nil), do: nil
  defp parse_rfc822_date(""), do: nil

  # Try to extract just the date part
  # RSS dates look like: "Thu, 5 Jan 2017 00:00:00 +0000"
  defp parse_rfc822_date(date_string) when is_binary(date_string) do
    case Regex.run(~r/(\d{1,2})\s+(\w{3})\s+(\d{4})/, date_string) do
      [_, day, month_abbr, year] ->
        with {:ok, month} <- Site.Support.month_number(month_abbr),
             {day_int, ""} <- Integer.parse(day),
             {year_int, ""} <- Integer.parse(year),
             {:ok, date} <- Date.new(year_int, month, day_int) do
          DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  @doc """
  Parses date strings in the format dd MMM yyyy HH:mm:ss Z, commonly found in some feeds.
  Example: "3 Mar 2026 09:20:41 +0000"
  """
  def parse_custom_date(""), do: nil

  def parse_custom_date(date_str) when is_binary(date_str) do
    case Regex.run(
           ~r/(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\s+([+-]\d{4})/,
           date_str
         ) do
      [_, day, month_abbr, year, hour, minute, second, tz] ->
        with {:ok, month} <- Site.Support.month_number(month_abbr),
             {day_int, ""} <- Integer.parse(day),
             {year_int, ""} <- Integer.parse(year),
             {hour_int, ""} <- Integer.parse(hour),
             {minute_int, ""} <- Integer.parse(minute),
             {second_int, ""} <- Integer.parse(second) do
          tz_offset = String.to_integer(tz)
          tz_hours = div(tz_offset, 100)
          tz_minutes = rem(tz_offset, 100)

          case DateTime.new(
                 Date.new(year_int, month, day_int),
                 Time.new(hour_int, minute_int, second_int),
                 "Etc/UTC"
               ) do
            {:ok, dt} ->
              DateTime.add(dt, -(tz_hours * 3600 + tz_minutes * 60))

            _ ->
              nil
          end
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end
end
