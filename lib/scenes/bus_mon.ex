defmodule ModsynthGui.Scene.BusMon do
  use Scenic.Scene
  require Logger
  require Modsynth
  alias Modsynth.Node
  alias Modsynth.Node_Param
  alias Modsynth.Connection

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias ModsynthGui.State
  alias ModsynthGui.Component.Nav
  alias ModsynthGui.EtsState

  import Scenic.Primitives
  import Scenic.Components

  @text_size 24
  @node_height 100
  @node_width 120
  @after_nav 60
  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    styles = opts[:styles] || %{}
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])
    graph =
      Graph.build(styles: styles, font_size: @text_size, clear_color: :dark_slate_grey)
      |> Nav.add_to_graph(__MODULE__)
      |> do_mon_if_already_loaded

    {:ok, %State{graph: graph, size: {width, height}, viewport: opts[:viewport]}, push: graph}
  end

  ####################################################################
  # scenic callbacks
  ####################################################################

  def handle_input(_event, _context, state) do
    # Logger.info("Received value change: #{inspect(event)}")
    {:noreply, state}
  end

  ####################################################################
  # non-scenic processing follows
  ####################################################################

  def do_mon_if_already_loaded(graph) do
    case :ets.lookup(:modsynth_graphs, :current) do
      [] -> {graph, nil}
      [current: %EtsState{nodes: nodes, connections: connections, width: width,
                           height: height, all_id: all_id, rand_pid: pid}] ->
        specs = draw_monitor(nodes, connections, width, height, all_id)
        add_specs_to_graph(graph, specs)
    end
  end

  def draw_monitor(nodes, connections, width, height, all_id) do
    Enum.map(Enum.with_index(connections), fn {%Connection{bus_id: bus_id, desc: desc, from_node_param: from_node, to_node_param: to_node}, i} ->
      # Logger.info("bus_id: #{bus_id}, desc: #{desc} from_param: #{from_node.param_name}, to_param: #{to_node.param_name}")
      w = 10
      h = 100 + (i * 30)
      [
        text_spec("#{bus_id}", fill: :white, t: {w, h}),
        text_spec(desc <> ": " <> from_node.param_name <> " -> " <> to_node.param_name, fill: :white, t: {w + 100, h})
      ]
      end
    ) |> List.flatten
  end
end
