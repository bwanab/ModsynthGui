defmodule ModsynthGui.Component.Nav do
  use Scenic.Component

  alias Scenic.ViewPort
  alias Scenic.Graph

  import Scenic.Primitives, only: [{:text, 3}, {:rect, 3}]
  import Scenic.Components, only: [{:dropdown, 3}]

  # import IEx

  @height 60

  # --------------------------------------------------------
  @impl true
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  # ----------------------------------------------------------------------------
  @impl true
  def init(current_scene, opts) do
    styles = opts[:styles] || %{}

    # Get the viewport width
    {:ok, %ViewPort.Status{size: {width, _}}} =
      opts[:viewport]
      |> ViewPort.info()

    graph =
      Graph.build(styles: styles, font_size: 20)
      |> rect({width, @height}, fill: {48, 48, 48})
      |> text("Scene:", translate: {14, 35}, align: :right)
      |> dropdown(
        {[
           {"Circuit", ModsynthGui.Scene.Home},
           {"Bus Monitor", ModsynthGui.Scene.BusMon}
         ], current_scene},
        id: :nav,
        translate: {70, 15}
      )

    {:ok, %{graph: graph, viewport: opts[:viewport], ex_state: nil}, push: graph}
  end

  @impl true
  def handle_call({:set_state, ex_state}, _from, state) do
    {:reply, :ok, %{state| ex_state: ex_state}}
  end


  # ----------------------------------------------------------------------------
  @impl true
  def filter_event({:value_changed, :nav, scene}, _, %{viewport: vp} = state)
      when is_atom(scene) do
    ViewPort.set_root(vp, {scene, nil})
    {:halt, state}
  end

  # ----------------------------------------------------------------------------
  @impl true
  def filter_event({:value_changed, :nav, scene}, _, %{viewport: vp} = state) do
    ViewPort.set_root(vp, scene)
    {:halt, state}
  end
end
