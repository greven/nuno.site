defmodule Site.Support do
  @moduledoc """
  General utilities and helper functions.
  """

  use Gettext, backend: SiteWeb.Gettext

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

  @doc """
  Strip HTML tags from a string while preserving the text content.
  """
  def strip_tags(text) do
    LazyHTML.from_fragment(text)
    |> LazyHTML.text()
    |> String.trim()
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
    if number >= 1_000 do
      number
      |> to_string()
      |> String.replace(~r/(?<=\d)(?=(\d{3})+(?!\d))/, ",")
    else
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

  @doc """
  Format a given `Date`, `DateTime` or `NaiveDateTime` to a string using the specified format.
  By default, it uses the format "%B %d, %Y" (e.g., "January 01, 2023") but the ouput
  can be customized by passing different options:

  ## Options

  - `:format` - The format string to use (default: "%B %d, %Y"). If the format string
    contains `%o`, it will be replaced with the day of the month with an ordinal suffix
    (e.g., "1st", "2nd", "3rd", "4th").
  - `:relative` - If true, returns a relative time string (e.g., "5 minutes ago")
    instead of a formatted date string.
  - `:cutoff_in_days` - If provided, and the option `relative` is true, the relative time
    string will only be returned if the difference is within this number of days.
    Otherwise, the original date will be formatted and returned.
  - `short` - If true and the option `relative` is true, use a shorter format
    for the relative time string. E.g., "5m ago" instead of "5 minutes ago", "1d ago".
    It is ignored if `relative` is false.
  """
  def format_date(date, opts \\ []) do
    format = Keyword.get(opts, :format, "%B %d, %Y")
    relative = Keyword.get(opts, :relative, false)
    cutoff = Keyword.get(opts, :cutoff_in_days, nil)
    short = Keyword.get(opts, :short, false)

    if relative do
      time_ago(date, cutoff_in_days: cutoff, short: short, format: format)
    else
      format_date_with_ordinal(date, format)
    end
  end

  @doc """
  Calendar.strftime with support for custom %o format for ordinal day.
  This function formats a date according to the given format string, allowing
  for a custom %o format that returns the day of the month with an ordinal suffix
  (e.g., "1st", "2nd", "3rd", "4th").
  """
  def format_date_with_ordinal(date, format) do
    # Handle custom %o format for ordinal day
    if String.contains?(format, "%o") do
      ordinal_day = ordinal_day(date)

      format
      |> String.replace("%o", ordinal_day)
      |> then(&Calendar.strftime(date, &1))
    else
      Calendar.strftime(date, format)
    end
  end

  defp ordinal_day(%Date{day: day}), do: ordinal_day(day)
  defp ordinal_day(%NaiveDateTime{day: day}), do: ordinal_day(day)

  defp ordinal_day(day) when is_integer(day) do
    suffix =
      case {rem(day, 100), rem(day, 10)} do
        # Special cases: 11th, 12th, 13th
        {n, _} when n in 11..13 -> "th"
        # 1st, 21st, 31st
        {_, 1} -> "st"
        # 2nd, 22nd
        {_, 2} -> "nd"
        # 3rd, 23rd
        {_, 3} -> "rd"
        # Everything else
        _ -> "th"
      end

    "#{day}#{suffix}"
  end

  @doc """
  Return the abbreviated month name for a given month number (1-12).
  1 -> "Jan", 2 -> "Feb", ..., 12 -> "Dec".
  """

  # Handle Date and DateTime struct
  def month_abbr(%Date{} = date), do: Calendar.strftime(date, "%b")
  def month_abbr(%DateTime{} = dt), do: Calendar.strftime(dt, "%b")
  def month_abbr(%NaiveDateTime{} = ndt), do: Calendar.strftime(ndt, "%b")

  def month_abbr(1), do: "Jan"
  def month_abbr(2), do: "Feb"
  def month_abbr(3), do: "Mar"
  def month_abbr(4), do: "Apr"
  def month_abbr(5), do: "May"
  def month_abbr(6), do: "Jun"
  def month_abbr(7), do: "Jul"
  def month_abbr(8), do: "Aug"
  def month_abbr(9), do: "Sep"
  def month_abbr(10), do: "Oct"
  def month_abbr(11), do: "Nov"
  def month_abbr(12), do: "Dec"

  def month_number("January"), do: {:ok, 1}
  def month_number("Jan"), do: {:ok, 1}
  def month_number("February"), do: {:ok, 2}
  def month_number("Feb"), do: {:ok, 2}
  def month_number("March"), do: {:ok, 3}
  def month_number("Mar"), do: {:ok, 3}
  def month_number("April"), do: {:ok, 4}
  def month_number("Apr"), do: {:ok, 4}
  def month_number("May"), do: {:ok, 5}
  def month_number("June"), do: {:ok, 6}
  def month_number("Jun"), do: {:ok, 6}
  def month_number("July"), do: {:ok, 7}
  def month_number("Jul"), do: {:ok, 7}
  def month_number("August"), do: {:ok, 8}
  def month_number("Aug"), do: {:ok, 8}
  def month_number("September"), do: {:ok, 9}
  def month_number("Sep"), do: {:ok, 9}
  def month_number("October"), do: {:ok, 10}
  def month_number("Oct"), do: {:ok, 10}
  def month_number("November"), do: {:ok, 11}
  def month_number("Nov"), do: {:ok, 11}
  def month_number("December"), do: {:ok, 12}
  def month_number("Dec"), do: {:ok, 12}
  def month_number(_), do: {:error, :invalid_month}

  @doc """
  List days of week names in a given locale.
  """
  def days_of_week_names(locale \\ :en)

  def days_of_week_names(:en) do
    [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ]
  end

  def days_of_week_names(:pt) do
    [
      "Segunda-Feira",
      "Terça-Feira",
      "Quarta-Feira",
      "Quinta-Feira",
      "Sexta-Feira",
      "Sábado",
      "Domingo"
    ]
  end

  @doc """
  Relative time humanized text format given a `Date`, `DateTime` or `NaiveDateTime`.

  Returns the time difference in words between the current time and the given datetime
  in text format, e.g. "5 minutes ago", "1 day ago", "3 hours ago", etc.

  If a Date is provided, it is assumed to be at midnight UTC of that date.

  | Range                         | Output
  ------------------------------------------------------------------------------
  | 0 seconds                     | "now"
  | 1 to 59 seconds               | "1 second ago" ... "59 seconds ago"
  | 60 to 119 seconds             | "1 minute ago"
  | 120 seconds to 59 minutes     | "2 minutes ago" ... "59 minutes ago"
  | 60 to 119 minutes             | "1 hour ago"
  | 120 minutes to 23 hours       | "2 hours ago" ... "23 hours ago"
  | 24 to 47 hours                | "1 day ago"
  | 48 hours to 6 days            | "2 days ago" ... "6 days ago"
  | 7 to 13 days                  | "1 week ago"
  | 14 to 27 days                 | "2 weeks ago" ... "3 weeks ago"
  | 28 days to 364 days           | "1 month ago" ... "11 months ago"
  | 365 days and above            | "1 year ago" ... "N years ago"

  ## Options

  - `:cutoff_in_days` - If provided, and the difference exceeds this number of days,
    the original datetime will be returned instead of a relative time string.
  - `short` - If true, use a shorter format for the relative time string. E.g.,
    "5m ago" instead of "5 minutes ago", "1d ago" instead of "1 day ago", etc.
  - `format` - The format to use when returning the original datetime.
  """

  @min_in_seconds 60
  @hour_in_seconds 60 * @min_in_seconds
  @day_in_seconds 24 * @hour_in_seconds
  @week_in_seconds 7 * @day_in_seconds
  @month_in_seconds 30 * @day_in_seconds
  @year_in_seconds 365 * @day_in_seconds

  def time_ago(date, options \\ [])

  def time_ago(%Date{} = date, options) do
    date
    |> NaiveDateTime.new!(~T[00:00:00])
    |> time_ago(options)
  end

  def time_ago(%DateTime{} = datetime, options) do
    cutoff = Keyword.get(options, :cutoff_in_days, nil)
    format = Keyword.get(options, :format, "%b %d, %Y")

    if cutoff && DateTime.diff(DateTime.utc_now(), datetime, :day) >= cutoff do
      Calendar.strftime(datetime, format)
    else
      datetime
      |> DateTime.to_naive()
      |> time_ago(options)
    end
  end

  def time_ago(%NaiveDateTime{} = datetime, options) do
    cutoff = Keyword.get(options, :cutoff_in_days, nil)
    format = Keyword.get(options, :format, "%b %d, %Y")
    short = Keyword.get(options, :short, false)

    if cutoff && NaiveDateTime.diff(NaiveDateTime.utc_now(), datetime, :day) >= cutoff do
      Calendar.strftime(datetime, format)
    else
      diff = NaiveDateTime.diff(NaiveDateTime.utc_now(), datetime, :second)

      cond do
        diff <= 0 -> "now"
        diff < @min_in_seconds -> seconds_ago(diff, short)
        diff < @hour_in_seconds -> minutes_ago(diff, short)
        diff < @day_in_seconds -> hours_ago(diff, short)
        diff < @week_in_seconds -> days_ago(diff, short)
        diff < @month_in_seconds -> weeks_ago(diff, short)
        diff < @year_in_seconds -> months_ago(diff, short)
        true -> years_ago(diff, short)
      end
    end
  end

  defp seconds_ago(seconds, true) do
    ngettext("%{seconds}s ago", "%{seconds}s ago", seconds, seconds: seconds)
  end

  defp seconds_ago(seconds, false) do
    ngettext("%{seconds} second ago", "%{seconds} seconds ago", seconds, seconds: seconds)
  end

  defp minutes_ago(seconds, true) do
    minutes = div(seconds, @min_in_seconds)
    ngettext("%{minutes}m ago", "%{minutes}m ago", minutes, minutes: minutes)
  end

  defp minutes_ago(seconds, false) do
    minutes = div(seconds, @min_in_seconds)
    ngettext("%{minutes} minute ago", "%{minutes} minutes ago", minutes, minutes: minutes)
  end

  defp hours_ago(seconds, true) do
    hours = div(seconds, @hour_in_seconds)
    ngettext("%{hours}h ago", "%{hours}h ago", hours, hours: hours)
  end

  defp hours_ago(seconds, false) do
    hours = div(seconds, @hour_in_seconds)
    ngettext("%{hours} hour ago", "%{hours} hours ago", hours, hours: hours)
  end

  defp days_ago(seconds, true) do
    days = div(seconds, @day_in_seconds)
    ngettext("%{days}d ago", "%{days}d ago", days, days: days)
  end

  defp days_ago(seconds, false) do
    days = div(seconds, @day_in_seconds)
    ngettext("%{days} day ago", "%{days} days ago", days, days: days)
  end

  defp weeks_ago(seconds, true) do
    weeks = div(seconds, @week_in_seconds)
    ngettext("%{weeks}w ago", "%{weeks}w ago", weeks, weeks: weeks)
  end

  defp weeks_ago(seconds, false) do
    weeks = div(seconds, @week_in_seconds)
    ngettext("%{weeks} week ago", "%{weeks} weeks ago", weeks, weeks: weeks)
  end

  defp months_ago(seconds, true) do
    months = div(seconds, @day_in_seconds * 30)
    ngettext("%{months}mo ago", "%{months}mo ago", months, months: months)
  end

  defp months_ago(seconds, false) do
    months = div(seconds, @day_in_seconds * 30)
    ngettext("%{months} month ago", "%{months} months ago", months, months: months)
  end

  defp years_ago(seconds, true) do
    years = div(seconds, @day_in_seconds * 365)
    ngettext("%{years}y ago", "%{years}y ago", years, years: years)
  end

  defp years_ago(seconds, false) do
    years = div(seconds, @day_in_seconds * 365)
    ngettext("%{years} year ago", "%{years} years ago", years, years: years)
  end

  ## Converters

  @doc """
  Converts bytes to megabytes.

  ## Examples

      iex> Site.Support.bytes_to_megabytes(1_048_576)
      1.0
  """
  def bytes_to_megabytes(bytes) do
    Float.round(bytes / 1_048_576, 2)
  end

  @doc """
  Converts bytes to gigabytes.

  ## Examples

      iex> Site.Support.bytes_to_gigabytes(1_073_741_824)
      1.0
  """
  def bytes_to_gigabytes(bytes) do
    Float.round(bytes / 1_073_741_824, 2)
  end

  @doc """
  Converts kilobytes to megabytes.

  ## Examples

      iex> Site.Support.kilobytes_to_megabytes(1_024)
      1.0
  """
  def kilobytes_to_megabytes(kilobytes) do
    Float.round(kilobytes / 1024, 2)
  end

  @doc """
  Converts megabytes to gigabytes.

  ## Examples

      iex> Site.Support.megabytes_to_gigabytes(1_024)
      1.0
  """
  def megabytes_to_gigabytes(megabytes) do
    Float.round(megabytes / 1024, 2)
  end
end
