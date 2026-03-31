defmodule Site.Blog.Markdown do
  @moduledoc """
  Markdown parsing options.
  """

  alias Site.Blog.SyntaxTheme
  alias MDEx.Document

  @aside_allowed_attrs ~w(intent title icon markdown)

  @default_opts [
    plugins: [MDExGFM, &__MODULE__.aside_plugin/1],
    extension: [
      highlight: true,
      phoenix_heex: true
    ],
    render: [
      unsafe: true,
      github_pre_lang: true,
      full_info_string: true
    ],
    syntax_highlight: [
      formatter:
        {:html_multi_themes,
         themes: [light: SyntaxTheme.light(), dark: SyntaxTheme.dark()], default_theme: nil}
    ]
  ]

  @doc """
  Default MDEx options.
  """
  def mdex_options, do: @default_opts
  def mdex_options(opts), do: build_opts(opts)

  defp build_opts(opts) do
    opts = Keyword.get(opts, :mdex_opts, [])
    Site.Support.deep_merge(@default_opts, opts)
  end

  ## Plugins

  @doc false
  def aside_plugin(document) do
    Document.append_steps(document, update_aside_blocks: &update_aside_blocks/1)
  end

  defp update_aside_blocks(document) do
    selector = fn
      %MDEx.CodeBlock{fenced: true, info: info} ->
        info
        |> String.trim()
        |> String.starts_with?("aside")

      _ ->
        false
    end

    Document.update_nodes(document, selector, &process_aside_block/1)
  end

  defp process_aside_block(%MDEx.CodeBlock{info: info, literal: content} = node) do
    info
    |> parse_aside_attrs()
    |> case do
      {:ok, attrs} ->
        %MDEx.HtmlBlock{literal: render_aside_component(attrs, content), nodes: node.nodes}

      :error ->
        node
    end
  end

  defp process_aside_block(node), do: node

  defp parse_aside_attrs(info) when is_binary(info) do
    trimmed = String.trim(info)

    if trimmed == "aside" do
      {:ok, []}
    else
      case Regex.run(~r/^aside\s+(.+)$/, trimmed, capture: :all_but_first) do
        [meta] -> {:ok, parse_meta_attrs(meta)}
        _ -> :error
      end
    end
  end

  defp parse_meta_attrs(meta) do
    for [_full, key, value] <- Regex.scan(~r/(\w+)=((?:"[^"]*")|(?:'[^']*')|\S+)/, meta),
        key in @aside_allowed_attrs,
        value = strip_quotes(value),
        value != "" do
      {key, value}
    end
  end

  defp render_aside_component(attrs, content) do
    attrs_html =
      attrs
      |> Enum.map_join("", fn {key, value} ->
        ~s( #{key}="#{html_escape(value)}")
      end)

    """
    <SiteWeb.BlogComponents.article_aside#{attrs_html}>
    #{content}</SiteWeb.BlogComponents.article_aside>
    """
    |> String.trim()
  end

  ## Helpers

  defp strip_quotes(value) do
    value
    |> String.trim()
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
    |> String.trim_leading("'")
    |> String.trim_trailing("'")
  end

  defp html_escape(value) do
    value
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
