defmodule SiteWeb.Theme do
  @moduledoc """
  Theme supporting functions.
  """

  def colors(:theme), do: ~w(primary secondary info success warning danger)

  def colors(:tailwind) do
    ~w(
        red orange amber yellow lime green emerald teal cyan sky
        blue indigo violet purple fuchsia pink rose
        slate gray zinc neutral stone
    )
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
        "bg-gray-100/50 ring-gray-300/80 text-gray-700 dark:bg-gray-500/10 dark:text-gray-400 dark:ring-gray-400/20"
    end
  end

  def badge_color_class("dot", color) do
    base_class =
      "text-gray-700 ring-1 ring-inset ring-gray-300 dark:text-gray-400 dark:ring-gray-800 before:content=[''] before:size-1.5 before:rounded-full"

    color_class =
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
          "before:bg-(--badge-color)"
      end

    [color_class, base_class]
  end

  def button_variant_class(variant) do
    %{
      "default" => "btn-default",
      "solid" => "btn-solid",
      "light" => "btn-light",
      "outlined" => "btn-outlined",
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
      nil => "btn-neutral"
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
