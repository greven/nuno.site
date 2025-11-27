defmodule SiteWeb.Seo do
  @moduledoc """
  SEO helper functions for generating meta tags and structured data.
  """

  use Phoenix.Component

  alias Site.Blog

  defstruct [
    :title,
    :description,
    :keywords,
    :og_type,
    :og_image,
    :article_published_time,
    :article_author,
    :article_tags
  ]

  @type t :: %__MODULE__{
          title: String.t() | nil,
          description: String.t() | nil,
          keywords: String.t() | nil,
          og_type: String.t() | nil,
          og_image: String.t() | nil,
          article_published_time: String.t() | nil,
          article_author: String.t() | nil,
          article_tags: [String.t()] | nil
        }

  defmacro __using__(_opts) do
    quote do
      import SiteWeb.Seo, only: [assign_seo: 2]
    end
  end

  defp config, do: Application.get_env(:site, :seo)

  ## Components

  @doc """
  Generates SEO tags for the given assigns.
  """

  # attr :conn, Plug.Conn, required: true
  attr :data, :map, required: true

  def tags(assigns) do
    # route_data = route_data(assigns.conn)

    # assigns =
    # assigns
    # |> assign(:data, page_meta(route_data, config()))
    # |> assign(:data, %{})

    # route_data(assigns.conn)
    # |> dbg()

    ~H"""
    <div></div>
    """
  end

  def data(conn_or_socket) do
    dbg(conn_or_socket)
  end

  # Get the route SEO assigns from the Plug.Conn or Phoenix.LiveView.Socket
  defp route_data(%Plug.Conn{} = conn), do: conn.private[:seo] || conn.assigns[:seo] || %{}
  defp route_data(%Phoenix.LiveView.Socket{} = socket), do: socket.assigns[:seo] || %{}

  # <%!-- Primary Meta Tags --%>
  #   <meta name="title" content={@meta[:title] || "Nuno Moço - Software Engineer"} />
  # <meta name="description" content={@meta[:description] || "Personal website of Nuno Moço"} />
  # <meta name="author" content="Nuno Moço" />
  # <meta
  # name="keywords"
  # content={
  # @meta[:keywords] ||
  # "software engineer, web development, elixir, phoenix, css, javascript, programming"
  # } />
  # <%!-- Article specific --%>
  # <meta
  # :if={@meta[:article_published_time]}
  # property="article:published_time"
  # content={@meta[:article_published_time]}
  # />
  # <meta :if={@meta[:article_author]} property="article:author" content={@meta[:article_author]} />
  # <meta :for={tag <- @meta[:article_tags] || []} property="article:tag" content={tag} />

  # <!-- Canonical URL -->
  # <link rel="canonical" href={assigns[:canonical_url] || "https://nuno.site"} />

  # <%!-- Open Graph / Facebook --%>
  # <%!-- <meta property="og:type" content={@meta[:og_type] || "website"} /> --%>
  # <%!-- <meta property="og:url" content={@meta[:url] || "https://nuno.site"} /> --%>
  # <%!-- <meta property="og:title" content={@meta[:title] || "Nuno Moço - Software Engineer"} /> --%>
  # <%!-- <meta property="og:description" content={@meta[:description] || "Personal website"} /> --%>
  # <%!-- <meta property="og:image" content={@meta[:og_image] || "https://nuno.site/images/og-default.jpg"} /> --%>
  # <%!-- <meta property="og:site_name" content="Nuno's Site" /> --%>

  # <%!-- Twitter --%>
  # <%!-- <meta property="twitter:card" content="summary_large_image" /> --%>
  # <%!-- <meta property="twitter:url" content={@meta[:url] || "https://nuno.site"} /> --%>
  # <%!-- <meta property="twitter:title" content={@meta[:title] || "Nuno Moço - Software Engineer"} /> --%>
  # <%!-- <meta property="twitter:description" content={@meta[:description] || "Personal website"} /> --%>
  # <%!-- <meta property="twitter:image" content={@meta[:og_image] || "https://nuno.site/images/og-default.jpg"} /> --%>

  @doc """
  Assigns SEO metadata to the given `conn` or `socket` based on the provided item.
  """
  @spec assign_seo(Plug.Conn.t() | Phoenix.LiveView.Socket.t(), Blog.Post.t() | t()) ::
          Plug.Conn.t() | Phoenix.LiveView.Socket.t()
  def assign_seo(conn_or_socket, item)

  def assign_seo(%Plug.Conn{} = conn, item) do
    Plug.Conn.put_private(conn, :seo, item)
  end

  def assign_seo(%Phoenix.LiveView.Socket{} = socket, item) do
    assign(socket, :seo, item)
  end

  ## Meta

  @spec page_meta(Blog.Post.t() | t(), keyword()) :: t()
  def page_meta(%Blog.Post{} = post, config) do
    post

    %__MODULE__{
      title: "#{post.title} · Nuno's Site"
    }

    # %{
    #   title: "#{post.title} · Nuno's Site",
    #   description: post.excerpt,
    #   keywords: default_keywords(),
    #   og_type: "article",
    #   og_image: post.image || "https://nuno.site/images/og-blog.jpg",
    #   article_published_time: published_datetime(post.date),
    #   article_author: "Nuno Moço",
    #   article_tags: post.tags
    # }
  end

  def page_meta(%__MODULE__{} = meta, config) do
    meta

    # %{
    #   title: meta[:page_title] || default_title(),
    #   description: meta[:meta_description] || default_description(),
    #   keywords: default_keywords(),
    #   og_type: meta[:og_type] || "website",
    #   og_image: meta[:og_image] || "https://nuno.site/images/og-default.jpg"
    # }
  end

  defp to_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp to_datetime(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp to_datetime(%Date{} = date), do: Date.to_iso8601(date)
  defp to_iso8601(_), do: nil
end
