defmodule ModsynthGui.State do
  defstruct  graph: nil,
    viewport: nil,
    ets_state: nil,
    examples_dir: ""

  @type t :: %__MODULE__{graph: Scenic.Graph,
                         viewport: Scenic.ViewPort,
                         ets_state: ModsynthGui.EtsState,
                         examples_dir: String.t
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
  alias ModsynthGui.Component.Nav
  alias ModsynthGui.EtsState

  import Scenic.Primitives
  import Scenic.Components

  @text_size 24
  @node_height 110
  @node_height_inc 40
  @node_width 120
  @after_nav 60
  @below_circuits 100
  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    examples_dir = Application.get_env(:modsynth_gui, :examples_dir)
    initial_circuit = Application.get_env(:modsynth_gui, :initial_circuit)
    styles = opts[:styles] || %{}
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])
    ets_state = case :ets.lookup(:modsynth_graphs, :current) do
                  [] -> %EtsState{width: width, height: height, filename: initial_circuit}
                  [current: ets_state] -> ets_state
                end
    circuits = File.ls!(examples_dir) |> Enum.filter(&(String.ends_with?(&1, ".json"))) |> Enum.sort
    {graph, all_id} =
      Graph.build(styles: styles, font_size: @text_size, clear_color: :dark_slate_grey)
      |> add_specs_to_graph([
      #text_field_spec(ets_state.filename, id: :filename_id, width: 200, hint: "Enter filename", filter: :all, t: {10, @after_nav}),
      dropdown_spec({Enum.map(circuits, &({&1, &1})), "fat-saw-reverb.json"}, t: {100, @after_nav}, id: :circuit_dropdown),
      dropdown_spec({
        [{"load", :load_button},
        {"clear", :clear_button},
        {"rand", :rand_button},
        {"play", :play_button},
        {"stop", :stop_button}],
          :load_button}, id: :dropdown, t: {10, @after_nav})])
      |> Nav.add_to_graph(__MODULE__)
      |> do_graph_if_already_loaded(ets_state)

      {:ok, %State{graph: graph, viewport: opts[:viewport], ets_state: %{ets_state | all_id: all_id}, examples_dir: examples_dir},
       push: graph}
  end

  ####################################################################
  # scenic callbacks
  ####################################################################


  def filter_event({:value_changed, :filename_id, value} = event, _context, %State{ets_state: ets_state} = state) do
    {:cont, event, %{state | ets_state: %{ets_state | filename: value}}, push: state.graph}
  end

  def filter_event({:value_changed, :circuit_dropdown, value} = event, _context, %State{ets_state: ets_state} = state) do
    {:cont, event, %{state | ets_state: %{ets_state | filename: value}}, push: state.graph}
  end

  def filter_event({:value_changed, :control_dropdown, value} = event, _context, %State{ets_state: ets_state} = state) do

    control_val = ScClient.get_control_val(value, "in")
    ets_state = %{ets_state |
                  current_control: value,
                  current_control_val: control_val}
    {graph, all_id} =
      do_graph_if_already_loaded(state.graph, ets_state)
    {:cont, event, %{state | ets_state: ets_state}, push: graph}
  end

  def filter_event({:value_changed, :dropdown, id} = event, _context, state) do
    state = case id do
              :load_button -> do_graph(state)
              :clear_button ->
                if state.ets_state.all_id != nil do
                  %{state | graph: Graph.delete(state.graph, state.ets_state.all_id)}
                else
                  state
                end
              :rand_button ->
                play(&Modsynth.Rand.play/1, state)
              :play_button ->
                play(&Modsynth.play/1, state)
              :stop_button ->
                Modsynth.Rand.stop_playing()
                state
            end
    {:cont, event, state, push: state.graph}
  end

  def handle_input(_event, _context, state) do
    # Logger.info("Received value change: #{inspect(event)}")
    {:noreply, state}
  end

  ####################################################################
  # non-scenic processing follows
  ####################################################################

  def play(play_fun, %State{ets_state: ets_state, examples_dir: examples_dir, graph: graph} = state) do
    filename = Path.join(examples_dir, ets_state.filename)
    {controls, node_map, connections} = play_fun.(filename)
    ets_state = %{ets_state | connections: connections, nodes: node_map, controls: controls}
    :ets.insert(:modsynth_graphs, {:current, ets_state})
    {graph, _all_id} = Graph.delete(graph, ets_state.all_id)
    |> do_graph_if_already_loaded(ets_state)
    {ets_state, graph}
    %{state | ets_state: ets_state, graph: graph}
  end

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
    ++ for {innode, index} <- Enum.with_index(Enum.reverse(nodes)), do: reorder_nodes(connections, innode, x + 1, len - index, width, height)

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

  def do_graph(%State{graph: graph, ets_state: %{width: width, height: height, filename: name}, examples_dir: examples_dir} = state) do
    all_id = String.to_atom(name)
    filename = Path.join(examples_dir, name)
    case Modsynth.look(filename) do
      {:error, reason} ->
        Logger.error("filename not valid: #{reason}")
        state
      {nodes, connections, _} ->
        ets_state = %EtsState{nodes: nodes, connections: connections, width: width,
                              height: height, all_id: all_id,
                              filename: name}
        :ets.insert(:modsynth_graphs, {:current, ets_state})
        {specs, all_id} = draw_graph(ets_state)
        graph = if state.ets_state.all_id != 0 do
          Graph.delete(graph, state.ets_state.all_id)
        else
          graph
        end
        |> add_specs_to_graph(specs)
        %{state | graph: graph, ets_state: %{ets_state | all_id: all_id}}
    end
  end

  def do_graph_if_already_loaded(graph, ets_state) do
    case ets_state do
      %EtsState{connections: []} -> {graph, nil}
      _ ->
        {specs, all_id} = draw_graph(ets_state)
        {add_specs_to_graph(graph, specs), all_id}
    end
  end

  def draw_graph(%EtsState{nodes: nodes,
                           connections: connections,
                           controls: controls,
                           current_control: current_control,
                           current_control_val: current_control_val,
                           width: width,
                           height: height,
                           all_id: all_id}) do
    control_data = Enum.map(controls, fn {name, id, _, to, _} ->
      {List.last(String.split(name, "_")) <> ":" <> to, id}
    end)
    dd = if length(control_data) > 0 do
      current_control_disp = if current_control != 0 do
        current_control else elem(Enum.at(control_data, 0),1) end
      [dropdown_spec({control_data, current_control_disp},
          t: {10, @below_circuits}, id: :control_dropdown),
       text_field_spec("#{Float.round(current_control_val, 3)}", id: :control_val_id, t: {220, @below_circuits})
      ]
    else
      []
    end

    node_pos_map = reorder_nodes(connections, Map.values(nodes), width, height)
    |> Enum.reduce(%{}, fn {id, {x, y}}, acc -> recompute_position_if_needed(acc, x, y, id) end)
    |> Enum.map(fn {{x, y}, id} -> {id, {x, y}} end)
    |> Enum.into(%{})
    connection_specs = get_connections(connections, node_pos_map, all_id) |> List.flatten
    node_sizes = get_node_sizes(nodes, connections)
    node_specs = Enum.map(node_pos_map, fn {node_id, {x_pos, y_pos}} ->
      node = nodes[node_id]
      node_size = Map.get(node_sizes, node_id, 0)
      build_node(node, node_size, all_id, x_pos, y_pos) end)
      |> List.flatten
    {dd ++ node_specs ++ connection_specs, all_id}
  end

  def build_node(node, node_size, all_id, x_pos, y_pos) do
    fill_color = case node.control do
                   :gain -> :golden_rod
                   :note -> :dark_orchid
                   _ -> :grey
                 end
      node_height = @node_height + if node_size > 3 do @node_height_inc * (node_size - 3) else 0 end
      group_spec(
        [rrect_spec({@node_width, node_height, 4}, fill: fill_color, stroke: {2, :yellow}, t: {0, 0}),
         text_spec("#{node.sc_id}", t: {60, 5 + node_height - round(node_height / 2)}),
         text_spec(node.name <> ":" <> Integer.to_string(node.node_id), t: {10, node_height - 30})],
        t: {x_pos, y_pos}, id: all_id)
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

  def get_node_sizes(nodes, connections) do
    from_points = get_node_connection_points(connections, :from)
    to_points = get_node_connection_points(connections, :to)
    Enum.map(Map.keys(nodes), fn id ->
      {id, max(length(Map.get(from_points, id, [])), length(Map.get(to_points, id, [])))}
    end)
    |> Enum.into(%{})
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
