defmodule App.Http do
  @moduledoc """
  An HTTP client wrapper.
  """

  def get(url, headers \\ []) do
    request(:get, url, headers)
    |> content_type()
    |> decode()
  end

  def post(url, headers, body \\ ""), do: request(:post, url, headers, body)
  def post(url), do: request(:post, url, [], "")

  def request(method, url, headers, body \\ nil) when is_atom(method) do
    call(method, url, headers, body)
    |> case do
      {:ok, %{status: status, body: body, headers: headers}} -> {:ok, status, body, headers}
      {:error, %{reason: reason}} -> {:error, reason}
    end
  end

  def call(method, url, headers, body \\ nil) when is_atom(method) do
    Finch.build(method, url, headers, body)
    |> Finch.request(App.Finch)
  end

  # Content Type

  def content_type({:error, _} = error), do: error

  def content_type({:ok, status, body, headers}) do
    {:ok, status, body, content_type(headers)}
  end

  def content_type([]), do: "application/json"

  def content_type([{"Content-Type", val} | _]) do
    val
    |> String.split(";")
    |> List.first()
  end

  def content_type([_ | t]), do: content_type(t)

  # Decode

  def decode({:error, _} = error), do: error

  def decode({:ok, status, body, "text/html"}), do: {:ok, status, body}

  def decode({:ok, status, body, "application/json"}) do
    body
    |> Jason.decode()
    |> case do
      {:ok, parsed} -> {:ok, status, parsed}
      _ -> {:error, status}
    end
  end

  def decode({:ok, status, body, "application/xml"}) do
    try do
      {:ok, status, body |> :binary.bin_to_list() |> :xmerl_scan.string()}
    catch
      :exit, _e -> {:error, status}
    end
  end

  def decode({:ok, status, body, _}), do: {:ok, status, body}
end
