defmodule Site.Blog.Parser do
  @moduledoc false

  alias Site.Blog.HeaderLink
  alias Site.Blog.Markdown

  @doc """
  Parse the given markdown contents.
  """
  def parse(_path, contents) do
    mdex_options = Markdown.mdex_options()
    [doc_header, markdown_body] = String.split(contents, "---\n", trim: true, parts: 2)

    {%{} = attrs, _} = Code.eval_string(doc_header, [])

    mdex_document =
      markdown_body
      |> MDEx.parse_document!(mdex_options)
      |> post_parsing(attrs)

    attrs = Map.put(attrs, :headers, parse_headers(mdex_document))

    {attrs, mdex_document}
  end

  # Apply transformations to the markdown AST before converting to HTML
  defp post_parsing(markdown_body, attrs) do
    markdown_body
    |> transform_lead(attrs)
    |> linkify_headers()
    |> decorate_code_blocks()
  end

  # If the `lead` attribute is set to true, add the `lead` class to the first paragraph of the markdown body.
  defp transform_lead(%MDEx.Document{nodes: nodes} = markdown_body, %{lead: true}) do
    {new_nodes, _found?} =
      Enum.map_reduce(nodes, false, fn
        %MDEx.Paragraph{} = paragraph, false ->
          {paragraph_to_lead_html_block(paragraph), true}

        node, found? ->
          {node, found?}
      end)

    %{markdown_body | nodes: new_nodes}
  end

  defp transform_lead(markdown_body, _attrs), do: markdown_body

  defp paragraph_to_lead_html_block(%MDEx.Paragraph{} = paragraph) do
    paragraph_html =
      paragraph
      |> MDEx.to_html!()
      |> String.replace(~r/<p>/, ~s(<p class="lead">), global: false)

    %MDEx.HtmlBlock{literal: paragraph_html}
  end

  @doc """
  Create a list of header links from the HTML body to be used in the table of contents.
  """
  def parse_headers(mdex_document) do
    html_body = MDEx.to_html!(mdex_document)

    html_body
    |> LazyHTML.from_fragment()
    |> LazyHTML.to_tree()
    |> LazyHTML.Tree.postwalk([], fn
      {"header", _, children} = header, acc ->
        {header, parse_header_nodes(children, acc)}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp parse_header_nodes(nodes, acc) do
    Enum.reduce(nodes, acc, fn
      {"h2", _, _} = header, acc ->
        acc ++ [header_link(1, header)]

      {"h3", _, _} = header, acc ->
        List.update_at(acc, -1, fn %{subsections: h3_subs} = h2_parent ->
          %{h2_parent | subsections: h3_subs ++ [header_link(2, header)]}
        end)

      {"h4", _, _} = header, acc ->
        List.update_at(acc, -1, fn %{subsections: h3_subs} = h2_parent ->
          %{
            h2_parent
            | subsections:
                List.update_at(h3_subs, -1, fn %{subsections: h4_subs} = h3_parent ->
                  %{h3_parent | subsections: h4_subs ++ [header_link(3, header)]}
                end)
          }
        end)

      _, acc ->
        acc
    end)
  end

  defp header_link(depth, header) do
    node = LazyHTML.from_tree([header])
    HeaderLink.new(get_header_id(node), LazyHTML.text(node), depth)
  end

  defp get_header_id(header_node) do
    header_node
    |> LazyHTML.attribute("id")
    |> List.first()
  end

  @doc """
  Linkify the headers in the given HTML body, that is, we add an anchor link
  to the headers with the header tag level as the link text and
  the id slug as the parent heading text.
  """
  def linkify_headers(markdown_body) do
    markdown_body
    |> MDEx.traverse_and_update(fn
      %MDEx.Heading{level: level, nodes: children} = heading_node ->
        id =
          to_string(heading_node)
          |> MDEx.to_html!()
          |> LazyHTML.from_fragment()
          |> LazyHTML.text()
          |> MDEx.anchorize()

        header_markdown =
          ~s(<header class="group relative h#{level}"><h#{level} id="#{id}">#{MDEx.to_html!(children)}</h#{level}>
               <a href="##{id}" class="header-link" aria-labelledby="#{id}">H#{level}</a></header>)

        case MDEx.parse_fragment(header_markdown) do
          {:ok, node} -> node
          _ -> heading_node
        end

      node ->
        node
    end)
  end

  defp decorate_code_blocks(markdown_body) do
    MDEx.traverse_and_update(markdown_body, fn
      %MDEx.CodeBlock{fenced: true, info: info} = node ->
        if aside_info?(info) do
          node
        else
          case build_decorated_code_block(node) do
            {:ok, html} -> %MDEx.HtmlBlock{literal: html}
            :error -> node
          end
        end

      node ->
        node
    end)
  end

  defp aside_info?(info) when is_binary(info) do
    info |> String.trim() |> String.starts_with?("aside")
  end

  defp aside_info?(_), do: false

  defp build_decorated_code_block(%MDEx.CodeBlock{} = node) do
    mdex_options = Markdown.mdex_options()
    meta = parse_code_block_info(node.info)

    code_html =
      %MDEx.Document{nodes: [%{node | info: meta.render_info}]}
      |> MDEx.to_html!(mdex_options)

    html =
      """
      <div class="code-block">
        <div class="code-block-header">
          <div class="code-block-lights" aria-hidden="true">
            <span class="code-block-light code-block-light-red"></span>
            <span class="code-block-light code-block-light-yellow"></span>
            <span class="code-block-light code-block-light-green"></span>
          </div>
          <div class="code-block-tab">
            <span class="#{language_icon_class(meta.language)} size-4" aria-hidden="true"></span>
            <span class="code-block-filename">#{html_escape(meta.filename || meta.title || meta.language_label)}</span>
          </div>
          <div class="code-block-spacer"></div>
          <div class="code-block-copy">
            <button class="code-block-copy-button" aria-label="Copy code to clipboard" title="Copy">
              <span class="lucide-copy size-4" aria-hidden="true"></span>
              <span class="lucide-check size-4 text-green-600 hidden" aria-hidden="true"></span>
            </button>
          </div>
        </div>
        #{code_html}
      </div>
      """

    {:ok, html}
  end

  defp build_decorated_code_block(_), do: :error

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
      |> Kernel.<>(~S( highlight_lines_class="code-line-highlight"))
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

  defp html_escape(nil), do: ""

  defp html_escape(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
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
end
