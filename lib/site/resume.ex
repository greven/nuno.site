defmodule Site.Resume do
  @moduledoc """
  Load and transform my resume data.
  """

  use Nebulex.Caching

  def get_profile, do: Map.get(data(), "profile")
  def get_languages, do: Map.get(data(), "languages")
  def get_education, do: Map.get(data(), "education")
  def get_experience, do: Map.get(data(), "work")
  def get_skills, do: Map.get(data(), "skills")

  def list_skills do
    get_skills()
    |> Enum.sort_by(&{&1["favourite"], &1["level"]}, :desc)
    |> Enum.map(fn skill -> {skill["name"], skill["favourite"]} end)
  end

  def list_favourite_skills do
    list_skills()
    |> Enum.filter(fn {_, favourite} -> favourite end)
  end

  @decorate cacheable(cache: Site.Cache, key: {:resume})
  def data do
    resume_path()
    |> File.read!()
    |> JSON.decode!()
    |> transform()
  end

  def resume_path, do: Path.join([:code.priv_dir(:site), "content/resume.json"])

  # Recursively convert keys to snake case
  defp transform(%{} = resume_data) do
    resume_data
    |> Enum.map(fn
      {key, value} when is_map(value) -> {Recase.to_snake(key), transform(value)}
      {key, value} when is_list(value) -> {Recase.to_snake(key), Enum.map(value, &transform/1)}
      {key, value} -> {Recase.to_snake(key), value}
    end)
    |> Enum.into(%{})
  end

  defp transform(value), do: value
end
