defmodule ModsynthGui.EtsState do
  defstruct nodes: %{},
    connections: [],
    controls: [],
    current_control: 0,
    current_control_val: 0.0,
    width: 1000,
    height: 600,
    all_id: nil,
    filename: ""

  @type t :: %__MODULE__{nodes: map,
                         connections: list,
                         controls: list,
                         current_control: integer,
                         current_control_val: float,
                         width: integer,
                         height: integer,
                         all_id: atom,
                         filename: String.t
  }
end
