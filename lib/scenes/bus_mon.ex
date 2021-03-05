defmodule ModsynthGui.Scene.BusMon do
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


end
