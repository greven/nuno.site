defmodule SiteWeb.Seo do
  @moduledoc """
  SEO helper functions for generating meta tags and structured data.
  """

  use SiteWeb, :live_component

  alias Site.Blog

  defstruct [
    :title,
    :description,
    :keywords,
    :canonical_url,
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
          canonical_url: String.t() | nil,
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

  defp site_url, do: Application.get_env(:site, :site_url)
  defp config, do: Application.get_env(:site, :seo)

  @doc """
  Generates SEO tags for the given assigns.
  """

  attr :conn, Plug.Conn, required: true

  def tags(%{conn: conn} = assigns) do
    assigns =
      assigns
      |> assign(:data, seo_data(conn))

    ~H"""
    <%!-- Canonical URL --%>
    <link rel="canonical" href={@data.canonical_url} />

    <%!-- Primary Meta Tags --%>
    <meta name="title" content={@data.title} />
    <meta name="description" content={@data.description} />
    <meta name="author" content="Nuno Moço" />

    <%!-- Open Graph --%>

    <%!-- PWA / Mobile --%>
    <meta name="theme-color" content="#000000" media="(prefers-color-scheme: dark)" />
    <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)" />
    <meta name="mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
    <meta name="apple-mobile-web-app-title" content="Nuno's Site" />

    <%!-- Blog specific --%>
    """
  end

  @doc """
  """

  def favicons(assigns) do
    ~H"""
    <link rel="icon" type="image/svg+xml" href={~p"/images/favicon.svg"} />
    <link rel="icon" type="image/png" sizes="16x16" href={~p"/images/favicon-16x16.png"} />
    <link rel="icon" type="image/png" sizes="32x32" href={~p"/images/favicon-32x32.png"} />
    <link rel="icon" type="image/png" sizes="192x192" href={~p"/images/icon-192x192.png"} />
    <link rel="icon" type="image/png" sizes="512x512" href={~p"/images/icon-512x512.png"} />
    <link rel="apple-touch-icon" sizes="180x180" href={~p"/images/apple-touch-icon.png"} />
    """
  end

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

  def seo_data(%Plug.Conn{} = conn) do
    Map.get(conn.assigns, :seo, %{})
    |> case do
      %Blog.Post{} = post -> from_post(post)
      data -> page_data(conn, data)
    end
  end

  defp page_data(conn, route_data) do
    [canonical_url: canonical_url(List.first(conn.path_info))]
    |> Keyword.merge(Map.to_list(route_data))
    |> default()
  end

  @doc """
  Returns the default SEO data for pages without specific content.
  """
  def default(overrides \\ []) do
    struct!(
      __MODULE__,
      Keyword.merge(
        [
          title: Keyword.get(config(), :default_title),
          description: Keyword.get(config(), :default_description),
          keywords: Keyword.get(config(), :default_keywords),
          canonical_url: canonical_url("/"),
          og_type: "website",
          og_image: "#{site_url()}/images/og-default.jpg"
        ],
        overrides
      )
    )
  end

  def from_post(%Blog.Post{} = post) do
    %__MODULE__{
      title: post.title <> Keyword.get(config(), :title_suffix, "· Nuno's Site"),
      description: post.excerpt,
      keywords: default().keywords,
      canonical_url: canonical_url("/blog/#{post.year}/#{post.slug}"),
      og_type: "article",
      og_image: post.image || "#{site_url()}/images/og-blog.jpg",
      article_published_time: to_datetime(post.date),
      article_author: "Nuno Moço",
      article_tags: post.tags
    }
  end

  # @doc """
  # Assigns SEO metadata to the given `conn` or `socket` based on the provided item.
  # """
  @spec assign_seo(Plug.Conn.t() | Phoenix.LiveView.Socket.t(), Blog.Post.t() | t()) ::
          Plug.Conn.t() | Phoenix.LiveView.Socket.t()
  def assign_seo(conn_or_socket, data)

  def assign_seo(%Plug.Conn{} = conn, data) do
    Plug.Conn.put_private(conn, :seo, data)
  end

  def assign_seo(%Phoenix.LiveView.Socket{} = socket, data) do
    Phoenix.Component.assign(socket, :seo, data)
  end

  @doc """
  Builds a canonical URL from a path.
  Strips query params and fragments, ensures HTTPS and proper domain.
  """
  @spec canonical_url(String.t() | nil) :: String.t()
  def canonical_url(nil), do: site_url()

  def canonical_url(path) do
    path
    |> String.split(["?", "#"])
    |> then(&URI.merge(site_url(), hd(&1)))
    |> URI.to_string()
  end

  defp to_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp to_datetime(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp to_datetime(%Date{} = date), do: Date.to_iso8601(date)
end
