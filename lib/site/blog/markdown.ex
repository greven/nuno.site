defmodule Site.Blog.Markdown do
  @moduledoc """
  Markdown parsing options.
  """

  alias Site.Blog.SyntaxTheme
  alias MDEx.Document

  @aside_allowed_attrs ~w(intent title icon markdown)

  @default_opts [
    plugins: [MDExGFM, &__MODULE__.aside_plugin/1, &__MODULE__.decorate_code_blocks_plugin/1],
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

  @doc """
  Transform fenced code blocks with `aside` in the info string into custom HTML
  blocks for rendering as asides (alerts) in the blog post.
  """
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

  @doc """
  Decorate code blocks with additional HTML for styling and functionality.
  """
  def decorate_code_blocks_plugin(document) do
    Document.append_steps(document, update_code_blocks: &update_code_blocks/1)
  end

  defp update_code_blocks(document) do
    selector = fn
      %MDEx.CodeBlock{fenced: true} -> true
      _ -> false
    end

    Document.update_nodes(document, selector, &maybe_decorate_code_block/1)
  end

  defp maybe_decorate_code_block(%MDEx.CodeBlock{fenced: true, info: info} = code_block) do
    if aside_info?(info) do
      code_block
    else
      render_decorated_code_block(code_block)
    end
  end

  defp aside_info?(info) when is_binary(info) do
    info |> String.trim() |> String.starts_with?("aside")
  end

  defp aside_info?(_), do: false

  defp render_decorated_code_block(node) do
    meta = parse_code_block_info(node.info)
    filename = meta.filename || meta.title || meta.language_label || "Code"

    html =
      Enum.join([
        ~s(<div class="code-block">),
        ~s(<div class="code-block-header">),
        ~s(<div class="code-block-lights" aria-hidden="true">),
        ~s(<span class="code-block-light code-block-light-red"></span>),
        ~s(<span class="code-block-light code-block-light-yellow"></span>),
        ~s(<span class="code-block-light code-block-light-green"></span>),
        ~s(</div>),
        ~s(<div class="code-block-tab">),
        ~s(<span class="#{language_icon_class(meta.language)} size-4" aria-hidden="true"></span>),
        ~s(<span class="code-block-filename">#{html_escape(filename)}</span>),
        ~s(</div>),
        ~s(<div class="code-block-spacer"></div>),
        ~s(<div class="code-block-copy">),
        ~s(<button class="code-block-copy-button" aria-label="Copy code to clipboard" title="Copy">),
        ~s(<span class="lucide-copy size-4" aria-hidden="true"></span>),
        ~s(<span class="lucide-check size-4 text-green-600 hidden" aria-hidden="true"></span>),
        ~s(</button>),
        ~s(</div>),
        ~s(</div>),
        render_code_block_node(node, meta),
        ~s(</div>)
      ])

    %MDEx.HtmlBlock{literal: html}
  end

  # Render the original code block content as HTML.
  defp render_code_block_node(node, meta) do
    # Remove plugins to avoid recursion
    opts = Keyword.drop(mdex_options(), [:plugins])

    %MDEx.Document{nodes: [%{node | info: meta.render_info}]}
    |> MDEx.to_html!(opts)
    |> String.trim()
  end

  defp parse_code_block_info(info) do
    trimmed = String.trim(info)

    language =
      case String.split(trimmed, ~r/\s+/, parts: 2, trim: true) do
        [lang | _] when lang != "" -> lang
        _ -> "text"
      end

    filename = extract_info_attr(trimmed, "data-filename")
    title = extract_info_attr(trimmed, "data-title")

    # Remove only our custom attrs, preserve all other decorators
    render_info =
      trimmed
      |> String.replace(~r/\s*\bdata-filename=(?:"[^"]*"|\S+)/, "")
      |> String.replace(~r/\s*\bdata-title=(?:"[^"]*"|\S+)/, "")
      |> Kernel.<>(~s( highlight_lines_class="code-line-highlight"))
      |> String.trim()
      |> case do
        "" -> language
        other -> other
      end

    %{
      language: language,
      language_label: language_label(language),
      title: title,
      filename: filename,
      render_info: render_info
    }
  end

  defp extract_info_attr(info, key) do
    escaped = Regex.escape(key)

    case Regex.run(~r/\b#{escaped}="([^"]*)"/, info, capture: :all_but_first) do
      [value] when value != "" ->
        value

      _ ->
        case Regex.run(~r/\b#{escaped}=([^\s"]+)/, info, capture: :all_but_first) do
          [value] when value != "" -> value
          _ -> nil
        end
    end
  end

  # Language icon classes based on the language name
  defp language_icon_class("elixir"), do: "lucide-droplet text-purple-500"
  defp language_icon_class("js"), do: "lucide-braces text-yellow-500"
  defp language_icon_class("javascript"), do: "lucide-braces text-yellow-500"
  defp language_icon_class("ts"), do: "lucide-braces text-sky-500"
  defp language_icon_class("typescript"), do: "lucide-braces text-sky-500"
  defp language_icon_class("html"), do: "lucide-code text-orange-500"
  defp language_icon_class("css"), do: "lucide-ampersand text-purple-500"
  defp language_icon_class("ruby"), do: "lucide-gem text-red-500"
  defp language_icon_class("python"), do: "lucide-line-squiggle text-yellow-500"
  defp language_icon_class("markdown"), do: "lucide-file-text text-gray-500"
  defp language_icon_class("json"), do: "lucide-file-text text-blue-500"
  defp language_icon_class("bash"), do: "lucide-terminal text-green-500"
  defp language_icon_class("sh"), do: "lucide-terminal text-green-500"
  defp language_icon_class(_), do: "lucide-file text-gray-500"

  # Human-readable language labels
  defp language_label("javascript"), do: "JavaScript"
  defp language_label("typescript"), do: "TypeScript"
  defp language_label("html"), do: "HTML"
  defp language_label("css"), do: "CSS"
  defp language_label(lang), do: String.capitalize(lang)

  ## Helpers

  defp strip_quotes(value) do
    value
    |> String.trim()
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
    |> String.trim_leading("'")
    |> String.trim_trailing("'")
  end

  defp html_escape(nil), do: ""

  defp html_escape(value) do
    value
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
