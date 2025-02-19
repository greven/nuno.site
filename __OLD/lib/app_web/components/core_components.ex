defmodule AppWeb.CoreComponents do
  @moduledoc """
  Core UI components.
  """

  use Phoenix.Component

  use Gettext, backend: AppWeb.Gettext

  alias Phoenix.LiveView.JS
  alias AppWeb.ComponentsHelpers, as: Helpers

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :show_close_button, :boolean, default: true

  attr :modal_class, :any, default: "w-full max-w-3xl p-4 sm:p-6 lg:py-8"

  attr :wrapper_class, :any,
    default:
      "rounded-2xl bg-white p-14 shadow-lg shadow-secondary-700/10 ring-1 ring-secondary-700/10 transition"

  attr :content_class, :any, default: "relative"

  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 bg-secondary-50/90 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class={@modal_class}>
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class={["hidden relative", @wrapper_class]}
            >
              <div :if={@show_close_button} class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="heroicons:x-mark-solid" class="w-5 h-5" />
                </button>
              </div>

              <div id={"#{@id}-content"} class={@content_class}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :success, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed hidden top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="heroicons:information-circle-mini" class="w-4 h-4" />
        <.icon :if={@kind == :error} name="heroicons:exclamation-circle-mini" class="w-4 h-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="heroicons:x-mark-solid" class="w-5 h-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="client-error"
      kind={:error}
      title="We can't find the internet"
      phx-disconnected={show(".phx-client-error #client-error")}
      phx-connected={hide("#client-error")}
      hidden
    >
      Attempting to reconnect <.icon name="heroicons:arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>

    <.flash
      id="server-error"
      kind={:error}
      title="Something went wrong!"
      phx-disconnected={show(".phx-server-error #server-error")}
      phx-connected={hide("#server-error")}
      hidden
    >
      Hang in there while we get back on track
      <.icon name="heroicons:arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-8 mt-10">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a badge.
  """

  attr :class, :string, default: nil

  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={["btn-outline btn-xs group", @class]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :size, :atom, values: ~w(xs sm md lg)a, default: :md
  attr :variant, :atom, values: ~w(default outline basic)a, default: :default
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75",
        button_variant_class(@variant),
        button_size_class(@size),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders a a Toggle Button that can be used to group
  related options.
  """

  attr :class, :string, default: nil
  attr :selected, :boolean, default: false
  attr :size, :atom, values: ~w(xs sm md lg)a, default: :md
  # attr :on_click, JS, default: %JS{}
  attr :rest, :global

  slot :inner_block, required: true

  def toggle_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        if(@selected, do: "btn", else: "btn-basic"),
        button_size_class(@size),
        @class
      ]}
      aria-pressed={@selected}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  The common container to use to group related
  `toggle_button` elements.
  """

  attr :value, :any, required: true
  attr :on_change, :string, required: true
  attr :class, :string, default: nil
  attr :size, :atom, values: ~w(xs sm md lg)a, default: :md
  attr :rest, :global

  # slot :inner_block, required: true
  slot :button do
    attr :value, :any, required: true
    attr :class, :any
    attr :size, :atom
    attr :aria_label, :string
  end

  def toggle_button_group(assigns) do
    ~H"""
    <div role="group" class={["flex gap-2", @class]} {@rest}>
      <%= for button <- @button do %>
        <.toggle_button
          size={@size}
          selected={@value == button.value}
          phx-click={JS.push(@on_change, value: %{value: button.value})}
          aria-label={button[:aria_label]}
        >
          {render_slot(button)}
        </.toggle_button>
      <% end %>
    </div>
    """
  end

  defp button_variant_class(size) do
    cond do
      size == :default -> "btn"
      size == :outline -> "btn-outline"
      size == :basic -> "btn-basic"
      true -> "btn"
    end
  end

  defp button_size_class(size) do
    cond do
      size == :xs -> "btn-xs"
      size == :sm -> "btn-sm"
      size == :md -> "btn-md"
      size == :lg -> "btn-lg"
      true -> "btn-md"
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
                 range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                  multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-secondary-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="phx-no-feedback:hidden mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <.icon name="heroicons:exclamation-circle-mini" class="mt-0.5 w-5 h-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true

  slot :subtitle do
    attr :class, :string
  end

  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-4xl font-normal leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p
          :for={subtitle <- @subtitle}
          :if={@subtitle != []}
          class={["mt-3 text-sm leading-6 font-medium text-secondary-500", subtitle[:class]]}
        >
          {render_slot(subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="mt-11 w-[40rem] sm:w-full">
        <thead class="text-left text-[0.8125rem] leading-6 text-secondary-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">{col[:label]}</th>
            <th class="relative p-0 pb-4"><span class="sr-only">{gettext("Actions")}</span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-secondary-100 border-t border-secondary-200 text-sm leading-6 text-secondary-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-secondary-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-secondary-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-secondary-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative p-0 w-14">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-secondary-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-secondary-900 hover:text-secondary-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-secondary-100">
        <div :for={item <- @item} class="flex gap-4 py-4 sm:gap-8">
          <dt class="w-1/4 flex-none text-[0.8125rem] leading-6 text-secondary-500">
            {item.title}
          </dt>
          <dd class="text-sm leading-6 text-secondary-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  attr :class, :string, default: nil

  slot :inner_block

  def back(assigns) do
    ~H"""
    <div class={@class}>
      <.link
        navigate={@navigate}
        class="flex items-center gap-1 text-sm font-semibold leading-6 text-secondary-400 no-underline transition-colors hover:text-secondary-800"
      >
        <.icon name="heroicons:chevron-left-solid" class="w-3 h-3 stroke-current inline" />
        <%= if length(@inner_block) == 0 do %>
          {gettext("Back")}
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders an icon.

  ## Examples

      <.icon name="paper-airplane" />
      <.icon name="arrow-path-20-solid" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(assigns) do
    ~H"""
    <span class={["icon", @name, @class]} />
    """
  end

  @doc false

  attr :class, :string, default: nil
  attr :key, :string, default: nil
  attr :modifier, :string, default: nil

  slot :inner_block

  def keyboard(assigns) do
    ~H"""
    <span class={[
      "flex items-center justify-center px-1.5 font-mono font-bold text-neutral-500 bg-neutral-200/50 tracking-wide text-center uppercase rounded group transition",
      @class
    ]}>
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        <span class="text-base leading-tight mr-1">{@modifier}</span>
        <span class="text-xs">{@key}</span>
      <% end %>
    </span>
    """
  end

  @doc false

  # TODO: Remove the hash_image decoding after we save the hash image to the filesystem

  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :width, :integer, default: nil
  attr :height, :integer, default: nil
  # attr :hash, :string, default: nil
  # attr :hash_image, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  # TODO: Inspiration: Next.js Image Component
  attr :placeholder, :atom, values: ~w(nil color blur)a, default: nil
  attr :blur_data_url, :string, default: nil
  attr :loading, :atom, values: ~w(eager lazy)a, default: :lazy
  attr :preload, :boolean, default: false
  # TODO: How to add srcset and sizes attributes?
  # attr :on_load, JS, default: %JS{}
  # attr :on_error, JS, default: %JS{}

  def image(assigns) do
    assigns =
      assigns
      # |> assign_hashimage()
      |> assign_new(:id, fn -> Helpers.use_id() end)

    # |> assign(:class, [not is_nil(assigns.hash_image) && "hidden", assigns.class])

    ~H"""
    <%!-- <img
      :if={@hash}
      id={"#{@id}-hash"}
      class={[@class, "transition-opacity"]}
      src={data_image_url(@hash_image)}
      {@rest}
    />
    <img
      id={@id}
      class={[@class, @hash && "hidden transition-opacity"]}
      src={@src}
      phx-hook="Image"
      data-hash={!!@hash}
      {@rest}
    /> --%>

    <img id={@id} class={[@class]} src={@src} {@rest} />
    """
  end

  # defp data_image_url(data), do: "data:image/*;base64,#{Base.encode64(data)}"

  # # TODO: Instead of saving the hash image to memory we should save it to the filesystem (or S3?) and serve it from there. This will allow us to use the image in the future without having to decode it again.
  # defp assign_hashimage(%{hash: hash, width: width, height: height} = assigns)
  #      when is_binary(hash) and is_integer(width) and is_integer(height) do
  #   {:ok, blurhash} = Image.Blurhash.decode(hash, width, height)

  #   case Image.write(blurhash, :memory, suffix: ".jpg") do
  #     {:ok, image} ->
  #       assign(assigns, :hash_image, image)

  #     {:error, _} ->
  #       assigns
  #   end
  # end

  # defp assign_hashimage(assigns), do: assigns

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(DevAppWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(DevAppWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
