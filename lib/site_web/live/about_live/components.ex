defmodule SiteWeb.AboutLive.Components do
  use SiteWeb, :html

  @doc false

  attr :rest, :global

  def contact_links(assigns) do
    ~H"""
    <div {@rest}>
      <%!-- Text --%>
      <div class="-ml-2">
        <div class="w-full mb-4 ml-1 flex items-center">
          <div class="relative inline-block">
            <em class="py-0.5 px-1 not-italic text-secondary dark:text-tint-secondary/25 bg-secondary/10 dark:bg-secondary/15">
              Stay in contact
            </em>
            <.icon
              name="lucide-corner-right-down"
              class="absolute top-2 -right-6 size-5 text-secondary"
            />
          </div>
        </div>
      </div>

      <%!-- Main Links --%>
      <ul class="flex flex-wrap items-center gap-2.5">
        <.contact_link href="mailto:hello@nuno.site" icon="hero-envelope" class="hidden md:block">
          Email
        </.contact_link>

        <.contact_link href="https://github.com/greven" icon="si-github">
          Github
        </.contact_link>

        <.contact_link href="https://bsky.app/profile/nuno.site" icon="si-bluesky">
          Bluesky
        </.contact_link>
      </ul>

      <%!-- Secondary Links --%>
      <ul class="mt-2 flex flex-wrap items-center gap-1">
        <.secondary_contact_link href="mailto:hello@nuno.site" class="md:hidden">
          Email
        </.secondary_contact_link>
        <.secondary_contact_link href="https://mastodon.social/@nuno_fm">
          Mastodon
        </.secondary_contact_link>
        <.secondary_contact_link href="https://www.linkedin.com/in/nuno-fr3ire/">
          LinkedIn
        </.secondary_contact_link>
        <.secondary_contact_link>Twitter</.secondary_contact_link>
      </ul>
    </div>
    """
  end

  @doc false

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :rest, :global

  slot :inner_block, required: true

  def contact_link(assigns) do
    ~H"""
    <li {@rest}>
      <.button href={@href} size="sm" class="group">
        <.icon name={@icon} class="size-4 text-content-40" />
        {render_slot(@inner_block)}
        <.icon
          name="lucide-arrow-up-right"
          class="size-5 text-content-40 group-hover:text-primary transition-colors"
        />
      </.button>
    </li>
    """
  end

  @doc false

  attr :href, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def secondary_contact_link(%{href: link} = assigns) do
    if link do
      ~H"""
      <li {@rest}>
        <.link href={@href} class="px-1.5 link-subtle">
          {render_slot(@inner_block)}
        </.link>
      </li>
      """
    else
      ~H"""
      <li {@rest}>
        <s class="px-1.5 text-content-40/70 decoration-content-40/70">
          {render_slot(@inner_block)}
        </s>
      </li>
      """
    end
  end

  @doc false

  attr :items, :list, default: []
  attr :show_summary, :boolean, default: false
  attr :rest, :global

  def work_experience_list(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.experience_list_item
            role={item["role"]}
            company={item["company"]}
            location={item["location"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            show_summary={@show_summary}
            summary={item["summary"]}
            url={item["url"]}
          />
        <% end %>
      </ul>
    </div>
    """
  end

  @doc false

  attr :role, :string, required: true
  attr :company, :string, required: true
  attr :location, :string, default: nil
  attr :start_date, :string, default: nil
  attr :end_date, :string, default: nil
  attr :url, :string, default: nil
  attr :summary, :string, default: nil
  attr :show_summary, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def experience_list_item(assigns) do
    ~H"""
    <li class="space-y-1 not-last:pb-8">
      <div class="flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@start_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {parse_date(@start_date)}
          <% end %>
        </span>
      </div>
      <div class="font-headings font-medium text-xl">
        {@role}<span class="ml-px text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        <%= if @url do %>
          <.link href={@url} target="_blank" rel="noopener noreferrer" class="link-subtle">
            {@company}
          </.link>
        <% else %>
          {@company}
        <% end %>
        <span :if={@location} class="text-content-30">
          <span class="text-content-40/90">—</span> {@location}
        </span>
      </div>

      <div :if={@show_summary} class="mt-2 max-w-[72ch] font-light text-lg/7 text-content-40">
        {@summary}
      </div>
    </li>
    """
  end

  @doc false

  attr :items, :list, default: []
  attr :rest, :global

  def education_list(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.education_list_item
            area={item["area"]}
            institution={item["institution"]}
            location={item["location"]}
            study_type={item["study_type"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            courses={item["courses"]}
            url={item["url"]}
          />
        <% end %>
      </ul>
    </div>
    """
  end

  @doc false

  attr :area, :string, required: true
  attr :institution, :string, required: true
  attr :study_type, :string, default: nil
  attr :location, :string, default: nil
  attr :start_date, :string, default: nil
  attr :end_date, :string, default: nil
  attr :url, :string, default: nil
  attr :courses, :string, default: nil
  attr :show_start_date, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def education_list_item(assigns) do
    ~H"""
    <li class="space-y-1 not-last:pb-8">
      <div class="flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@end_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date && @show_start_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {parse_date(@end_date)}
          <% end %>
        </span>
      </div>

      <div class="mt-2 font-headings text-xl">
        <span :if={@study_type}>
          <span>{@study_type}</span>
          <span class="font-light text-content-40">in</span>
        </span>
        <span class="font-medium">{@area}</span><span class="text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        <%= if @url do %>
          <.link href={@url} target="_blank" rel="noopener noreferrer" class="link-ghost">
            {@institution}<span :if={@location}> — {@location}</span>
          </.link>
        <% else %>
          {@institution}
        <% end %>
      </div>

      <div :if={@courses} class="mt-2 max-w-[72ch] font-light text-lg/7 text-content-40">
        {@courses}
      </div>
    </li>
    """
  end

  @doc false

  attr :items, :list, default: []
  attr :rest, :global

  def project_list(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.project_list_item
            name={item["name"]}
            context={item["context"]}
            description={item["description"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            location={item["location"]}
            url={item["url"]}
          />
        <% end %>
      </ul>
    </div>
    """
  end

  @doc false

  attr :name, :string, required: true
  attr :context, :string, required: true
  attr :description, :string, required: true
  attr :start_date, :string, default: nil
  attr :end_date, :string, default: nil
  attr :location, :string, default: nil
  attr :url, :string, default: nil

  def project_list_item(assigns) do
    ~H"""
    <li class="space-y-1 not-last:pb-8">
      <div class="font-headings font-medium text-xl">
        <span>{@name}</span><span class="text-primary text-xl"></span><span class="text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        {@context}
        <span :if={@location} class="text-content-30">
          <span class="text-content-40/90">—</span> {@location}
        </span>
      </div>

      <div class="mt-2 flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@start_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {parse_date(@start_date)}
          <% end %>
        </span>
      </div>

      <div :if={@description} class="mt-2 max-w-[72ch] font-light text-lg/7 text-content-40">
        {@description}
      </div>
    </li>
    """
  end

  @doc false

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :icon, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def resume_section_header(assigns) do
    ~H"""
    <.header
      tag="h2"
      class={[
        "relative xl:block",
        "before:content-['0'_counter(item-counter)] before:hidden lg:before:block before:absolute before:-left-28 before:top-0 before:text-7xl before:font-semibold before:font-headings
            before:text-primary before:text-right before:opacity-10 dark:before:saturate-0",
        @class
      ]}
      style="counter-increment: item-counter;"
      {@rest}
    >
      <div class="flex items-center gap-2.5">
        <.icon name={@icon} class="size-7 text-content-40" />
        <span>{@title}<span class="text-primary">.</span></span>
      </div>
      <:subtitle :if={@subtitle}>{@subtitle}</:subtitle>
    </.header>
    """
  end

  ## Renderless Helpers

  # Shortened date string, e.g. "2023-10-01" -> "Oct 2023"
  defp parse_date(nil), do: "Present"

  defp parse_date(string) do
    case Date.from_iso8601(string) do
      {:ok, date} -> Calendar.strftime(date, "%b %Y")
      {:error, _} -> nil
    end
  end
end
