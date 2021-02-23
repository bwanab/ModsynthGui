defmodule ModsynthGui.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  @text_size 24
  #@text_field text_field_spec("", id: :text, width: 240, hint: "Type here...", t: {200, 160})
  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    styles = opts[:styles] || %{}
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    # show the version of scenic and the glfw driver

    quads = [
      rrect_spec(
        {50, 60, 6},
        fill: :green,
        stroke: {6, :yellow},
        t: {85, 0}
      )
    ]

    graph =
      Graph.build(styles: styles, font_size: @text_size)
      |> add_specs_to_graph([
      # group_spec(quads, t: {250, 330}),
      text_field_spec("", id: :text_id, width: 200, hint: "Enter filename", t: {200, 160}),
      # slider_spec({{0, 100}, 0}, id: :num_slider, t: {0, 100}),
      rect_spec({width, height})
      ])

    {:ok, graph, push: graph}
  end

  def handle_input({:value_changed, _id, value}, _context, state) do
    Logger.info("Received value change: #{value}")
    {:noreply, state}
  end

  def handle_input(_event, _context, state) do
    # Logger.info("Received value change: #{value}")
    {:noreply, state}
  end
end
