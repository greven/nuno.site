defmodule Site.Blog.Parser do
  import MDEx.Sigil

  alias Site.Blog.HeaderLink
  alias Site.Blog.SyntaxTheme

  def parse(_path, contents) do
    [header, markdown_body] = String.split(contents, "---\n", trim: true, parts: 2)
    {%{} = attrs, _} = Code.eval_string(header, [])

    options = [
      syntax_highlight: [formatter: {:html_inline, theme: SyntaxTheme.umbra_theme()}],
      render: [
        unsafe_: true,
        github_pre_lang: true,
        hardbreaks: true
      ],
      extension: [
        underline: true,
        strikethrough: true,
        tagfilter: true,
        table: true,
        autolink: true,
        tasklist: true,
        footnotes: true,
        shortcodes: true
      ],
      parse: [
        smart: true,
        relaxed_tasklist_matching: true,
        relaxed_autolinks: true
      ]
    ]

    html_body =
      markdown_body
      |> MDEx.parse_document!(options)
      |> linkify_headers()
      |> MDEx.to_html!(options)

    attrs = Map.put(attrs, :headers, parse_headers(html_body))

    {attrs, html_body}
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
          |> Site.Support.slugify()

        ~m(<header class="group relative h#{level}">
            <h#{level} id="#{id}">#{MDEx.to_html!(children)}</h#{level}>
            <a href="##{id}" class="header-link" aria-labelledby="#{id}">H#{level}</a>
          </header>)

      node ->
        node
    end)
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
