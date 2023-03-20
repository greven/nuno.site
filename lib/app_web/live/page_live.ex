defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @live_action == :about do %>
      <div class="grid grid-cols-1 gap-y-16 lg:grid-cols-2 lg:grid-rows-[auto_1fr] lg:gap-y-12">
        <div class="flex justify-center lg:pl-20">
          <div class="relative max-w-[200px] lg:max-w-[300px]">
            <div class="absolute -inset-2 aspect-square rounded-full border-2 border-dashed border-primary-600">
            </div>
            <img
              src="images/profile.png"
              alt="Profile picture"
              class="relative aspect-square rounded-full"
            />
          </div>
        </div>

        <div class="lg:order-first lg:row-span-2">
          <h1 class="text-4xl font-headings font-light tracking-tight">
            HEY! I'm <mark class="font-medium">Nuno</mark>, a
            <span class="font-semibold">Software Developer</span>
            based in <span class="font-normal uppercase">Lisbon</span>.
          </h1>

          <div class="mt-6 space-y-6 text-base text-secondary-600 dark:text-secondary-400">
            <p>
              Lorem ipsum dolor sit, amet consectetur adipisicing elit. Inventore unde veniam repellendus odio beatae ullam, recusandae repudiandae mollitia natus voluptate, explicabo ab possimus aut. In commodi cum sint maiores odit!
            </p>

            <p>
              Lorem ipsum dolor sit amet consectetur adipisicing elit. Facilis doloribus error nemo nulla aperiam odio molestias veniam ut, quis in laboriosam nihil expedita ex quo repudiandae? Earum repellendus nihil aperiam?
              Alias deserunt provident accusantium asperiores non autem facilis totam eveniet numquam sunt enim, dolores illo blanditiis veritatis qui. Incidunt harum corrupti temporibus ducimus magni beatae eius voluptas hic atque vitae!
            </p>
          </div>
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
