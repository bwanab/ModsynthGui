defmodule ModsynthGui.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  # alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  @text_size 24
  @node_height 100
  @node_width 120
  #@text_field text_field_spec("", id: :text, width: 240, hint: "Type here...", t: {200, 160})
  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    styles = opts[:styles] || %{}
    # {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])
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
      filename = Path.join("../sc_em/examples", name <> ".json")
      Logger.info("filename is #{filename}")
      {:ok, d} = File.read(filename)
      {:ok, ms} = Jason.decode(d)
      node_map = Enum.map(ms["nodes"], fn node -> {node["id"], node} end) |> Enum.into(%{})
      node_specs =  Enum.map(ms["nodes"], fn node ->
            [rrect_spec({@node_width, @node_height, 4}, fill: :green, stroke: {4, :yellow}, t: {node["x"], node["y"]}),
             text_spec(node["name"] <> ":" <> Integer.to_string(node["id"]), t: {node["x"] + 10, node["y"] + 30})] end)
      |> List.flatten
      connection_specs = get_connections(ms["connections"], node_map)
      add_specs_to_graph(graph, node_specs ++ connection_specs)
  end

  def get_connections(connections, node_map) do
    Enum.map(connections, fn c ->
      from_node = node_map[c["from_node"]["id"]]
      to_node = node_map[c["to_node"]["id"]]
      Logger.info("#{from_node["x"]}, #{from_node["y"]}, #{to_node["x"]}, #{to_node["y"]}")
      line_spec({{from_node["x"] + @node_width, from_node["y"] + 50}, {to_node["x"], to_node["y"] + 50}}, stroke: {4, :white}, cap: :round)
      # path_spec([
      #   :begin,
      #   {:move_to, from_node["x"] + 100, from_node["y"] + 50},
      #   {:quadratic_to, from_node["x"], from_node["y"], to_node["x"], to_node["y"] + 50},
      #   :close_path
      # ], stroke: {4, :white}, cap: :round)
    end)
  end

  def handle_input(event, _context, state) do
    Logger.info("Received value change: #{inspect(event)}")
    {:noreply, state}
  end
end
