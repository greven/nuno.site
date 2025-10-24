defmodule SiteWeb.ChangelogLive.Components do
  use SiteWeb, :html

  @doc """
  Renders a navigation list of dates to filter the changelog timeline.
  The first entry should be "Week", followed by "Month" and then the current year and
  previous years down to first year with updates, e.g., "Week", "Month", "2025", "2024".

  A list of `counts`, where each entry is a tuple of `{label, count}` is required,
  for example: [{"Week", 5}, {"Month", 20}, {"2024", 100}, {"2023", 80}].
  """

  attr :counts, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def timeline_nav(assigns) do
    ~H"""
    <div></div>
    """
  end

  # @doc false

  # attr :updates, :list, required: true
  # attr :class, :string, default: nil
  # attr :rest, :global

  # def updates_timeline(assigns) do
  #   ~H"""
  #   <div class={@class} {@rest}>
  #     <div id="changelog-list" phx-update="stream">
  #       <div :for={{dom_id, update} <- @updates} id={dom_id} class="">
  #         <.update_title type={update.type} update={update} />
  #       </div>
  #     </div>
  #   </div>
  #   """
  # end

  # defp update_title(%{type: :posts} = assigns) do
  #   ~H"""
  #   <a href={@update.uri} class="text-lg font-medium text-neutral-600 hover:underline">
  #     {@update.title}
  #   </a>
  #   """
  # end

  # defp update_title(%{type: :bluesky} = assigns) do
  #   ~H"""
  #   <a href={@update.uri} class="text-lg font-medium text-cyan-600 hover:underline">
  #     BLUESKY!
  #   </a>
  #   """
  # end
end
