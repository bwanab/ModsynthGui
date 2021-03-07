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

  @text_size 24

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
      [current: %EtsState{nodes: nodes, connections: connections}] ->
        {columns, rows} = monitor_data(nodes, connections)
        Scenic.Table.Components.table(graph, columns, rows, t: {10, 10})
    end
  end

  def monitor_data(nodes, connections) do
    {["bus id", "param spec"],
    Enum.map(connections, fn %Connection{bus_id: bus_id, desc: desc, from_node_param: from_node, to_node_param: to_node} ->
      ["#{bus_id}", desc <> ": " <> from_node.param_name <> " -> " <> to_node.param_name]
    end )}
  end
end
