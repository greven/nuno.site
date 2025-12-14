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

  # Dynamically builds the site URL from the connection
  defp site_url(%Plug.Conn{} = conn) do
    scheme = if conn.scheme == :https, do: "https", else: "http"
    port = if conn.port in [80, 443], do: "", else: ":#{conn.port}"
    "#{scheme}://#{conn.host}#{port}"
  end

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
    <meta
      :if={@data.article_published_time}
      property="article:published_time"
      content={@data.article_published_time}
    />
    <meta :if={@data.article_author} property="article:author" content={@data.article_author} />
    <meta :for={tag <- @data.article_tags || []} property="article:tag" content={tag} />

    <%!-- Open Graph - Facebook --%>
    <meta property="og:type" content={@data.og_type} />
    <meta property="og:url" content={@data.canonical_url} />
    <meta property="og:title" content={@data.title} />
    <meta property="og:description" content={@data.description} />
    <meta property="og:image" content={@data.og_image} />
    <meta property="og:site_name" content="Nuno's Site" />

    <%!-- Twitter --%>
    <meta property="twitter:card" content="summary_large_image" />
    <meta property="twitter:url" content={@data.canonical_url} />
    <meta property="twitter:title" content={@data.title} />
    <meta property="twitter:description" content={@data.description} />
    <meta property="twitter:image" content={@data.og_image} />
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

  @spec seo_data(Plug.Conn.t()) :: t()
  def seo_data(%Plug.Conn{} = conn) do
    Map.get(conn.assigns, :seo, %{})
    |> case do
      %Blog.Post{} = post -> from_post(post, conn)
      data -> page_data(conn, data)
    end
  end

  @spec page_data(Plug.Conn.t(), map()) :: t()
  defp page_data(conn, route_data) do
    [canonical_url: canonical_url(conn, List.first(conn.path_info))]
    |> Keyword.merge(Map.to_list(route_data))
    |> default(conn)
  end

  @doc """
  Returns the default SEO data for pages without specific content.
  """
  @spec default(keyword(), Plug.Conn.t() | nil) :: t()
  def default(overrides \\ [], conn \\ nil)

  def default(overrides, nil) do
    struct!(
      __MODULE__,
      Keyword.merge(
        [
          title: Keyword.get(config(), :default_title),
          description: Keyword.get(config(), :default_description),
          keywords: Keyword.get(config(), :default_keywords),
          canonical_url: canonical_url(nil, "/"),
          og_type: "website",
          og_image: og_image_url(nil)
        ],
        overrides
      )
    )
  end

  def default(overrides, %Plug.Conn{} = conn) do
    struct!(
      __MODULE__,
      Keyword.merge(
        [
          title: Keyword.get(config(), :default_title),
          description: Keyword.get(config(), :default_description),
          keywords: Keyword.get(config(), :default_keywords),
          canonical_url: canonical_url(conn, "/"),
          og_type: "website",
          og_image: og_image_url(conn)
        ],
        overrides
      )
    )
  end

  @spec from_post(Blog.Post.t(), Plug.Conn.t() | nil) :: t()
  def from_post(%Blog.Post{} = post, conn \\ nil) do
    %__MODULE__{
      title: post.title <> Keyword.get(config(), :title_suffix, "· Nuno's Site"),
      description: post.excerpt,
      keywords: Keyword.get(config(), :default_keywords),
      canonical_url: canonical_url(conn, "/blog/#{post.year}/#{post.slug}"),
      og_type: "article",
      og_image: og_image_url(conn, post),
      article_published_time: to_datetime(post.date),
      article_author: "Nuno Moço",
      article_tags: post.tags
    }
  end

  # Generates the default OG image URL
  defp og_image_url(nil) do
    "#{site_url()}/og-image"
  end

  defp og_image_url(%Plug.Conn{} = conn) do
    "#{site_url(conn)}/og-image"
  end

  # Generates the OG image URL for a blog post
  defp og_image_url(nil, %Blog.Post{} = post) do
    "#{site_url()}/og-image?year=#{post.year}&slug=#{post.slug}"
  end

  defp og_image_url(%Plug.Conn{} = conn, %Blog.Post{} = post) do
    "#{site_url(conn)}/og-image?year=#{post.year}&slug=#{post.slug}"
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
  @spec canonical_url(Plug.Conn.t() | nil, String.t() | nil) :: String.t()
  def canonical_url(conn \\ nil, path \\ nil)

  def canonical_url(nil, nil), do: site_url()

  def canonical_url(nil, path) when is_binary(path) do
    path
    |> String.split(["?", "#"])
    |> then(&URI.merge(site_url(), hd(&1)))
    |> URI.to_string()
  end

  def canonical_url(%Plug.Conn{} = conn, nil), do: site_url(conn)

  def canonical_url(%Plug.Conn{} = conn, path) when is_binary(path) do
    path
    |> String.split(["?", "#"])
    |> then(&URI.merge(site_url(conn), hd(&1)))
    |> URI.to_string()
  end

  defp to_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp to_datetime(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp to_datetime(%Date{} = date), do: Date.to_iso8601(date)
end
