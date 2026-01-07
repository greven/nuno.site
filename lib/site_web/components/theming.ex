# credo:disable-for-this-file
defmodule SiteWeb.Components.Theming do
  @moduledoc """
  Shared theming-related helpers.
  """

  @doc """
  Generate classes for focus-visible outlines.
  """
  def focus_visible_outline_cx(color \\ :primary)

  def focus_visible_outline_cx(:primary) do
    [focus_visible_outline(), "focus-visible:outline-primary"]
  end

  def focus_visible_outline_cx(:secondary) do
    [focus_visible_outline(), "focus-visible:outline-secondary"]
  end

  defp focus_visible_outline do
    "focus-visible:outline-1 focus-visible:outline-offset-2 focus-visible:outline-dashed"
  end

  ## Buttons

  def button_cx(assigns) do
    %{color: color, variant: variant, size: size, radius: radius, wide: wide} = assigns

    size_cx = button_size_cx(size)
    variant_cx = button_variant_cx(color, variant)

    %{
      root: [
        "relative isolate outline-none overflow-hidden cursor-pointer transition-all",
        "disabled:opacity-50 disabled:shadow-none disabled:cursor-not-allowed",
        "aria-invalid:ring-danger aria-invalid:border-danger",
        "active:shadow-none",
        focus_visible_outline_cx(),
        "[&_svg]:pointer-events-none [&_[data-slot=icon]]:pointer-events-none [&_svg]:shrink-0 [&_[data-slot=icon]]:shrink-0 [&_svg:not([class*='size-'])]:size-5! [&_[data-slot=icon]:not([class*='size-'])]:size-5!",
        "[&:disabled_svg]:opacity-50 [&:disabled_[data-slot=icon]]:opacity-50",
        "[--button-shadow:var(--shadow-xs)]",
        if(wide, do: "block w-full", else: "inline-block"),
        radius_class(radius),
        size_cx.root,
        variant_cx
      ],
      inner: [
        "h-full flex justify-center items-center shrink-0 text-sm font-medium whitespace-nowrap align-middle text-center no-underline",
        size_cx.inner
      ]
    }
  end

  def button_size_cx(size) do
    case size do
      "sm" ->
        %{
          root: [
            "[--button-height:--spacing(9)] [--button-padding:--spacing(3)] [--button-gap:--spacing(2)] h-(--button-height)"
          ],
          inner:
            "gap-x-(--button-gap) px-(--button-padding) has-[>svg]:px-2.5 has-[>[data-slot=icon]]:px-2.5"
        }

      "md" ->
        %{
          root: [
            "[--button-height:--spacing(10)] [--button-padding:--spacing(4)] [--button-gap:--spacing(2)] h-(--button-height)"
          ],
          inner:
            "gap-x-(--button-gap) px-(--button-padding) has-[>svg]:px-3 has-[>[data-slot=icon]]:px-3"
        }

      "lg" ->
        %{
          root: [
            "[--button-height:--spacing(11)] [--button-padding:--spacing(6)] [--button-gap:--spacing(2)] h-(--button-height)"
          ],
          inner:
            "gap-x-(--button-gap) px-(--button-padding) has-[>svg]:px-4 has-[>[data-slot=icon]]:px-4"
        }
    end
  end

  def button_variant_cx("default", variant) do
    case variant do
      "default" ->
        "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-200 ring-1 ring-neutral-300 dark:ring-white/10 shadow-(--button-shadow) before:absolute before:inset-0 before:p-0 before:pb-[1px] before:bg-linear-to-t before:from-neutral-600/15 dark:before:from-white/8 before:to-transparent before:rounded-[calc(var(--border-radius)-0.075rem)] before:[mask:linear-gradient(#fff_0_0)_content-box_exclude,_linear-gradient(#fff_0_0)] before:-z-1 before:pointer-events-none active:before:opacity-0 not-active:not-disabled:hover:bg-neutral-600/8 aria-[pressed]:bg-neutral-600/8 dark:not-active:not-disabled:hover:bg-neutral-800/75 dark:aria-[pressed]:bg-neutral-800/75"

      "solid" ->
        "bg-neutral-900 dark:bg-neutral-300 text-neutral-50 dark:text-neutral-900 shadow-(--button-shadow) not-active:not-disabled:hover:bg-neutral-900/85 dark:not-active:not-disabled:hover:bg-neutral-300/85 aria-[pressed]:bg-neutral-900/85 dark:aria-[pressed]:bg-neutral-300/85"

      "light" ->
        "bg-neutral-600/8 dark:bg-neutral-600/15 text-neutral-900 dark:text-neutral-200 shadow-none not-active:not-disabled:hover:bg-neutral-600/15 not-active:not-disabled:dark:hover:bg-neutral-600/20 aria-[pressed]:bg-neutral-600/15"

      "outline" ->
        "bg-transparent text-neutral-900 dark:text-neutral-200 ring-1 ring-neutral-300 dark:ring-neutral-700 ring-inset shadow-(--button-shadow) not-active:not-disabled:hover:bg-neutral-600/8 aria-[pressed]:bg-neutral-600/8"

      "ghost" ->
        "bg-transparent text-neutral-900 dark:text-neutral-200 shadow-none not-active:not-disabled:hover:bg-neutral-600/15 aria-[pressed]:bg-neutral-600/15"

      "link" ->
        "bg-transparent text-content-10 shadow-none decoration-[1.5px] decoration-content-40/60 underline underline-offset-3 transition-colors hover:decoration-primary"
    end
  end

  def button_variant_cx("primary", variant) do
    case variant do
      "default" ->
        "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-200 ring-1 ring-neutral-300 dark:ring-white/10 shadow-(--button-shadow) before:absolute before:inset-0 before:p-0 before:pb-[1px] before:bg-linear-to-t before:from-neutral-600/15 dark:before:from-white/8 before:to-transparent before:rounded-[calc(var(--border-radius)-0.075rem)] before:[mask:linear-gradient(#fff_0_0)_content-box_exclude,_linear-gradient(#fff_0_0)] before:-z-1 before:pointer-events-none active:before:opacity-0 not-active:not-disabled:hover:bg-neutral-600/8 aria-[pressed]:bg-neutral-600/8 dark:not-active:not-disabled:hover:bg-neutral-800/75 dark:aria-[pressed]:bg-neutral-800/75"

      "solid" ->
        "bg-primary text-primary-contrast shadow-(--button-shadow) not-active:not-disabled:hover:bg-primary/85 aria-[pressed]:bg-primary/85"

      "light" ->
        "bg-primary/8 dark:bg-primary/15 text-primary dark:text-primary shadow-none not-active:not-disabled:hover:bg-primary/15 not-active:not-disabled:dark:hover:bg-primary/20 aria-[pressed]:bg-primary/15"

      "outline" ->
        "bg-transparent text-primary ring-1 ring-primary ring-inset shadow-(--button-shadow) not-active:not-disabled:hover:bg-primary/10 aria-[pressed]:bg-primary/10"

      "ghost" ->
        "bg-transparent text-primary shadow-none not-active:not-disabled:hover:bg-primary/15 aria-[pressed]:bg-primary/15"

      "link" ->
        "bg-transparent text-content-10 shadow-none decoration-[1.5px] decoration-primary underline underline-offset-3 transition-colors hover:decoration-content-40/60"
    end
  end

  def button_variant_cx("secondary", variant) do
    case variant do
      "default" ->
        "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-200 ring-1 ring-neutral-300 dark:ring-white/10 shadow-(--button-shadow) before:absolute before:inset-0 before:p-0 before:pb-[1px] before:bg-linear-to-t before:from-neutral-600/15 dark:before:from-white/8 before:to-transparent before:rounded-[calc(var(--border-radius)-0.075rem)] before:[mask:linear-gradient(#fff_0_0)_content-box_exclude,_linear-gradient(#fff_0_0)] before:-z-1 before:pointer-events-none active:before:opacity-0 not-active:not-disabled:hover:bg-neutral-600/8 aria-[pressed]:bg-neutral-600/8 dark:not-active:not-disabled:hover:bg-neutral-800/75 dark:aria-[pressed]:bg-neutral-800/75"

      "solid" ->
        "bg-secondary text-secondary-contrast shadow-(--button-shadow) not-active:not-disabled:hover:bg-secondary/85 aria-[pressed]:bg-secondary/85"

      "light" ->
        "bg-secondary/8 dark:bg-secondary/15 text-secondary dark:text-secondary shadow-none not-active:not-disabled:hover:bg-secondary/15 not-active:not-disabled:dark:hover:bg-secondary/20 aria-[pressed]:bg-secondary/15"

      "outline" ->
        "bg-transparent text-secondary ring-1 ring-secondary shadow-(--button-shadow) not-active:not-disabled:hover:bg-secondary/10 aria-[pressed]:bg-secondary/10"

      "ghost" ->
        "bg-transparent text-secondary shadow-none not-active:not-disabled:hover:bg-secondary/15 aria-[pressed]:bg-secondary/15"

      "link" ->
        "bg-transparent text-content-10 shadow-none decoration-[1.5px] decoration-secondary underline underline-offset-3 transition-colors hover:decoration-content-40/60"
    end
  end

  def button_variant_cx("info", variant) do
    case variant do
      "default" ->
        "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-200 ring-1 ring-neutral-300 dark:ring-white/10 shadow-(--button-shadow) before:absolute before:inset-0 before:p-0 before:pb-[1px] before:bg-linear-to-t before:from-neutral-600/15 dark:before:from-white/8 before:to-transparent before:rounded-[calc(var(--border-radius)-0.075rem)] before:[mask:linear-gradient(#fff_0_0)_content-box_exclude,_linear-gradient(#fff_0_0)] before:-z-1 before:pointer-events-none active:before:opacity-0 not-active:not-disabled:hover:bg-neutral-600/8 aria-[pressed]:bg-neutral-600/8 dark:not-active:not-disabled:hover:bg-neutral-800/75 dark:aria-[pressed]:bg-neutral-800/75"

      "solid" ->
        "bg-info text-info-contrast shadow-(--button-shadow) not-active:not-disabled:hover:bg-info/85 aria-[pressed]:bg-info/85"

      "light" ->
        "bg-info/8 dark:bg-info/15 text-info shadow-none not-active:not-disabled:hover:bg-info/15 not-active:not-disabled:dark:hover:bg-info/20 aria-[pressed]:bg-info/15"

      "outline" ->
        "bg-transparent text-info ring-1 ring-info shadow-(--button-shadow) not-active:not-disabled:hover:bg-info/10 aria-[pressed]:bg-info/10"

      "ghost" ->
        "bg-transparent text-info shadow-none not-active:not-disabled:hover:bg-info/15 aria-[pressed]:bg-info/15"

      "link" ->
        "bg-transparent text-content-10 shadow-none decoration-[1.5px] decoration-info underline underline-offset-3 transition-colors hover:decoration-content-40/60"
    end
  end

  def button_variant_cx("success", variant) do
    case variant do
      "default" ->
        "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-200 ring-1 ring-neutral-300 dark:ring-white/10 shadow-(--button-shadow) before:absolute before:inset-0 before:p-0 before:pb-[1px] before:bg-linear-to-t before:from-neutral-600/15 dark:before:from-white/8 before:to-transparent before:rounded-[calc(var(--border-radius)-0.075rem)] before:[mask:linear-gradient(#fff_0_0)_content-box_exclude,_linear-gradient(#fff_0_0)] before:-z-1 before:pointer-events-none active:before:opacity-0 not-active:not-disabled:hover:bg-neutral-600/8 aria-[pressed]:bg-neutral-600/8 dark:not-active:not-disabled:hover:bg-neutral-800/75 dark:aria-[pressed]:bg-neutral-800/75"

      "solid" ->
        "bg-success text-success-contrast shadow-(--button-shadow) not-active:not-disabled:hover:bg-success/85 aria-[pressed]:bg-success/85"

      "light" ->
        "bg-success/8 dark:bg/15 text-success shadow-none not-active:not-disabled:hover:bg-success/15 not-active:not-disabled:dark:hover:bg-success/20 aria-[pressed]:bg-success/15"

      "outline" ->
        "bg-transparent text-success ring-1 ring-success shadow-(--button-shadow) not-active:not-disabled:hover:bg-success/10 aria-[pressed]:bg-success/10"

      "ghost" ->
        "bg-transparent text-success shadow-none not-active:not-disabled:hover:bg-success/15 aria-[pressed]:bg-success/15"

      "link" ->
        "bg-transparent text-content-10 shadow-none decoration-[1.5px] decoration-secondary underline underline-offset-3 transition-colors hover:decoration-content-40/60"
    end
  end

  def button_variant_cx("warning", variant) do
    case variant do
      "default" ->
        "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-200 ring-1 ring-neutral-300 dark:ring-white/10 shadow-(--button-shadow) before:absolute before:inset-0 before:p-0 before:pb-[1px] before:bg-linear-to-t before:from-neutral-600/15 dark:before:from-white/8 before:to-transparent before:rounded-[calc(var(--border-radius)-0.075rem)] before:[mask:linear-gradient(#fff_0_0)_content-box_exclude,_linear-gradient(#fff_0_0)] before:-z-1 before:pointer-events-none active:before:opacity-0 not-active:not-disabled:hover:bg-neutral-600/8 aria-[pressed]:bg-neutral-600/8 dark:not-active:not-disabled:hover:bg-neutral-800/75 dark:aria-[pressed]:bg-neutral-800/75"

      "solid" ->
        "bg-warning text-warning-contrast border border-warning shadow-(--button-shadow) not-active:not-disabled:hover:bg-warning/85 aria-[pressed]:bg-warning/85"

      "light" ->
        "bg-warning/8 dark:bg-warning/15 text-warning border border-transparent shadow-none not-active:not-disabled:hover:bg-warning/15 not-active:not-disabled:dark:hover:bg-warning/20 aria-[pressed]:bg-warning/15"

      "outline" ->
        "bg-transparent text-warning border border-warning shadow-(--button-shadow) not-active:not-disabled:hover:bg-warning/10 aria-[pressed]:bg-warning/10"

      "ghost" ->
        "bg-transparent text-warning border border-transparent shadow-none not-active:not-disabled:hover:bg-warning/15 aria-[pressed]:bg-warning/15"

      "link" ->
        "bg-transparent text-content-10 shadow-none decoration-[1.5px] decoration-warning underline underline-offset-3 transition-colors hover:decoration-content-40/60"
    end
  end

  def button_variant_cx("danger", variant) do
    case variant do
      "default" ->
        "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-200 ring-1 ring-neutral-300 dark:ring-white/10 shadow-(--button-shadow) before:absolute before:inset-0 before:p-0 before:pb-[1px] before:bg-linear-to-t before:from-neutral-600/15 dark:before:from-white/8 before:to-transparent before:rounded-[calc(var(--border-radius)-0.075rem)] before:[mask:linear-gradient(#fff_0_0)_content-box_exclude,_linear-gradient(#fff_0_0)] before:-z-1 before:pointer-events-none active:before:opacity-0 not-active:not-disabled:hover:bg-neutral-600/8 aria-[pressed]:bg-neutral-600/8 dark:not-active:not-disabled:hover:bg-neutral-800/75 dark:aria-[pressed]:bg-neutral-800/75"

      "solid" ->
        "bg-danger text-danger-contrast shadow-(--button-shadow) not-active:not-disabled:hover:bg-danger/85 aria-[pressed]:bg-danger/85"

      "light" ->
        "bg-danger/8 dark:bg-danger/15 text-danger shadow-none not-active:not-disabled:hover:bg-danger/15 not-active:not-disabled:dark:hover:bg-danger/20 aria-[pressed]:bg-danger/15"

      "outline" ->
        "bg-transparent text-danger ring-1 ring-danger shadow-(--button-shadow) not-active:not-disabled:hover:bg-danger/10 aria-[pressed]:bg-danger/10"

      "ghost" ->
        "bg-transparent text-danger shadow-none not-active:not-disabled:hover:bg-danger/15 aria-[pressed]:bg-danger/15"

      "link" ->
        "bg-transparent text-content-10 shadow-none decoration-[1.5px] decoration-danger underline underline-offset-3 transition-colors hover:decoration-content-40/60"
    end
  end

  ## Badges

  def badge_cx(assigns) do
    [
      "flex justify-center items-center whitespace-nowrap [&>[data-slot=icon]]::size-[0.9375rem]",
      if(assigns.circle, do: "size-[1.725em] p-0 rounded-full", else: "gap-x-1.5 px-2.5 py-0.5"),
      assigns.variant == "default" && "ring-1 ring-inset",
      badge_color_class(assigns[:variant], assigns[:color])
    ]
  end

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
        "bg-surface-10 ring-surface-30 text-content-30 dark:text-content-20"
    end
  end

  def badge_color_class("solid", color) do
    case color do
      "red" ->
        "bg-red-100/50 text-red-700 dark:bg-red-500/10 dark:text-red-400"

      "orange" ->
        "bg-orange-100/50 text-orange-700 dark:bg-orange-500/10 dark:text-orange-400"

      "amber" ->
        "bg-amber-100/50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400"

      "yellow" ->
        "bg-yellow-100/50 text-yellow-700 dark:bg-yellow-500/10 dark:text-yellow-400"

      "lime" ->
        "bg-lime-100/50 text-lime-700 dark:bg-lime-500/10 dark:text-lime-400"

      "green" ->
        "bg-green-100/50 text-green-700 dark:bg-green-500/10 dark:text-green-400"

      "emerald" ->
        "bg-emerald-100/50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400"

      "teal" ->
        "bg-teal-100/50 text-teal-700 dark:bg-teal-500/10 dark:text-teal-400"

      "cyan" ->
        "bg-cyan-100/50 text-cyan-700 dark:bg-cyan-500/10 dark:text-cyan-400"

      "sky" ->
        "bg-sky-100/50 text-sky-700 dark:bg-sky-500/10 dark:text-sky-400"

      "blue" ->
        "bg-blue-100/50 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400"

      "indigo" ->
        "bg-indigo-100/50 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-400"

      "violet" ->
        "bg-violet-100/50 text-violet-700 dark:bg-violet-500/10 dark:text-violet-400"

      "purple" ->
        "bg-purple-100/50 text-purple-700 dark:bg-purple-500/10 dark:text-purple-400"

      "fuchsia" ->
        "bg-fuchsia-100/50 text-fuchsia-700 dark:bg-fuchsia-500/10 dark:text-fuchsia-400"

      "pink" ->
        "bg-pink-100/50 text-pink-700 dark:bg-pink-500/10 dark:text-pink-400"

      "rose" ->
        "bg-rose-100/50 text-rose-700 dark:bg-rose-500/10 dark:text-rose-400"

      "slate" ->
        "bg-slate-100/50 text-slate-700 dark:bg-slate-500/10 dark:text-slate-400"

      "gray" ->
        "bg-gray-100/50 text-gray-700 dark:bg-gray-500/10 dark:text-gray-400"

      "zinc" ->
        "bg-zinc-100/50 text-zinc-700 dark:bg-zinc-500/10 dark:text-zinc-400"

      "neutral" ->
        "bg-neutral-100/50 text-neutral-700 dark:bg-neutral-500/10 dark:text-neutral-400"

      "stone" ->
        "bg-stone-100/50 text-stone-700 dark:bg-stone-500/10 dark:text-stone-400"

      _ ->
        "bg-surface-10 text-content-30 dark:text-content-20"
    end
  end

  def badge_color_class("dot", color) do
    base_class =
      "bg-surface-10 ring-1 ring-inset ring-surface-30 text-content-30 dark:text-content-20
        before:content=[''] before:size-1.5 before:rounded-full transition"

    [badge_dot_color(color), base_class]
  end

  def badge_dot_color(color) do
    case color do
      "red" ->
        "before:bg-red-500 dark:before:bg-red-400"

      "orange" ->
        "before:bg-orange-500 dark:before:bg-orange-400"

      "amber" ->
        "before:bg-amber-500 dark:before:bg-amber-400"

      "yellow" ->
        "before:bg-yellow-500 dark:before:bg-yellow-400"

      "lime" ->
        "before:bg-lime-500 dark:before:bg-lime-400"

      "green" ->
        "before:bg-green-500 dark:before:bg-green-400"

      "emerald" ->
        "before:bg-emerald-500 dark:before:bg-emerald-400"

      "teal" ->
        "before:bg-teal-500 dark:before:bg-teal-400"

      "cyan" ->
        "before:bg-cyan-500 dark:before:bg-cyan-400"

      "sky" ->
        "before:bg-sky-500 dark:before:bg-sky-400"

      "blue" ->
        "before:bg-blue-500 dark:before:bg-blue-400"

      "indigo" ->
        "before:bg-indigo-500 dark:before:bg-indigo-400"

      "violet" ->
        "before:bg-violet-500 dark:before:bg-violet-400"

      "purple" ->
        "before:bg-purple-500 dark:before:bg-purple-400"

      "fuchsia" ->
        "before:bg-fuchsia-500 dark:before:bg-fuchsia-400"

      "pink" ->
        "before:bg-pink-500 dark:before:bg-pink-400"

      "rose" ->
        "before:bg-rose-500 dark:before:bg-rose-400"

      "slate" ->
        "before:bg-slate-500 dark:before:bg-slate-400"

      "gray" ->
        "before:bg-gray-500 dark:before:bg-gray-400"

      "zinc" ->
        "before:bg-zinc-500 dark:before:bg-zinc-400"

      "neutral" ->
        "before:bg-neutral-500 dark:before:bg-neutral-400"

      "stone" ->
        "before:bg-stone-500 dark:before:bg-stone-400"

      _ ->
        "before:bg-(--badge-dot-color)"
    end
  end

  ## Alerts

  def alert_cx(%{intent: intent}) do
    case intent do
      "default" ->
        "bg-surface-10 border-surface-30 text-content"

      "primary" ->
        "bg-primary/10 border-primary/20 text-primary dark:bg-primary/5 dark:border-primary/15"

      "secondary" ->
        "bg-secondary/10 border-secondary/20 text-secondary dark:bg-secondary/5 dark:border-secondary/15"

      "info" ->
        "bg-blue-50 border-blue-200 text-blue-800 dark:bg-blue-950/30 dark:border-blue-800/30 dark:text-blue-200"

      "success" ->
        "bg-green-50 border-green-200 text-green-800 dark:bg-green-950/30 dark:border-green-800/30 dark:text-green-200"

      "warning" ->
        "bg-amber-50 border-amber-200 text-amber-800 dark:bg-amber-950/30 dark:border-amber-800/30 dark:text-amber-200"

      "danger" ->
        "bg-red-50 border-red-200 text-red-800 dark:bg-red-950/30 dark:border-red-800/30 dark:text-red-200"
    end
  end

  def default_alert_icon(%{intent: intent}) do
    case intent do
      "default" -> "hero-information-circle"
      "info" -> "hero-information-circle"
      "success" -> "hero-check-circle"
      "warning" -> "hero-exclamation-triangle"
      "danger" -> "hero-exclamation-circle"
      _ -> nil
    end
  end

  ## Flash Messages

  def flash_cx(%{kind: kind}) do
    case kind do
      :info ->
        "border-blue-200 text-blue-800 bg-blue-50 dark:bg-blue-950/30 dark:border-blue-800/30 dark:text-blue-200"

      :error ->
        "border-red-200 text-red-800 bg-red-50 dark:bg-red-950/30 dark:border-red-800/30 dark:text-red-200"

      _ ->
        "border-surface-30 text-content-10"
    end
  end

  ## Helpers

  def radius_class(radius) do
    case radius do
      "xs" -> "rounded-xs"
      "sm" -> "rounded-sm"
      "md" -> "rounded-md"
      "lg" -> "rounded-lg"
      "xl" -> "rounded-xl"
      "2xl" -> "rounded-2xl"
      "3xl" -> "rounded-3xl"
      "4xl" -> "rounded-4xl"
      "full" -> "rounded-full"
      "none" -> "rounded-none"
      _ -> nil
    end
  end

  def radius_var(radius) do
    case radius do
      "xs" -> "var(--radius-xs)"
      "sm" -> "var(--radius-sm)"
      "md" -> "var(--radius-md)"
      "lg" -> "var(--radius-lg)"
      "xl" -> "var(--radius-xl)"
      "2xl" -> "var(--radius-2xl)"
      "3xl" -> "var(--radius-3xl)"
      "4xl" -> "var(--radius-4xl)"
      "full" -> "calc(infinity * 1px)"
      "none" -> "0"
      _ -> nil
    end
  end
end
