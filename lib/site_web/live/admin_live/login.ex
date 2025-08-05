defmodule SiteWeb.AdminLive.Login do
  use SiteWeb, :live_view

  alias Site.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <Layouts.page_content class="mx-auto max-w-sm space-y-4">
        <.header class="text-center">Admin Login</.header>

        <.alert :if={local_mail_adapter?()} intent="info">
          To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
        </.alert>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/admin/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            placeholder="Your email address"
            required
            phx-mounted={JS.focus()}
          />
          <.button variant="solid" color="primary" wide>
            Log in with email
            <span aria-hidden="true">
              <.icon name="hero-arrow-right-mini" class="text-tint-primary/50" />
            </span>
          </.button>
        </.form>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/admin/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/admin/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:site, Site.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
