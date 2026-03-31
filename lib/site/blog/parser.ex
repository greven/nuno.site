defmodule Site.Blog.Parser do
  @moduledoc false

  alias Site.Blog.HeaderLink
  alias Site.Blog.Markdown

  @doc """
  Parse the given markdown contents.
  """
  def parse(_path, contents) do
    [doc_header, markdown_body] = String.split(contents, "---\n", trim: true, parts: 2)

    {%{} = attrs, _} = Code.eval_string(doc_header, [])

    mdex_options =
      Keyword.update(Markdown.mdex_options(), :plugins, [], fn plugins ->
        plugins ++ [Markdown.lead_plugin(attrs)]
      end)

    mdex_document = MDEx.parse_document!(markdown_body, mdex_options)
    attrs = Map.put(attrs, :headers, parse_headers(mdex_document))

    {attrs, mdex_document}
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
end
