defmodule AppWeb.Layouts do
  use AppWeb, :html

  import AppWeb.LayoutComponents

  embed_templates "layouts/*"
end
