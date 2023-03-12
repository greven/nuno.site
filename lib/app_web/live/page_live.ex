defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @live_action == :home do %>
      Page Live
    <% end %>

    <%= if @live_action == :about do %>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Voluptatum sapiente neque itaque sed nostrum mollitia eaque animi minima impedit. Ducimus commodi molestias esse! Dignissimos voluptatem, voluptate quae ea nihil vero.
      Magni neque quaerat voluptatem possimus perferendis ullam expedita qui maiores porro fuga aut, distinctio iure nostrum sint dolores eius facere consequuntur ipsum soluta ad eveniet quam! Officia, id esse. Nihil?
      Beatae odio labore et dolore laboriosam provident fugiat in sunt fuga quod maiores cumque voluptates saepe quos ut ea ullam doloremque autem, nostrum illo possimus magni. Assumenda soluta sed cumque.
      Et, eius vero quo ipsa id doloribus consequuntur ipsam dolorum reprehenderit, dolore debitis? Minima reprehenderit unde excepturi ad aliquam? Magni quos at id nemo? Ipsum doloremque repellendus ea at id.
      Officiis quaerat autem laudantium maxime provident quas nemo, molestiae earum saepe rerum adipisci in? Eaque, eum est! Incidunt, iure, animi nemo sint ut at voluptatibus totam vitae illo corrupti perspiciatis.
      At, omnis deleniti, labore quae qui non perspiciatis autem accusamus repudiandae voluptatibus eligendi veritatis, eum obcaecati. Doloribus illo iure consectetur quasi? Dignissimos soluta illo aperiam quia incidunt temporibus sequi adipisci!
      Facilis dolorem cumque illo optio maxime ipsum labore laborum ad saepe ratione voluptate modi, tempore autem sint quis laboriosam atque voluptatum nihil neque et. Totam nulla magni sapiente numquam hic!
      Quos nulla dolore eum sapiente officiis natus obcaecati. Odio reprehenderit laudantium itaque at nam excepturi aliquam ipsum modi ut mollitia beatae consequuntur cumque ab, delectus ex harum commodi temporibus quasi.
      Hic quam nihil minus, adipisci magni, veritatis autem deserunt perferendis ducimus blanditiis totam assumenda cumque recusandae necessitatibus ex alias sapiente, eveniet repudiandae iusto consequatur? Incidunt nihil tempore aut officia molestias!
    <% end %>
    """
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :home, _params) do
    socket
    |> assign(:page_title, "Home")
  end

  defp apply_action(socket, :about, _params) do
    socket
    |> assign(:page_title, "About")
  end
end
