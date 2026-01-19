defmodule SiteWeb.AboutLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.SiteComponents
  alias SiteWeb.AboutLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-16 md:gap-24">
        <div class="about-intro">
          <%!-- Intro --%>
          <div class="w-full text-center md:text-left lg:order-first lg:row-span-2">
            <h1 class="text-3xl md:text-4xl font-headings font-light tracking-tight">
              HEY! My name is <em class="font-medium underline not-italic decoration-4 decoration-primary underline-offset-4 text-content-10">Nuno</em>.
            </h1>

            <p class="mt-2 text-lg md:text-xl font-light">
              I'm a <span class="font-semibold">Software Engineer</span>
              from <span class="font-normal uppercase">
              <.icon
                  name="lucide-map-pin"
                  class="size-5 mr-1 mb-1.5 hidden md:inline-block"
                />Lisbon</span>.
            </p>

            <div class="mt-8 space-y-4 text-base text-content-20">
              <SiteComponents.profile_picture
                size={300}
                class="w-full flex justify-center md:w-auto md:block md:ml-8 md:float-right [shape-outside:circle(50%)]"
              />

              <p class="mt-12 font-light text-base md:text-lg text-pretty">
                Hello fellow visitor! I'm Nuno Moço, a seasoned software developer focused on web technologies.
                I love crafting web applications with a focus on <span class="font-medium">User Experience</span>.
              </p>

              <p class="font-light text-base md:text-lg text-pretty">
                I've always been passionate about design and user experience, so the web was a natural fit for me. I've been building web applications before they were called applications 🧙‍♂️.
              </p>

              <p class="font-light text-base md:text-lg text-pretty">
                As a full-stack developer I enjoy working with various technologies. My main toolkit includes <span class="font-medium">Elixir</span>, <span class="font-medium">Phoenix</span>, <span class="font-medium">CSS</span>, <span class="font-medium">SQL</span>, <span class="font-medium">JavaScript</span>, and <span class="font-medium">React</span>.
              </p>
            </div>

            <Components.contact_links class="mt-10 flex flex-col items-center justify-center md:items-start gap-1" />
          </div>
        </div>

        <%!-- Skills --%>
        <div class="about-skills">
          <.header tag="h2">
            <div class="flex items-center gap-3">
              <.icon name="hero-rectangle-stack" class="size-8 text-content-40" />
              <span>Skills</span>
            </div>
            <:subtitle>Some of the tech I work with</:subtitle>
          </.header>

          <div class="mt-4 max-w-2xl flex flex-wrap gap-2">
            <%= for {skill, fav} <- @skills do %>
              <.badge>
                <.icon :if={fav} name="hero-star-mini" class="size-4 bg-tint-secondary/25" />
                {skill}
              </.badge>
            <% end %>
          </div>
        </div>

        <%!-- Experience --%>
        <div class="about-experience">
          <.header tag="h2">
            <div class="flex items-center gap-3">
              <.icon name="hero-briefcase" class="size-8 text-content-40" />
              <span>Career</span>
            </div>
            <:subtitle>Recent work experience</:subtitle>
          </.header>

          <Components.work_experience_list class="mt-4 max-w-xl" items={@experience} />

          <.button navigate={~p"/resume"} variant="light" class="group mt-8">
            Full Resume
            <.icon
              name="lucide-arrow-right"
              class="size-4 inline-block text-primary duration-200 group-hover:transform group-hover:translate-x-0.5 transition-transform"
            />
          </.button>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    experience = Enum.take(Site.Resume.get_experience(), 3)

    {:ok,
     assign(socket,
       page_title: "About",
       experience: experience,
       skills: Site.Resume.list_skills()
     )}
  end
end
