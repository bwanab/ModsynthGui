# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Configure the main viewport for the Scenic application
config :modsynth_gui, :viewport, %{
  name: :main_viewport,
  size: {1800, 1000},
  default_scene: {ModsynthGui.Scene.Home, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: true, title: "modsynth_gui"]
    }
  ]
}

config :modsynth_gui,
  examples_dir: "../sc_em/examples",
  initial_circuit: "fat-saw-reverb.json"

config :sc_em,
  port: String.to_integer(System.fetch_env!("SC_PORT")),
  ip: String.split(System.fetch_env!("SC_IP"), ".") |> Enum.map(&(String.to_integer(&1))) |> List.to_tuple,
  remote_synth_dir: System.fetch_env!("MODSYNTH_REMOTE_DIR"),
  local_synth_dir: System.fetch_env!("MODSYNTH_LOCAL_DIR")


config :logger,
  level: :info,
  format: "[$level] $messge $metadata\n",
  metadata: [:error_code, :file, :line]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "prod.exs"
