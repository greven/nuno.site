defmodule SiteWeb.AdminLive.Confirmation do
  use SiteWeb, :live_view

  alias Site.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="mx-auto max-w-sm space-y-4">
        <.header class="text-center">
          Welcome <span class="text-[0.75em] text-content-40">{@user.email}</span>
        </.header>

        <.form
          :if={!@user.confirmed_at}
          for={@form}
          id="confirmation_form"
          phx-mounted={JS.focus_first()}
          phx-submit="submit"
          action={~p"/admin/log-in?_action=confirmed"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <.button
            variant="solid"
            color="primary"
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with="Confirming..."
            wide
          >
            Confirm and stay logged in
          </.button>
          <.button variant="light" color="primary" phx-disable-with="Confirming..." class="mt-2" wide>
            Confirm and log in only this time
          </.button>
        </.form>

        <.form
          :if={@user.confirmed_at}
          for={@form}
          id="login_form"
          phx-submit="submit"
          phx-mounted={JS.focus_first()}
          action={~p"/admin/log-in"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <%= if @current_scope do %>
            <.button
              variant="solid"
              color="primary"
              phx-disable-with="Logging in..."
              class="btn btn-primary w-full"
            >
              Log in
            </.button>
          <% else %>
            <.button
              variant="solid"
              color="primary"
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with="Logging in..."
              wide
            >
              Keep me logged in on this device
            </.button>
            <.button
              variant="light"
              color="primary"
              class="mt-2"
              phx-disable-with="Logging in..."
              wide
            >
              Log me in only this time
            </.button>
          <% end %>
        </.form>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/admin/log-in")}
    end
  end

  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
