defmodule ModsynthGui.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

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


    graph =
      Graph.build(styles: styles, font_size: @text_size)
      |> add_specs_to_graph([
      text_field_spec("", id: :text_id, width: 200, hint: "Enter filename", filter: :all, t: {10, 10}),
      ])

    {:ok, graph, push: graph}
  end

  def filter_event({:value_changed, id, value}, _context, graph) do
    graph = if String.ends_with?(value, " ") do
      do_graph(graph, String.slice(value, 0..-2))
    else
      graph
    end
    {:cont, {:value_changed, id, value}, graph, push: graph}
  end

  def do_graph(graph, name) do
      filename = Path.join("../sc_em/examples", name)
      Logger.info("filename is #{filename}")
      {:ok, d} = File.read(filename)
      {:ok, ms} = Jason.decode(d)
      add_specs_to_graph(graph, List.flatten(Enum.map(ms["nodes"], fn node ->
            [rrect_spec({100, 100, 4}, fill: :green, stroke: {4, :yellow}, t: {node["x"], node["y"]}),
            text_spec(node["name"], t: {node["x"] + 10, node["y"] + 30})] end)))
  end

  def filter_event({:click, id}, _context, graph) do
    Logger.info("button clicked: #{id}")
    {:cont, {:click, id}, graph, push: graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received value change: #{inspect(event)}")
    {:noreply, state}
  end
end
