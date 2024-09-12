defmodule AppWeb.BlogComponents do
  @moduledoc """
  Blog components and helpers.
  """

  use Phoenix.Component
  use AppWeb, :verified_routes
  use Gettext, backend: AppWeb.Gettext

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
          <span class="text-secondary-400" aria-hidden="true">•</span>
          <span>
            <.reading_time time={@post.reading_time} />
            <%= gettext("read") %>
          </span>
        </:subtitle>
      </.header>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :time, :float, required: true
  attr :rest, :global

  def reading_time(%{time: time} = assigns) do
    {duration, unit} =
      cond do
        time < 1.0 ->
          {Timex.Duration.from_minutes(time) |> Timex.Duration.to_seconds() |> round(), "s"}

        true ->
          {time |> round(), "min"}
      end

    assigns =
      assigns
      |> assign(:duration, duration)
      |> assign(:unit, unit)

    ~H"""
    <span class={["normal-case", @class]} {@rest}>
      <span class="font-bold"><%= @duration %></span><span class=""><%= @unit %></span>
    </span>
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
      <div class="hidden lg:mt-6 lg:flex flex-col gap-2 text-xs font-medium text-secondary-500 uppercase">
        <div class="flex items-center gap-1.5 mb-2">
          <.icon name="heroicons:presentation-chart-line" class="w-5 h-5 stroke-current inline" />
          <h3 class="font-headings text-sm font-semibold text-secondary-800">Statistics</h3>
        </div>

        <div class="pl-1">
          <span class="mr-1 text-secondary-700">
            <%= if @today_views, do: App.Helpers.format_number(@today_views), else: "-" %>
          </span>
          <%= gettext("views today") %>
        </div>

        <div class="pl-1">
          <span class="mr-1 text-secondary-700">
            <%= if @page_views, do: App.Helpers.format_number(@page_views), else: "-" %>
          </span>
          <%= gettext("page views") %>
        </div>

        <div class="pl-1">
          <span class="mr-1 text-secondary-700"><%= @readers %></span>
          <%= ngettext(
            "reader",
            "readers",
            @readers
          ) %>
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
        <.link :if={tag.enabled} navigate={~p"/writing/tags/#{tag}"}>
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
