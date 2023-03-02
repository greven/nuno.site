defmodule AppWeb.PageComponents do
  @moduledoc """
  Components and page helpers.
  """

  use Phoenix.Component
  use AppWeb, :verified_routes

  import AppWeb.CoreComponents, only: [badge: 1]

  attr :tags, :list, required: true
  attr :class, :string, default: nil

  def post_tags(assigns) do
    ~H"""
    <div class="not-prose flex items-center gap-1.5">
      <%= for tag <- @tags do %>
        <.link navigate={~p"/blog/tags/#{tag}"}>
          <.badge><%= tag %></.badge>
        </.link>
      <% end %>
    </div>
    """
  end

  attr :post, :any, required: true
  attr :class, :string, default: nil

  def publication_date(assigns) do
    assigns = assign(assigns, :date, relative_date(assigns.post.date))

    ~H"""
    <time><%= @date %></time>
    """
  end

  defp relative_date(date) do
    date_diff = Date.diff(Date.utc_today(), date)

    cond do
      date_diff <= 5 -> Timex.from_now(date)
      true -> Timex.format!(date, "{D} {Mfull} {YYYY}")
    end
  end
end
