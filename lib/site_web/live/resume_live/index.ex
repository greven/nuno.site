defmodule SiteWeb.ResumeLive.Index do
  use SiteWeb, :live_view

  alias Site.Resume

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} active_link={@active_link}>
      <Layouts.page_content class="resume-page">
        <header class="border-b border-surface-40">
          <%!-- Contact Information --%>
          <div class="px-2 flex justify-between items-center text-content border-b border-surface-40 border-dashed pb-6">
            <%!-- Location --%>
            <div class="flex items-center justify-center gap-2.5">
              <.icon name="hero-map-pin" class="size-5 text-content-20" />
              {@resume["profile"]["location"]["city"]},
              <span class="font-medium">{@profile_country}</span>
            </div>

            <%!-- Email --%>
            <div class="flex items-center justify-center gap-2.5 text-content">
              <.icon name="hero-at-symbol-mini" class="size-5 text-content-20" />
              <a href={"mailto:#{@resume["profile"]["email"]}"}>
                {@resume["profile"]["email"]}
              </a>
            </div>

            <%!-- LinkedIn --%>
            <div class="flex items-center justify-center gap-2.5 text-content">
              <.icon name="lucide-linkedin" class="size-4 text-content-20" />
              <a href="https://www.linkedin.com/in/nuno-fr3ire/">linkedin</a>
            </div>

            <%!-- GitHub --%>
            <div class="flex items-center justify-center gap-2.5 text-content">
              <.icon name="lucide-github" class="size-4 text-content-20" />
              <a href="https://github.com/greven">github</a>
            </div>
          </div>

          <%!-- Name and Summary --%>
          <div class="py-8">
            <div class="flex items-end gap-2">
              <span class="text-8xl font-medium">Nuno</span>
              <.icon name="lucide-arrow-down-right" class="size-22 text-primary" />
            </div>

            <div class="">
              <div class="">
                <span class="text-7xl font-medium">Moço</span>
                <p class="mt-4 font-light text-xl text-content-30">{@resume["profile"]["title"]}</p>
              </div>

              <div class="">
                <p
                  :for={p <- @resume["profile"]["summary"]}
                  class="font-light text-content-20/90 text-base/8"
                >
                  {Helpers.render_markdown!(p)}
                </p>
              </div>
            </div>
          </div>
        </header>
        <div></div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    resume = Resume.data()

    profile_country =
      resume["profile"]["location"]["country_code"]
      |> Site.Geo.get_country()
      |> Map.get(:name)

    {:ok,
     assign(socket,
       page_title: "Resume",
       profile_country: profile_country,
       resume: resume
     )}
  end
end
