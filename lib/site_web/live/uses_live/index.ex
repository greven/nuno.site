defmodule SiteWeb.UsesLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.LiveComponents
  alias SiteWeb.UsesLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-16">
        <.header tag="h1">
          Uses
          <:subtitle>Some of the things I use on a daily basis.</:subtitle>
        </.header>

        <section>
          <p class="prose">
            I spend most of my time on MacOS nowdays since it is my primary development environment using a
            <u class="emphasis">Macbook Pro</u>
            14&quot; M2 Max <span class="text-content-30">(2023)</span>. But I also have a small form factor
            <u class="emphasis">Desktop PC</u>
            that I use to run Linux (Arch, by the way!) and dual boot Microslop Windows 11 for gaming and other tasks.
          </p>
        </section>

        <Components.section>
          <:title>Code Editors</:title>

          <:subtitle>
            I switch between these regularly based on my mood, with <u class="emphasis">vim mode</u>
            on!
          </:subtitle>

          <div class="flex flex-col gap-8">
            <div class="flex gap-3 flex-wrap">
              <LiveComponents.live_preview id="zed-link" href="https://zed.dev" text="Zed" />
              <LiveComponents.live_preview
                id="vscode-link"
                href="https://code.visualstudio.com/"
                text="Visual Studio Code"
              />
            </div>

            <ul class="list">
              <li>
                <u class="emphasis">
                  Editor Font
                </u>
                is
                <.external_link href="https://github.com/zed-industries/zed-fonts/tree/main/zed-iosevka">
                  Zed Mono
                </.external_link>
              </li>

              <li>
                <u class="emphasis">Syntax Theme</u>
                is my own
                <.external_link href="https://vscodethemes.com/e/greven.umbra/umbra">
                  Umbra
                </.external_link>
              </li>
            </ul>
          </div>
        </Components.section>

        <Components.section>
          <:title>Applications</:title>

          <:subtitle>
            Some of my favourite applications (mostly MacOS but some cross-platform).
          </:subtitle>

          <div class="flex gap-3 flex-wrap">
            <LiveComponents.live_preview id="bearapp-link" href="https://bear.app" text="Bear Notes" />
            <LiveComponents.live_preview
              id="things-link"
              href="https://culturedcode.com/things/"
              text="Things 3"
            />
            <LiveComponents.live_preview
              id="cleanshot-link"
              href="https://getcleanshot.com/"
              text="CleanShot"
            />
            <LiveComponents.live_preview
              id="paste-link"
              href="https://pasteapp.io/"
              text="Paste"
            />
            <LiveComponents.live_preview
              id="reeder-link"
              href="https://reederapp.com/"
              text="Reeder"
            />
            <LiveComponents.live_preview
              id="eagle-link"
              href="https://eagle.cool/"
              text="Eagle"
            />
          </div>

          <ul class="list">
            <li>
              My MacOS <u class="emphasis">Window Manager</u>
              is
              <.external_link href="https://magnet.crowdcafe.com">
                Magnet
              </.external_link>
            </li>
            <li>
              My <u class="emphasis">Password Manager</u>
              is <.external_link href="https://1password.com/">1Password</.external_link>
            </li>
            <li>
              Big fan of the
              <.external_link href="https://www.affinity.studio/">Affinity</.external_link>
              suite for <u class="emphasis">design</u>
              and <u class="emphasis">photo editing</u>
            </li>
            <li>
              My <u class="emphasis">Browser</u>
              swings between <.external_link href="https://brave.com/">Brave</.external_link>
              and <.external_link href="https://www.mozilla.org/firefox/">Firefox</.external_link>
            </li>
            <li>
              The <u class="emphasis">terminals</u>
              I use are <.external_link href="https://iterm2.com/">iTerm2</.external_link>
              and <.external_link href="https://ghostty.org/">Ghostty</.external_link>
            </li>
          </ul>
        </Components.section>

        <Components.section>
          <:title>Hardware</:title>

          <:subtitle>
            A few of the physical things I use <s>daily</s> often.
          </:subtitle>

          <div class="flex flex-col gap-4">
            <Components.hardware_item icon="lucide-laptop">
              <:name>Macbook Pro 14&quot;</:name>
              <:description>Laptop</:description>
              <:spec label="CPU">M2 Max</:spec>
              <:spec label="RAM">32GB</:spec>
              <:spec label="GPU">38-Core</:spec>
              <:spec label="Storage">1TB SSD</:spec>
            </Components.hardware_item>

            <Components.hardware_item icon="hero-computer-desktop">
              <:name>Mainframe</:name>
              <:description>Desktop</:description>
              <:spec label="CPU">AMD 5600X</:spec>
              <:spec label="RAM">32GB</:spec>
              <:spec label="GPU">AMD RX 9700XT</:spec>
              <:spec label="Storage">2TB SSD</:spec>
              <:spec label="Monitor">MSI 321URX</:spec>
            </Components.hardware_item>

            <Components.hardware_item icon="hero-camera">
              <:name>Sony Alpha 6000</:name>
              <:description>Camera</:description>
              <:spec label="Lens">Sony Zeiss 24mm</:spec>
              <:spec label="Lens">Sony 50mm</:spec>
              <:spec label="Lens">Sony 16-50mm</:spec>
            </Components.hardware_item>
          </div>
        </Components.section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end
end
