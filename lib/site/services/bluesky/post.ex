defmodule Site.Services.Bluesky.Post do
  @moduledoc """
  A BlueSky post (skeet) Ecto schema and related functions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %{
          did: String.t(),
          rkey: String.t(),
          cid: String.t(),
          uri: String.t(),
          url: String.t() | nil,
          text: String.t() | nil,
          created_at: DateTime.t() | nil,
          deleted_at: DateTime.t() | nil,
          edited_at: DateTime.t() | nil,
          like_count: non_neg_integer() | nil,
          repost_count: non_neg_integer() | nil,
          reply_count: non_neg_integer() | nil,
          author_handle: String.t() | nil,
          author_name: String.t() | nil,
          avatar_url: String.t() | nil
        }

  schema "bluesky_posts" do
    field :did, :string
    field :rkey, :string
    field :cid, :string
    field :uri, :string
    field :url, :string
    field :text, :string
    field :created_at, :utc_datetime
    field :deleted_at, :utc_datetime
    field :edited_at, :utc_datetime
    field :like_count, :integer, default: 0
    field :repost_count, :integer, default: 0
    field :reply_count, :integer, default: 0
    field :author_handle, :string
    field :author_name, :string
    field :avatar_url, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:did, :rkey, :cid, :uri, :url, :text, :created_at])
    |> validate_required([:did, :rkey, :cid, :uri])
  end
end
