defmodule Site.Services.WeatherTest do
  use ExUnit.Case

  alias Site.Services.Weather

  describe "weather_description/1" do
    test "maps WMO codes to descriptions" do
      assert Weather.weather_description(0) == "Clear sky"
      assert Weather.weather_description(2) == "Partly cloudy"
      assert Weather.weather_description(45) == "Fog"
      assert Weather.weather_description(61) == "Slight rain"
      assert Weather.weather_description(63) == "Moderate rain"
      assert Weather.weather_description(95) == "Thunderstorm"
      assert Weather.weather_description(99) == "Thunderstorm with heavy hail"
    end

    test "returns :unknown for unhandled codes" do
      assert Weather.weather_description(100) == :unknown
      assert Weather.weather_description(4) == :unknown
    end
  end

  describe "weather_short_description/1" do
    test "maps codes to compact descriptions" do
      assert Weather.weather_short_description(0) == "Clear sky"
      assert Weather.weather_short_description(51) == "Drizzle"
      assert Weather.weather_short_description(63) == "Moderate rain"
      assert Weather.weather_short_description(71) == "Snow fall"
      assert Weather.weather_short_description(95) == "Thunderstorm"
      assert Weather.weather_short_description(99) == "Thunderstorm"
    end
  end

  describe "uv_index_description/1" do
    test "maps UV index ranges" do
      assert Weather.uv_index_description(0) == "Low"
      assert Weather.uv_index_description(2) == "Low"
      assert Weather.uv_index_description(3) == "Moderate"
      assert Weather.uv_index_description(5) == "Moderate"
      assert Weather.uv_index_description(6) == "High"
      assert Weather.uv_index_description(7) == "High"
      assert Weather.uv_index_description(8) == "Very High"
      assert Weather.uv_index_description(10) == "Very High"
      assert Weather.uv_index_description(11) == "Extreme"
      assert Weather.uv_index_description(15) == "Extreme"
    end
  end
end
