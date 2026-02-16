defmodule Site.Services.Weather do
  @moduledoc """
  Weather information service using Open Meteo API (https://open-meteo.com).
  """

  alias __MODULE__.Forecast
  alias __MODULE__.Current
  alias __MODULE__.Daily
  alias __MODULE__.AirQuality

  @doc """
  Fetches weather information for the configured location.
  Returns {:ok, weather_data} on success or {:error, reason} on failure.
  """

  def get_forecast do
    Req.get(forecast_endpoint(), params: forecast_params())
    |> case do
      {:ok, %{status: 200} = %{body: body}} -> {:ok, map_weather_response(body)}
      {:ok, resp} -> {:error, resp.status}
      {:error, _} = error -> error
    end
  end

  def get_air_quality do
    Req.get(air_quality_endpoint(), params: air_quality_params())
    |> case do
      {:ok, %{status: 200} = %{body: body}} -> {:ok, map_air_quality_response(body)}
      {:ok, resp} -> {:error, resp.status}
      {:error, _} = error -> error
    end
  end

  defp map_weather_response(body) do
    %Forecast{
      current: map_current_weather(body),
      daily: map_daily_weather(body),
      elevation: body["elevation"],
      latitude: body["latitude"],
      longitude: body["longitude"],
      utc_offset: body["utc_offset_seconds"],
      timezone_abbr: body["timezone_abbreviation"]
    }
  end

  defp map_current_weather(body) do
    values = body["current"]
    units = body["current_units"]

    utc_offset_seconds = body["utc_offset_seconds"]
    datetime = parse_datetime(values["time"], utc_offset_seconds)

    %Current{
      time: datetime,
      temperature: %{value: values["temperature_2m"], unit: units["temperature_2m"]},
      apparent_temperature: %{
        value: values["apparent_temperature"],
        unit: units["apparent_temperature"]
      },
      precipitation: %{value: values["precipitation"], unit: units["precipitation"]},
      rain: %{value: values["rain"], unit: units["rain"]},
      showers: %{value: values["showers"], unit: units["showers"]},
      snowfall: %{value: values["snowfall"], unit: units["snowfall"]},
      relative_humidity: %{
        value: values["relative_humidity_2m"],
        unit: units["relative_humidity_2m"]
      },
      surface_pressure: %{value: values["surface_pressure"], unit: units["surface_pressure"]},
      sea_pressure: %{value: values["pressure_msl"], unit: units["pressure_msl"]},
      wind_direction: %{value: values["wind_direction_10m"], unit: units["wind_direction_10m"]},
      wind_speed: %{value: values["wind_speed_10m"], unit: units["wind_speed_10m"]},
      wind_gusts: %{value: values["wind_gusts_10m"], unit: units["wind_gusts_10m"]},
      cloud_cover: %{value: values["cloud_cover"], unit: units["cloud_cover"]},
      weather_code: values["weather_code"],
      is_day: values["is_day"] == 1
    }
  end

  defp map_daily_weather(body) do
    values = body["daily"]
    units = body["daily_units"]

    utc_offset_seconds = body["utc_offset_seconds"]

    %Daily{
      days: Enum.map(values["time"], &Date.from_iso8601!/1),
      temperature_min: %{unit: units["temperature_2m_min"], values: values["temperature_2m_min"]},
      temperature_max: %{unit: units["temperature_2m_max"], values: values["temperature_2m_max"]},
      rain_sum: %{unit: units["rain_sum"], values: values["rain_sum"]},
      showers_sum: %{unit: units["showers_sum"], values: values["showers_sum"]},
      snowfall_sum: %{unit: units["snowfall_sum"], values: values["snowfall_sum"]},
      precipitation_sum: %{unit: units["precipitation_sum"], values: values["precipitation_sum"]},
      precipitation_probability_max: %{
        unit: units["precipitation_probability_max"],
        values: values["precipitation_probability_max"]
      },
      uv_index_max: values["uv_index_max"],
      daylight_duration: %{unit: units["daylight_duration"], values: values["daylight_duration"]},
      sunshine_duration: %{unit: units["sunshine_duration"], values: values["sunshine_duration"]},
      sunrise: Enum.map(values["sunrise"], &parse_datetime(&1, utc_offset_seconds)),
      sunset: Enum.map(values["sunset"], &parse_datetime(&1, utc_offset_seconds)),
      weather_code: values["weather_code"]
    }
  end

  defp map_air_quality_response(body) do
    values = body["current"]
    units = body["current_units"]

    utc_offset_seconds = body["utc_offset_seconds"]
    datetime = parse_datetime(values["time"], utc_offset_seconds)

    %AirQuality{
      aqi: values["european_aqi"],
      unit: units["european_aqi"],
      time: datetime,
      elevation: body["elevation"],
      latitude: body["latitude"],
      longitude: body["longitude"],
      utc_offset: body["utc_offset_seconds"],
      timezone_abbr: body["timezone_abbreviation"]
    }
  end

  defp parse_datetime(datetime_str, utc_offset_seconds) do
    utc_offset = format_utc_offset(utc_offset_seconds)

    case DateTime.from_iso8601("#{datetime_str}:00#{utc_offset}") do
      {:ok, dt, _} -> dt
      {:error, _} -> nil
    end
  end

  defp format_utc_offset(seconds) when seconds == 0, do: "Z"

  defp format_utc_offset(seconds) do
    sign = if seconds >= 0, do: "+", else: "-"
    abs_seconds = abs(seconds)
    hours = div(abs_seconds, 3600)
    minutes = div(rem(abs_seconds, 3600), 60)

    "#{sign}#{String.pad_leading(Integer.to_string(hours), 2, "0")}:#{String.pad_leading(Integer.to_string(minutes), 2, "0")}"
  end

  @doc """
  WMO Weather interpretation codes (WW).
  Translates the weather code from the API to a human-readable description.
  Source: https://open-meteo.com/en/docs#weather_variable_documentation
  """
  def weather_description(code) when is_integer(code) do
    case code do
      0 -> "Clear sky"
      1 -> "Mainly clear"
      2 -> "Partly cloudy"
      3 -> "Overcast"
      45 -> "Fog"
      48 -> "Rime fog"
      51 -> "Light drizzle"
      53 -> "Moderate drizzle"
      55 -> "Dense drizzle"
      56 -> "Light freezing drizzle"
      57 -> "Dense freezing drizzle"
      61 -> "Slight rain"
      63 -> "Moderate rain"
      65 -> "Heavy rain"
      66 -> "Light freezing rain"
      67 -> "Heavy freezing rain"
      71 -> "Slight snow fall"
      73 -> "Moderate snow fall"
      75 -> "Heavy snow fall"
      77 -> "Snow grains"
      80 -> "Slight rain showers"
      81 -> "Moderate rain showers"
      82 -> "Violent rain showers"
      85 -> "Slight snow showers"
      86 -> "Heavy snow showers"
      95 -> "Thunderstorm"
      96 -> "Thunderstorm with slight hail"
      99 -> "Thunderstorm with heavy hail"
      _ -> :unknown
    end
  end

  @doc """
  Like weather_description/1 but returns a shorter description
  suitable for compact UI elements.
  """
  def weather_short_description(code) when is_integer(code) do
    case code do
      0 -> "Clear sky"
      1 -> "Mainly clear"
      2 -> "Partly cloudy"
      3 -> "Overcast"
      45 -> "Fog"
      48 -> "Rime fog"
      51 -> "Drizzle"
      53 -> "Drizzle"
      55 -> "Drizzle"
      56 -> "Freezing drizzle"
      57 -> "Freezing drizzle"
      61 -> "Slight rain"
      63 -> "Moderate rain"
      65 -> "Heavy rain"
      66 -> "Freezing rain"
      67 -> "Freezing rain"
      71 -> "Snow fall"
      73 -> "Snow fall"
      75 -> "Snow fall"
      77 -> "Snow grains"
      80 -> "Rain showers"
      81 -> "Rain showers"
      82 -> "Rain showers"
      85 -> "Snow showers"
      86 -> "Snow showers"
      95 -> "Thunderstorm"
      96 -> "Thunderstorm"
      99 -> "Thunderstorm"
      _ -> :unknown
    end
  end

  @doc """
  UV index scale interpretation.
  Translates the UV index value from the API to a human-readable description.
  """
  def uv_index_description(index) when is_integer(index) do
    cond do
      index <= 2 -> "Low"
      index <= 5 -> "Moderate"
      index <= 7 -> "High"
      index <= 10 -> "Very High"
      index >= 11 -> "Extreme"
      true -> :unknown
    end
  end

  defp forecast_params do
    [
      timezone: "Europe/London",
      latitude: coords()[:latitude],
      longitude: coords()[:longitude],
      current: current_params(),
      daily: daily_params()
    ]
  end

  defp current_params do
    [
      "temperature_2m",
      "apparent_temperature",
      "precipitation",
      "rain",
      "showers",
      "snowfall",
      "relative_humidity_2m",
      "surface_pressure",
      "pressure_msl",
      "wind_direction_10m",
      "wind_speed_10m",
      "wind_gusts_10m",
      "cloud_cover",
      "weather_code",
      "is_day"
    ]
    |> Enum.join(",")
  end

  defp daily_params do
    [
      "temperature_2m_min",
      "temperature_2m_max",
      "rain_sum",
      "showers_sum",
      "snowfall_sum",
      "precipitation_sum",
      "precipitation_probability_max",
      "uv_index_max",
      "daylight_duration",
      "sunshine_duration",
      "sunrise",
      "sunset",
      "weather_code"
    ]
    |> Enum.join(",")
  end

  defp air_quality_params do
    [
      current: "european_aqi",
      timezone: "Europe/London",
      latitude: coords()[:latitude],
      longitude: coords()[:longitude]
    ]
  end

  defp forecast_endpoint, do: "https://api.open-meteo.com/v1/forecast"
  defp air_quality_endpoint, do: "https://air-quality-api.open-meteo.com/v1/air-quality"

  defp coords do
    case Site.Geo.current_coords() do
      {:ok, {lat, long}} -> %{latitude: lat, longitude: long}
      error -> error
    end
  end
end
