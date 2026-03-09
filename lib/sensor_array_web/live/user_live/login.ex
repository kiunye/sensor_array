defmodule SensorArrayWeb.UserLive.Login do
  use SensorArrayWeb, :live_view

  alias Phoenix.Flash
  alias SensorArray.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md motion-reduce:animate-none">
      <div class="card bg-base-200 border border-base-300 motion-safe:animate-fade-in">
        <div class="card-body gap-6">
          <div class="text-center">
            <.header>
              <p class="text-xl font-semibold tracking-tight text-base-content">Log in</p>
              <:subtitle>
                <%= if @current_scope do %>
                  Reauthenticate to perform sensitive actions on your account.
                <% else %>
                  Don't have an account?
                  <.link navigate={~p"/users/register"} class="link link-primary font-medium" phx-no-format>
                    Sign up
                  </.link>
                  for an account.
                <% end %>
              </:subtitle>
            </.header>
          </div>

          <div :if={local_mail_adapter?()} class="alert alert-info text-sm">
            <.icon name="hero-information-circle" class="size-5 shrink-0" />
            <div>
              <p>Local mail adapter. Visit <.link href="/dev/mailbox" class="link link-primary">dev/mailbox</.link> to see sent emails.</p>
            </div>
          </div>

          <.form
            :let={f}
            for={@form}
            id="login_form_magic"
            action={~p"/users/log-in"}
            phx-submit="submit_magic"
            class="space-y-4"
          >
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              spellcheck="false"
              required
              phx-mounted={JS.focus()}
            />
            <.button class="btn btn-primary w-full">
              Log in with email <span aria-hidden="true">→</span>
            </.button>
          </.form>

          <div class="flex items-center gap-3">
            <div class="flex-1 h-px bg-base-300" aria-hidden="true"></div>
            <span class="text-xs uppercase tracking-wider text-base-content/60">or</span>
            <div class="flex-1 h-px bg-base-300" aria-hidden="true"></div>
          </div>

          <.form
            :let={f}
            for={@form}
            id="login_form_password"
            action={~p"/users/log-in"}
            phx-submit="submit_password"
            phx-trigger-action={@trigger_submit}
            class="space-y-4"
          >
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              spellcheck="false"
              required
            />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="current-password"
              spellcheck="false"
            />
            <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
              Log in and stay logged in <span aria-hidden="true">→</span>
            </.button>
            <.button class="btn btn-ghost w-full mt-1 text-base-content/80">
              Log in only this time
            </.button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:sensor_array, SensorArray.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
