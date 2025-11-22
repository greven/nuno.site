defmodule SiteWeb.CoreComponents do
  @moduledoc false

  use Phoenix.Component
  use Gettext, backend: SiteWeb.Gettext

  alias Phoenix.LiveView.JS

  alias Site.Support
  alias SiteWeb.Helpers
  alias SiteWeb.Components.Theming

  @button_radius "lg"

  @theme_colors ~w(default primary secondary info success warning danger)

  @tailwind_colors ~w(
    red orange amber yellow lime green emerald teal cyan sky
    blue indigo violet purple fuchsia pink rose
    slate gray zinc neutral stone)

  @doc """
  Box component that provides a base element styled with the theme defaults
  for background, border, and shadow.
  """

  attr :class, :any, default: nil, doc: "the base classes to apply to the box element"
  attr :tag, :string, default: "div", doc: "the HTML tag to use for the box element"
  attr :bg, :string, default: "bg-surface-10", doc: "the background color of the box"
  attr :border, :string, default: "border border-border", doc: "the border color of the box"
  attr :shadow, :string, default: "shadow-xs", doc: "the shadow class of the box"
  attr :radius, :string, default: "rounded-lg", doc: "the border radius of the box"
  attr :padding, :string, default: "p-4", doc: "the padding of the box"

  attr :focus, :string,
    default:
      "has-focus-visible:outline-1 has-focus-visible:-outline-offset-1 has-focus-visible:outline-primary **:outline-none",
    doc: "the focus classes to apply to the box element"

  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the box"
  slot :inner_block, required: true

  def box(assigns) do
    ~H"""
    <.dynamic_tag
      tag_name={@tag}
      class={[@class, @bg, @border, @shadow, @radius, @padding, @focus]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  @doc false

  attr :tag, :string, default: "div"
  attr :class, :any, default: nil
  attr :content_class, :any, default: "h-full flex flex-col gap-3"
  attr :bg, :string, default: "bg-surface-10/80 hover:bg-surface-10"
  attr :padding, :string, default: "p-4"

  attr :border, :string, default: "border border-border border-dashed hover:border-solid"

  attr :radius, :string, default: "rounded-lg"
  attr :shadow, :string, default: "hover:shadow-drop"
  attr :rest, :global, include: ~w(href navigate patch method disabled)
  slot :inner_block, required: true

  def card(%{rest: rest} = assigns) do
    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.dynamic_tag tag_name={@tag} class={["isolate", @class, @radius]}>
        <.box
          bg={@bg}
          border={@border}
          radius={@radius}
          padding={@padding}
          shadow={@shadow}
          class={["group/card isolate relative overflow-hidden", @content_class]}
          data-part="card"
        >
          <.link
            class={["absolute inset-0 z-10 outline-none", @radius]}
            {@rest}
          >
          </.link>
          {render_slot(@inner_block)}
        </.box>
      </.dynamic_tag>
      """
    else
      ~H"""
      <.dynamic_tag tag_name={@tag} class={@class} {@rest}>
        <.box
          bg={@bg}
          border={@border}
          radius={@radius}
          padding={@padding}
          shadow={@shadow}
          class={["group/card isolate relative overflow-hidden", @content_class]}
          data-part="card"
        >
          {render_slot(@inner_block)}
        </.box>
      </.dynamic_tag>
      """
    end
  end

  @doc """
  Renders a card stack container that stacks cards on top of each other.
  It is possible to swipe through the cards using the navigation buttons.
  """

  # TODO: Add autoplay functionality

  attr :items, :list, default: []
  attr :class, :any, default: nil

  attr :container_class, :string,
    default: "w-full h-[148px] md:w-[512px] md:h-[196px] lg:w-[600px] lg:h-[200px]"

  attr :max_stack, :integer, default: 3
  attr :show_nav, :boolean, default: false
  attr :autoplay, :boolean, default: false
  attr :duration, :integer, default: 5_000
  attr :rest, :global

  slot :inner_block, required: true

  def card_stack(assigns) do
    ~H"""
    <div
      class={@class}
      phx-hook="CardStack"
      {@rest}
      data-max-stack={@max_stack}
      data-show-nav={@show_nav}
      data-autoplay={@autoplay}
      data-duration={@duration}
      data-part="card-stack"
    >
      <div class="flex flex-col items-center justify-center gap-10">
        <div
          class={["relative isolate will-change-transform", @container_class]}
          data-part="card-container"
        >
          {render_slot(@inner_block)}
        </div>

        <%!-- Nav Buttons --%>
        <div :if={@show_nav} class="flex gap-2">
          <button
            :for={index <- 1..min(length(@items), @max_stack)}
            type="button"
            data-part="nav-button"
            data-index={index - 1}
            aria-currrent={index == 1}
            aria-label={"View Card #{index}"}
            class="group relative h-4 w-6 cursor-pointer"
          >
            <div class={[
              "h-1 w-6 overflow-hidden rounded-full bg-surface-40 transition-colors duration-150 ease-out",
              "group-hover:bg-content-10 group-aria-[current]:bg-content-20"
            ]}>
            </div>
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a skeleton placeholder for content loading.
  """

  attr :class, :any, default: "bg-surface-30 rounded-xs"
  attr :loading, :boolean, default: true, doc: "whether the skeleton is in loading state"
  attr :height, :string, default: "24px", doc: "the height of the skeleton"
  attr :width, :string, default: "100%", doc: "the width of the skeleton"
  slot :inner_block

  def skeleton(assigns) do
    ~H"""
    <div class={[@loading && "animate-pulse", @class]} style={"height:#{@height}; width:#{@width};"}>
      <div :if={@inner_block != []} class="flex items-center justify-center h-full">
        {render_slot(@inner_block)}
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
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "flash-#{assigns.kind}" end)
      |> assign(:cx, Theming.flash_cx(assigns))

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="fixed top-4 right-4 z-50 w-80 sm:w-96 max-w-80 sm:max-w-96"
      {@rest}
    >
      <div class={[
        "relative flex items-center gap-3 p-4 rounded-lg border text-sm shadow",
        "bg-surface-10 backdrop-blur-sm",
        @cx
      ]}>
        <.icon
          :if={@kind == :info}
          name="hero-information-circle-mini"
          class="size-5 shrink-0 text-blue-600 dark:text-blue-400"
        />
        <.icon
          :if={@kind == :error}
          name="hero-exclamation-circle-mini"
          class="size-5 shrink-0 text-red-600 dark:text-red-400"
        />

        <div class="flex-1 min-w-0">
          <p :if={@title} class="font-semibold mb-1">{@title}</p>
          <p class="text-wrap wrap-break-words">{msg}</p>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders an alert component for displaying contextual feedback messages.

  ## Examples

      <.alert intent="info">This is an info alert</.alert>
      <.alert intent="success" closable>Operation completed successfully</.alert>
      <.alert intent="warning" icon="hero-exclamation-triangle">
        Warning: This action cannot be undone
      </.alert>
  """
  attr :class, :any, default: nil
  attr :intent, :string, default: "default", values: @theme_colors
  attr :show_icon, :boolean, default: true
  attr :icon, :string, default: nil
  attr :title, :string, default: nil
  attr :id, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def alert(assigns) do
    assigns =
      assigns
      |> assign(:alert_cx, Theming.alert_cx(assigns))
      |> assign(:icon, assigns.icon || Theming.default_alert_icon(assigns))

    ~H"""
    <div
      class={[
        "relative flex items-center gap-3.5 p-4 rounded-lg border text-sm",
        @alert_cx,
        @class
      ]}
      role="alert"
      {@rest}
    >
      <.icon :if={@icon && @show_icon} name={@icon} class="shrink-0" />

      <div class="flex-1 min-w-0">
        <h4 :if={@title} class="font-semibold mb-1">{@title}</h4>
        <div>{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
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
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

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
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :class, :string, default: "w-full mb-4", doc: "the CSS class to apply to the root element"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class={@class}>
      <label class="inline-flex items-center gap-3">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={[
            "size-4 rounded border-2 text-primary transition-colors",
            "border-surface-30 bg-surface-10",
            "focus:ring-2 focus:ring-primary/20 focus:border-primary",
            "checked:bg-primary checked:border-primary",
            "disabled:opacity-50 disabled:cursor-not-allowed",
            @errors != [] && "border-danger focus:border-danger focus:ring-danger/20"
          ]}
          {@rest}
        />
        <span :if={@label} class="text-sm font-medium text-content-10">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class={@class}>
      <label class="block w-full">
        <span :if={@label} class="block text-sm font-medium text-content-10 mb-2">{@label}</span>
        <div class="grid grid-cols-1">
          <select
            id={@id}
            name={@name}
            class={[
              "col-start-1 row-start-1 w-full px-3 py-2 text-sm rounded-lg border transition-colors appearance-none",
              "bg-surface-10 border-surface-30 text-content-10",
              "focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary",
              "disabled:opacity-50 disabled:cursor-not-allowed disabled:bg-surface-20",
              @errors != [] && "border-danger focus:border-danger focus:ring-danger/20"
            ]}
            multiple={@multiple}
            {@rest}
          >
            <option :if={@prompt} value="">{@prompt}</option>
            {Phoenix.HTML.Form.options_for_select(@options, @value)}
          </select>
          <svg
            viewBox="0 0 16 16"
            fill="currentColor"
            data-slot="icon"
            aria-hidden="true"
            class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end text-content-40 sm:size-4"
          >
            <path
              d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z"
              clip-rule="evenodd"
              fill-rule="evenodd"
            />
          </svg>
        </div>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class={@class}>
      <label class="block">
        <span :if={@label} class="block text-sm font-medium text-content-10 mb-2">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            "w-full px-3 py-2 text-sm rounded-lg border transition-colors resize-y",
            "bg-surface-10 border-surface-30 text-content-10",
            "focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary",
            "disabled:opacity-50 disabled:cursor-not-allowed disabled:bg-surface-20",
            "placeholder:text-content-40",
            @errors != [] && "border-danger focus:border-danger focus:ring-danger/20"
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <fieldset class={["grid grid-cols-1 gap-1.5 py-1", @class]}>
      <label>
        <span :if={@label} class="block text-sm/6 font-medium text-content-10 pl-0.5 mb-2">
          {@label}
        </span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "w-full px-3 py-2 text-sm rounded-lg border transition-colors",
            "bg-surface-10 border-surface-30 text-content-10",
            "focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary",
            "disabled:opacity-50 disabled:cursor-not-allowed disabled:bg-surface-20",
            "placeholder:text-content-40/80",
            @errors != [] && "border-danger focus:border-danger focus:ring-danger/20"
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle-mini" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :header_class, :string
  attr :padding_class, :string, default: "pb-4"
  attr :class, :any, default: "flex flex-col"
  attr :anchor, :string, default: nil
  attr :show_anchor_link, :boolean, default: false
  attr :tag, :string, default: "h1"
  attr :rest, :global

  slot :inner_block, required: true

  slot :subtitle do
    attr :class, :string
  end

  slot :actions

  def header(assigns) do
    assigns =
      assigns
      |> assign_new(:header_class, fn -> ["font-medium", header_font_size(assigns.tag)] end)

    ~H"""
    <header
      class={[@padding_class, @actions != [] && "flex items-center justify-between gap-6"]}
      {@rest}
    >
      <div class={@class}>
        <.dynamic_tag
          tag_name={@tag}
          class={[
            if(@anchor,
              do: "relative group sm:flex items-center",
              else: "flex items-center"
            ),
            "text-content-10",
            @header_class
          ]}
        >
          <%= if @anchor do %>
            <a
              id={@anchor}
              class={if(@show_anchor_link, do: "header-link", else: "scroll-header")}
              href={"##{@anchor}"}
            >
              <span :if={@show_anchor_link}>{@tag}</span>
            </a>
            {render_slot(@inner_block)}
          <% else %>
            {render_slot(@inner_block)}
          <% end %>
        </.dynamic_tag>

        <p
          :for={subtitle <- @subtitle}
          class={["mt-2 text-content-40", header_subtitle_font_size(@tag), subtitle[:class]]}
        >
          {render_slot(subtitle)}
        </p>
      </div>
      <div :if={@actions != []} class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  defp header_font_size(tag) do
    case tag do
      "h1" -> "text-5xl"
      "h2" -> "text-3xl"
      "h3" -> "text-xl"
      _ -> "text-base"
    end
  end

  defp header_subtitle_font_size(tag) do
    case tag do
      "h1" -> "text-lg"
      "h2" -> "text-base"
      "h3" -> "text-sm"
      _ -> "text-sm"
    end
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
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
    <table class="table">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  # @doc """
  # Renders a data list.

  # ## Examples

  #     <.list>
  #       <:item title="Title">{@post.title}</:item>
  #       <:item title="Views">{@post.views}</:item>
  #     </.list>
  # """
  # slot :item, required: true do
  #   attr :title, :string, required: true
  # end

  # def list(assigns) do
  #   ~H"""
  #   <ul class="list">
  #     <li :for={item <- @item} class="list-row">
  #       <div>
  #         <div class="font-bold">{item.title}</div>
  #         <div>{render_slot(item)}</div>
  #       </div>
  #     </li>
  #   </ul>
  #   """
  # end

  @doc false

  attr :position, :string, values: ~w(left center right), default: "center"
  attr :bg_color, :string, default: "bg-surface"
  attr :border_class, :string, default: "w-full border-t border-surface-30"
  attr :class, :string, default: nil
  slot :inner_block

  def divider(assigns) do
    assigns =
      assigns
      |> assign(
        :content_position,
        case assigns.position do
          "left" -> "justify-start"
          "center" -> "justify-center"
          "right" -> "justify-end"
        end
      )

    ~H"""
    <div class={["relative", @class]}>
      <div class="absolute inset-0 flex items-center">
        <div class={@border_class}></div>
      </div>

      <div :if={@inner_block != []} class={["relative flex", @content_position]}>
        <span class={@bg_color}>{render_slot(@inner_block)}</span>
      </div>
    </div>
    """
  end

  @doc """
  Renders a badge.
  Badges are small, compact labels that can be used to display
  contextual information, such as status or categories.
  """
  attr :variant, :string, values: ~w(default solid dot), default: "default"
  attr :color, :string, values: @tailwind_colors
  attr :circle, :boolean, default: false
  attr :class, :string, default: nil
  attr :badge_class, :any, default: "text-sm"
  attr :rounded_class, :string, default: "rounded-full"
  attr :rest, :global, include: ~w(href navigate patch method disabled)
  slot :inner_block, required: true

  def badge(%{rest: rest} = assigns) do
    assigns = assign(assigns, :cx, Theming.badge_cx(assigns))

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={["group", @class]} {@rest}>
        <span style="--badge-dot-color: var(--color-gray-400);">
          <span class={[
            "group-hover:ring-surface-40 group-hover:bg-surface-10 group-hover:text-content-10",
            @cx,
            @badge_class,
            @rounded_class
          ]}>
            {render_slot(@inner_block)}
          </span>
        </span>
      </.link>
      """
    else
      ~H"""
      <span style="--badge-dot-color: var(--color-gray-400);" class={["group", @class]} {@rest}>
        <span class={[@cx, @badge_class, @rounded_class]}>
          {render_slot(@inner_block)}
        </span>
      </span>
      """
    end
  end

  @doc false

  attr :color, :string, values: @tailwind_colors
  attr :class, :string, default: nil

  def dot(assigns) do
    assigns = assign(assigns, :dot_class, Theming.badge_dot_color(assigns[:color]))

    ~H"""
    <span class={["relative flex items-center size-1.5", @class]}>
      <span class={[
        "before:content=[''] before:size-1.5 before:inline-flex before:rounded-full",
        @dot_class
      ]}>
      </span>
    </span>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="solid">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :class, :any, default: nil
  attr :color, :string, values: @theme_colors, default: "default"
  attr :variant, :string, values: ~w(default solid light outline ghost link), default: "default"
  attr :size, :string, values: ~w(sm md lg), default: "md"
  attr :wide, :boolean, default: false
  attr :loading, :boolean, default: false
  attr :radius, :string, values: ~w(none xs sm md lg xl 2xl 3xl 4xl full), default: @button_radius
  attr :rest, :global, include: ~w(href navigate patch method disabled name value popovertarget)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    assigns = assign(assigns, :cx, Theming.button_cx(assigns))

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link
        class={[@class, @cx.root]}
        data-slot="button-root"
        data-color={@color}
        data-variant={@variant}
        data-size={@size}
        {@rest}
      >
        <span class={@cx.inner} data-slot="button-inner">
          {render_slot(@inner_block)}
        </span>
      </.link>
      """
    else
      ~H"""
      <button
        class={[@class, @cx.root]}
        data-slot="button-root"
        data-color={@color}
        data-variant={@variant}
        data-size={@size}
        {@rest}
      >
        <span class={@cx.inner} data-slot="button-inner">
          {render_slot(@inner_block)}
        </span>
      </button>
      """
    end
  end

  @doc false

  attr :class, :any, default: nil
  attr :color, :string, values: @theme_colors, default: "default"
  attr :variant, :string, values: ~w(default solid light outline ghost link), default: "default"
  attr :size, :string, values: ~w(sm md lg), default: "md"
  attr :loading, :boolean, default: false
  attr :radius, :string, values: ~w(none xs sm md lg xl 2xl 3xl 4xl full), default: @button_radius
  attr :rest, :global, include: ~w(href navigate patch method disabled)
  slot :inner_block, required: true

  def icon_button(assigns) do
    ~H"""
    <.button
      class={@class}
      variant={@variant}
      color={@color}
      size={@size}
      radius={@radius}
      loading={@loading}
      style="width: var(--button-height)"
      {@rest}
    >
      {render_slot(@inner_block)}
    </.button>
    """
  end

  @doc """
  Renders a keyboard key.
  """

  attr :class, :any, default: nil
  attr :text_class, :string, default: "text-sm text-content-20"
  attr :surface_class, :string, default: "bg-surface-30"
  attr :shadow_class, :string, default: "shadow-sm"
  attr :rest, :global
  slot :inner_block, required: true

  def kbd(assigns) do
    ~H"""
    <kbd
      class={[
        "flex h-5 min-w-5 items-center justify-center rounded-sm border border-surface-40",
        @surface_class,
        @shadow_class,
        @text_class,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </kbd>
    """
  end

  @doc """
  Renders a tabs component with a list of tabs and panels.
  """

  attr :id, :string, required: true
  attr :default, :string, default: nil, doc: "the default active tab name"

  attr :on_select, :string,
    default: nil,
    doc: "the client event to trigger on tab select"

  attr :grow, :boolean,
    default: false,
    doc: "Determines whether tabs should take all available space"

  attr :justify, :string,
    values: ~w(start center end),
    default: "start",
    doc: "Determines how tabs are justified"

  attr :rest, :global

  slot :tab do
    attr :name, :string
    attr :disabled, :boolean
    attr :class, :any
  end

  slot :panel do
    attr :name, :string
    attr :class, :any
  end

  def tabs(assigns) do
    ~H"""
    <div id={@id} {@rest} phx-hook="Tabs" data-value={@default} data-onselect={@on_select}>
      <nav
        class={[
          "relative flex flex-wrap items-center gap-4",
          "before:content-[''] before:absolute before:bottom-0 before:left-0 before:right-0 before:border-b before:border-surface-30",
          tabs_justify_class(@justify)
        ]}
        role="tablist"
        data-value={@default}
        aria-orientation="horizontal"
        aria-label="Tabs"
      >
        <button
          :for={tab <- @tab}
          type="button"
          id={"#{@id}-tab-#{tab[:name]}"}
          data-name={tab[:name]}
          disabled={tab[:disabled]}
          class={[
            "relative flex shrink-0 items-center justify-center gap-x-2 px-4 py-2 border-b-2 border-transparent whitespace-nowrap select-none cursor-pointer text-content-40 text-sm font-medium transition-colors",
            "[&>svg]:pointer-events-none *:data-[slot=icon]:pointer-events-none [&>svg]:shrink-0 *:data-[slot=icon]:shrink-0 [&>svg:not([class*='size-'])]:[1.25em] [&>[data-slot=icon]:not([class*='size-'])]:[1.25em]",
            "aria-[selected]:border-content aria-[selected]:text-zinc-800",
            "hover:not-aria-[selected]:text-content-10",
            @grow && "flex-1",
            tab[:class]
          ]}
          role="tab"
          aria-selected={tab[:name] == @default}
          aria-controls={"#{@id}-panel-#{tab[:name]}"}
          tabindex={if(tab[:name] == @default, do: "0", else: "-1")}
        >
          {render_slot(tab, tab[:name] == @default)}
        </button>
      </nav>

      <div
        :for={panel <- @panel}
        id={"#{@id}-panel-#{panel[:name]}"}
        role="tabpanel"
        aria-labelledby={panel[:name]}
        aria-hidden={panel[:name] != @default}
        hidden={panel[:name] != @default}
        class={panel[:class]}
      >
        {render_slot(panel)}
      </div>
    </div>
    """
  end

  defp tabs_justify_class("start"), do: "justify-start"
  defp tabs_justify_class("center"), do: "justify-center"
  defp tabs_justify_class("end"), do: "justify-end"

  @doc """
  Renders a segmented control component with a list of options.
  The segmented control is equivalent to a radio button group where
  all options are visible at once and mutually exclusive.
  """

  attr :value, :any, required: true, doc: "the current value of the segmented control"
  attr :on_change, :string, required: true, doc: "the event to trigger on value change"
  attr :aria_label, :string, required: true, doc: "the aria-label for the segmented control"
  attr :orientation, :atom, values: ~w(horizontal vertical class)a, default: :horizontal

  attr :scrollable, :boolean,
    default: false,
    doc:
      "whether the segmented control is scrollable when overflowing and orientation is horizontal"

  attr :root_tag, :string, default: "div"

  attr :show_backdrop, :boolean, default: false
  attr :size, :string, values: ~w(sm md), default: "md"
  attr :class, :string, default: nil

  attr :backdrop_class, :string,
    default: "p-1 bg-surface-20 border border-surface-30 rounded-full"

  attr :items_gap_class, :string,
    default: "gap-3",
    doc: "the gap class to apply between items"

  attr :orientation_class, :string,
    default: "flex-row",
    doc: "the flex direction class to apply when orientation is :class"

  attr :rest, :global

  slot :item do
    attr :value, :any, required: true
    attr :id, :string
    attr :icon, :string
    attr :class, :any
    attr :icon_base_class, :string
    attr :icon_color_class, :string
    attr :disabled, :boolean
  end

  def segmented_control(assigns) do
    assigns =
      assigns
      |> assign(
        :orientation_class,
        case assigns.orientation do
          :horizontal -> "flex-row"
          :vertical -> "flex-col"
          :class -> assigns.orientation_class
        end
      )
      |> assign(
        :scrollable_class,
        "max-w-(--content-width) pb-2 overflow-x-auto scrollbar-thin snap-x snap-mandatory scroll-px-4"
      )

    ~H"""
    <.dynamic_tag tag_name={@root_tag} class={@class}>
      <ul
        {@rest}
        aria-label={@aria_label}
        class={[
          "p-1 w-full inline-flex",
          @items_gap_class,
          @orientation_class,
          @scrollable && @scrollable_class,
          @show_backdrop && @backdrop_class
        ]}
      >
        <li :for={item <- @item} id={item[:id]}>
          <button
            type="button"
            disabled={item[:disabled]}
            aria-current={item[:value] == @value}
            phx-click={JS.push(@on_change, value: %{value: item[:value]})}
            class={[
              item[:class],
              "group relative w-full h-10 px-4 inline-flex flex-nowrap shrink-0 items-center justify-center",
              "text-sm rounded-full corner-squircle overflow-hidden whitespace-nowrap cursor-pointer align-middle text-center",
              "text-content-40 border border-surface-30/50 bg-surface-20/50 transition-colors duration-150 backdrop-blur-sm",
              "hover:not-aria-current:bg-surface-10/25 hover:not-aria-current:text-content-10  hover:not-aria-current:border-surface-40",
              "aria-current:text-content aria-current:bg-surface-10 aria-current:border-primary aria-current:shadow-sm active:shadow-none",
              "focus-visible:outline-1 focus-visible:outline-offset-2 focus-visible:outline-dashed focus-visible:outline-primary"
            ]}
          >
            <%= if item[:icon] do %>
              <div class="flex items-center gap-2">
                <.icon
                  name={item[:icon]}
                  class={[
                    Map.get(item, :icon_base_class, "size-5"),
                    "group-aria-[current]:text-primary"
                  ]}
                />

                {render_slot(item, item[:value] == @value)}
              </div>
            <% else %>
              {render_slot(item, item[:value] == @value)}
            <% end %>
          </button>
        </li>
      </ul>
    </.dynamic_tag>
    """
  end

  @doc """
  Renders a timeline component.
  Timelines are used to display a list of events in chronological order.
  """

  attr :node_size, :integer, default: 24, doc: "the size of the timeline nodes in px"

  attr :node_radius, :string,
    values: ~w(xs sm md lg xl full),
    default: "full",
    doc: "the border radius of the timeline nodes"

  attr :line_width, :integer, default: 2, doc: "the width of the timeline line in px"

  attr :align, :string,
    values: ~w(left right),
    default: "left",
    doc: "the alignment of the timeline relative to content"

  attr :rest, :global
  slot :inner_block, required: true

  def timeline(assigns) do
    ~H"""
    <div
      {@rest}
      class="flow-root"
      style={"--tl-node-size: #{@node_size}px; --tl-line-width: #{@line_width}px;
        --tl-node-radius: #{Theming.radius_var(@node_radius)}; --tl-align: #{@align};
        --tl-offset: calc(var(--tl-node-size) / 2 + var(--tl-line-width) / 2);
        --tl-border-width: #{@line_width}px;"}
    >
      <ul
        role="list"
        data-align={@align}
        class={[
          "data-[align=left]:[--tl-ps:var(--tl-offset)]",
          "data-[align=right]:[--tl-pe:var(--tl-offset)]",
          "data-[align=left]:ps-(--tl-offset)",
          "data-[align=right]:pe-(--tl-offset)",
          "data-[align=left]:[--tl-node-left:calc((var(--tl-node-size)/2+var(--tl-line-width)/2)*-1)]",
          "data-[align=left]:[--tl-node-right:auto]",
          "data-[align=right]:[--tl-node-right:calc((var(--tl-node-size)/2+var(--tl-line-width)/2)*-1)]",
          "data-[align=right]:[--tl-node-left:auto]",
          "data-[align=left]:[--tl-line-left:calc(var(--tl-line-width)*-1)]",
          "data-[align=left]:[--tl-line-right:auto]",
          "data-[align=right]:[--tl-line-right:calc(var(--tl-line-width)*-1)]",
          "data-[align=right]:[--tl-line-left:auto]"
        ]}
      >
        {render_slot(@inner_block)}
      </ul>
    </div>
    """
  end

  @doc """
  Renders a timeline item component.
  Timeline items are used to display individual events within a timeline.
  """

  attr :active, :boolean, default: false
  attr :line, :string, values: ~w(dashed dotted solid), default: "solid"
  attr :show_backdrop, :boolean, default: true
  attr :show_border, :boolean, default: true
  attr :class, :string, default: nil
  attr :rest, :global

  slot :node do
    attr :class, :string
  end

  slot :title do
    attr :class, :string
  end

  slot :inner_block

  def timeline_item(assigns) do
    ~H"""
    <li
      data-active={@active}
      style={"--tl-border: var(--tl-border-width) #{@line} #{if(@active,
        do: "var(--color-primary)", else: "var(--color-surface-30)")};"}
      class={[
        "relative not-first:mt-8 ps-(--tl-ps) pe-(--tl-pe)",
        "before:content-[''] last:before:hidden before:absolute before:pointer-events-none",
        "before:[border-inline-start:var(--tl-border)]",
        "before:top-0 before:-bottom-8 before:left-(--tl-line-left)",
        @class
      ]}
      {@rest}
    >
      <div
        data-part="timeline-node"
        aria-hidden="true"
        style={"width: var(--tl-node-size); height: var(--tl-node-size); border-radius: var(--tl-node-radius);
          #{@show_border && "border-width: var(--tl-line-width);"}"}
        class={[
          "absolute left-(--tl-node-left) right-(--tl-node-right) top-0 flex items-center justify-center",
          @active && @show_backdrop && "bg-primary",
          @active && @show_border && "border-primary border-shade-primary/10",
          !@active && @show_backdrop && "bg-surface-20",
          !@active && @show_border && "border-surface-30"
        ]}
      >
        <div
          :for={node <- @node}
          class={["w-full h-full relative inline-flex items-center justify-center", node[:class]]}
        >
          {render_slot(node)}
        </div>
      </div>

      <div
        data-part="timeline-body"
        class="flex flex-col justify-center items-start ps-(--tl-ps) pe-(--tl-pe)"
      >
        <h3
          :for={title <- @title}
          class={Map.get(title, :class, "mt-0.5 text-base font-medium text-content-10")}
        >
          {render_slot(title)}
        </h3>

        <div class="text-sm text-content-40">
          {render_slot(@inner_block)}
        </div>
      </div>
    </li>
    """
  end

  @doc """
  Renders a spoiler component.
  The spoiler component allows you to hide long sections of text until the user clicks to reveal them.
  The cut-off point is determined by the `max_height` attribute.
  """

  attr :id, :string, required: true
  attr :max_height, :string, default: "8rem", doc: "the maximum height of the spoiler content"
  attr :open, :boolean, default: false, doc: "the initial state of the spoiler"
  attr :loading, :boolean, default: false

  attr :transition_duration, :integer,
    default: 300,
    doc: "the duration of the expand/collapse transition in milliseconds"

  attr :trigger_class, :string,
    default: "text-sm font-medium text-primary text-center hover:underline hover:cursor-pointer"

  attr :expand_label, :string,
    default: gettext("Show more"),
    doc: "the label for the expand button"

  attr :collapse_label, :string,
    default: gettext("Hide"),
    doc: "the label for the collapse button"

  attr :rest, :global

  slot :inner_block, required: true

  def spoiler(assigns) do
    ~H"""
    <div {@rest}>
      <div id={"spoiler-#{@id}"} data-open={@open} phx-hook="Spoiler">
        <div
          id={"spoiler-#{@id}-region"}
          style={"--spoiler-max-height: #{@max_height}; interpolate-size: allow-keywords;
            will-change: max-height; transition: max-height #{@transition_duration}ms ease-in-out;"}
          class={[
            "relative flex flex-col overflow-hidden",
            "max-h-(--spoiler-max-height) aria-expanded:max-h-min",
            @open && "max-h-min"
          ]}
          aria-expanded={@open}
          data-part="spoiler-content"
          role="region"
        >
          <div
            class={[
              "absolute bottom-0 left-0 right-0 h-7 z-1 bg-surface/85 mask-t-from-50% transition-opacity duration-150",
              @open && "opacity-0"
            ]}
            data-part="spoiler-overlay"
          >
          </div>
          {render_slot(@inner_block)}
        </div>

        <button
          type="button"
          class={[
            "group mt-2 text-sm font-medium text-primary",
            "hover:underline hover:cursor-pointer",
            "disabled:opacity-50 disabled:text-content-10/50 disabled:cursor-not-allowed"
          ]}
          aria-expanded={@open}
          aria-controls={"spoiler-#{@id}-region"}
          data-part="spoiler-trigger"
          disabled={@loading}
        >
          <span class="group-aria-expanded:hidden">
            {@expand_label}
          </span>
          <span class="hidden group-aria-expanded:inline-block">
            {@collapse_label}
          </span>
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders an icon.

  Supports three icon libraries:
  - [Heroicons](https://heroicons.com) - prefixed with "hero-"
  - [Lucide](https://lucide.dev) - prefixed with "lucide-"
  - [Simple Icons](https://simpleicons.org) - prefixed with "si-"

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from their respective directories and bundled within
  your compiled app.css by the plugins in `assets/vendor/`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      <.icon name="lucide-github" />
      <.icon name="si-github" class="size-6" />
      <.icon name="si-elixir" class="size-5 text-purple-600" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-5"
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} data-slot="icon" {@rest} />
    """
  end

  def icon(%{name: "lucide-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} data-slot="icon" {@rest} />
    """
  end

  def icon(%{name: "si-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} data-slot="icon" {@rest} />
    """
  end

  @doc false

  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :width, :integer, required: true
  attr :height, :integer, required: true
  # attr :use_loader, :boolean, default: true
  attr :use_blur, :boolean,
    default: false,
    doc: "whether to use a blurred placeholder if available"

  attr :use_picture, :boolean, default: false

  attr :srcset, :string,
    default: nil,
    doc: "the srcset attribute for the <source> tag
      if :use_picture is true and no :source slots are provided"

  attr :source_ext, :list,
    default: ~w(webp),
    doc: "list of source extensions for the <picture> tag
      if :use_picture is true and no :source slots are provided"

  attr :sizes, :string, default: nil, doc: "list of sizes for the <source> tag
    if :use_picture is true and no :source slots are provided"

  attr :id, :string
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(loading)

  slot :source do
    attr :type, :string
    attr :srcset, :string
    attr :sizes, :string
  end

  def image(%{src: src} = assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> Helpers.use_id() end)
      |> assign_new(:blur_path, fn
        %{use_blur: true} -> Site.Media.image_blur_exists?(src) && Site.Media.image_blur_path(src)
        _ -> nil
      end)

    ~H"""
    <%= if @use_picture && @source != [] do %>
      <%= for source <- @source do %>
        <source type={source.type} srcset={source.srcset} sizes={source.sizes} />
      <% end %>
    <% else %>
      <%= if @use_picture && @source_ext != [] do %>
        <%= for ext <- @source_ext do %>
          <source type={"image/#{ext}"} srcset={picture_srcset(@srcset, @src, ext)} sizes={@sizes} />
        <% end %>
      <% end %>
    <% end %>

    <img
      src={@src}
      width={@width}
      height={@height}
      alt={@alt}
      id={@id}
      class={["image", @class]}
      phx-hook="Image"
      data-src-blur={@blur_path}
      style="font-size: 0;"
      {@rest}
    />
    """
  end

  # Replace the file extension in the srcset attribute
  defp picture_srcset(nil, src, ext) do
    String.replace(src, ~r/\.(jpg|jpeg|png|gif)$/, ".#{ext}")
  end

  defp picture_srcset(srcset, _src, _ext), do: srcset

  @doc """
  Renders a date/datetime as a formatted string.
  """

  attr :date, :string, required: true
  attr :format, :string, default: "%B %o, %Y"
  attr :class, :any, default: nil

  def date(assigns) do
    assigns =
      assigns
      |> assign(
        :formatted_date,
        Support.format_date_with_ordinal(assigns.date, assigns.format)
      )

    ~H"""
    <time datetime={@date} class={@class}>{@formatted_date}</time>
    """
  end

  @doc """
  Renders a date as a relative time string.
  """

  attr :date, :string, required: true
  attr :cutoff_in_days, :integer, default: nil
  attr :short, :boolean, default: false
  attr :format, :string, default: "%B %o, %Y"
  attr :class, :any, default: nil

  def relative_time(assigns) do
    %{date: date, cutoff_in_days: cutoff, short: short, format: format} = assigns

    assigns =
      assign(
        assigns,
        :date,
        case Support.time_ago(date, cutoff_in_days: cutoff, short: short) do
          %NaiveDateTime{} = datetime -> Support.format_date_with_ordinal(datetime, format)
          relative_date -> relative_date
        end
      )

    ~H"""
    <time datetime={@date} class={@class}>{@date}</time>
    """
  end

  @doc """
  Renders a barebones dialog using the native HTML <dialog> element.
  """

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :close_on_click_outside, :boolean, default: true
  attr :on_cancel, JS, default: %JS{}
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dialog(assigns) do
    ~H"""
    <dialog
      id={@id}
      phx-hook="Dialog"
      phx-mounted={@show && show_dialog("##{@id}")}
      phx-remove={hide_dialog("##{@id}")}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      data-close-on-click-outside={@close_on_click_outside}
      class={[
        "starting:open:opacity-0 starting:open:backdrop:bg-transparent starting:open:backdrop:opacity-0",
        "border-none outline-none bg-transparent transition-discrete backdrop:transition-discrete",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block, JS.exec("data-cancel", to: "##{@id}"))}
    </dialog>
    """
  end

  @doc """
  Renders a tooltip component.

  The tooltip component displays a small popup with additional information when hovering over an element.
  Tooltip requires an HTML element or component as its child. The Anchor Positioning API is
  used to position the tooltip relative to the target element.

  The placement of the tooltip can set using the `position` attribute. If set to `auto`, the tooltip will
  automatically adjust its position to fit within the viewport.

  The appearance of the tooltip can be customized using the `bg_class`, `border_class`,
  `shadow_class` `radius_class` and `class` (content styling by default) attributes.
  If no content slot is provided, the `label` attribute will be used as the tooltip text.
  """

  attr :label, :string,
    default: nil,
    doc: "the text label for the tooltip, if not using the content slot"

  attr :position, :string, values: ["top", "bottom"], default: "top"
  attr :gap, :string, default: "1ch", doc: "the gap/offset (CSS unit) to the anchor element"

  attr :open_delay, :integer,
    default: 50,
    doc: "the delay in milliseconds before showing the tooltip"

  attr :close_delay, :integer,
    default: 0,
    doc: "the delay in milliseconds before hiding the tooltip"

  attr :show_arrow, :boolean,
    default: true,
    doc: "whether to show an arrow pointing to the anchor element"

  attr :multiline, :boolean,
    default: false,
    doc: "whether to allow multiline text in the tooltip"

  attr :max_width, :string,
    default: "auto",
    doc: "the maximum width of the tooltip content when using multiline"

  attr :bg_class, :string, default: "bg-neutral-800 dark:bg-neutral-950"
  attr :border_class, :string, default: "border-1 border-neutral-950 dark:border-neutral-800"
  attr :radius_class, :string, default: "rounded"
  attr :shadow_class, :string, default: "shadow-md"

  attr :class, :any, default: "px-3 py-1.5 text-neutral-300 text-sm"

  attr :rest, :global

  slot :inner_block, required: true

  slot :content do
    attr :class, :string
  end

  def tooltip(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> Helpers.use_id() end)
      |> assign(:area, tooltip_area(assigns[:position]))

    ~H"""
    <div
      id={@id}
      phx-hook="Tooltip"
      class="tooltip-container"
      style={"--tooltip-position: #{@position}; --tooltip-max-width: #{@max_width}; --tooltip-gap: #{@gap};"}
      data-open-delay={@open_delay}
      data-close-delay={@close_delay}
      {@rest}
    >
      <div
        id={"#{@id}-anchor"}
        class="tooltip-anchor"
        style={"anchor-name: --#{@id}-anchor;"}
      >
        {render_slot(@inner_block)}
      </div>

      <%!-- anchor-name: --#{@id}-tooltip; --%>
      <div
        id={"#{@id}-tooltip"}
        class={["tooltip", @bg_class, @border_class, @shadow_class, @radius_class, @class]}
        style={"position-anchor: --#{@id}-anchor;"}
        role="tooltip"
        popover="hint"
        data-popover={@id}
        data-tooltip-area={@area}
        data-multiline={@multiline}
        data-show-arrow={@show_arrow}
      >
        <%= if @content != [] do %>
          {render_slot(@content)}
        <% else %>
          {@label}
        <% end %>
      </div>
    </div>
    """
  end

  defp tooltip_area("top" <> _), do: "block"
  defp tooltip_area("bottom" <> _), do: "block"
  defp tooltip_area(_position), do: "inline"

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_dialog(js \\ %JS{}, selector) do
    JS.dispatch(js, "show-dialog", to: selector)
  end

  def hide_dialog(js \\ %JS{}, selector) do
    JS.dispatch(js, "hide-dialog", to: selector)
  end

  @doc """
  Render an svg diagonal pattern.
  """

  attr :class, :string, default: "border-1 border-surface-10 rounded-lg z-1"
  attr :use_transition, :boolean, default: true

  attr :hover_transition, :string,
    default:
      "group-hover/card:text-primary group-hover/card:opacity-40 transition-opacity duration-150"

  def diagonal_pattern(assigns) do
    assigns =
      assigns
      |> assign(:svg_id, SiteWeb.Helpers.use_id())

    ~H"""
    <div class={["absolute inset-0", @class]}>
      <svg class={[
        "absolute inset-0 size-full text-content-40/70 rounded-lg opacity-20 pointer-events-none select-none",
        "mask-[linear-gradient(to_left,#ffffffad,transparent)]",
        @use_transition && @hover_transition
      ]}>
        <defs>
          <pattern
            id={@svg_id}
            width="4"
            height="4"
            patternUnits="userSpaceOnUse"
            patternTransform="rotate(45)"
          >
            <line x1="0" y1="0" x2="0" y2="4" stroke="currentColor" stroke-width="1.5"></line>
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill={"url(##{@svg_id})"}></rect>
      </svg>
    </div>
    """
  end

  ## Helpers

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
      Gettext.dngettext(SiteWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(SiteWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
