defmodule ModsynthGui.EtsState do
  defstruct nodes: %{},
    connections: [],
    width: 1000,
    height: 600,
    all_id: nil,
    filename: "",
    rand_pid: nil

  @type t :: %__MODULE__{nodes: map,
                         connections: list,
                         width: integer,
                         height: integer,
                         all_id: atom,
                         filename: String.t,
                         rand_pid: reference
  }
end
