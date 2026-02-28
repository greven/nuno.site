%{
title: "Flag icons in Phoenix",
tags: ~w(dev elixir phoenix),
excerpt: "Easily add country flag icons to your phoenix app using a Tailwind plugin.",
category: :article,
status: :published,
featured: true,
}

---

<!-- lead -->

Easily add country flag icons to your phoenix app using a Tailwind plugin.

While I was writing this article I was thinking if I should write it at all. One thing that saddens me in the [Age of AI](https://nuno.site/blog/2026/ai-fatigue-in-the-age-of-agents) is
that tutorial like content was made kind of irrelevant. It is specially ironic since the LLMs were trained on them in the first place.

Anyway... In a world obsessed with adding yet another dependency, sometimes the cleanest solution is to **generate exactly what you need**.

## Libraries Galore

Libraries have taken over development for a while now. What I mean by this is that no development ecosystem can thrive if it doesn’t provide you with a vast
amount of library options. This is specially true in web development. Libraries provide “turn-key” solutions, they allow you to add features quickly to your application.
Nonetheless there is a price to be paid by using someone’s else’s library. After all you are trusting someone else, most of the times a network of people (or AI agents… 😒),
with your app security and long term maintainability. Delegation always has an associated cost. There are other issues with library obsession, but I will not be focusing on that.

This is why I find refreshing the approach of generating code. One of the most popular UI component libraries on React, [shadcn](https://ui.shadcn.com/), does it.
[Phoenix](https://www.phoenixframework.org/) in [Elixir](https://elixir-lang.org/) also does it, since Elixir has first class
[metaprogramming](https://elixirschool.com/en/lessons/advanced/metaprogramming/) support. Generating code isn’t without fault of course, after all
there are not silver bullets to anything (in coding and life). By using code generation you save time, take full ownership of it and
you can modify it to your heart’s desire.

So why not just add a flag icon library as a dependency? Because it is very easy to generate the exact code you need as we will see in the next section and you will own the solution.

This is what we want to achieve:

<div class="flex gap-6 flex-wrap">
  <!-- Simple -->
  <div class="flex gap-4">
    <SiteWeb.CoreComponents.flag_icon name="flag-eu" class="w-24" />
    <div class="flex flex-col gap-1 text-sm">
      <div><span class="font-headings font-medium">Overlay:</span> <span class="text-content-20">none</span></div>
      <div><span class="font-headings font-medium">Border:</span> <span class="text-content-20">no</span></div>
      <div><span class="font-headings font-medium">Shadow:</span> <span class="text-content-20">no</span></div>
    </div>
  </div>

  <!-- Linear with Border and Shadow -->
 <div class="flex gap-4">
    <SiteWeb.CoreComponents.flag_icon name="flag-eu" class="w-24" overlay="linear" border shadow />
    <div class="flex flex-col gap-1 text-sm">
      <div><span class="font-headings font-medium">Overlay:</span> <span class="text-content-20">linear</span></div>
      <div><span class="font-headings font-medium">Border:</span> <span class="text-content-20">yes</span></div>
      <div><span class="font-headings font-medium">Shadow:</span> <span class="text-content-20">yes</span></div>
    </div>
  </div>

  <!-- Wave with Border and Shadow -->
  <div class="flex gap-4">
    <SiteWeb.CoreComponents.flag_icon name="flag-eu" class="w-24" overlay="wave" border shadow />
    <div class="flex flex-col gap-1 text-sm">
      <div><span class="font-headings font-medium">Overlay:</span> <span class="text-content-20">wave</span></div>
      <div><span class="font-headings font-medium">Border:</span> <span class="text-content-20">yes</span></div>
      <div><span class="font-headings font-medium">Shadow:</span> <span class="text-content-20">yes</span></div>
    </div>
  </div>
</div>

More Varations:

<div class="flex gap-4 flex-wrap">
  <SiteWeb.CoreComponents.flag_icon name="flag-ar" class="w-24" overlay="wave" border shadow />
  <SiteWeb.CoreComponents.flag_icon name="flag-gb" class="w-24" overlay="linear" border shadow />
  <SiteWeb.CoreComponents.flag_icon name="flag-ch" class="w-24" label="Switzerland" shadow />
  <SiteWeb.CoreComponents.flag_icon name="flag-ca" class="w-24" overlay="wave" radius="rounded-lg" shadow />
  <SiteWeb.CoreComponents.flag_icon name="flag-jp" class="w-24" overlay="linear" radius="rounded-lg" border />
  <SiteWeb.CoreComponents.flag_icon name="flag-es" class="w-24" overlay="wave" radius="rounded" border />
</div>

<div class="mt-8 flex gap-4 flex-wrap">
  <SiteWeb.CoreComponents.flag_icon name="flag-br-square" class="w-16" overlay="wave" radius="rounded-full" border />
  <SiteWeb.CoreComponents.flag_icon name="flag-fr-square" class="w-16" overlay="wave" radius="rounded-full" border />
  <SiteWeb.CoreComponents.flag_icon name="flag-so-square" class="w-16" overlay="wave" radius="rounded-full" border />
  <SiteWeb.CoreComponents.flag_icon name="flag-bt-square" class="w-16" overlay="wave" radius="rounded-full" border />
  <SiteWeb.CoreComponents.flag_icon name="flag-mz-square" class="w-16" overlay="wave" radius="rounded-full" border />
  <SiteWeb.CoreComponents.flag_icon name="flag-vn-square" class="w-16" overlay="wave" radius="rounded-full" border />
  <SiteWeb.CoreComponents.flag_icon name="flag-za-square" class="w-16" overlay="wave" radius="rounded-full" border />
  <SiteWeb.CoreComponents.flag_icon name="flag-it-square" class="w-16" overlay="wave" radius="rounded-full" border />
</div>

## The Recipe

The Phoenix generators already bring with it an icon library, [heroicons](https://heroicons.com/).
I have [previously written about how easy is to extend this idea](https://bsky.app/profile/nuno.site/post/3lmm7momvrk27) to other icon sets. For our flag icon
set we are using [Lipis Flag Icons](https://github.com/lipis/flag-icons) but any SVG icon set with properly named files should work fine (by properly named I mean using country ISO codes).

[Mix](https://hexdocs.pm/elixir/introduction-to-mix.html) has the ability to add local packages [as well as from other sources](https://hexdocs.pm/mix/Mix.Tasks.Deps.html#module-git-options-git), such as Git/GitHub by adding it as as dependency in `mix.exs`.

```elixir
# mix.exs

defp deps do
	[ {:heroicons, github: "tailwindlabs/heroicons", tag: "v2.2.0",
     sparse: "optimized", app: false, compile: false, depth: 1}
	]
end
```

This will download the `heroicons` from the Github repo and add it to our dependency folder. Note the `:sparse`option that allow us to checkout a single directory inside the Git repository.

With the icon SVGs downloaded to our `deps` folder we now need a way to use them, this is where the [Tailwind CSS plugins](https://v3.tailwindcss.com/docs/plugins) enters the picture.
For this post I am considering the use of Tailwind CSS since it is now the default in Phoenix (and I don’t want discuss the merits or demerits of using Tailwind here).

<SiteWeb.BlogComponents.article_aside intent="info" title="Tailwind plugins in version 4">

Tailwind plugins are now considered by Tailwind a legacy system but are still supported in Tailwind v4. This is because Tailwind moved to a CSS only configuration but still supports the “old” JavaScript file based system, including plugins.

I haven’t explored a “Tailwind v4 way of doing things” but I suppose it shouldn’t be much different. Instead of a JavaScript plugin using `matchComponents` we could write a script that generates a CSS file with the icon utilities, then import it in our `app.css`.

</SiteWeb.BlogComponents.article_aside>

The plugin file that we will import in our `app.css` is the following (adapted from the generated `heroicons.js`file in the `assets\vendor`):

```javascript
// assets/vendor/flag_icons.js

import plugin from "tailwindcss/plugin";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let iconsDir = path.join(__dirname, "../../deps/flag_icons/flags");
const svgCache = new Map();

let icons = [
  ["", "/4x3"],
  ["-square", "/1x1"],
];

let values = {};

icons.forEach(([suffix, dir]) => {
  fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
    let name = path.basename(file, ".svg") + suffix;
    values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
  });
});

export default plugin(function ({ matchComponents, theme }) {
  matchComponents(
    {
      flag: ({ name, fullPath }) => {
        if (!svgCache.has(fullPath)) {
          const content = encodeURIComponent(
            fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, ""),
          );

          svgCache.set(fullPath, content);
        }

        const content = svgCache.get(fullPath);

        let aspect = "4 / 3";
        let size = theme("spacing.6");
        if (name.endsWith("-square")) {
          aspect = "1";
        }

        return {
          [`--flag-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          "background-image": `var(--flag-${name})`,
          "background-repeat": "no-repeat",
          "background-size": "cover",
          "background-position": "center",
          "vertical-align": "middle",
          display: "inline-block",
          "aspect-ratio": aspect,
          width: size,
        };
      },
    },
    { values },
  );
});
```

I’m not going to go through the code (ask your friend LLM!) but we have two folders with two distinct icon formats, a squared `1x1` format and a `4x3`.
Just like the `heroicons` plugin, we are using `matchComponents` to generate a utility class for each icon. The utility class will have the name of the icon prefixed with `flag-`
and it will set the background image to the SVG content of the icon encoded as a data URI.

The last part of the recipe, just like the default `heroicons`is to be able to used them from the `<.icon>` HEEx component defined in our `core_components.ex` file.

```elixir
  attr :name, :string, required: true
  attr :class, :any, default: "size-5"
  attr :rest, :global

  @icon_prefixes ~w(hero- lucide- si- flag-)

  def icon(%{name: icon_name} = assigns) do
    if Enum.any?(@icon_prefixes, &String.starts_with?(icon_name, &1)) do
      ~H"""
      <span class={[@name, @class]} data-slot="icon" {@rest} />
      """
    else
      raise ArgumentError, "Invalid icon name: #{icon_name}."
    end
  end
```

The function clause relevant to us its the last one, but since I have extended the icon function to support more icons on this website, I will leave the whole thing here.

## Usage

With the plugin in place we can now use the flag icons in our codebase.
I also created a HEEx component to add specific features to the flag icons that makes use of the icon component above.

```elixir
attr :name, :string, required: true
attr :label, :string, default: nil
attr :radius, :string, default: "rounded-xs"
attr :overlay, :string, values: ~w(none linear wave), default: "none"
attr :border, :boolean, default: false
attr :shadow, :boolean, default: false
attr :class, :any, default: "w-6"
attr :rest, :global

def flag_icon(assigns) do
  assigns =
    assigns
    |> assign(:effects_cx, [
      "before:content-[''] before:absolute before:inset-0 before:rounded-[inherit]",
      case assigns.overlay do
        "linear" ->
          "before:bg-linear-to-t before:from-black/30 from-2% before:to-white/70 to-98%"

        "wave" ->
          "before:bg-[linear-gradient(45deg,rgba(0,0,0,.2),rgba(39,39,39,.22)11%,hsla(0,0%,100%,.3)27%,rgba(0,0,0,.24)41%,rgba(0,0,0,.55)52%,hsla(0,0%,100%,.26)63%,rgba(0,0,0,.27)74%,hsla(0,0%,100%,.3))]"

        _ ->
          nil
      end,
      assigns.radius,
      assigns.shadow && "shadow",
      assigns.border &&
        "before:border before:border-black/40 before:mix-blend-overlay"
    ])

  ~H"""
  <.icon
    name={@name}
    class={["relative", @effects_cx, @radius, @class]}
    aria-label={@label}
    role="img"
    {@rest}
  />
  """
end
```

To display the flag of the European Union with a linear overlay and a border we can do:

```elixir
<.flag_icon name="flag-pt" overlay="wave" class="w-24" radius="rounded-lg" border shadow />
```

Which will render the following flag icon:

<SiteWeb.CoreComponents.flag_icon name="flag-pt" overlay="wave" class="w-24" radius="rounded-lg" border shadow />

You know, I'm a bit of a vexillologist myself... 😏
