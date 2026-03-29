defmodule Site.Blog.Markdown do
  @moduledoc """
  Markdown parsing options.
  """

  alias Site.Blog.SyntaxTheme

  @default_opts [
    plugins: [MDExGFM],
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
         themes: [light: SyntaxTheme.light(), dark: SyntaxTheme.dark()], default_theme: "dark"}
    ]
  ]

  @doc """
  Default MDEx options.
  """
  def mdex_options, do: @default_opts
  def mdex_options(opts), do: build_opts(opts)

  defp build_opts(opts) do
    opts = Keyword.get(opts, :mdex_opts, [])
    deep_merge(@default_opts, opts)
  end

  @doc false
  defp deep_merge(base, override) do
    Keyword.merge(base, override, fn
      _key, base_val, override_val when is_list(base_val) and is_list(override_val) ->
        if Keyword.keyword?(base_val) and Keyword.keyword?(override_val) do
          deep_merge(base_val, override_val)
        else
          override_val
        end

      _key, _base_val, override_val ->
        override_val
    end)
  end
end
