defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @live_action == :about do %>
      <div class="grid grid-cols-1 gap-y-16 lg:grid-cols-2 lg:grid-rows-[auto_1fr] lg:gap-y-12">
        <div class="flex justify-center lg:pl-20">
          <div class="group relative max-w-[200px] lg:max-w-[300px]">
            <div class="absolute -inset-2 aspect-square rounded-full border-2 border-dashed border-secondary-400 group-hover:border-primary-600 group-hover:animate-spin-slow transition">
            </div>
            <img
              src="/images/profile.png"
              alt="Profile picture"
              class="relative aspect-square rounded-full"
            />
          </div>
        </div>

        <div class="lg:order-first lg:row-span-2">
          <h1 class="text-3xl md:text-4xl font-headings font-light tracking-tight">
            HEY! My name is <em class="not-italic font-medium underline decoration-4 decoration-primary-600 underline-offset-4">Nuno</em>.
          </h1>

          <p class="mt-2.5 text-lg md:text-xl font-light">
            I'm a <span class="font-semibold">Software Developer</span>
            from <span class="font-normal uppercase"><.icon
                name="hero-map-pin"
                class="w-5 h-5 mr-0.5 mb-1 hidden md:inline-block"
              />Lisbon</span>.
          </p>

          <div class="mt-8 space-y-6 text-base text-secondary-600 dark:text-secondary-400">
            <p>
              Lorem ipsum dolor sit, amet consectetur adipisicing elit. Inventore unde veniam repellendus odio beatae ullam, recusandae repudiandae mollitia natus voluptate, explicabo ab possimus aut. In commodi cum sint maiores odit!
            </p>

            <p>
              Lorem ipsum dolor sit amet consectetur adipisicing elit. Facilis doloribus error nemo nulla aperiam odio molestias veniam ut, quis in laboriosam nihil expedita ex quo repudiandae? Earum repellendus nihil aperiam?
              Alias deserunt provident accusantium asperiores non autem facilis totam eveniet numquam sunt enim, dolores illo blanditiis veritatis qui. Incidunt harum corrupti temporibus ducimus magni beatae eius voluptas hic atque vitae!
            </p>
          </div>
        </div>

        <div class="lg:pl-20">
          <ul role="list" class="flex flex-wrap gap-4 mb-8 justify-center">
            <%!-- Email --%>
            <li>
              <a href="mailto:hello@nuno.site" class="btn btn-sm border-2">
                <.icon name="hero-envelope-solid" class="w-5 h-5" />
                <span>Email</span>
              </a>
            </li>

            <%!-- Github --%>
            <li>
              <a href="https://github.com/greven" class="group btn-outline btn-sm border-2">
                <svg
                  viewBox="0 0 24 24"
                  aria-hidden="true"
                  class="h-5 w-5 flex-none fill-secondary-900 group-hover:fill-primary-600 transition"
                >
                  <path
                    fill-rule="evenodd"
                    clip-rule="evenodd"
                    d="M12 2C6.475 2 2 6.588 2 12.253c0 4.537 2.862 8.369 6.838 9.727.5.09.687-.218.687-.487 0-.243-.013-1.05-.013-1.91C7 20.059 6.35 18.957 6.15 18.38c-.113-.295-.6-1.205-1.025-1.448-.35-.192-.85-.667-.013-.68.788-.012 1.35.744 1.538 1.051.9 1.551 2.338 1.116 2.912.846.088-.666.35-1.115.638-1.371-2.225-.256-4.55-1.14-4.55-5.062 0-1.115.387-2.038 1.025-2.756-.1-.256-.45-1.307.1-2.717 0 0 .837-.269 2.75 1.051.8-.23 1.65-.346 2.5-.346.85 0 1.7.115 2.5.346 1.912-1.333 2.75-1.05 2.75-1.05.55 1.409.2 2.46.1 2.716.637.718 1.025 1.628 1.025 2.756 0 3.934-2.337 4.806-4.562 5.062.362.32.675.936.675 1.897 0 1.371-.013 2.473-.013 2.82 0 .268.188.589.688.486a10.039 10.039 0 0 0 4.932-3.74A10.447 10.447 0 0 0 22 12.253C22 6.588 17.525 2 12 2Z"
                  >
                  </path>
                </svg>
                <span class="group-hover:text-primary-600">Github</span>
              </a>
            </li>

            <%!-- Twitter --%>
            <li>
              <a href="https://twitter.com/grv_pt" class="group btn-outline btn-sm border-2">
                <svg
                  viewBox="0 0 24 24"
                  aria-hidden="true"
                  class="h-5 w-5 flex-none fill-secondary-900 group-hover:fill-primary-600 transition"
                >
                  <path d="M20.055 7.983c.011.174.011.347.011.523 0 5.338-3.92 11.494-11.09 11.494v-.003A10.755 10.755 0 0 1 3 18.186c.308.038.618.057.928.058a7.655 7.655 0 0 0 4.841-1.733c-1.668-.032-3.13-1.16-3.642-2.805a3.753 3.753 0 0 0 1.76-.07C5.07 13.256 3.76 11.6 3.76 9.676v-.05a3.77 3.77 0 0 0 1.77.505C3.816 8.945 3.288 6.583 4.322 4.737c1.98 2.524 4.9 4.058 8.034 4.22a4.137 4.137 0 0 1 1.128-3.86A3.807 3.807 0 0 1 19 5.274a7.657 7.657 0 0 0 2.475-.98c-.29.934-.9 1.729-1.713 2.233A7.54 7.54 0 0 0 22 5.89a8.084 8.084 0 0 1-1.945 2.093Z">
                  </path>
                </svg>
                <span class="group-hover:text-primary-600">Twitter</span>
              </a>
            </li>
          </ul>
        </div>
      </div>
    <% end %>
    """
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :about, _params) do
    socket
    |> assign(:page_title, "About")
  end
end
