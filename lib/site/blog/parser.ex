defmodule Site.Blog.Parser do
  def parse(_path, contents) do
    [header, markdown_body] = String.split(contents, "---\n", trim: true, parts: 2)

    {%{} = attrs, _} = Code.eval_string(header, [])
    html_body = markdown_to_html!(markdown_body)

    {attrs, html_body}
  end

  defp markdown_to_html!(markdown_body) do
    MDEx.to_html(markdown_body,
      syntax_highlight: [formatter: {:html_inline, theme: "cyberdream_dark"}],
      extension: [
        header_ids: "",
        strikethrough: true,
        underline: true,
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
      ],
      render: [
        unsafe_: true,
        github_pre_lang: true,
        hardbreaks: true
      ]
    )
  end
end
