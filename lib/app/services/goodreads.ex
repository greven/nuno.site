defmodule App.Services.Goodreads do
  @moduledoc """
  Goodreads scraper (we can't use the API because it's no longer available) to retrive my
  currently reading and total books read.
  """

  import App.Http

  @cache_ttl :timer.hours(48)

  @base_url "https://www.goodreads.com/review/list/87020422"

  def currently_reading(opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @cache_ttl)
    use_cache? = Keyword.get(opts, :use_cache, true)

    if App.Cache.ttl(:currently_reading) && use_cache? do
      {:ok, App.Cache.get(:currently_reading)}
    else
      case do_get_currently_reading() do
        {:ok, currently_reading} ->
          App.Cache.put(:currently_reading, currently_reading, ttl: ttl)
          {:ok, currently_reading}

        {:error, status} ->
          {:error, status}
      end
    end
  end

  defp do_get_currently_reading(opts \\ []) do
    (@base_url <> "?shelf=currently-reading")
    |> get()
    |> parse_currently_reading_response()
  end

  defp parse_currently_reading_response({:ok, status, response}) do
    case status do
      200 ->
        response

      _ ->
        {:error, status}
    end
  end

  defp parse_currently_reading_response({:error, status, _}), do: {:error, status}
end
