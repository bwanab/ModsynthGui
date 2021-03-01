# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Configure the main viewport for the Scenic application
config :modsynth_gui, :viewport, %{
  name: :main_viewport,
  size: {1400, 800},
  default_scene: {ModsynthGui.Scene.Home, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: true, title: "modsynth_gui"]
    }
  ]
}

config :sc_em,
  port: 57110,
  ip: {192,168,4,39},
  remote_synth_dir: "/home/bill/Dropbox/music/supercollider/synthdefs/modsynth",
  local_synth_dir: "/Users/williamallen/Dropbox/music/supercollider/synthdefs/modsynth"


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
