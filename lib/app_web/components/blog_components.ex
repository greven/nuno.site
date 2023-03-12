defmodule AppWeb.BlogComponents do
  @moduledoc """
  Blog components and helpers.
  """

  use Phoenix.Component
  use AppWeb, :verified_routes

  import AppWeb.Gettext
  import AppWeb.CoreComponents

  attr :class, :string, default: nil
  attr :post, :any, required: true

  def post_header(assigns) do
    ~H"""
    <div class={@class}>
      <.header>
        <%= @post.title %>

        <:subtitle class="flex gap-2">
          <.publication_date post={@post} />
          <span class="text-neutral-400" aria-hidden="true">•</span>
          <span>
            <span class="font-bold"><%= @post.reading_time %></span>
            <%= ngettext("minute read", "minutes read", @post.reading_time) %>
          </span>
        </:subtitle>
      </.header>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :readers, :integer, required: true
  attr :today_views, :integer, required: true
  attr :page_views, :integer, required: true

  def post_sidebar(assigns) do
    ~H"""
    <div class={@class}>
      <.back navigate={~p"/writing/"} />
      <%!-- Stats --%>
      <div class="hidden lg:mt-6 lg:flex flex-col gap-2 text-xs font-medium text-neutral-500 uppercase">
        <div class="flex items-center gap-1.5 mb-2">
          <.icon name="hero-presentation-chart-bar" class="w-5 h-5 stroke-current inline" />
          <h3 class="font-headings text-sm font-semibold text-neutral-600">Statistics</h3>
        </div>

        <div class="pl-1">
          <span class="mr-1 text-neutral-700"><%= @readers %></span>
          <%= ngettext(
            "reader",
            "readers",
            @readers
          ) %>
        </div>

        <div class="pl-1">
          <span class="mr-1 text-neutral-700">
            <%= if @today_views, do: App.Helpers.format_number(@today_views), else: "-" %>
          </span>
          <%= gettext("views today") %>
        </div>

        <div class="pl-1">
          <span class="mr-1 text-neutral-700">
            <%= if @page_views, do: App.Helpers.format_number(@page_views), else: "-" %>
          </span>
          <%= gettext("page views") %>
        </div>
      </div>
    </div>
    """
  end

  attr :tags, :list, required: true
  attr :class, :string, default: nil

  def post_tags(assigns) do
    ~H"""
    <div class={["not-prose flex items-center gap-1.5", @class]}>
      <%= for tag <- @tags do %>
        <.link navigate={~p"/writing/tags/#{tag}"}>
          <.badge><%= tag.name %></.badge>
        </.link>
      <% end %>
    </div>
    """
  end

  attr :post, :any, required: true
  attr :class, :string, default: nil

  def publication_date(assigns) do
    assigns = assign(assigns, :date, relative_date(assigns.post.published_date))

    ~H"""
    <time><%= @date %></time>
    """
  end

  defp relative_date(date) when not is_nil(date) do
    date_diff = Date.diff(Date.utc_today(), date)

    cond do
      date_diff <= 5 -> Timex.from_now(date)
      true -> Timex.format!(date, "{D} {Mfull} {YYYY}")
    end
  end

  defp relative_date(date), do: date
end
