defmodule App.Http do
  @moduledoc """
  An HTTP client wrapper.
  """

  def get(url, headers \\ []) do
    call(:get, url, headers)
    |> content_type()
    |> decode()
  end

  def post(url, body, headers \\ []), do: call(:post, url, headers, body)

  def call(method, url, headers, body \\ nil) when is_atom(method) do
    Finch.build(method, url, headers, body)
    |> Finch.request(Iki.Finch)
    |> case do
      {:ok, %{status: status, body: body, headers: headers}} -> {:ok, status, body, headers}
      {:error, %{reason: reason}} -> {:error, reason}
    end
  end

  # Content Type

  def content_type({:error, _} = error), do: error

  def content_type({:ok, _status, body, headers}) do
    {:ok, body, content_type(headers)}
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

  def decode({:ok, body, "application/json"}) do
    body
    |> Jason.decode()
    |> case do
      {:ok, parsed} -> {:ok, parsed}
      _ -> {:error, body}
    end
  end

  def decode({:ok, body, "application/xml"}) do
    try do
      {:ok, body |> :binary.bin_to_list() |> :xmerl_scan.string()}
    catch
      :exit, _e -> {:error, body}
    end
  end

  def decode({:ok, body, _}), do: {:ok, body}
end
