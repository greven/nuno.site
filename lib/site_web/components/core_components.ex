defmodule SiteWeb.CoreComponents do
  @moduledoc false

  use Phoenix.Component
  use Gettext, backend: SiteWeb.Gettext

  alias Phoenix.LiveView.JS
  alias SiteWeb.Theme

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
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark-solid" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a badge.
  Badges are small, compact labels that can be used to display
  contextual information, such as status or categories.
  """
  attr :variant, :string, values: ~w(default dot), default: "default"
  attr :color, :string, values: Theme.colors(:tailwind)
  attr :badge_class, :string, default: "text-sm"
  attr :rest, :global
  slot :inner_block, required: true

  def badge(assigns) do
    assigns =
      assigns
      |> assign(
        :base_class,
        "flex items-center ring-1 ring-inset whitespace-nowrap gap-x-1.5 px-2.5 py-0.5 [&>.icon]:size-[0.9375rem] rounded-[var(--badge-radius)]"
      )
      |> assign(:variant_class, badge_color_class(assigns[:variant], assigns[:color]))

    ~H"""
    <span {@rest} style="--badge-dot-color: var(--color-gray-400);">
      <span class={[@base_class, @variant_class, @badge_class]}>
        {render_slot(@inner_block)}
      </span>
    </span>
    """
  end

  @doc false

  attr :color, :string, values: Theme.colors(:tailwind)
  attr :class, :string, default: nil

  def dot(assigns) do
    assigns = assign(assigns, :dot_class, badge_dot_color(assigns[:color]))

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
  attr :color, :string, values: Theme.colors(:theme)
  attr :size, :string, values: ~w(sm md), default: "md"
  attr :variant, :string, values: ~w(default solid light ghost link), default: "default"
  attr :rest, :global, include: ~w(href navigate patch method disabled)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    assigns =
      assigns
      |> assign(:size_class, button_size_class(assigns[:size]))
      |> assign(:variant_class, button_variant_class(assigns[:variant]))
      |> assign(:color_class, button_color_class(assigns[:color]))

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={["btn", @size_class, @variant_class, @color_class, @class]} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={["btn", @size_class, @variant_class, @color_class, @class]} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders a segmented control component with a list of options.
  The segmented control is equivalent to a radio button group where
  all options are visible at once and mutually exclusive.
  """

  # TODO: Replace button with custom selected element (and fix the radius of the element) and the elemnt should "swipe" between changes

  attr :value, :any, required: true, doc: "the current value of the segmented control"
  attr :on_change, :string, required: true, doc: "the event to trigger on value change"
  attr :aria_label, :string, required: true, doc: "the aria-label for the segmented control"
  attr :balanced, :boolean, default: false, doc: "whether to set equal width for all items"
  attr :size, :string, values: ~w(sm md), default: "md"
  attr :class, :string, default: nil
  attr :rest, :global

  slot :item do
    attr :value, :any, required: true
    attr :disabled, :boolean
    attr :class, :any
    attr :icon, :string
    attr :icon_base_class, :string
    attr :icon_color_class, :string
  end

  def segmented_control(assigns) do
    assigns =
      assigns
      |> assign(
        :container_class,
        if(assigns.balanced,
          do: "inline-grid grid-cols-#{length(assigns.item)}",
          else: "w-full inline-flex"
        )
      )

    ~H"""
    <div class={@class}>
      <ul
        class={[
          "gap-2 p-1 bg-surface-20/20 rounded-box border border-surface-30",
          @container_class
        ]}
        aria-label={@aria_label}
        {@rest}
      >
        <li :for={item <- @item} class="w-full">
          <.button
            type="button"
            size={@size}
            class={["group w-full", item[:class]]}
            disabled={item[:disabled]}
            aria-current={item[:value] == @value}
            variant={if(item[:value] == @value, do: "default", else: "ghost")}
            phx-click={JS.push(@on_change, value: %{value: item[:value]})}
          >
            <%!-- "size-5 text-content-10/45 group-aria-[current]:text-primary group-hover:group-[:not(:disabled)]:group-[:not([aria-current])]:text-content-30" --%>

            <%= if item[:icon] do %>
              <div class="flex items-center gap-2">
                <.icon
                  name={item[:icon]}
                  class={[
                    Map.get(item, :icon_base_class, "size-5"),
                    Map.get(
                      item,
                      :icon_color_class,
                      "text-content-10/45 group-aria-[current]:text-primary group-hover:group-[:not(:disabled)]:group-[:not([aria-current])]:text-content-30"
                    )
                  ]}
                />

                {render_slot(item, item[:value] == @value)}
              </div>
            <% else %>
              {render_slot(item, item[:value] == @value)}
            <% end %>
          </.button>
        </li>
      </ul>
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
    <fieldset class="fieldset mb-2">
      <label>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <span class="fieldset-label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class="checkbox checkbox-sm"
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <label>
        <span :if={@label} class="fieldset-label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={["w-full select", @errors != [] && "select-error"]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <label>
        <span :if={@label} class="fieldset-label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={["w-full textarea", @errors != [] && "textarea-error"]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <label>
        <span :if={@label} class="fieldset-label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={["w-full input", @errors != [] && "input-error"]}
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
  attr :class, :string, default: nil
  attr :header_class, :string, default: nil
  attr :anchor, :string, default: nil
  attr :tag, :string, default: "h1"

  slot :inner_block, required: true

  slot :subtitle do
    attr :class, :string
  end

  slot :actions

  def header(assigns) do
    assigns =
      assigns
      |> assign(:default_header_class, ["font-medium", header_font_size(assigns.tag)])

    ~H"""
    <header class={[
      @actions != [] && "flex items-center justify-between gap-6",
      "pb-4",
      @class
    ]}>
      <div>
        <%!-- flex items-center gap-2.5  --%>
        <.dynamic_tag
          tag_name={@tag}
          class={[
            "text-content-10",
            if(@header_class, do: @header_class, else: @default_header_class)
          ]}
        >
          <%= if @anchor do %>
            <div class="relative group hidden sm:block">
              <a id={@anchor} class="header-link" href={"##{@anchor}"}>
                <%!-- {@tag} --%>
              </a>
              {render_slot(@inner_block)}
            </div>
          <% else %>
            {render_slot(@inner_block)}
          <% end %>
        </.dynamic_tag>

        <p
          :for={subtitle <- @subtitle}
          class={["text-content-40", header_subtitle_font_size(@tag), subtitle[:class]]}
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
  attr :bg_color, :string, default: "bg-surface-10"
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
  attr :class, :any, default: "size-4"
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  def icon(%{name: "lucide-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  def icon(%{name: "si-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  @doc false

  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :width, :integer, required: true
  attr :height, :integer, required: true
  attr :picture, :boolean, default: true
  attr :source_ext, :list, default: ~w(webp)
  attr :class, :any, default: nil
  attr :rest, :global

  def image(assigns) do
    ~H"""
    <%= if @picture do %>
      <picture>
        <%= for ext <- @source_ext do %>
          <source type={"image/#{ext}"} srcset={srcset(@src, ext)} />
        <% end %>
        <img class={@class} src={@src} width={@width} height={@height} alt={@alt} {@rest} />
      </picture>
    <% else %>
      <img class={@class} src={@src} width={@width} height={@height} alt={@alt} {@rest} />
    <% end %>
    """
  end

  # Replace the file extension in the srcset attribute
  defp srcset(src, ext) do
    String.replace(src, ~r/\.(jpg|jpeg|png|gif)$/, ".#{ext}")
  end

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

  ## Component Theming

  def badge_color_class("default", color) do
    case color do
      "red" ->
        "bg-red-100/50 ring-red-200/90 text-red-700 dark:bg-red-500/10 dark:text-red-400 dark:ring-red-400/20"

      "orange" ->
        "bg-orange-100/50 ring-orange-200/90 text-orange-700 dark:bg-orange-500/10 dark:text-orange-400 dark:ring-orange-400/20"

      "amber" ->
        "bg-amber-100/50 ring-amber-200/90 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400 dark:ring-amber-400/20"

      "yellow" ->
        "bg-yellow-100/50 ring-yellow-200/90 text-yellow-700 dark:bg-yellow-500/10 dark:text-yellow-400 dark:ring-yellow-400/20"

      "lime" ->
        "bg-lime-100/50 ring-lime-200/90 text-lime-700 dark:bg-lime-500/10 dark:text-lime-400 dark:ring-lime-400/20"

      "green" ->
        "bg-green-100/50 ring-green-200/90 text-green-700 dark:bg-green-500/10 dark:text-green-400 dark:ring-green-400/20"

      "emerald" ->
        "bg-emerald-100/50 ring-emerald-200/90 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 dark:ring-emerald-400/20"

      "teal" ->
        "bg-teal-100/50 ring-teal-200/90 text-teal-700 dark:bg-teal-500/10 dark:text-teal-400 dark:ring-teal-400/20"

      "cyan" ->
        "bg-cyan-100/50 ring-cyan-200/90 text-cyan-700 dark:bg-cyan-500/10 dark:text-cyan-400 dark:ring-cyan-400/20"

      "sky" ->
        "bg-sky-100/50 ring-sky-200/90 text-sky-700 dark:bg-sky-500/10 dark:text-sky-400 dark:ring-sky-400/20"

      "blue" ->
        "bg-blue-100/50 ring-blue-200/90 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400 dark:ring-blue-400/20"

      "indigo" ->
        "bg-indigo-100/50 ring-indigo-200/90 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-400 dark:ring-indigo-400/20"

      "violet" ->
        "bg-violet-100/50 ring-violet-200/90 text-violet-700 dark:bg-violet-500/10 dark:text-violet-400 dark:ring-violet-400/20"

      "purple" ->
        "bg-purple-100/50 ring-purple-200/90 text-purple-700 dark:bg-purple-500/10 dark:text-purple-400 dark:ring-purple-400/20"

      "fuchsia" ->
        "bg-fuchsia-100/50 ring-fuchsia-200/90 text-fuchsia-700 dark:bg-fuchsia-500/10 dark:text-fuchsia-400 dark:ring-fuchsia-400/20"

      "pink" ->
        "bg-pink-100/50 ring-pink-200/90 text-pink-700 dark:bg-pink-500/10 dark:text-pink-400 dark:ring-pink-400/20"

      "rose" ->
        "bg-rose-100/50 ring-rose-200/90 text-rose-700 dark:bg-rose-500/10 dark:text-rose-400 dark:ring-rose-400/20"

      "slate" ->
        "bg-slate-100/50 ring-slate-300/80 text-slate-700 dark:bg-slate-500/10 dark:text-slate-400 dark:ring-slate-400/20"

      "gray" ->
        "bg-gray-100/50 ring-gray-300/80 text-gray-700 dark:bg-gray-500/10 dark:text-gray-400 dark:ring-gray-400/20"

      "zinc" ->
        "bg-zinc-100/50 ring-zinc-300/80 text-zinc-700 dark:bg-zinc-500/10 dark:text-zinc-400 dark:ring-zinc-400/20"

      "neutral" ->
        "bg-neutral-100/50 ring-neutral-300/80 text-neutral-700 dark:bg-neutral-500/10 dark:text-neutral-400 dark:ring-neutral-400/20"

      "stone" ->
        "bg-stone-100/50 ring-stone-300/80 text-stone-700 dark:bg-stone-500/10 dark:text-stone-400 dark:ring-stone-400/20"

      _ ->
        "bg-gray-100/50 ring-gray-300/80 text-gray-700 dark:bg-gray-500/10 dark:text-gray-400 dark:ring-gray-400/20"
    end
  end

  def badge_color_class("dot", color) do
    base_class =
      "bg-surface-10 text-gray-700 ring-1 ring-inset ring-gray-300 dark:text-gray-400 dark:ring-gray-800 before:content=[''] before:size-1.5 before:rounded-full"

    [badge_dot_color(color), base_class]
  end

  defp badge_dot_color(color) do
    case color do
      "red" ->
        "before:bg-red-500 before:dark:bg-red-400"

      "orange" ->
        "before:bg-orange-500 before:dark:bg-orange-400"

      "amber" ->
        "before:bg-amber-500 before:dark:bg-amber-400"

      "yellow" ->
        "before:bg-yellow-500 before:dark:bg-yellow-400"

      "lime" ->
        "before:bg-lime-500 before:dark:bg-lime-400"

      "green" ->
        "before:bg-green-500 before:dark:bg-green-400"

      "emerald" ->
        "before:bg-emerald-500 before:dark:bg-emerald-400"

      "teal" ->
        "before:bg-teal-500 before:dark:bg-teal-400"

      "cyan" ->
        "before:bg-cyan-500 before:dark:bg-cyan-400"

      "sky" ->
        "before:bg-sky-500 before:dark:bg-sky-400"

      "blue" ->
        "before:bg-blue-500 before:dark:bg-blue-400"

      "indigo" ->
        "before:bg-indigo-500 before:dark:bg-indigo-400"

      "violet" ->
        "before:bg-violet-500 before:dark:bg-violet-400"

      "purple" ->
        "before:bg-purple-500 before:dark:bg-purple-400"

      "fuchsia" ->
        "before:bg-fuchsia-500 before:dark:bg-fuchsia-400"

      "pink" ->
        "before:bg-pink-500 before:dark:bg-pink-400"

      "rose" ->
        "before:bg-rose-500 before:dark:bg-rose-400"

      "slate" ->
        "before:bg-slate-500 before:dark:bg-slate-400"

      "gray" ->
        "before:bg-gray-500 before:dark:bg-gray-400"

      "zinc" ->
        "before:bg-zinc-500 before:dark:bg-zinc-400"

      "neutral" ->
        "before:bg-neutral-500 before:dark:bg-neutral-400"

      "stone" ->
        "before:bg-stone-500 before:dark:bg-stone-400"

      _ ->
        "before:bg-(--badge-dot-color)"
    end
  end

  def button_variant_class(variant) do
    %{
      "default" => "btn-default",
      "solid" => "btn-solid",
      "light" => "btn-light",
      "ghost" => "btn-ghost",
      "link" => "btn-link",
      nil => "btn-default"
    }
    |> Map.get(variant, "btn-default")
  end

  def button_color_class(color) do
    %{
      "primary" => "btn-primary",
      "secondary" => "btn-secondary",
      "accent" => "btn-accent",
      "info" => "btn-info",
      "success" => "btn-success",
      "warning" => "btn-warning",
      "danger" => "btn-danger",
      "neutral" => "btn-neutral"
    }
    |> Map.get(color, "btn-neutral")
  end

  def button_size_class(size) do
    case size do
      "sm" -> "btn-sm"
      "md" -> "btn-md"
      _ -> "btn-md"
    end
  end
end
