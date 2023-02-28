defmodule App.Blog.Post do
  @moduledoc """
  Blog post
  """

  @enforce_keys [:id, :title, :body, :description, :reading_time, :tags, :date]
  defstruct [
    :id,
    :title,
    :body,
    :description,
    :reading_time,
    :tags,
    :date,
    published: true,
    toc: false
  ]

  def build(filename, attrs, body) do
    [year, month, day, id] =
      filename
      |> Path.rootname()
      |> Path.split()
      |> List.last()
      |> String.split("-", parts: 4)

    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    struct!(
      __MODULE__,
      [
        id: id,
        date: date,
        body: body,
        reading_time: estimate_reading_time(body)
      ] ++
        Map.to_list(attrs)
    )
  end

  @avg_wpm 200
  defp estimate_reading_time(body) do
    body
    |> String.split(" ")
    |> Enum.count()
    |> then(&(&1 / @avg_wpm))
    |> round()
  end
end
