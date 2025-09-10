defmodule SiteWeb.AboutLive.Resume do
  use SiteWeb, :live_view

  alias Site.Resume

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
      show_progress
    >
      <Layouts.page_content class="resume-page">
        <div id="resume" phx-hook="Resume" style="counter-reset: item-counter;">
          <header>
            <%!-- Contact Information --%>
            <div class="flex flex-wrap justify-between items-center gap-4 px-2 pb-6 text-content border-b border-surface-40 border-dashed">
              <%!-- Location --%>
              <div class="flex items-center justify-center gap-1.5 md:gap-2.5 print:text-sm">
                <.icon name="hero-map-pin" class="size-5 text-content-20 print:size-4" />
                {@resume["profile"]["location"]["city"]},
                <span class="font-medium">{@profile_country}</span>
              </div>

              <%!-- Phone (Admin only) --%>
              <div
                :if={@current_scope}
                class="hidden lg:flex items-center justify-center gap-1.5 md:gap-2.5 text-content print:text-sm"
              >
                <.icon name="hero-device-phone-mobile" class="size-5 text-content-20 print:size-4" />
                <a href={"tel:#{@resume["profile"]["phone_country_code"]} #{@resume["profile"]["phone"]}"}>
                  {@resume["profile"]["phone"]}
                </a>
              </div>

              <%!-- Email --%>
              <div class="flex items-center justify-center gap-1.5 md:gap-2.5 text-content print:text-sm">
                <.icon name="hero-at-symbol-mini" class="size-5 text-content-20 print:size-4" />
                <a href={"mailto:#{@resume["profile"]["email"]}"} class="link-ghost">
                  {@resume["profile"]["email"]}
                </a>
              </div>

              <%!-- LinkedIn --%>
              <div class="hidden md:flex items-center justify-center gap-1.5 md:gap-2.5 text-content print:text-sm">
                <.icon name="lucide-linkedin" class="size-4 text-content-20 print:size-4" />
                <a href="https://www.linkedin.com/in/nuno-fr3ire/" class="link-ghost">linkedin</a>
              </div>

              <%!-- GitHub --%>
              <div class="hidden md:flex items-center justify-center gap-1.5 md:gap-2.5 text-content print:text-sm">
                <.icon name="lucide-github" class="size-4 text-content-20 print:size-4" />
                <a href="https://github.com/greven" class="link-ghost">github</a>
              </div>
            </div>

            <%!-- Name, Summary and Highlights --%>
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 py-8">
              <%!-- Name and Skills --%>
              <div class="col-span-1 lg:col-span-5 flex flex-col font-medium">
                <div class="resume-id">
                  <div class="flex flex-row items-center gap-2 lg:flex-col lg:items-start">
                    <div class="text-5xl lg:text-8xl print:text-6xl">Nuno</div>
                    <div class="flex items-center">
                      <div class="text-5xl lg:text-8xl print:text-6xl">Moço</div>
                      <.icon
                        id="resume-arrow"
                        name="lucide-arrow-up-right"
                        class="size-14 lg:size-22 aspect-square text-primary translate-y-1 lg:translate-y-2"
                      />
                    </div>
                  </div>

                  <%!-- Title --%>
                  <p class="mt-1 lg:mt-6 font-headings font-light text-2xl text-content-30 print:text-lg print:mt-4">
                    {@resume["profile"]["title"]}
                  </p>
                </div>

                <%!-- Skills (Desktop) --%>
                <div class="hidden lg:block mt-5">
                  <h3 class="sr-only font-headings font-sm uppercase text-content-40">Skills</h3>
                  <div class="mt-4 max-w-2xl flex flex-wrap gap-2">
                    <%= for {skill, fav} <- Enum.take(@skills, 10) do %>
                      <.badge>
                        <.icon :if={fav} name="hero-star-mini" class="size-4 bg-tint-primary/25" />
                        {skill}
                      </.badge>
                    <% end %>
                  </div>
                </div>
              </div>

              <%!-- Summary --%>
              <div
                id="resume-summary"
                class="col-span-1 lg:col-span-7 text-justify font-light text-lg/8 text-content-40"
              >
                <p>{Helpers.render_markdown!(@resume["profile"]["summary"])}</p>
              </div>

              <%!-- Skills (Mobile) --%>
              <div class="block lg:hidden -mt-4">
                <h3 class="sr-only font-headings font-sm uppercase text-content-40">Skills</h3>
                <div class="mt-4 max-w-2xl flex flex-wrap gap-2">
                  <%= for {skill, fav} <- Enum.take(@skills, 10) do %>
                    <.badge>
                      <.icon :if={fav} name="hero-star-mini" class="size-4 bg-tint-primary/25" />
                      {skill}
                    </.badge>
                  <% end %>
                </div>
              </div>
            </div>
          </header>

          <section class="border-t border-surface-40 border-dashed">
            <%!-- Spoken Languages --%>
            <div class="flex flex-col flex-wrap py-6 lg:flex-row lg:items-center">
              <h3 class="m-0 font-headings font-medium flex items-center">
                <.icon name="hero-language" class="size-5 text-content-40 mr-2" /> Spoken Languages
              </h3>
              <ul class="mt-4 flex flex-col list-disc list-inside marker:text-primary lg:list-none lg:flex-row lg:items-center gap-2.5 lg:gap-4 lg:ml-4 lg:mt-0">
                <%= for lang <- @resume["languages"] do %>
                  <li class="font-normal lg:not-last:after:content-['•'] after:text-primary after:ml-3">
                    <span class="underline underline-offset-2 decoration-surface-40">
                      {lang["language"]}
                    </span>
                    <span class="font-light text-content-40">({lang["fluency"]})</span>
                  </li>
                <% end %>
              </ul>
            </div>
          </section>

          <%!-- Experience --%>
          <section class="py-12 border-t border-surface-40 border-dashed">
            <SiteWeb.SiteComponents.resume_section_header
              title="Career"
              subtitle="Recent work experience"
              icon="hero-briefcase"
            />

            <SiteWeb.SiteComponents.work_experience_list
              class="mt-12"
              items={@resume["work"]}
              show_summary
            />
          </section>

          <%!-- Education --%>
          <section class="py-12 border-t border-surface-40">
            <SiteWeb.SiteComponents.resume_section_header
              title="Education"
              subtitle="Relevant education"
              icon="hero-academic-cap"
            />

            <SiteWeb.SiteComponents.education_list
              class="mt-12"
              items={@resume["education"]}
            />
          </section>

          <%!-- Projects --%>
          <section class="py-12 border-t border-surface-40">
            <SiteWeb.SiteComponents.resume_section_header
              title="Projects"
              subtitle="Some projects I have worked on"
              icon="hero-clipboard-document-check"
            />

            <SiteWeb.SiteComponents.project_list
              class="mt-12"
              items={@resume["projects"]}
            />
          </section>
        </div>
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
       resume: resume,
       skills: Resume.list_skills(),
       favourite_skills: Resume.list_favourite_skills()
     )}
  end
end
