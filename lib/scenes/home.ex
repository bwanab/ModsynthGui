defmodule ModsynthGui.Scene.Home do
  use Scenic.Scene
  require Logger
  require Modsynth
  require Modsynth.Node
  require Modsynth.Node_Param
  require Modsynth.Connection

  alias Scenic.Graph
  alias Scenic.ViewPort

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
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])
    graph =
      Graph.build(styles: styles, font_size: @text_size)
      |> add_specs_to_graph([
      text_field_spec("", id: :text_id, width: 200, hint: "Enter filename", filter: :all, t: {10, 10}),
      ])

    {:ok, %{graph: graph, size: {width, height}}, push: graph}
  end

  def filter_event({:value_changed, id, value}, _context, state) do
    state = if String.ends_with?(value, " ") do
      do_graph(state, String.slice(value, 0..-2))
    else
      state
    end
    {:cont, {:value_changed, id, value}, state, push: state.graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received value change: #{inspect(event)}")
    {:noreply, state}
  end

  ####################################################################
  # non-scenic processing follows
  ####################################################################

  def map_nodes_by_node_id(nodes) do
    Enum.map(nodes, fn node ->
      %{node_id: node_id} = node
      {node_id, node}
    end)
    |> Enum.into(%{})
  end

  @doc """
  This is the same process as reorder_nodes in modsynth. There the reason is that supercollider
  needs the nodes to be instantiated in the right order. Here it is to build the display in a
  way that shows the processing graph.
  """
  def reorder_nodes(connections, nodes, width, height) do
    audio_out = Enum.find(nodes, fn node -> node.name == "audio-out" end).node_id
    reorder_nodes(connections, audio_out, 0, 0, width, height)
    |> List.flatten |> Enum.reject(&is_nil/1) |> Enum.uniq
  end

  def reorder_nodes(connections, node_id, x, y, width, height) do
    x_pos = width - @node_width - (@node_width * 1.5 * x)
    y_pos = height - (@node_height) - (@node_height * 1.5 * y)
    nodes = for c when c.to_node_param.node_id == node_id <- connections do c.from_node_param.node_id end
    len = length(nodes)
    [{node_id, {x_pos, y_pos}}]
    ++ for {innode, index} <- Enum.with_index(nodes), do: reorder_nodes(connections, innode, x + 1, len - index, width, height)

  end

  def recompute_position_if_needed(acc, x, y, id) do
    if Map.has_key?(acc, {x, y}) do
      recompute_position_if_needed(acc, x, y - @node_height * 1.5, id)
    else
      Map.put(acc, {x,y}, id)
    end
  end

  def do_graph(%{graph: graph, size: {width, height}}, name) do
      filename = Path.join("../sc_em/examples", name <> ".json")
      {nodes, connections} = Modsynth.look(filename)
      node_pos_map = reorder_nodes(connections, Map.values(nodes), width, height)
      |> Enum.reduce(%{}, fn {id, {x, y}}, acc -> recompute_position_if_needed(acc, x, y, id) end)
      |> Enum.map(fn {{x, y}, id} -> {id, {x, y}} end)
      |> Enum.into(%{})
      connection_specs = get_connections(connections, node_pos_map)
      node_specs = Enum.map(node_pos_map, fn {node_id, {x_pos, y_pos}} ->
        node = nodes[node_id]
        [rrect_spec({@node_width, @node_height, 4}, fill: :green, stroke: {4, :yellow}, t: {x_pos, y_pos}),
         text_spec(node.name <> ":" <> Integer.to_string(node_id), t: {x_pos + 10, y_pos + 30})] end)
      |> List.flatten
      %{graph: add_specs_to_graph(graph, node_specs ++ connection_specs), size: {width, height}}
  end

  def get_connections(connections, node_pos_map) do
    Enum.map(connections, fn c ->
      {from_node_x, from_node_y} = node_pos_map[c.from_node_param.node_id]
      {to_node_x, to_node_y} = node_pos_map[c.to_node_param.node_id]
      line_spec({{from_node_x + @node_width, from_node_y + 50}, {to_node_x, to_node_y + 50}}, stroke: {4, :white}, cap: :round)
      # path_spec([
      #   :begin,
      #   {:move_to, from_node["x"] + 100, from_node["y"] + 50},
      #   {:quadratic_to, from_node["x"], from_node["y"], to_node["x"], to_node["y"] + 50},
      #   :close_path
      # ], stroke: {4, :white}, cap: :round)
    end)
  end

end
