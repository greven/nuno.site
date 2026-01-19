defmodule Site.Blog.Parser do
  @moduledoc false

  alias Site.Blog.HeaderLink
  # alias Site.Blog.SyntaxTheme

  @syntax_theme "neovim_dark"

  def parse(_path, contents) do
    [doc_header, markdown_body] = String.split(contents, "---\n", trim: true, parts: 2)

    {%{} = attrs, _} = Code.eval_string(doc_header, [])

    mdex_options = mdex_options()

    html_body =
      markdown_body
      |> MDEx.parse_document!(mdex_options)
      |> post_parsing()
      |> MDEx.to_html!(mdex_options)
      |> post_processing()

    attrs = Map.put(attrs, :headers, parse_headers(html_body))

    # We need to eval the template to render any EEx tags
    # to allow embedding LiveView components in the markdown
    env = __ENV__

    html_body =
      EEx.compile_string(
        html_body,
        engine: Phoenix.LiveView.TagEngine,
        file: env.file,
        line: env.line + 1,
        caller: env,
        indentation: 0,
        source: html_body,
        tag_handler: Phoenix.LiveView.HTMLEngine
      )
      |> Code.eval_quoted([assigns: %{}], env)
      |> then(fn {rendered, _} -> Phoenix.HTML.Safe.to_iodata(rendered) end)
      |> IO.iodata_to_binary()

    {attrs, html_body}
  end

  # Apply transformations to the markdown AST before converting to HTML
  defp post_parsing(markdown_body) do
    markdown_body
    |> linkify_headers()
  end

  # Apply transformations to the HTML body
  defp post_processing(html_body) do
    html_body
    |> parse_lead_paragraph()
  end

  defp mdex_options do
    [
      syntax_highlight: [
        formatter: {:html_inline, theme: @syntax_theme}
      ],
      render: [
        unsafe: true,
        escape: false,
        hardbreaks: false,
        github_pre_lang: true,
        full_info_string: true
      ],
      extension: [
        alerts: true,
        autolink: false,
        description_lists: true,
        footnotes: true,
        highlight: true,
        math_code: true,
        math_dollars: true,
        multiline_block_quotes: true,
        phoenix_heex: true,
        shortcodes: true,
        spoiler: true,
        strikethrough: true,
        superscript: true,
        table: true,
        tasklist: true,
        underline: true
      ],
      parse: [
        smart: true,
        relaxed_autolinks: true,
        relaxed_tasklist_matching: true
      ]
    ]
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

  # Replace the first <p> after an HTML comment marker
  defp parse_lead_paragraph(html) do
    html
    |> String.replace(
      ~r/<!-- lead -->\s*<p>/,
      ~s(<p class="lead">),
      global: false
    )
  end

  @doc """
  Create a list of header links from the HTML body to be used in the table of contents.
  """
  def parse_headers(html_body) do
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
end
