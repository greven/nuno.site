defmodule SiteWeb.ChartComponents do
  @moduledoc """
  Chart / Data Visualization components and helpers.
  """

  use SiteWeb, :html

  # Default plot dimensions
  @plot_width 100
  @plot_height 100

  # Corner geometry (viewBox units) applied to the top of each bar
  @bar_radius 1
  @bar_corner_height 2.5

  # Plot insets (viewBox units) reserved around the plot area
  @plot_top 5
  @plot_bottom 95
  @plot_left 5
  @plot_right 5

  # How far the axis extends past the last gridline, as a fraction of the step;
  # gives the tallest bar a little breathing room without an extra gridline
  @plot_grace 0.2

  # Default target number of y-axis intervals used to compute gridline density
  @gridline_count 4

  # Stagger (ms) between consecutive bars when they animate in
  @bar_stagger_ms 50

  # X-axis label heuristics: assumed rendered plot width (px) and estimated
  # pixel width per label character at text-xs (~12px font). Used to space
  # labels so they don't overlap or truncate when there are many bars.
  @label_plot_width 360
  @label_char_width 7

  @doc """
  Renders a vertical bar chart from a list of points.

  Each point is a map:
    * `:label` - string rendered under the bar (HTML, truncates)
    * `:value` - integer, bar height is proportional to the axis max
    * `:dim` - optional boolean, renders the bar dimmed (e.g. an in-progress period)

  The y-axis is scaled to a "nice" max just above the highest value: the axis
  extends a fraction of a step past the last gridline, so the tallest bar keeps
  a little breathing room from the top of the chart without an extra gridline.
  The plot is padded on all sides so bars don't touch the chart edges.
  Horizontal gridlines are drawn at nice intervals (e.g. a chart peaking at
  4_000 gets lines at 1_000, 2_000, 3_000, 4_000 and 5_000) with abbreviated
  value labels next to them. Density is controlled by `tick_count` and label
  formatting by `format_axis`.

  X-axis labels are spaced so only as many render as fit comfortably: with more
  bars than labels can show, every Nth label is drawn, always keeping the first
  and last. By default the step is estimated from the label text; pass
  `max_labels` to set the count explicitly.

  ## Examples

      <.bar_chart
        points={[
          %{label: "Jan", value: 120},
          %{label: "Feb", value: 80, dim: true}
        ]}
        format_value={&Site.Support.format_number(&1, 0)}
      />
  """

  attr :points, :list, required: true
  attr :bar_class, :string, default: "fill-primary", doc: "Tailwind fill-* classes for the bars"
  attr :height_class, :string, default: "h-44"
  attr :format_value, :fun, default: nil, doc: "fun (value) -> binary, used for tooltips"
  attr :gridlines, :boolean, default: true, doc: "render horizontal gridlines and y-axis labels"

  attr :tick_count, :integer,
    default: @gridline_count,
    doc: "target number of y-axis intervals (actual density snaps to nice steps)"

  attr :format_axis, :fun,
    default: &Site.Support.abbreviate_number/1,
    doc: "fun (value) -> binary used for y-axis tick labels"

  attr :max_labels, :integer,
    default: nil,
    doc: "max x-axis labels; nil spaces them automatically so they don't overlap"

  attr :aria_label, :string, default: nil, doc: "accessible label for the chart"
  attr :class, :any, default: nil
  attr :rest, :global

  def bar_chart(assigns) do
    max_value = chart_max_value(assigns.points)
    {ticks, axis_max} = y_axis(max_value, assigns.tick_count)

    assigns =
      assigns
      |> assign(:axis_max, axis_max)
      |> assign(:gridline_rows, gridline_rows(ticks, axis_max, assigns.format_axis))
      |> assign(:bars, bar_geometry(assigns.points, axis_max))
      |> assign(:labels, label_visibility(assigns.points, assigns.max_labels))

    ~H"""
    <div class={["w-full", @class]} {@rest}>
      <div class="flex w-full items-start">
        <div :if={@gridlines} class={["relative w-9 shrink-0 mr-1.5", @height_class]}>
          <span
            :for={line <- @gridline_rows}
            class="absolute right-0 -translate-y-1/2 text-[10px] leading-none text-content-40 tabular-nums"
            style={"top: #{line.y}%"}
          >
            {line.label}
          </span>
        </div>

        <div class="min-w-0 flex-1">
          <svg
            class={["block w-full", @height_class]}
            viewBox={view_box()}
            preserveAspectRatio="none"
            role="img"
            aria-label={@aria_label}
          >
            <g :if={@gridlines} class="stroke-content-40/30" stroke-width="0.5" aria-hidden="true">
              <line
                :for={line <- @gridline_rows}
                x1="0"
                x2={plot_width()}
                y1={line.y}
                y2={line.y}
              />
            </g>

            <g :for={bar <- @bars} class="bar">
              <title>{bar_title(bar.point.label, bar.point.value, @format_value)}</title>
              <rect
                class="hit"
                x={bar.x}
                y={plot_top()}
                width={bar.width}
                height={plot_range()}
                fill="transparent"
              />
              <path
                d={bar.path}
                class={[
                  "bar-grow transition-all hover:brightness-110",
                  @bar_class,
                  bar.point[:dim] && "opacity-45 hover:opacity-100"
                ]}
                style={"animation-delay: #{bar.delay}ms"}
              />
            </g>
          </svg>

          <div class="relative h-4 mt-1.5">
            <div
              :for={label <- @labels}
              title={label.label}
              class="absolute top-0 -translate-x-1/2 text-center text-xs leading-none text-content-40 truncate"
              style={"left: #{label.left}%; max-width: #{label.max_width}px"}
            >
              {label.label}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Placeholder bar chart used while data is loading. Mirrors the layout of
  `bar_chart/1` (y-axis gutter, gridlines, padded slots, x-label row) so the
  final chart replaces it without a layout shift.

  ## Examples

      <ChartComponents.bar_chart_skeleton bars={12} />
  """

  attr :bars, :integer, default: 12
  attr :gridlines, :boolean, default: true
  attr :class, :any, default: nil
  attr :height_class, :string, default: "h-44"
  attr :rest, :global

  def bar_chart_skeleton(assigns) do
    assigns =
      assign(assigns, :skeleton_bars, skeleton_bars(assigns.bars))
      |> assign(:gridline_ys, skeleton_gridline_ys())

    ~H"""
    <div class={["w-full", @class]} {@rest}>
      <div class="flex w-full items-start">
        <div :if={@gridlines} class={["relative w-9 shrink-0 mr-1.5", @height_class]}></div>

        <div class="min-w-0 flex-1">
          <svg
            class={["block w-full", @height_class]}
            viewBox={view_box()}
            preserveAspectRatio="none"
            aria-hidden="true"
          >
            <g :if={@gridlines} class="stroke-content-40/30" stroke-width="0.5" aria-hidden="true">
              <line :for={y <- @gridline_ys} x1="0" x2={plot_width()} y1={y} y2={y} />
            </g>

            <path :for={bar <- @skeleton_bars} d={bar.path} class="fill-surface-30 animate-pulse" />
          </svg>

          <div class="relative h-4 mt-1.5"></div>
        </div>
      </div>
    </div>
    """
  end

  # The SVG viewBox, e.g. "0 0 100 100". Keep in sync with the plot constants.
  defp view_box, do: "0 0 #{plot_width()} #{plot_height()}"

  defp plot_width, do: @plot_width
  defp plot_height, do: @plot_height
  defp plot_top, do: @plot_top
  defp plot_bottom, do: @plot_bottom
  defp plot_left, do: @plot_left
  defp plot_right, do: @plot_right
  defp plot_range, do: @plot_bottom - @plot_top

  # Highest value across all points; never below 1 so an all-zero chart still
  # renders bars.
  defp chart_max_value(points) do
    points
    |> Enum.map(& &1.value)
    |> Enum.max(fn -> 0 end)
    |> max(1)
  end

  # "Nice" y-axis ticks plus the axis max they imply. The axis tops out at the
  # next nice step above the highest value and extends a little past it (see
  # @plot_grace), so the tallest bar keeps a small amount of headroom without
  # adding a gridline, e.g. a max of 4_000 becomes an axis of 0..5_200 with
  # gridlines every 1_000.
  defp y_axis(max_value, target) do
    step = nice_step(max_value, target)
    tick_count = floor(max_value / step) + 1
    axis_max = (tick_count + @plot_grace) * step
    ticks = Enum.map(0..tick_count, fn index -> round_tick(index * step) end)

    {ticks, axis_max}
  end

  # Pick a step from 1, 2, 5 or 10 times a power of ten so `max_value` is split
  # into roughly `target` intervals, the same "nice ticks" approach used by d3
  # and Chart.js.
  defp nice_step(max_value, target) do
    raw_step = max_value / max(target, 1)
    magnitude = 10 ** :math.floor(:math.log10(raw_step))
    residual = raw_step / magnitude

    multiplier =
      cond do
        residual >= 7.5 -> 10
        residual >= 3.5 -> 5
        residual >= 1.5 -> 2
        true -> 1
      end

    multiplier * magnitude
  end

  # Snap tick values back to clean numbers: integral floats (from power-of-ten
  # steps like 5000.0) become integers so formatters like abbreviate_number/1
  # (which uses div/2) work, and float steps (e.g. 0.2) lose accumulation errors
  # like 0.6000000000000001 while keeping their decimals.
  defp round_tick(tick) when is_integer(tick), do: tick

  defp round_tick(tick) do
    rounded = Float.round(tick, 10)

    if rounded == trunc(rounded) do
      trunc(rounded)
    else
      rounded
    end
  end

  # Gridline geometry (y in viewBox units) plus the rendered tick label. y is
  # rounded so it doubles as a clean CSS `top` percentage for the label column.
  defp gridline_rows(ticks, axis_max, format_axis) do
    Enum.map(ticks, fn tick ->
      %{y: Float.round(y_position(tick, axis_max), 4), label: format_axis.(tick)}
    end)
  end

  # y position in viewBox units for a value on the axis; the top of the plot is
  # `@plot_top` and the bottom (0 baseline) is `@plot_bottom`.
  defp y_position(tick, axis_max) do
    plot_bottom() - tick / axis_max * plot_range()
  end

  # Bar height in plot units, with a 2-unit minimum so zero-valued bars stay
  # visible.
  defp bar_height(value, axis_max) do
    max(value / axis_max * plot_range(), 2)
  end

  # SVG path for the visible fill of a bar: rounded top corners (quadratic
  # beziers, like the reference chart) and square bottom corners so the bar
  # sits flat on the baseline. The fill is inset by `radius` on each side,
  # which is what visually separates adjacent bars. The corner curve drops
  # @bar_corner_height (clamped for short bars) so it renders as a proper arc
  # instead of a flattened sliver under the stretched viewBox. Coordinates are
  # rounded to keep the generated path clean.
  defp bar_path(x, y, width, height, radius) do
    corner_height = min(@bar_corner_height, height / 2)
    # radius may be an integer (e.g. `@bar_radius 1`), but Float.round/2 only
    # accepts floats
    r = Float.round(radius * 1.0, 4)
    left_x = Float.round(x + radius, 4)
    right_x = Float.round(x + width - radius, 4)
    top = Float.round(y, 4)
    top_arc_y = Float.round(y + corner_height, 4)
    bottom = Float.round(y + height, 4)
    top_left_x = Float.round(left_x + r, 4)
    top_right_x = Float.round(right_x - r, 4)

    "M #{left_x} #{bottom} " <>
      "L #{left_x} #{top_arc_y} " <>
      "Q #{left_x} #{top} #{top_left_x} #{top} " <>
      "L #{top_right_x} #{top} " <>
      "Q #{right_x} #{top} #{right_x} #{top_arc_y} " <>
      "L #{right_x} #{bottom} Z"
  end

  # Compute each bar's geometry (x/y/width/height) in viewBox units. Bars span
  # the plot between `@plot_left` and `@plot_right`, so the first and last bars
  # don't touch the chart edges. The hit rect spans the full slot and plot
  # height (a generous hover target); the visible fill path is inset by the
  # corner radius.
  defp bar_geometry([], _axis_max), do: []

  defp bar_geometry(points, axis_max) do
    slot = (plot_width() - plot_left() - plot_right()) / length(points)
    radius = min(@bar_radius, slot / 4)

    points
    |> Enum.with_index()
    |> Enum.map(fn {point, index} ->
      height = bar_height(point.value, axis_max)
      x = plot_left() + index * slot
      y = plot_bottom() - height

      %{
        point: point,
        x: x,
        y: y,
        width: slot,
        height: height,
        path: bar_path(x, y, slot, height, radius),
        delay: index * @bar_stagger_ms
      }
    end)
  end

  # Skeleton bar geometries: same slot geometry as the real chart (padded plot,
  # corner-radius inset) with placeholder heights echoing a typical chart
  # silhouette, so the loading state matches the final render.
  defp skeleton_bars(count) when count < 1, do: []

  defp skeleton_bars(count) do
    heights = skeleton_heights()
    slot = (plot_width() - plot_left() - plot_right()) / count
    radius = min(@bar_radius, slot / 4)

    Enum.map(0..(count - 1), fn index ->
      height = Enum.at(heights, rem(index, length(heights))) * plot_range()
      x = plot_left() + index * slot
      y = plot_bottom() - height

      %{path: bar_path(x, y, slot, height, radius)}
    end)
  end

  # Repeating pattern of placeholder bar heights (fraction of the plot range).
  defp skeleton_heights, do: [0.85, 0.55, 0.7, 0.4, 0.95, 0.6, 0.75, 0.5, 0.8, 0.65, 0.45, 0.9]

  # Skeleton gridlines at evenly spaced positions (no data loaded yet).
  defp skeleton_gridline_ys do
    Enum.map(0..4, fn i -> plot_bottom() - i / 4 * plot_range() end)
  end

  # Which x-axis labels to render, as maps centered on each visible bar. Labels
  # are spaced `step` cells apart (first and last always shown); each one is
  # absolutely positioned at its bar's center with a max width equal to its
  # spacing, so text neither overlaps its neighbors nor truncates.
  defp label_visibility(points, max_labels) do
    count = length(points)
    step = label_step(points, max_labels)
    slot = (plot_width() - plot_left() - plot_right()) / max(count, 1)
    max_width = round(step * cell_width(count))

    points
    |> Enum.with_index()
    |> Enum.filter(fn {_point, index} -> rem(index, step) == 0 or index == count - 1 end)
    |> Enum.map(fn {point, index} ->
      %{
        label: point.label,
        left: Float.round(plot_left() + (index + 0.5) * slot, 4),
        max_width: max_width
      }
    end)
  end

  # Label step: how many cells apart labels are shown. `max_labels` forces a
  # count; nil estimates a step from the label text so labels don't overlap.
  defp label_step(points, nil), do: auto_label_step(points)
  defp label_step(_points, max_labels) when max_labels < 1, do: 1
  defp label_step(points, max_labels), do: max(ceil(length(points) / max_labels), 1)

  # Rendered width (px) of one bar slot, assuming the viewBox renders at
  # @label_plot_width px wide.
  defp cell_width(count) do
    slot = (plot_width() - plot_left() - plot_right()) / max(count, 1)
    slot * @label_plot_width / plot_width()
  end

  # Pick the step so each shown label has room for its text: labels need to be
  # at least `ceil(avg_width / cell_width)` cells apart.
  defp auto_label_step(points) do
    count = length(points)
    max(ceil(avg_label_width(points) / max(cell_width(count), 1)), 1)
  end

  # Average estimated pixel width of the labels (text length × char width).
  defp avg_label_width(points) do
    count = length(points)

    points
    |> Enum.map(fn %{label: label} -> max(String.length(label), 1) end)
    |> Enum.sum()
    |> then(&(&1 * @label_char_width / max(count, 1)))
  end

  defp bar_title(label, value, nil), do: "#{label}: #{value}"

  defp bar_title(label, value, format_value) do
    "#{label}: #{format_value.(value)}"
  end
end
