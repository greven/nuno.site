defmodule SiteWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :site,
    pubsub_server: Site.PubSub

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_metas(topic, %{joins: joins, leaves: leaves}, _presences, state) do
    for {id, _presence} <- joins do
      Phoenix.PubSub.local_broadcast(Site.PubSub, "proxy:#{topic}", {__MODULE__, {:join, id}})
    end

    for {id, _presence} <- leaves do
      Phoenix.PubSub.local_broadcast(Site.PubSub, "proxy:#{topic}", {__MODULE__, {:leave, id}})
    end

    {:ok, state}
  end

  def count_readers do
    list("readers")
    |> Enum.count()
  end

  def count_post_readers(%Site.Blog.Post{} = post) do
    post_topic(post)
    |> list()
    |> Enum.count()
  end

  def count_post_readers(post_topic) when is_binary(post_topic) do
    list(post_topic) |> Enum.count()
  end

  def track_readers(id), do: track(self(), "readers", id, %{id: id})
  def track_post_readers(post, id), do: track(self(), post_topic(post), id, %{id: id})

  def post_topic(%Site.Blog.Post{} = post), do: "readers:#{post.year}:#{post.id}"

  def subscribe, do: Phoenix.PubSub.subscribe(Site.PubSub, "proxy:readers")

  def subscribe(%Site.Blog.Post{} = post),
    do: Phoenix.PubSub.subscribe(Site.PubSub, "proxy:#{post_topic(post)}")
end
