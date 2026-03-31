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
      |> transform_lead(attrs)
      |> linkify_headers()

    attrs = Map.put(attrs, :headers, parse_headers(mdex_document))

    {attrs, mdex_document}
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
end
