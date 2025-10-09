defmodule SiteWeb.KitchenSinkLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.SiteComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="my-16 flex flex-col gap-16">
        <.header>
          Kitchen Sink
          <:subtitle>
            Collection of all the website components
          </:subtitle>

          <:actions>
            <Layouts.theme_toggle />
          </:actions>
        </.header>

        <%!--Colours --%>

        <div class="flex flex-col gap-6">
          <h2 class="flex items-center gap-1 text-2xl font-medium">
            <a name="colours" href="#colours" class="text-content-40 scroll-my-(--header-height)">#</a>Colours
          </h2>

          <div class="flex gap-8">
            <div>
              <h3 class="text-lg mb-2 text-content-20">Surface</h3>
              <div class="flex gap-8">
                <SiteComponents.color_swatch color="--color-surface" label="Base" />
                <SiteComponents.color_swatch color="--color-surface-10" label="10" />
                <SiteComponents.color_swatch color="--color-surface-20" label="20" />
                <SiteComponents.color_swatch color="--color-surface-30" label="30" />
                <SiteComponents.color_swatch color="--color-surface-40" label="40" />
              </div>
            </div>

            <div>
              <h3 class="text-lg mb-2 text-content-20">Content</h3>
              <div class="flex gap-8">
                <SiteComponents.color_swatch color="--color-content" label="Base" />
                <SiteComponents.color_swatch color="--color-content-10" label="10" />
                <SiteComponents.color_swatch color="--color-content-20" label="20" />
                <SiteComponents.color_swatch color="--color-content-30" label="30" />
                <SiteComponents.color_swatch color="--color-content-40" label="40" />
              </div>
            </div>
          </div>

          <div>
            <h3 class="text-lg mb-2 text-content-20">Neutral</h3>
            <div class="flex gap-8">
              <SiteComponents.color_swatch color="--color-neutral-50" label="50" />
              <SiteComponents.color_swatch color="--color-neutral-100" label="100" />
              <SiteComponents.color_swatch color="--color-neutral-200" label="200" />
              <SiteComponents.color_swatch color="--color-neutral-300" label="300" />
              <SiteComponents.color_swatch color="--color-neutral-400" label="400" />
              <SiteComponents.color_swatch color="--color-neutral-500" label="500" />
              <SiteComponents.color_swatch color="--color-neutral-600" label="600" />
              <SiteComponents.color_swatch color="--color-neutral-700" label="700" />
              <SiteComponents.color_swatch color="--color-neutral-800" label="800" />
              <SiteComponents.color_swatch color="--color-neutral-900" label="900" />
              <SiteComponents.color_swatch color="--color-neutral-950" label="950" />
            </div>
          </div>

          <div class="flex gap-8">
            <div>
              <h3 class="text-lg mb-2 text-content-20">Primary</h3>
              <div class="flex gap-8">
                <SiteComponents.color_swatch color="--color-primary" label="Default" />
                <SiteComponents.color_swatch color="--color-primary-contrast" label="Contrast" />
              </div>
            </div>

            <div>
              <h3 class="text-lg mb-2 text-content-20">Secondary</h3>
              <div class="flex gap-8">
                <SiteComponents.color_swatch color="--color-secondary" label="Default" />
                <SiteComponents.color_swatch color="--color-secondary-contrast" label="Contrast" />
              </div>
            </div>
          </div>

          <div class="flex gap-8">
            <div>
              <h3 class="text-lg mb-2 text-content-20">Info</h3>
              <div class="flex gap-8">
                <SiteComponents.color_swatch color="--color-info" label="Default" />
                <SiteComponents.color_swatch color="--color-info-contrast" label="Contrast" />
              </div>
            </div>

            <div>
              <h3 class="text-lg mb-2 text-content-20">Success</h3>
              <div class="flex gap-8">
                <SiteComponents.color_swatch color="--color-success" label="Default" />
                <SiteComponents.color_swatch color="--color-success-contrast" label="Contrast" />
              </div>
            </div>

            <div>
              <h3 class="text-lg mb-2 text-content-20">Warning</h3>
              <div class="flex gap-8">
                <SiteComponents.color_swatch color="--color-warning" label="Default" />
                <SiteComponents.color_swatch color="--color-warning-contrast" label="Contrast" />
              </div>
            </div>

            <div>
              <h3 class="text-lg mb-2 text-content-20">Danger</h3>
              <div class="flex gap-8">
                <SiteComponents.color_swatch color="--color-danger" label="Default" />
                <SiteComponents.color_swatch color="--color-danger-contrast" label="Contrast" />
              </div>
            </div>
          </div>
        </div>

        <%!-- Buttons --%>
        <div class="flex flex-col gap-6">
          <h2 class="flex items-center gap-1 text-2xl font-medium ">
            <a name="buttons" href="#buttons" class="text-content-40 scroll-my-(--header-height)">#</a>Buttons
          </h2>

          <%!-- Default --%>
          <div>
            <h3 class="text-lg mb-2 text-content-20">Default</h3>
            <div class="flex flex-col gap-4 flex-wrap">
              <div class="flex gap-4 flex-wrap">
                <.button>Default</.button>
                <.button color="primary">Primary</.button>
                <.button color="secondary">Secondary</.button>
                <.button color="info">Info</.button>
                <.button color="success">Success</.button>
                <.button color="warning">Warning</.button>
                <.button color="danger">Danger</.button>
              </div>

              <div class="flex gap-4 flex-wrap">
                <.button disabled>Default</.button>
                <.button><.icon name="hero-briefcase" />With Icon</.button>
                <.button loading>Loading</.button>
              </div>
            </div>
          </div>

          <div>
            <h3 class="text-lg mb-2 text-content-20">Solid</h3>
            <div class="flex gap-4 flex-wrap">
              <.button variant="solid">Default</.button>
              <.button variant="solid" color="primary">Primary</.button>
              <.button variant="solid" color="secondary">Secondary</.button>
              <.button variant="solid" color="info">Info</.button>
              <.button variant="solid" color="success">Success</.button>
              <.button variant="solid" color="warning">Warning</.button>
              <.button variant="solid" color="danger">Danger</.button>
            </div>
          </div>

          <div>
            <h3 class="text-lg mb-2 text-content-20">Light</h3>
            <div class="flex gap-4 flex-wrap">
              <.button variant="light">Default</.button>
              <.button variant="light" color="primary">Primary</.button>
              <.button variant="light" color="secondary">Secondary</.button>
              <.button variant="light" color="info">Info</.button>
              <.button variant="light" color="success">Success</.button>
              <.button variant="light" color="warning">Warning</.button>
              <.button variant="light" color="danger">Danger</.button>
            </div>
          </div>

          <div>
            <h3 class="text-lg mb-2 text-content-20">Outline</h3>
            <div class="flex gap-4 flex-wrap">
              <.button variant="outline">Default</.button>
              <.button variant="outline" color="primary">Primary</.button>
              <.button variant="outline" color="secondary">Secondary</.button>
              <.button variant="outline" color="info">Info</.button>
              <.button variant="outline" color="success">Success</.button>
              <.button variant="outline" color="warning">Warning</.button>
              <.button variant="outline" color="danger">Danger</.button>
            </div>
          </div>

          <div>
            <h3 class="text-lg mb-2 text-content-20">Ghost</h3>
            <div class="flex gap-4 flex-wrap">
              <.button variant="ghost">Default</.button>
              <.button variant="ghost" color="primary">Primary</.button>
              <.button variant="ghost" color="secondary">Secondary</.button>
              <.button variant="ghost" color="info">Info</.button>
              <.button variant="ghost" color="success">Success</.button>
              <.button variant="ghost" color="warning">Warning</.button>
              <.button variant="ghost" color="danger">Danger</.button>
            </div>
          </div>

          <div>
            <h3 class="text-lg mb-2 text-content-20">Link</h3>
            <div class="flex gap-4 flex-wrap">
              <.button variant="link">Default</.button>
              <.button variant="link" color="primary">Primary</.button>
              <.button variant="link" color="secondary">Secondary</.button>
              <.button variant="link" color="info">Info</.button>
              <.button variant="link" color="success">Success</.button>
              <.button variant="link" color="warning">Warning</.button>
              <.button variant="link" color="danger">Danger</.button>
            </div>
          </div>
        </div>

        <%!-- Avatar --%>
        <div class="flex flex-col gap-6">
          <h2 class="flex items-center gap-1 text-2xl font-medium ">
            <a name="avatar" href="#avatar" class="text-content-40 scroll-my-(--header-height)">#</a>Avatars
          </h2>

          <div class="flex gap-8">
            <SiteComponents.avatar_picture />
          </div>
        </div>

        <%!-- Badges --%>
        <div class="flex flex-col gap-6">
          <h2 class="flex items-center gap-1 text-2xl font-medium ">
            <a name="badges" href="#badges" class="text-content-40 scroll-my-(--header-height)">#</a>Badges
          </h2>

          <div>
            <h3 class="text-lg mb-2 text-content-20">Default</h3>
            <div class="max-w-[564px] flex flex-wrap gap-2">
              <.badge>Badge</.badge>
              <.badge color="red">Red</.badge>
              <.badge color="orange">Orange</.badge>
              <.badge color="amber">Amber</.badge>
              <.badge color="yellow">Yellow</.badge>
              <.badge color="lime">Lime</.badge>
              <.badge color="green">Green</.badge>
              <.badge color="emerald">Emerald</.badge>
              <.badge color="teal">Teal</.badge>
              <.badge color="cyan">Cyan</.badge>
              <.badge color="sky">Sky</.badge>
              <.badge color="blue">Blue</.badge>
              <.badge color="indigo">Indigo</.badge>
              <.badge color="violet">Violet</.badge>
              <.badge color="purple">Purple</.badge>
              <.badge color="pink">Pink</.badge>
              <.badge color="rose">Rose</.badge>
              <.badge color="neutral">Neutral</.badge>
            </div>
          </div>

          <div>
            <h3 class="text-lg mb-2 text-content-20">Dot</h3>
            <div class="max-w-[564px] flex flex-wrap gap-2">
              <.badge variant="dot">Badge</.badge>
              <.badge variant="dot" color="red">Red</.badge>
              <.badge variant="dot" color="orange">Orange</.badge>
              <.badge variant="dot" color="amber">Amber</.badge>
              <.badge variant="dot" color="yellow">Yellow</.badge>
              <.badge variant="dot" color="lime">Lime</.badge>
              <.badge variant="dot" color="green">Green</.badge>
              <.badge variant="dot" color="emerald">Emerald</.badge>
              <.badge variant="dot" color="teal">Teal</.badge>
              <.badge variant="dot" color="cyan">Cyan</.badge>
              <.badge variant="dot" color="sky">Sky</.badge>
              <.badge variant="dot" color="blue">Blue</.badge>
              <.badge variant="dot" color="indigo">Indigo</.badge>
              <.badge variant="dot" color="violet">Violet</.badge>
              <.badge variant="dot" color="purple">Purple</.badge>
              <.badge variant="dot" color="pink">Pink</.badge>
              <.badge variant="dot" color="rose">Rose</.badge>
              <.badge variant="dot" color="neutral">Neutral</.badge>
            </div>
          </div>
        </div>

        <%!-- Dividers --%>
        <div class="flex flex-col gap-6">
          <h2 class="flex items-center gap-1 text-2xl font-medium ">
            <a name="dividers" href="#dividers" class="text-content-40 scroll-my-(--header-height)">#</a>Dividers
          </h2>

          <.divider border_class="w-full border-t border-dashed border-surface-40" />

          <.divider>
            <span class="px-2 text-sm text-content-40">With Label</span>
          </.divider>

          <.divider>
            <.button size="sm">
              <.icon name="hero-plus" class="-ml-0.5 size-4.5 text-neutral-500" /> Button Text
            </.button>
          </.divider>

          <.divider>
            <button
              type="button"
              class="inline-flex items-center gap-x-1.5 rounded-full bg-white px-3 py-1.5 text-sm font-semibold text-neutral-900 shadow-xs ring-1 ring-neutral-300 ring-inset hover:bg-neutral-50"
            >
              <.icon name="hero-plus" class="-ml-1 size-4.5 text-neutral-500" /> Button text
            </button>
          </.divider>

          <.divider />
        </div>

        <%!-- Tooltips --%>
        <div class="flex flex-col gap-6">
          <h2 class="flex items-center gap-1 text-2xl font-medium ">
            <a name="tooltips" href="#tooltips" class="text-content-40 scroll-my-(--header-height)">#</a>Tooltips
          </h2>

          <div class="flex gap-4">
            <.tooltip label="This is a tooltip" position="top">
              <.button variant="solid">Hover for tooltip</.button>
            </.tooltip>

            <.tooltip label="Another tooltip" position="bottom">
              <.button variant="solid">Hover for tooltip</.button>
            </.tooltip>
          </div>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, page_title: "Kitchen Sink")
    {:ok, socket}
  end
end
