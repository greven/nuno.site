defmodule App.Blog.Post do
  @moduledoc false

  @enforce_keys ~w(id title body excerpt date)a
  defstruct id: nil,
            title: nil,
            body: nil,
            excerpt: nil,
            image: nil,
            likes: nil,
            status: :draft,
            featured: false,
            reading_time: 0,
            date: nil,
            tags: []

  def status, do: ~w(draft review published)a

  # TODO: ID how to deal with conflicts? Maybe add a UUID generated from the date, or simply add the date to the ID?
  def build(filename, attrs, body) do
    [year, month_day_id] = filename |> Path.rootname() |> Path.split() |> Enum.take(-2)
    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    reading_time = reading_time_in_minutes(body)

    struct!(
      __MODULE__,
      [id: id, date: date, body: body, reading_time: reading_time] ++ Map.to_list(attrs)
    )
  end

  @avg_wpm 200
  defp reading_time_in_minutes(html_body) do
    Floki.parse_fragment!(html_body)
    |> Floki.text()
    |> String.split(~r/\s+/)
    |> Enum.count()
    |> then(&(&1 / @avg_wpm))
    |> then(&round(&1))
  end
end
