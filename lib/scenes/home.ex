defmodule ModsynthGui.State do
  defstruct  graph: nil,
    size: {1,1},
    id: nil,
    filename: "",
    connections: nil


  @type t :: %__MODULE__{graph: Scenic.Graph,
                         size: tuple,
                         id: atom,
                         filename: String.t,
                         connections: list
  }
end

defmodule ModsynthGui.Scene.Home do
  use Scenic.Scene
  require Logger
  require Modsynth
  require Modsynth.Node
  require Modsynth.Node_Param
  require Modsynth.Connection

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias ModsynthGui.State

  import Scenic.Primitives
  import Scenic.Components

  @text_size 24
  @node_height 100
  @node_width 120
  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    styles = opts[:styles] || %{}
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])
    graph =
      Graph.build(styles: styles, font_size: @text_size, clear_color: :dark_slate_grey)
      |> add_specs_to_graph([
      text_field_spec("", id: :text_id, width: 200, hint: "Enter filename", filter: :all, t: {10, 10}),
      button_spec("load", id: :load_button, t: {215, 10}),
      button_spec("clear", id: :clear_button, t: {280, 10}),
      button_spec("rand", id: :rand_button, t: {350, 10}),
      button_spec("play", id: :play_button, t: {410, 10}),
      button_spec("stop", id: :stop_button, t: {470, 10}),
      ])

    {:ok, %State{graph: graph, size: {width, height}}, push: graph}
  end

  ####################################################################
  # scenic callbacks
  ####################################################################


  def filter_event({:value_changed, id, value}, _context, state) do
    {:cont, {:value_changed, id, value}, %{state | filename: value}, push: state.graph}
  end

  def filter_event({:click, id}, _context, state) do
    state = case id do
              :load_button -> do_graph(state)
              :clear_button ->
                if state.id != nil do
                  Logger.info("delete old graph")
                  %{state | graph: Graph.delete(state.graph, state.id)}
                else
                  state
                end
              :rand_button ->
                filename = Path.join("../sc_em/examples", state.filename <> ".json")
                {_, _, connections} = Modsynth.Rand.play(filename)
                %{state | connections: connections}
              :play_button ->
                filename = Path.join("../sc_em/examples", state.filename <> ".json")
                {_, connections} = Modsynth.play(filename)
                %{state | connections: connections}
              :stop_button ->
                Modsynth.Rand.stop_playing()
                state
            end
    {:cont, {:clicked, id}, state, push: state.graph}
  end

  def handle_input(_event, _context, state) do
    # Logger.info("Received value change: #{inspect(event)}")
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

  @doc """
  since nodes are created in different paths, they often collide in space. This function has a simple
  scheme to reposition nodes that are in conflict with previously placed nodes.

  It simply moves the new node up until no more conflict.
  """
  def recompute_position_if_needed(acc, x, y, id) do
    if Map.has_key?(acc, {x, y}) do
      recompute_position_if_needed(acc, x, y - @node_height * 1.5, id)
    else
      Map.put(acc, {x,y}, id)
    end
  end

  def do_graph(%State{graph: graph, size: {width, height}, filename: name} = state) do
    all_id = String.to_atom(name)
    filename = Path.join("../sc_em/examples", name <> ".json")
    case Modsynth.look(filename) do
      {:error, reason} ->
        Logger.error("filename not valid: #{reason}")
        state
      {nodes, connections} ->
        node_pos_map = reorder_nodes(connections, Map.values(nodes), width, height)
        |> Enum.reduce(%{}, fn {id, {x, y}}, acc -> recompute_position_if_needed(acc, x, y, id) end)
        |> Enum.map(fn {{x, y}, id} -> {id, {x, y}} end)
        |> Enum.into(%{})
        connection_specs = get_connections(connections, node_pos_map, all_id) |> List.flatten
        node_specs = Enum.map(node_pos_map, fn {node_id, {x_pos, y_pos}} ->
          node = nodes[node_id]
          fill_color = case node.control do
                         :gain -> :golden_rod
                         :note -> :dark_orchid
                         _ -> :grey
                       end
          [rrect_spec({@node_width, @node_height, 4}, fill: fill_color, stroke: {2, :yellow}, t: {x_pos, y_pos}, id: all_id),
           text_spec(node.name <> ":" <> Integer.to_string(node_id), t: {x_pos + 10, y_pos + @node_height - 10}, id: all_id)] end)
           |> List.flatten
        %{state | graph: add_specs_to_graph(graph, node_specs ++ connection_specs), id: all_id}
    end
  end

  def get_node_connection_points(connections, from_or_to) do
    Enum.reduce(connections, %{},
      fn c, acc ->
        {id, param} = case from_or_to do
                        :from -> {c.from_node_param.node_id, c.from_node_param.param_name}
                        :to -> {c.to_node_param.node_id, c.to_node_param.param_name}
                      end
        Map.put(acc, id, [param|Map.get(acc, id, [])])
      end)
  end

  def get_connections(connections, node_pos_map, all_id) do
    from_points = get_node_connection_points(connections, :from)
    to_points = get_node_connection_points(connections, :to)
    Enum.map(connections, fn c ->
      from_id = c.from_node_param.node_id
      to_id = c.to_node_param.node_id
      from_param = c.from_node_param.param_name
      to_param = c.to_node_param.param_name
      from_index = Enum.find_index(from_points[from_id], fn x -> x == from_param end)
      to_index = Enum.find_index(to_points[to_id], fn x -> x == to_param end)
      {from_node_x, from_node_y} = node_pos_map[from_id]
      {to_node_x, to_node_y} = node_pos_map[to_id]
      [line_spec({{from_node_x + @node_width, from_node_y + 20 + 40 * from_index},
                 {to_node_x, to_node_y + 20 + 40 * to_index}},
          stroke: {2, :beige}, cap: :round, id: all_id),
       text_spec(from_param, fill: :dark_sea_green,
         t: {from_node_x + @node_width - String.length(from_param) * 12, from_node_y + 20 + 40 * from_index}, id: all_id),
       # rrect_spec({String.length(from_param), 20, 2}, fill: :blue, stroke: {2, :white},
       #   t: {from_node_x + @node_width, from_node_y + 20 + 40 * from_index}, id: all_id),
       text_spec(to_param, fill: :blue, t: {to_node_x + 10, to_node_y + 20 + 40 * to_index}, id: all_id),
       # rrect_spec({String.length(to_param), 20, 2}, fill: :blue, stroke: {2, :white},
       #   t: {to_node_x, to_node_y + 20 + 40 * to_index}, id: all_id)
       ]
      # path_spec([
      #   :begin,
      #   {:move_to, from_node["x"] + 100, from_node["y"] + 50},
      #   {:quadratic_to, from_node["x"], from_node["y"], to_node["x"], to_node["y"] + 50},
      #   :close_path
      # ], stroke: {4, :white}, cap: :round)
    end)
  end

end
