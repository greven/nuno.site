defmodule Site.Pulse.Helpers do
  @moduledoc false

  def strip_text(text) do
    text
    |> Site.Support.strip_tags()
    |> String.replace(~r/^\s*"\s*/, "")
    |> String.replace(~r/\s*"\s*$/, "")
    |> String.replace(~r/\s+/, " ")
  end

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
end
